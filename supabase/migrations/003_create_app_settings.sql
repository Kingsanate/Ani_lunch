CREATE TABLE IF NOT EXISTS app_settings (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  home_video_url TEXT,
  show_hero_banner BOOLEAN DEFAULT true,
  hero_badge_text TEXT DEFAULT '🔥 Fresh Meat Daily',
  hero_title TEXT DEFAULT 'Your Daily Lunch,\nDelivered Fresh & Fast!',
  hero_subtitle TEXT DEFAULT 'Delicious meals, delivered to your door',
  hero_button_text TEXT DEFAULT 'Order Now',
  footer_subtitle TEXT DEFAULT 'Fresh meat, delivered daily.',
  footer_support_links TEXT DEFAULT 'Help Center, Contact Us, FAQs',
  footer_legal_links TEXT DEFAULT 'Privacy Policy, Terms of Use, Refund Policy',
  footer_copyright TEXT DEFAULT '© 2026 Anilunch. All rights reserved.',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read app_settings" ON app_settings
  FOR SELECT USING (true);

CREATE POLICY "Only admin can modify app_settings" ON app_settings
  FOR ALL USING (auth.role() = 'service_role');

INSERT INTO app_settings (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
