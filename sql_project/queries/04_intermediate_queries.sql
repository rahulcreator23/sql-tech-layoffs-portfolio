-- =============================================================================
-- FILE: 04_intermediate_queries.sql
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: Intermediate queries — JOINs, subqueries, UNION, EXISTS,
--              date math, aggregated filters, ROLLUP
-- =============================================================================


-- =============================================================================
-- TOPIC 1: JOINs
-- Note: For JOIN demos, we use the dim_* lookup tables from 01_schema_ddl.sql
--       and self-join patterns on the main table.
-- =============================================================================

-- Q1. INNER JOIN — enrich layoffs with region from dim_country
SELECT
    t.company_name,
    t.industry,
    t.year,
    t.layoffs_count,
    c.region
FROM tech_layoffs t
INNER JOIN dim_country c
    ON t.country = c.country_name
ORDER BY t.layoffs_count DESC
LIMIT 20;


-- Q2. LEFT JOIN — all layoff records; show company size range even if no match
SELECT
    t.company_name,
    t.company_size,
    t.layoffs_count,
    s.min_headcount,
    s.max_headcount
FROM tech_layoffs t
LEFT JOIN dim_company_size s
    ON t.company_size = s.size_label
ORDER BY t.layoffs_count DESC
LIMIT 20;


-- Q3. SELF JOIN — find pairs of events where same company had consecutive layoffs
--     (same company, different years)
SELECT
    a.company_name,
    a.year         AS year_1,
    a.layoffs_count AS layoffs_1,
    b.year         AS year_2,
    b.layoffs_count AS layoffs_2,
    (b.layoffs_count - a.layoffs_count) AS yoy_change
FROM tech_layoffs a
JOIN tech_layoffs b
    ON  a.company_name = b.company_name
    AND b.year = a.year + 1
WHERE a.layoffs_count > 0
  AND b.layoffs_count > 0
ORDER BY yoy_change DESC
LIMIT 20;


-- Q4. FULL OUTER JOIN — show all industries vs all countries,
--     even if no event exists for that combination
--     (useful to detect data gaps in a reporting matrix)
SELECT
    di.industry_name,
    dc.country_name,
    COUNT(t.record_id) AS event_count,
    COALESCE(SUM(t.layoffs_count), 0) AS total_layoffs
FROM dim_industry di
FULL OUTER JOIN dim_country dc ON 1=1                  -- Cross all combinations
LEFT JOIN tech_layoffs t
    ON  t.industry = di.industry_name
    AND t.country  = dc.country_name
GROUP BY di.industry_name, dc.country_name
ORDER BY di.industry_name, dc.country_name;
-- MySQL: use UNION of LEFT JOIN + RIGHT JOIN instead of FULL OUTER JOIN


-- Q5. CROSS JOIN — generate all possible year × market_condition combinations
SELECT
    y.year,
    m.market_condition,
    COUNT(t.record_id)    AS event_count,
    SUM(t.layoffs_count)  AS total_layoffs
FROM (SELECT DISTINCT year FROM tech_layoffs) y
CROSS JOIN (SELECT DISTINCT market_condition FROM tech_layoffs) m
LEFT JOIN tech_layoffs t
    ON t.year = y.year AND t.market_condition = m.market_condition
GROUP BY y.year, m.market_condition
ORDER BY y.year, m.market_condition;


-- =============================================================================
-- TOPIC 2: Subqueries
-- =============================================================================

-- Q6. Scalar subquery — companies with above-average layoff counts
SELECT
    company_name,
    industry,
    layoffs_count,
    (SELECT ROUND(AVG(layoffs_count), 0) FROM tech_layoffs) AS global_avg
FROM tech_layoffs
WHERE layoffs_count > (SELECT AVG(layoffs_count) FROM tech_layoffs)
ORDER BY layoffs_count DESC;


-- Q7. Subquery in FROM (derived table) — industry stats, filtered to high-layoff ones
SELECT
    industry_stats.industry,
    industry_stats.total_layoffs,
    industry_stats.avg_layoff_pct
