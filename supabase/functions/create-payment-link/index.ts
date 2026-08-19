import { serve } from 'https://deno.land/std@0.208.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { orderId, amount, customerName, customerEmail, customerPhone } = await req.json()
    
    if (!orderId || !amount) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing orderId or amount' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Verify order exists and belongs to the user (using auth context)
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ success: false, error: 'Missing authorization' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get user from JWT
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    if (authError || !user) {
      return new Response(
        JSON.stringify({ success: false, error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify order exists and user owns it
    const { data: order, error: orderError } = await supabase
      .from('orders')
      .select('id, user_id, total_amount_paise, total_amount, status, payment_method')
      .eq('id', orderId)
      .single()

    if (orderError || !order) {
      return new Response(
        JSON.stringify({ success: false, error: 'Order not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify user owns this order
    if (order.user_id !== user.id) {
      return new Response(
        JSON.stringify({ success: false, error: 'Unauthorized' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify order is in a payable state
    if (!['pending_payment', 'pending'].includes(order.status)) {
      return new Response(
        JSON.stringify({ success: false, error: 'Order cannot be paid' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify amount matches (convert to paise for comparison)
    const expectedAmountPaise = order.total_amount_paise || Math.round((order.total_amount || 0) * 100)
    const providedAmountPaise = typeof amount === 'number' ? Math.round(amount * 100) : Math.round(parseFloat(amount) * 100)
    
    if (expectedAmountPaise !== providedAmountPaise) {
      return new Response(
        JSON.stringify({ success: false, error: 'Amount mismatch' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Razorpay integration
    const razorpayKeyId = Deno.env.get('RAZORPAY_KEY_ID')
    const razorpayKeySecret = Deno.env.get('RAZORPAY_KEY_SECRET')
    
    if (!razorpayKeyId || !razorpayKeySecret) {
      return new Response(
        JSON.stringify({ success: false, error: 'Payment provider not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Razorpay order
    const razorpayOrderData = {
      amount: providedAmountPaise, // Razorpay expects amount in paise
      currency: 'INR',
      receipt: orderId,
      notes: {
        order_id: orderId,
        user_id: user.id
      }
    }

    const razorpayAuth = btoa(`${razorpayKeyId}:${razorpayKeySecret}`)
    const razorpayResponse = await fetch('https://api.razorpay.com/v1/orders', {
      method: 'POST',
      headers: {
        `Authorization`: `Basic ${razorpayAuth}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(razorpayOrderData)
    })

    const razorpayOrder = await razorpayResponse.json()

    if (!razorpayResponse.ok) {
      console.error('Razorpay error:', razorpayOrder)
      return new Response(
        JSON.stringify({ success: false, error: 'Failed to create payment order' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update order with Razorpay order ID
    await supabase
      .from('orders')
      .update({ 
        payment_intent_id: razorpayOrder.id,
        payment_status: 'created'
      })
      .eq('id', orderId)

    // Return the payment URL (Razorpay checkout URL)
    // The frontend will use Razorpay's checkout with the order_id
    return new Response(
      JSON.stringify({ 
        success: true, 
        orderId: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency,
        keyId: razorpayKeyId
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Create payment link error:', error)
    return new Response(
      JSON.stringify({ success: false, error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
