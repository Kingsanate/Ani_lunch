CREATE OR REPLACE FUNCTION accept_order(p_order_id UUID, p_rider_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_order orders%ROWTYPE;
  v_updated orders%ROWTYPE;
BEGIN
  SELECT * INTO v_order FROM orders WHERE id = p_order_id FOR UPDATE;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Order not found' USING ERRCODE = 'P0002';
  END IF;
  
  IF v_order.rider_id IS NOT NULL THEN
    RAISE EXCEPTION 'Order already accepted by rider %', v_order.rider_id USING ERRCODE = 'P0001';
  END IF;
  
  UPDATE orders 
  SET rider_id = p_rider_id, status = 'accepted', updated_at = NOW()
  WHERE id = p_order_id AND rider_id IS NULL;
  
  GET DIAGNOSTICS v_updated = ROW_COUNT;
  
  IF v_updated = 0 THEN
    RAISE EXCEPTION 'Race condition: order was just taken' USING ERRCODE = 'P0001';
  END IF;
  
  SELECT * INTO v_order FROM orders WHERE id = p_order_id;
  RETURN row_to_json(v_order)::JSONB;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
