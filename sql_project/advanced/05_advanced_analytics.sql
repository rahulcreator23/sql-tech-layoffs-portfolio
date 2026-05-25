-- =============================================================================
-- FILE: 05_advanced_analytics.sql
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: Expert-level queries — Window functions, CTEs, recursive CTEs,
--              running totals, cohort analysis, percentile analysis, pivoting
-- =============================================================================


-- =============================================================================
-- TOPIC 1: Window Functions — Ranking
-- =============================================================================

-- Q1. ROW_NUMBER — assign a unique sequential rank per country by layoffs
SELECT
    country,
    company_name,
    year,
    layoffs_count,
    ROW_NUMBER() OVER (
        PARTITION BY country
        ORDER BY layoffs_count DESC
    ) AS rank_in_country
FROM tech_layoffs
ORDER BY country, rank_in_country;


-- Q2. RANK vs DENSE_RANK vs ROW_NUMBER — understand the difference
SELECT
    company_name,
    industry,
    layoffs_count,
    ROW_NUMBER()  OVER (PARTITION BY industry ORDER BY layoffs_count DESC) AS row_num,
    RANK()        OVER (PARTITION BY industry ORDER BY layoffs_count DESC) AS rank_with_gaps,
    DENSE_RANK()  OVER (PARTITION BY industry ORDER BY layoffs_count DESC) AS dense_rank_no_gaps
FROM tech_layoffs
WHERE industry = 'AI'
ORDER BY layoffs_count DESC
LIMIT 20;


-- Q3. Top-3 layoff events per industry (RANK-based filter)
SELECT *
FROM (
    SELECT
        industry,
        company_name,
        country,
        year,
        layoffs_count,
        DENSE_RANK() OVER (PARTITION BY industry ORDER BY layoffs_count DESC) AS dr
    FROM tech_layoffs
) ranked
WHERE dr <= 3
ORDER BY industry, dr;


-- Q4. NTILE — quartile ranking of companies by AI replacement risk
SELECT
    company_name,
    industry,
    ai_replacement_risk,
    NTILE(4) OVER (ORDER BY ai_replacement_risk DESC) AS risk_quartile,
    CASE NTILE(4) OVER (ORDER BY ai_replacement_risk DESC)
        WHEN 1 THEN 'Q1 – Very High Risk'
        WHEN 2 THEN 'Q2 – High Risk'
        WHEN 3 THEN 'Q3 – Moderate Risk'
        WHEN 4 THEN 'Q4 – Low Risk'
    END AS risk_label
FROM tech_layoffs
ORDER BY risk_quartile, ai_replacement_risk DESC;


-- =============================================================================
-- TOPIC 2: Window Functions — Running Totals & Moving Averages
-- =============================================================================

