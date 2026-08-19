import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// Server-side delivery fee in paise. Centralized here (and in the Go backend)
// so clients can never set it: ₹30 base, free above ₹500 subtotal.
// Override the base via the SUPABASE_FUNCTION env var.
const DELIVERY_FEE_BASE_PAISE = parseInt(Deno.env.get('DELIVERY_FEE_PAISE') ?? '3000', 10)
const FREE_DELIVERY_MIN_PAISE = 50000

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { items, address, paymentMethod, customerLat, customerLng } = await req.json()

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Verify caller identity from the JWT — NEVER trust a client-supplied userId.
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing authorization' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!Array.isArray(items) || items.length === 0) {
      return new Response(
        JSON.stringify({ success: false, error: 'Items must be a non-empty array' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Server-authoritative pricing: fetch current price from the items table.
    let subtotal = 0
    const validatedItems = []
    for (const item of items) {
      const qty = Math.max(1, Math.floor(item.qty || 1))
      const { data: product, error: productError } = await supabase
        .from('items')
        .select('id, price, item_price')
        .eq('id', item.id)
        .single()

      if (productError || !product) {
        return new Response(
          JSON.stringify({ success: false, error: `Product ${item.id} not found` }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      // price is canonical paise (008 backfill); fall back to legacy rupees*100
      const unitPricePaise = (product.price || product.item_price * 100 || 0)
      subtotal += unitPricePaise * qty
      validatedItems.push({ ...item, qty, price_paise: unitPricePaise })
    }

    const deliveryFeePaise = subtotal >= FREE_DELIVERY_MIN_PAISE ? 0 : DELIVERY_FEE_BASE_PAISE
    const totalPaise = subtotal + deliveryFeePaise

    const { data: order, error } = await supabase
      .from('orders')
      .insert({
        user_id: user.id,
        items: validatedItems,
        subtotal_paise: subtotal,
        delivery_fee_paise: deliveryFeePaise,
        discount_paise: 0,
        total_amount_paise: totalPaise,
        status: paymentMethod === 'Online' ? 'pending_payment' : 'pending',
        payment_method: paymentMethod,
        address,
        customer_lat: customerLat,
        customer_lng: customerLng,
        order_time: new Date().toISOString(),
      })
      .select()
      .single()

    if (error) throw error
    return new Response(JSON.stringify({ success: true, order }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    })
  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
