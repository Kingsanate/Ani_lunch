-- Migration: Add rice_options and meat_options to meal_products
-- Run this in the Supabase SQL editor.
-- These columns control which rice and meat choices are shown to the user
-- in the customization bottom sheet. NULL means show all defaults.

ALTER TABLE meal_products
  ADD COLUMN IF NOT EXISTS rice_options text[],
  ADD COLUMN IF NOT EXISTS meat_options text[];

-- Optional: Set sensible defaults for existing rows (show all options)
-- Uncomment if you want existing rows to have explicit values:
-- UPDATE meal_products
-- SET
--   rice_options = ARRAY['White Rice', 'Brown Rice', 'Jadoh', 'No Rice'],
--   meat_options = ARRAY['Chicken', 'Beef', 'Pork', 'Fish']
-- WHERE rice_options IS NULL OR meat_options IS NULL;
