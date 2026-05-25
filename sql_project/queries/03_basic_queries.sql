-- =============================================================================
-- FILE: 03_basic_queries.sql
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: Beginner-level queries — SELECT, WHERE, GROUP BY, ORDER BY,
--              HAVING, DISTINCT, LIKE, BETWEEN, NULL handling, CASE
-- =============================================================================


-- =============================================================================
-- TOPIC 1: Basic SELECT & Filtering
-- =============================================================================

-- Q1. Show all columns for the first 10 records
SELECT *
FROM tech_layoffs
LIMIT 10;                -- MySQL/PostgreSQL/SQLite
-- TOP 10 * FROM tech_layoffs;   -- SQL Server syntax


-- Q2. Select specific columns only
SELECT
    company_name,
    industry,
    country,
    year,
    layoffs_count,
    hiring_trend
FROM tech_layoffs
LIMIT 10;


-- Q3. All US-based layoff events
SELECT
    company_name,
    industry,
    year,
    layoffs_count,
    reason_for_layoffs
FROM tech_layoffs
WHERE country = 'USA'
ORDER BY layoffs_count DESC;


-- Q4. Companies that had more than 10,000 layoffs
SELECT
    company_name,
    country,
    year,
    layoffs_count,
    layoff_percentage
FROM tech_layoffs
WHERE layoffs_count > 10000
ORDER BY layoffs_count DESC;


-- Q5. Events in 2025 AND in the AI industry
SELECT
    record_id,
    company_name,
    month,
    layoffs_count,
    ai_automation_impact
FROM tech_layoffs
WHERE year = 2025
  AND industry = 'AI'
ORDER BY ai_automation_impact DESC;


-- Q6. Events in Gaming OR FinTech sectors
SELECT
    company_name,
    industry,
    country,
    year,
    layoffs_count
FROM tech_layoffs
WHERE industry IN ('Gaming', 'FinTech')
ORDER BY industry, layoffs_count DESC;


-- Q7. Companies with layoff % between 5% and 20%
SELECT
    company_name,
    industry,
    layoff_percentage,
    reason_for_layoffs
FROM tech_layoffs
WHERE layoff_percentage BETWEEN 5.0 AND 20.0
ORDER BY layoff_percentage DESC;


-- Q8. Companies whose name starts with 'A'
SELECT DISTINCT
    company_name,
    industry,
    country
FROM tech_layoffs
WHERE company_name LIKE 'A%'
ORDER BY company_name;


-- Q9. Handling NULLs — find rows where top_hiring_role might be missing
--     (In this dataset all are populated, but good practice to check)
SELECT
    record_id,
    company_name,
    top_hiring_role
FROM tech_layoffs
WHERE top_hiring_role IS NULL
   OR top_hiring_role = '';


-- Q10. Use COALESCE to replace NULLs with a default value
SELECT
    company_name,
    COALESCE(top_hiring_role, 'Not Specified') AS hiring_role,
    COALESCE(CAST(ai_adoption_level AS VARCHAR), 'N/A') AS ai_adoption
FROM tech_layoffs
LIMIT 10;


-- =============================================================================
-- TOPIC 2: Sorting & Limiting
-- =============================================================================

-- Q11. Top 5 companies by total layoffs
SELECT
    company_name,
    layoffs_count,
    layoff_percentage
FROM tech_layoffs
ORDER BY layoffs_count DESC
LIMIT 5;


-- Q12. Bottom 5 companies by layoff count (fewest layoffs)
SELECT
    company_name,
    layoffs_count,
    country
FROM tech_layoffs
ORDER BY layoffs_count ASC
LIMIT 5;


-- Q13. Multi-column sort: by country (A→Z) then layoffs (high→low)
SELECT
    company_name,
    country,
    year,
    layoffs_count
FROM tech_layoffs
ORDER BY country ASC, layoffs_count DESC;


-- =============================================================================
-- TOPIC 3: Aggregate Functions
-- =============================================================================

-- Q14. Total layoffs across all records
SELECT
    SUM(layoffs_count)                    AS total_layoffs,
    COUNT(*)                              AS total_events,
    ROUND(AVG(layoffs_count), 0)          AS avg_layoffs_per_event,
    MAX(layoffs_count)                    AS max_single_layoff,
    MIN(layoffs_count)                    AS min_single_layoff
FROM tech_layoffs;


-- Q15. Total layoffs by industry
SELECT
    industry,
    COUNT(*)                              AS events,
    SUM(layoffs_count)                    AS total_layoffs,
    ROUND(AVG(layoff_percentage), 2)      AS avg_layoff_pct