-- Q5. Running total of layoffs per industry (ordered by year)
SELECT
    industry,
    year,
    SUM(layoffs_count)                                  AS yearly_layoffs,
    SUM(SUM(layoffs_count)) OVER (
        PARTITION BY industry
        ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                                   AS running_total
FROM tech_layoffs
GROUP BY industry, year
ORDER BY industry, year;


-- Q6. 3-year moving average of layoffs by country
SELECT
    country,
    year,
    SUM(layoffs_count) AS yearly_layoffs,
    ROUND(
        AVG(SUM(layoffs_count)) OVER (
            PARTITION BY country
            ORDER BY year
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
    0) AS moving_avg_3yr
FROM tech_layoffs
GROUP BY country, year
ORDER BY country, year;


-- Q7. Percentage of total layoffs each year (per industry)
SELECT
    industry,
    year,
    SUM(layoffs_count) AS year_layoffs,
    SUM(SUM(layoffs_count)) OVER (PARTITION BY industry) AS industry_total,
    ROUND(
        100.0 * SUM(layoffs_count) / SUM(SUM(layoffs_count)) OVER (PARTITION BY industry),
    2) AS pct_of_industry_total
FROM tech_layoffs
GROUP BY industry, year
ORDER BY industry, year;


-- =============================================================================
-- TOPIC 3: Window Functions — LAG / LEAD (Time Series)
-- =============================================================================

-- Q8. YoY change in layoffs per country using LAG
SELECT
    country,
    year,
    SUM(layoffs_count) AS total_layoffs,
    LAG(SUM(layoffs_count), 1) OVER (
        PARTITION BY country
        ORDER BY year
    ) AS prev_year_layoffs,
    SUM(layoffs_count) - LAG(SUM(layoffs_count), 1) OVER (
        PARTITION BY country
        ORDER BY year
    ) AS yoy_change,
    ROUND(
        100.0 * (SUM(layoffs_count) - LAG(SUM(layoffs_count), 1) OVER (
            PARTITION BY country ORDER BY year
        )) / NULLIF(LAG(SUM(layoffs_count), 1) OVER (
            PARTITION BY country ORDER BY year
        ), 0),
    2) AS yoy_pct_change
FROM tech_layoffs
GROUP BY country, year
ORDER BY country, year;


-- Q9. LEAD — look ahead: next year's open roles for each industry
SELECT
    industry,
    year,
    ROUND(AVG(open_roles), 0) AS avg_open_roles_this_year,
    ROUND(
        LEAD(AVG(open_roles), 1) OVER (
            PARTITION BY industry
            ORDER BY year
        ),
    0) AS avg_open_roles_next_year
FROM tech_layoffs
GROUP BY industry, year
ORDER BY industry, year;


-- =============================================================================
-- TOPIC 4: CTEs (Common Table Expressions)
-- =============================================================================

-- Q10. Simple CTE — industry summary, then filter
WITH industry_totals AS (
    SELECT
        industry,
        SUM(layoffs_count)               AS total_layoffs,
        COUNT(*)                         AS events,
        ROUND(AVG(ai_adoption_level), 2) AS avg_ai_adoption
    FROM tech_layoffs
    GROUP BY industry
)
SELECT *
FROM industry_totals
WHERE total_layoffs > 1000000
ORDER BY total_layoffs DESC;


-- Q11. Chained CTEs — multi-step analysis
WITH
-- Step 1: Base metrics per company
company_metrics AS (
    SELECT
        company_name,
        COUNT(*)                            AS total_events,
        SUM(layoffs_count)                  AS total_layoffs,
        ROUND(AVG(ai_replacement_risk), 2)  AS avg_ai_risk,
        ROUND(AVG(job_security_score), 2)   AS avg_security,
        ROUND(AVG(revenue_growth_percent), 2) AS avg_revenue_growth
    FROM tech_layoffs
    GROUP BY company_name
),
-- Step 2: Flag companies by risk profile
risk_profiles AS (
    SELECT
        company_name,
        total_layoffs,
        avg_ai_risk,
        avg_security,
        avg_revenue_growth,
        CASE
            WHEN avg_ai_risk >= 8 AND avg_security <= 4 THEN 'Critical Risk'
            WHEN avg_ai_risk >= 6 AND avg_security <= 6 THEN 'Elevated Risk'
            WHEN avg_ai_risk <= 4 AND avg_security >= 7 THEN 'Low Risk'
            ELSE 'Moderate Risk'
        END AS risk_profile
    FROM company_metrics
),
-- Step 3: Count companies per risk profile
profile_summary AS (
    SELECT
        risk_profile,
        COUNT(*) AS company_count,
        SUM(total_layoffs) AS total_layoffs
    FROM risk_profiles
    GROUP BY risk_profile
)
SELECT *
FROM profile_summary
ORDER BY total_layoffs DESC;


-- Q12. Recursive CTE — generate a series of years 2023–2026
--      (useful for complete time-series even if data is sparse)
WITH RECURSIVE year_series AS (
    SELECT 2023 AS yr          -- Anchor member
    UNION ALL
    SELECT yr + 1              -- Recursive member
    FROM year_series
    WHERE yr < 2026
)
SELECT
    ys.yr,
    COALESCE(SUM(t.layoffs_count), 0) AS total_layoffs
FROM year_series ys
LEFT JOIN tech_layoffs t ON t.year = ys.yr
GROUP BY ys.yr
ORDER BY ys.yr;
-- MySQL: uses WITH RECURSIVE identically
-- SQLite: also supports WITH RECURSIVE


-- Q13. CTE with window function — find above-median companies per industry
WITH industry_medians AS (
    SELECT
        industry,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY layoffs_count) AS median_layoffs
    FROM tech_layoffs
    GROUP BY industry
)
SELECT
    t.company_name,
    t.industry,
    t.layoffs_count,
    im.median_layoffs,
    t.layoffs_count - im.median_layoffs AS vs_median
FROM tech_layoffs t
JOIN industry_medians im ON t.industry = im.industry
WHERE t.layoffs_count > im.median_layoffs
ORDER BY vs_median DESC
LIMIT 20;


-- =============================================================================
-- TOPIC 5: Advanced Analytical Queries
-- =============================================================================

-- Q14. Cohort Analysis — companies that first appeared in each year
WITH first_appearance AS (
    SELECT
        company_name,
        MIN(year) AS cohort_year
    FROM tech_layoffs
    GROUP BY company_name
)
SELECT
    fa.cohort_year,
    COUNT(DISTINCT fa.company_name)    AS new_companies,
    SUM(t.layoffs_count)               AS total_layoffs_from_cohort,
    ROUND(AVG(t.ai_adoption_level), 2) AS avg_ai_adoption
FROM first_appearance fa
JOIN tech_layoffs t
    ON t.company_name = fa.company_name
WHERE t.year = fa.cohort_year
GROUP BY fa.cohort_year
ORDER BY fa.cohort_year;


-- Q15. Percentile analysis — P25, P50, P75, P90 of layoff counts
SELECT
    industry,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY layoffs_count), 0) AS p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY layoffs_count), 0) AS p50_median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY layoffs_count), 0) AS p75,
    ROUND(PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY layoffs_count), 0) AS p90,
    MAX(layoffs_count) AS max_layoffs