FROM (
    SELECT
        industry,
        SUM(layoffs_count)                  AS total_layoffs,
        ROUND(AVG(layoff_percentage), 2)    AS avg_layoff_pct,
        COUNT(*)                            AS events
    FROM tech_layoffs
    GROUP BY industry
) AS industry_stats
WHERE industry_stats.total_layoffs > 500000
ORDER BY industry_stats.total_layoffs DESC;


-- Q8. Correlated subquery — for each record, find avg layoffs in same industry
SELECT
    company_name,
    industry,
    layoffs_count,
    ROUND(
        (SELECT AVG(i.layoffs_count)
         FROM tech_layoffs i
         WHERE i.industry = t.industry),
    0) AS industry_avg_layoffs,
    layoffs_count - ROUND(
        (SELECT AVG(i.layoffs_count)
         FROM tech_layoffs i
         WHERE i.industry = t.industry),
    0) AS vs_industry_avg
FROM tech_layoffs t
ORDER BY vs_industry_avg DESC
LIMIT 15;


-- Q9. EXISTS — companies that have BOTH experienced a hiring freeze AND a year
--     of aggressive hiring (at different points in time)
SELECT DISTINCT company_name
FROM tech_layoffs t1
WHERE hiring_trend = 'Hiring Freeze'
  AND EXISTS (
      SELECT 1
      FROM tech_layoffs t2
      WHERE t2.company_name = t1.company_name
        AND t2.hiring_trend = 'Aggressive Hiring'
  )
ORDER BY company_name;


-- Q10. NOT EXISTS — companies that have NEVER had an aggressive hiring trend
SELECT DISTINCT company_name
FROM tech_layoffs t1
WHERE NOT EXISTS (
    SELECT 1
    FROM tech_layoffs t2
    WHERE t2.company_name = t1.company_name
      AND t2.hiring_trend = 'Aggressive Hiring'
)
ORDER BY company_name;


-- Q11. IN with subquery — events from companies that had a recession-era layoff
SELECT
    company_name,
    year,
    layoffs_count,
    market_condition
FROM tech_layoffs
WHERE company_name IN (
    SELECT DISTINCT company_name
    FROM tech_layoffs
    WHERE market_condition = 'Recession'
      AND layoff_percentage > 15
)
ORDER BY company_name, year;


-- =============================================================================
-- TOPIC 3: UNION and Set Operations
-- =============================================================================

-- Q12. UNION — combine AI-automation-driven and cost-cutting events
--      into a single result set with a source label
SELECT
    company_name, industry, country, year, layoffs_count,
    'AI Automation' AS trigger_type
FROM tech_layoffs
WHERE reason_for_layoffs = 'AI Automation'
  AND layoffs_count > 5000

UNION ALL

SELECT
    company_name, industry, country, year, layoffs_count,
    'Cost Cutting' AS trigger_type
FROM tech_layoffs
WHERE reason_for_layoffs = 'Cost Cutting'
  AND layoffs_count > 5000

ORDER BY layoffs_count DESC;


-- Q13. INTERSECT — companies that appear in both: high AI risk AND recession
SELECT DISTINCT company_name
FROM tech_layoffs
WHERE ai_replacement_risk >= 8.0

INTERSECT

SELECT DISTINCT company_name
FROM tech_layoffs
WHERE market_condition = 'Recession'

ORDER BY company_name;
-- MySQL: use INNER JOIN on subqueries instead of INTERSECT


-- Q14. EXCEPT — companies in high AI risk but NOT in recession
SELECT DISTINCT company_name
FROM tech_layoffs
WHERE ai_replacement_risk >= 8.0

EXCEPT

SELECT DISTINCT company_name
FROM tech_layoffs
WHERE market_condition = 'Recession'

ORDER BY company_name;
-- MySQL: use LEFT JOIN + IS NULL pattern


-- =============================================================================
-- TOPIC 4: GROUP BY Extensions — ROLLUP, CUBE
-- =============================================================================

