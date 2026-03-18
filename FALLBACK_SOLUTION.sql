-- Fallback Solution - Complete bypass of any relationship queries
-- Run this in Supabase SQL Editor to create a view that avoids relationship issues

-- Step 1: Create a materialized view that combines the data without relationships
CREATE OR REPLACE VIEW kpi_tiers_with_targets AS
SELECT 
    t.id,
    t.name,
    t.min_assets,
    t.max_assets,
    COALESCE(
        json_agg(
            json_build_object(
                'phase_id', tt.phase_id,
                'target_percentage', tt.target_percentage
            )
        ) FILTER (WHERE tt.phase_id IS NOT NULL),
        '[]'::json
    ) as targets
FROM kpi_tiers t
LEFT JOIN kpi_tier_targets tt ON t.id = tt.tier_id
GROUP BY t.id, t.name, t.min_assets, t.max_assets;

-- Step 2: Test the view (this should work without any relationship syntax)
SELECT 'Testing fallback view:' as status;
SELECT * FROM kpi_tiers_with_targets LIMIT 3;

-- Step 3: Grant permissions on the view
GRANT SELECT ON kpi_tiers_with_targets TO authenticated, anon, service_role;

-- Step 4: Alternative - Create a function that returns combined data
CREATE OR REPLACE FUNCTION get_kpi_tiers_with_targets()
RETURNS TABLE (
    id UUID,
    name TEXT,
    min_assets INTEGER,
    max_assets INTEGER,
    targets JSON
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.name,
        t.min_assets,
        t.max_assets,
        COALESCE(
            json_agg(
                json_build_object(
                    'phase_id', tt.phase_id,
                    'target_percentage', tt.target_percentage
                )
            ) FILTER (WHERE tt.phase_id IS NOT NULL),
            '[]'::json
        ) as targets
    FROM kpi_tiers t
    LEFT JOIN kpi_tier_targets tt ON t.id = tt.tier_id
    GROUP BY t.id, t.name, t.min_assets, t.max_assets;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Test the function
SELECT 'Testing fallback function:' as status;
SELECT * FROM get_kpi_tiers_with_targets() LIMIT 3;

-- Step 6: Grant permissions on the function
GRANT EXECUTE ON FUNCTION get_kpi_tiers_with_targets() TO authenticated, anon, service_role;

-- Step 7: Force refresh all caches
SELECT 'Refreshing all caches:' as status;
NOTIFY pgrst, 'reload_schema';
NOTIFY pgrst, 'reload_config';