FROM tech_layoffs
GROUP BY industry
ORDER BY p90 DESC;


-- Q16. Z-score normalization — flag statistical outliers in layoffs
WITH stats AS (
    SELECT
        AVG(layoffs_count)    AS mean_layoffs,
        STDDEV(layoffs_count) AS std_layoffs
    FROM tech_layoffs
)
SELECT
    t.company_name,
    t.industry,
    t.layoffs_count,
    ROUND((t.layoffs_count - s.mean_layoffs) / NULLIF(s.std_layoffs, 0), 2) AS z_score,
    CASE
        WHEN ABS((t.layoffs_count - s.mean_layoffs) / NULLIF(s.std_layoffs, 0)) > 3
            THEN 'Extreme Outlier'
        WHEN ABS((t.layoffs_count - s.mean_layoffs) / NULLIF(s.std_layoffs, 0)) > 2
            THEN 'Outlier'
        ELSE 'Normal'
    END AS outlier_flag
FROM tech_layoffs t, stats s
ORDER BY z_score DESC
LIMIT 20;


-- Q17. Gap analysis — net position: open roles vs layoffs per company per year
WITH net_positions AS (
    SELECT
        company_name,
        year,
        SUM(open_roles)      AS total_open_roles,
        SUM(layoffs_count)   AS total_layoffs,
        SUM(open_roles) - SUM(layoffs_count) AS net_headcount_signal
    FROM tech_layoffs
    GROUP BY company_name, year
)
SELECT
    company_name,
    year,
    total_open_roles,
    total_layoffs,
    net_headcount_signal,
    CASE
        WHEN net_headcount_signal > 5000  THEN 'Strong Net Growth'
        WHEN net_headcount_signal > 0     THEN 'Net Growth'
        WHEN net_headcount_signal = 0     THEN 'Break Even'
        WHEN net_headcount_signal > -5000 THEN 'Net Decline'
        ELSE 'Strong Net Decline'
    END AS headcount_trend
FROM net_positions
ORDER BY net_headcount_signal DESC;


-- Q18. Correlation proxy: AI adoption vs employee sentiment by industry
--      (Higher AI adoption → higher or lower sentiment?)
SELECT
    industry,
    ROUND(AVG(ai_adoption_level),   2) AS avg_ai_adoption,
    ROUND(AVG(employee_sentiment),  2) AS avg_sentiment,
    ROUND(AVG(job_security_score),  2) AS avg_security,
    COUNT(*)                           AS sample_size,
    -- Simple correlation direction: difference from industry avg
    ROUND(
        CORR(ai_adoption_level, employee_sentiment),
    3) AS ai_sentiment_correlation
FROM tech_layoffs
GROUP BY industry
HAVING COUNT(*) > 100
ORDER BY ai_sentiment_correlation DESC;
-- CORR() is PostgreSQL-specific; SQLite/MySQL need manual calculation


-- Q19. Consecutive year analysis — companies with layoffs in ALL of 2024, 2025, 2026
SELECT company_name
FROM tech_layoffs
WHERE year IN (2024, 2025, 2026)
GROUP BY company_name
HAVING COUNT(DISTINCT year) = 3
ORDER BY company_name;


-- Q20. Advanced pivot: hiring trend by industry and year as a matrix
SELECT
    industry,
    SUM(CASE WHEN year = 2024 AND hiring_trend = 'Aggressive Hiring' THEN 1 ELSE 0 END) AS "2024_aggressive",
    SUM(CASE WHEN year = 2024 AND hiring_trend = 'Hiring Freeze'     THEN 1 ELSE 0 END) AS "2024_freeze",
    SUM(CASE WHEN year = 2025 AND hiring_trend = 'Aggressive Hiring' THEN 1 ELSE 0 END) AS "2025_aggressive",
    SUM(CASE WHEN year = 2025 AND hiring_trend = 'Hiring Freeze'     THEN 1 ELSE 0 END) AS "2025_freeze",
    SUM(CASE WHEN year = 2026 AND hiring_trend = 'Aggressive Hiring' THEN 1 ELSE 0 END) AS "2026_aggressive",
    SUM(CASE WHEN year = 2026 AND hiring_trend = 'Hiring Freeze'     THEN 1 ELSE 0 END) AS "2026_freeze"
FROM tech_layoffs
GROUP BY industry
ORDER BY industry;


-- =============================================================================
-- END OF FILE: 05_advanced_analytics.sql
-- =============================================================================
