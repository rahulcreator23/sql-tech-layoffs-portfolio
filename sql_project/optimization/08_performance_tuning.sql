-- =============================================================================
-- FILE: 08_performance_tuning.sql
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: Query optimization, EXPLAIN ANALYZE, index strategies,
--              anti-patterns and their fixes, partitioning
-- DIALECT: PostgreSQL (with notes for MySQL)
-- =============================================================================


-- =============================================================================
-- SECTION 1: EXPLAIN ANALYZE — Understanding Query Plans
-- =============================================================================

-- HOW TO READ EXPLAIN ANALYZE:
-- → Seq Scan:    Full table scan — no index used (costly on large tables)
-- → Index Scan:  Uses an index — fast for selective queries
-- → Index Only:  Reads only index, not heap — fastest possible
-- → Hash Join:   Common join strategy — generally efficient
-- → Nested Loop: Can be slow for large datasets without indexes
-- → cost=X..Y:   Estimated startup cost .. total cost (in arbitrary units)
-- → rows=N:      Estimated output rows
-- → actual time: Real execution time in ms

-- Bad query — full table scan, no filter index:
EXPLAIN ANALYZE
SELECT *
FROM tech_layoffs
WHERE market_condition = 'Recession'
  AND layoff_percentage > 20;

-- After adding index:
-- CREATE INDEX idx_market_layoff_pct ON tech_layoffs (market_condition, layoff_percentage);
-- Rerun EXPLAIN ANALYZE and compare cost change.


-- =============================================================================
-- SECTION 2: Index Strategy Demonstrations
-- =============================================================================

-- 2A. B-TREE index (default) — range queries, equality, ORDER BY
CREATE INDEX IF NOT EXISTS idx_layoffs_year_industry
    ON tech_layoffs (year, industry);

-- Covered by this index: WHERE year = 2025 AND industry = 'AI'
-- Not covered: WHERE industry = 'AI' (first column must be in WHERE or ORDER BY)


-- 2B. Composite index — order matters (leftmost prefix rule)
CREATE INDEX IF NOT EXISTS idx_country_size_year
    ON tech_layoffs (country, company_size, year);

-- Queries that USE this index:
--   WHERE country = 'USA'
--   WHERE country = 'USA' AND company_size = 'Startup'
--   WHERE country = 'USA' AND company_size = 'Startup' AND year = 2025

-- Queries that DO NOT use this index:
--   WHERE company_size = 'Startup'   (skips leftmost column)
--   WHERE year = 2025                (skips both left columns)


-- 2C. Partial index — only index the high-value subset
CREATE INDEX IF NOT EXISTS idx_high_layoff_events
    ON tech_layoffs (company_name, year, layoffs_count)
    WHERE layoffs_count > 5000;
-- This index is smaller and faster for "large layoff" queries


-- 2D. Expression / functional index
CREATE INDEX IF NOT EXISTS idx_company_name_lower
    ON tech_layoffs (LOWER(company_name));

-- Enables case-insensitive search without full scan:
-- WHERE LOWER(company_name) = 'microsoft'


-- 2E. GIN index for array/full-text (PostgreSQL)
CREATE INDEX IF NOT EXISTS idx_reason_fts
    ON tech_layoffs USING GIN (to_tsvector('english', reason_for_layoffs));

-- Enables full-text search:
-- WHERE to_tsvector('english', reason_for_layoffs) @@ plainto_tsquery('automation')


-- =============================================================================
-- SECTION 3: Anti-Patterns & Rewrites
-- =============================================================================

-- ❌ ANTI-PATTERN 1: Function on indexed column kills index usage
-- BAD:
SELECT * FROM tech_layoffs
WHERE YEAR(created_at) = 2025;   -- function wraps the column — index not used

-- ✅ FIX: Use range predicate instead
SELECT * FROM tech_layoffs
WHERE created_at >= '2025-01-01'
  AND created_at <  '2026-01-01';


-- ❌ ANTI-PATTERN 2: SELECT * — fetches all columns unnecessarily
-- BAD:
SELECT * FROM tech_layoffs WHERE country = 'USA';

-- ✅ FIX: Select only needed columns
SELECT company_name, industry, year, layoffs_count
FROM tech_layoffs
WHERE country = 'USA';


-- ❌ ANTI-PATTERN 3: OR on different columns prevents index merge
-- BAD (may cause full table scan):
SELECT * FROM tech_layoffs
WHERE country = 'USA' OR industry = 'AI';

-- ✅ FIX: UNION ALL (each branch can use its own index)
SELECT company_name, country, industry FROM tech_layoffs WHERE country = 'USA'
UNION ALL
SELECT company_name, country, industry FROM tech_layoffs WHERE industry = 'AI'
  AND country != 'USA';  -- avoid duplicates


-- ❌ ANTI-PATTERN 4: Correlated subquery in SELECT (N+1 pattern)
-- BAD: Runs a subquery for every row
SELECT
    company_name,
    (SELECT COUNT(*) FROM tech_layoffs t2 WHERE t2.company_name = t1.company_name) AS event_count
FROM tech_layoffs t1;