-- Q15. ROLLUP — subtotals and grand total for industry + year
SELECT
    COALESCE(industry, '【ALL INDUSTRIES】') AS industry,
    COALESCE(CAST(year AS VARCHAR), '【ALL YEARS】') AS year,
    COUNT(*) AS events,
    SUM(layoffs_count) AS total_layoffs
FROM tech_layoffs
GROUP BY ROLLUP (industry, year)
ORDER BY industry NULLS LAST, year NULLS LAST;


-- Q16. CUBE — all combinations: industry × country
SELECT
    COALESCE(industry, 'ALL') AS industry,
    COALESCE(country,  'ALL') AS country,
    SUM(layoffs_count)        AS total_layoffs
FROM tech_layoffs
GROUP BY CUBE (industry, country)
ORDER BY industry NULLS LAST, country NULLS LAST;


-- =============================================================================
-- TOPIC 5: Conditional Aggregation (Pivot-style)
-- =============================================================================

-- Q17. Layoffs by industry broken out by market condition (manual pivot)
SELECT
    industry,
    SUM(CASE WHEN market_condition = 'Bull Market' THEN layoffs_count ELSE 0 END) AS bull_market_layoffs,
    SUM(CASE WHEN market_condition = 'Recession'   THEN layoffs_count ELSE 0 END) AS recession_layoffs,
    SUM(CASE WHEN market_condition = 'Stable'      THEN layoffs_count ELSE 0 END) AS stable_layoffs,
    SUM(layoffs_count) AS total_layoffs
FROM tech_layoffs
GROUP BY industry
ORDER BY total_layoffs DESC;


-- Q18. Hiring trend distribution by company size (%)
SELECT
    company_size,
    COUNT(*)                                                          AS total_events,
    SUM(CASE WHEN hiring_trend = 'Aggressive Hiring' THEN 1 ELSE 0 END) AS aggressive,
    SUM(CASE WHEN hiring_trend = 'Moderate Hiring'   THEN 1 ELSE 0 END) AS moderate,
    SUM(CASE WHEN hiring_trend = 'Hiring Freeze'     THEN 1 ELSE 0 END) AS freeze,
    SUM(CASE WHEN hiring_trend = 'Downsizing'        THEN 1 ELSE 0 END) AS downsizing,
    ROUND(100.0 * SUM(CASE WHEN hiring_trend IN ('Aggressive Hiring','Moderate Hiring')
                           THEN 1 ELSE 0 END) / COUNT(*), 1)        AS pct_growing
FROM tech_layoffs
GROUP BY company_size
ORDER BY pct_growing DESC;


-- Q19. Year-over-year comparison with conditional aggregation
SELECT
    industry,
    SUM(CASE WHEN year = 2024 THEN layoffs_count ELSE 0 END) AS layoffs_2024,
    SUM(CASE WHEN year = 2025 THEN layoffs_count ELSE 0 END) AS layoffs_2025,
    SUM(CASE WHEN year = 2026 THEN layoffs_count ELSE 0 END) AS layoffs_2026,
    ROUND(
        100.0 * (
            SUM(CASE WHEN year = 2025 THEN layoffs_count ELSE 0 END) -
            SUM(CASE WHEN year = 2024 THEN layoffs_count ELSE 0 END)
        ) / NULLIF(SUM(CASE WHEN year = 2024 THEN layoffs_count ELSE 0 END), 0),
    2) AS yoy_pct_change_24_to_25
FROM tech_layoffs
GROUP BY industry
ORDER BY yoy_pct_change_24_to_25 DESC;


-- Q20. Top reason for layoffs per country (with tie handling)
SELECT
    country,
    reason_for_layoffs,
    event_count
FROM (
    SELECT
        country,
        reason_for_layoffs,
        COUNT(*) AS event_count,
        RANK() OVER (PARTITION BY country ORDER BY COUNT(*) DESC) AS rnk
    FROM tech_layoffs
    GROUP BY country, reason_for_layoffs
) ranked
WHERE rnk = 1
ORDER BY country;


-- =============================================================================
-- END OF FILE: 04_intermediate_queries.sql
-- =============================================================================
