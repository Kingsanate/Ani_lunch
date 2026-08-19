ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers read own orders" ON orders
  FOR SELECT USING (auth.uid()::text = user_id);

CREATE POLICY "Customers insert own orders" ON orders
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Customers cancel own pending orders" ON orders
  FOR UPDATE USING (auth.uid()::text = user_id AND status IN ('pending', 'pending_payment'))
  WITH CHECK (status = 'cancelled');

CREATE POLICY "Riders read available orders" ON orders
  FOR SELECT USING (
    rider_id IS NULL AND status IN ('pending', 'ready_for_pickup')
  );

CREATE POLICY "Riders read own orders" ON orders
  FOR SELECT USING (rider_id = auth.uid()::text);

CREATE POLICY "Riders accept orders" ON orders
  FOR UPDATE USING (rider_id = auth.uid()::text OR rider_id IS NULL)
  WITH CHECK (rider_id = auth.uid()::text);

CREATE POLICY "Riders update own order status" ON orders
  FOR UPDATE USING (rider_id = auth.uid()::text)
  WITH CHECK (rider_id = auth.uid()::text);

CREATE POLICY "Admins read all orders" ON orders
  FOR SELECT USING (auth.role() = 'service_role');

CREATE POLICY "Admins update any order" ON orders
  FOR UPDATE USING (auth.role() = 'service_role');