FROM tech_layoffs
GROUP BY industry
ORDER BY total_layoffs DESC;


-- Q16. Layoffs by country and year (cross-tab style)
SELECT
    country,
    year,
    SUM(layoffs_count)                    AS total_layoffs,
    COUNT(DISTINCT company_name)          AS companies_affected
FROM tech_layoffs
GROUP BY country, year
ORDER BY country, year;


-- Q17. HAVING: industries with more than 500 total events
SELECT
    industry,
    COUNT(*) AS event_count
FROM tech_layoffs
GROUP BY industry
HAVING COUNT(*) > 500
ORDER BY event_count DESC;


-- Q18. Average AI adoption level by hiring trend
SELECT
    hiring_trend,
    ROUND(AVG(ai_adoption_level), 2)      AS avg_ai_adoption,
    ROUND(AVG(job_security_score), 2)     AS avg_job_security,
    ROUND(AVG(employee_sentiment), 2)     AS avg_sentiment,
    COUNT(*)                              AS record_count
FROM tech_layoffs
GROUP BY hiring_trend
ORDER BY avg_ai_adoption DESC;


-- =============================================================================
-- TOPIC 4: CASE Statements (Conditional Logic)
-- =============================================================================

-- Q19. Categorize layoff size
SELECT
    company_name,
    layoffs_count,
    CASE
        WHEN layoffs_count >= 10000 THEN 'Massive (10K+)'
        WHEN layoffs_count >= 5000  THEN 'Large (5K–10K)'
        WHEN layoffs_count >= 1000  THEN 'Medium (1K–5K)'
        WHEN layoffs_count >= 100   THEN 'Small (100–1K)'
        ELSE                             'Minimal (<100)'
    END AS layoff_category
FROM tech_layoffs
ORDER BY layoffs_count DESC;


-- Q20. Flag whether a company is in a bull or risk market
SELECT
    company_name,
    market_condition,
    job_security_score,
    CASE
        WHEN market_condition = 'Bull Market' AND job_security_score >= 7.0
            THEN '🟢 Safe Growth'
        WHEN market_condition = 'Recession'   AND job_security_score <= 4.0
            THEN '🔴 High Risk'
        WHEN market_condition = 'Stable'
            THEN '🟡 Neutral'
        ELSE '🟠 Watch'
    END AS risk_flag
FROM tech_layoffs
ORDER BY job_security_score ASC;


-- Q21. Count events by hiring trend category
SELECT
    CASE
        WHEN hiring_trend = 'Aggressive Hiring' THEN 'Growth Mode'
        WHEN hiring_trend = 'Moderate Hiring'   THEN 'Growth Mode'
        WHEN hiring_trend = 'Hiring Freeze'     THEN 'Contraction'
        WHEN hiring_trend = 'Downsizing'        THEN 'Contraction'
    END AS market_stance,
    COUNT(*) AS events,
    SUM(layoffs_count) AS total_layoffs
FROM tech_layoffs
GROUP BY
    CASE
        WHEN hiring_trend IN ('Aggressive Hiring','Moderate Hiring') THEN 'Growth Mode'
        ELSE 'Contraction'
    END
ORDER BY events DESC;


-- =============================================================================
-- TOPIC 5: DISTINCT & String Functions
-- =============================================================================

-- Q22. All unique industries in the dataset
SELECT DISTINCT industry
FROM tech_layoffs
ORDER BY industry;


-- Q23. Unique combinations of country + industry
SELECT DISTINCT
    country,
    industry
FROM tech_layoffs
ORDER BY country, industry;


-- Q24. String functions — format company name for display
SELECT
    UPPER(company_name)                         AS company_upper,
    LOWER(industry)                             AS industry_lower,
    LENGTH(reason_for_layoffs)                  AS reason_length,
    CONCAT(company_name, ' (', country, ')')    AS display_name
FROM tech_layoffs
LIMIT 10;
-- SQLite: use || for concatenation: company_name || ' (' || country || ')'


-- Q25. Date/period filter — 2024 and 2025 only
SELECT
    year,
    month,
    COUNT(*) AS events,
    SUM(layoffs_count) AS total_layoffs
FROM tech_layoffs
WHERE year IN (2024, 2025)
GROUP BY year, month
ORDER BY year, month;


-- =============================================================================
-- END OF FILE: 03_basic_queries.sql
-- =============================================================================
