-- Schema Fix for KPI Tier Targets
-- Run this in Supabase SQL Editor to fix schema cache issues

-- 1. Check if tables exist and have correct structure
SELECT 'kpi_tiers' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'kpi_tiers' 
ORDER BY ordinal_position;

SELECT 'kpi_tier_targets' as table_name, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'kpi_tier_targets' 
ORDER BY ordinal_position;

-- 2. Check if foreign key constraints exist
SELECT
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name IN ('kpi_tiers', 'kpi_tier_targets');

-- 3. Fix: Add explicit foreign key constraints if missing
-- Uncomment and run if constraints are missing

-- ALTER TABLE kpi_tier_targets 
--   ADD CONSTRAINT fk_tier_targets_tier 
--   FOREIGN KEY (tier_id) REFERENCES kpi_tiers(id) 
--   ON DELETE CASCADE;

-- ALTER TABLE kpi_tier_targets 
--   ADD CONSTRAINT fk_tier_targets_phase 
--   FOREIGN KEY (phase_id) REFERENCES audit_phases(id) 
--   ON DELETE CASCADE;

-- 4. Refresh schema cache (Supabase specific)
-- This may help refresh the schema cache
NOTIFY pgrst, 'reload_schema';
