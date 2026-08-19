CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_rider_id ON orders(rider_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_time ON orders(order_time DESC);
CREATE INDEX IF NOT EXISTS idx_orders_rider_status ON orders(rider_id, status) WHERE rider_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_orders_available ON orders(status, rider_id) 
  WHERE rider_id IS NULL AND status IN ('pending', 'ready_for_pickup');