-- ✅ FIX: Use window function or JOIN with aggregation
SELECT
    t.company_name,
    c.event_count
FROM tech_layoffs t
JOIN (
    SELECT company_name, COUNT(*) AS event_count
    FROM tech_layoffs
    GROUP BY company_name
) c ON c.company_name = t.company_name;


-- ❌ ANTI-PATTERN 5: HAVING without GROUP BY (inefficient filter)
-- BAD:
SELECT company_name, SUM(layoffs_count) AS total
FROM tech_layoffs
GROUP BY company_name
HAVING company_name LIKE 'M%';  -- HAVING filters after grouping

-- ✅ FIX: Use WHERE to filter before grouping
SELECT company_name, SUM(layoffs_count) AS total
FROM tech_layoffs
WHERE company_name LIKE 'M%'    -- filters rows BEFORE GROUP BY
GROUP BY company_name;


-- ❌ ANTI-PATTERN 6: NOT IN with NULLs — silent bugs
-- BAD: If subquery returns any NULL, NOT IN returns no rows
SELECT * FROM tech_layoffs
WHERE company_name NOT IN (SELECT company_name FROM some_table);

-- ✅ FIX: Use NOT EXISTS (handles NULLs correctly)
SELECT * FROM tech_layoffs t
WHERE NOT EXISTS (
    SELECT 1 FROM some_table s WHERE s.company_name = t.company_name
);


-- ❌ ANTI-PATTERN 7: DISTINCT to fix a bad JOIN (masking duplicates)
-- BAD: Using DISTINCT because the JOIN produced duplicates
SELECT DISTINCT t.company_name
FROM tech_layoffs t
JOIN dim_industry i ON i.industry_name = t.industry;

-- ✅ FIX: Fix the JOIN condition or use EXISTS
SELECT t.company_name
FROM tech_layoffs t
WHERE EXISTS (SELECT 1 FROM dim_industry i WHERE i.industry_name = t.industry);


-- =============================================================================
-- SECTION 4: Rewrite Examples (Slow → Fast)
-- =============================================================================

-- SLOW: Nested correlated subqueries
SELECT
    t.company_name,
    t.industry,
    t.layoffs_count
FROM tech_layoffs t
WHERE t.layoffs_count > (
    SELECT AVG(t2.layoffs_count)
    FROM tech_layoffs t2
    WHERE t2.industry = t.industry
);

-- FAST: CTE pre-computes averages once
WITH industry_avgs AS (
    SELECT industry, AVG(layoffs_count) AS avg_layoffs
    FROM tech_layoffs
    GROUP BY industry
)
SELECT
    t.company_name,
    t.industry,
    t.layoffs_count
FROM tech_layoffs t
JOIN industry_avgs ia ON ia.industry = t.industry
WHERE t.layoffs_count > ia.avg_layoffs;


-- SLOW: Using OFFSET for pagination (scans all preceding rows)
SELECT * FROM tech_layoffs ORDER BY layoffs_count DESC LIMIT 10 OFFSET 10000;

-- FAST: Keyset / cursor pagination (starts from last seen value)
SELECT * FROM tech_layoffs
WHERE layoffs_count < :last_seen_layoff_count    -- pass from previous page
ORDER BY layoffs_count DESC
LIMIT 10;


-- =============================================================================
-- SECTION 5: Partitioning (PostgreSQL)
-- =============================================================================

-- Range partition by year — useful for large time-series tables
CREATE TABLE tech_layoffs_partitioned (
    LIKE tech_layoffs INCLUDING ALL
) PARTITION BY RANGE (year);

CREATE TABLE tech_layoffs_2024
    PARTITION OF tech_layoffs_partitioned
    FOR VALUES FROM (2024) TO (2025);

CREATE TABLE tech_layoffs_2025
    PARTITION OF tech_layoffs_partitioned
    FOR VALUES FROM (2025) TO (2026);

CREATE TABLE tech_layoffs_2026
    PARTITION OF tech_layoffs_partitioned
    FOR VALUES FROM (2026) TO (2027);

-- Queries with WHERE year = 2025 will touch ONLY the 2025 partition (partition pruning)
-- EXPLAIN ANALYZE SELECT * FROM tech_layoffs_partitioned WHERE year = 2025;


-- =============================================================================
-- SECTION 6: Maintenance Commands
-- =============================================================================

-- Reclaim space and update planner statistics after large updates/deletes
VACUUM ANALYZE tech_layoffs;

-- Check index usage — drop unused indexes
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,         -- times index was used by queries
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
WHERE tablename = 'tech_layoffs'
ORDER BY idx_scan ASC;  -- low idx_scan = index rarely used → candidate for removal


-- Check table bloat
SELECT
    tablename,
    pg_size_pretty(pg_total_relation_size(tablename::regclass)) AS total_size,
    pg_size_pretty(pg_relation_size(tablename::regclass)) AS table_size,
    pg_size_pretty(pg_indexes_size(tablename::regclass)) AS index_size
FROM pg_tables
WHERE tablename = 'tech_layoffs';


-- =============================================================================
-- END OF FILE: 08_performance_tuning.sql
-- =============================================================================
