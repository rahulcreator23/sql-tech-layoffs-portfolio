-- =============================================================================
-- FILE: 09_interview_questions.sql
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: 30+ real SQL interview questions with full answers
--              organized by difficulty level
-- LEGEND: 🟢 Easy | 🟡 Medium | 🔴 Hard | ⚡ Scenario
-- =============================================================================


-- =============================================================================
-- 🟢 EASY QUESTIONS (Beginner)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- Q1 🟢 Find the total number of layoffs per industry, sorted descending.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    industry,
    SUM(layoffs_count) AS total_layoffs
FROM tech_layoffs
GROUP BY industry
ORDER BY total_layoffs DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q2 🟢 Which companies had a hiring freeze during a recession?
-- ─────────────────────────────────────────────────────────────────────────────
SELECT DISTINCT
    company_name,
    industry,
    country,
    year
FROM tech_layoffs
WHERE hiring_trend   = 'Hiring Freeze'
  AND market_condition = 'Recession'
ORDER BY company_name;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q3 🟢 What is the average layoff percentage per company size?
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    company_size,
    ROUND(AVG(layoff_percentage), 2) AS avg_layoff_pct,
    COUNT(*)                          AS events
FROM tech_layoffs
GROUP BY company_size
ORDER BY avg_layoff_pct DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q4 🟢 Find all events where AI automation impact score is above 10 (data quality check).
-- ─────────────────────────────────────────────────────────────────────────────
SELECT record_id, company_name, ai_automation_impact
FROM tech_layoffs
WHERE ai_automation_impact > 10
   OR ai_automation_impact < 0;
-- Answer: Should return 0 rows if CHECK constraint is working.
-- This tests understanding of data validation.


-- ─────────────────────────────────────────────────────────────────────────────
-- Q5 🟢 Write a query to remove duplicate records based on company + year,
--       keeping the one with the highest layoffs_count.
-- ─────────────────────────────────────────────────────────────────────────────
-- Step 1: See if duplicates exist
SELECT company_name, year, COUNT(*) AS cnt
FROM tech_layoffs
GROUP BY company_name, year
HAVING COUNT(*) > 1;

-- Step 2: Delete duplicates, keep highest layoff row
DELETE FROM tech_layoffs
WHERE record_id NOT IN (
    SELECT DISTINCT ON (company_name, year) record_id
    FROM tech_layoffs
    ORDER BY company_name, year, layoffs_count DESC
);
-- Note: DISTINCT ON is PostgreSQL-specific.
-- MySQL: use a self-join with MIN(record_id) or ROW_NUMBER()


-- =============================================================================
-- 🟡 MEDIUM QUESTIONS
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- Q6 🟡 Find the company with the highest layoffs in each country.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    country,
    company_name,
    layoffs_count
FROM (
    SELECT
        country,
        company_name,
        layoffs_count,
        RANK() OVER (PARTITION BY country ORDER BY layoffs_count DESC) AS rnk
    FROM tech_layoffs
) ranked
WHERE rnk = 1
ORDER BY country;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q7 🟡 What is the month-over-month trend in total layoffs for 2025?
-- ─────────────────────────────────────────────────────────────────────────────
WITH monthly AS (
    SELECT
        month,
        year,
        SUM(layoffs_count) AS monthly_layoffs
    FROM tech_layoffs
    WHERE year = 2025
    GROUP BY month, year
)
SELECT
    month,
    monthly_layoffs,
    LAG(monthly_layoffs) OVER (ORDER BY monthly_layoffs) AS prev_month,  -- Note: proper ordering requires month→int mapping
    monthly_layoffs - LAG(monthly_layoffs) OVER (ORDER BY monthly_layoffs) AS mom_change
FROM monthly;

-- Better: map month to number for correct ordering
WITH monthly AS (
    SELECT
        month,
        CASE month
            WHEN 'Jan' THEN 1  WHEN 'Feb' THEN 2  WHEN 'Mar' THEN 3
            WHEN 'Apr' THEN 4  WHEN 'May' THEN 5  WHEN 'Jun' THEN 6
            WHEN 'Jul' THEN 7  WHEN 'Aug' THEN 8  WHEN 'Sep' THEN 9
            WHEN 'Oct' THEN 10 WHEN 'Nov' THEN 11 WHEN 'Dec' THEN 12
        END AS month_num,
        SUM(layoffs_count) AS monthly_layoffs
    FROM tech_layoffs
    WHERE year = 2025
    GROUP BY month
)
SELECT
    month,
    monthly_layoffs,
    LAG(monthly_layoffs) OVER (ORDER BY month_num) AS prev_month_layoffs,
    monthly_layoffs - LAG(monthly_layoffs) OVER (ORDER BY month_num) AS mom_diff
FROM monthly
ORDER BY month_num;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q8 🟡 Find the second-highest layoff count in the dataset.
-- ─────────────────────────────────────────────────────────────────────────────
-- Method 1: OFFSET (simple but slow)
SELECT DISTINCT layoffs_count
FROM tech_layoffs
ORDER BY layoffs_count DESC
LIMIT 1 OFFSET 1;

-- Method 2: Subquery (more robust, handles ties)
SELECT MAX(layoffs_count) AS second_highest
FROM tech_layoffs
WHERE layoffs_count < (SELECT MAX(layoffs_count) FROM tech_layoffs);

-- Method 3: DENSE_RANK (handles ties properly)
SELECT layoffs_count
FROM (
    SELECT layoffs_count, DENSE_RANK() OVER (ORDER BY layoffs_count DESC) AS dr
    FROM tech_layoffs
) ranked
WHERE dr = 2
LIMIT 1;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q9 🟡 Calculate the running total of layoffs by year (cumulative sum).
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    year,
    SUM(layoffs_count) AS yearly_total,
    SUM(SUM(layoffs_count)) OVER (ORDER BY year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM tech_layoffs
GROUP BY year
ORDER BY year;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q10 🟡 Which industries have above-average AI adoption levels?
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    industry,
    ROUND(AVG(ai_adoption_level), 2) AS avg_adoption,
    ROUND((SELECT AVG(ai_adoption_level) FROM tech_layoffs), 2) AS global_avg
FROM tech_layoffs
GROUP BY industry
HAVING AVG(ai_adoption_level) > (SELECT AVG(ai_adoption_level) FROM tech_layoffs)
ORDER BY avg_adoption DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q11 🟡 For each company, show whether their latest year's layoffs were
--        higher or lower than their first year's layoffs.
-- ─────────────────────────────────────────────────────────────────────────────
WITH company_first_last AS (
    SELECT
        company_name,
        FIRST_VALUE(SUM(layoffs_count)) OVER (
            PARTITION BY company_name ORDER BY year ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS first_year_layoffs,
        LAST_VALUE(SUM(layoffs_count)) OVER (
            PARTITION BY company_name ORDER BY year ASC
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS last_year_layoffs
    FROM tech_layoffs
    GROUP BY company_name, year
)
SELECT DISTINCT
    company_name,
    first_year_layoffs,
    last_year_layoffs,
    last_year_layoffs - first_year_layoffs AS change,
    CASE
        WHEN last_year_layoffs > first_year_layoffs THEN 'Worsening'
        WHEN last_year_layoffs < first_year_layoffs THEN 'Improving'
        ELSE 'Unchanged'
    END AS trend
FROM company_first_last
ORDER BY change DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q12 🟡 What percentage of events had BOTH high AI risk (≥7) and low job security (≤4)?
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    COUNT(*) FILTER (WHERE ai_replacement_risk >= 7 AND job_security_score <= 4)
        AS high_risk_events,
    COUNT(*) AS total_events,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE ai_replacement_risk >= 7 AND job_security_score <= 4)
        / NULLIF(COUNT(*), 0),
    2) AS pct_of_total
FROM tech_layoffs;
-- MySQL: use SUM(CASE WHEN ... THEN 1 ELSE 0 END) instead of COUNT(*) FILTER


-- =============================================================================
-- 🔴 HARD QUESTIONS (Advanced)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- Q13 🔴 Find companies that switched from "Hiring Freeze" to "Aggressive Hiring"
--        in consecutive years (recovery signal).
-- ─────────────────────────────────────────────────────────────────────────────
WITH yearly_trend AS (
    SELECT
        company_name,
        year,
        -- Get the most common hiring trend per company per year
        MODE() WITHIN GROUP (ORDER BY hiring_trend) AS dominant_trend
    FROM tech_layoffs
    GROUP BY company_name, year
),
with_next AS (
    SELECT
        company_name,
        year,
        dominant_trend,
        LEAD(dominant_trend) OVER (PARTITION BY company_name ORDER BY year) AS next_trend,
        LEAD(year)           OVER (PARTITION BY company_name ORDER BY year) AS next_year
    FROM yearly_trend
)
SELECT
    company_name,
    year           AS freeze_year,
    next_year      AS recovery_year,
    dominant_trend AS from_trend,
    next_trend     AS to_trend
FROM with_next
WHERE dominant_trend = 'Hiring Freeze'
  AND next_trend     = 'Aggressive Hiring'
  AND next_year = year + 1
ORDER BY company_name;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q14 🔴 Rank each company within its industry based on total layoffs,
--        and also show their percentile rank.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    company_name,
    industry,
    SUM(layoffs_count) AS total_layoffs,
    RANK()         OVER (PARTITION BY industry ORDER BY SUM(layoffs_count) DESC) AS rank_in_industry,
    ROUND(
        PERCENT_RANK() OVER (PARTITION BY industry ORDER BY SUM(layoffs_count)) * 100,
    1) AS percentile_in_industry,
    ROUND(
        CUME_DIST() OVER (PARTITION BY industry ORDER BY SUM(layoffs_count)) * 100,
    1) AS cumulative_dist_pct
FROM tech_layoffs
GROUP BY company_name, industry
ORDER BY industry, rank_in_industry;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q15 🔴 Write a query to pivot: show layoff totals by year as columns,
--        with one row per country. (Without using PIVOT syntax)
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    country,
    SUM(CASE WHEN year = 2024 THEN layoffs_count ELSE 0 END) AS "2024",
    SUM(CASE WHEN year = 2025 THEN layoffs_count ELSE 0 END) AS "2025",
    SUM(CASE WHEN year = 2026 THEN layoffs_count ELSE 0 END) AS "2026",
    SUM(layoffs_count) AS grand_total
FROM tech_layoffs
GROUP BY country
ORDER BY grand_total DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q16 🔴 What is the median layoff count per industry?
--        (MEDIAN is not a standard aggregate — must use PERCENTILE_CONT)
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    industry,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY layoffs_count), 0) AS median_layoffs,
    ROUND(AVG(layoffs_count), 0) AS mean_layoffs,
    -- If median << mean: right-skewed (a few extreme layoff events pulling mean up)
    ROUND(AVG(layoffs_count) - PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY layoffs_count), 0) AS mean_median_gap
FROM tech_layoffs
GROUP BY industry
ORDER BY median_layoffs DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q17 🔴 Recursive CTE: Build a simple risk escalation chain.
--        For each company, list events from lowest to highest risk score.
-- ─────────────────────────────────────────────────────────────────────────────
WITH RECURSIVE risk_chain AS (
    -- Anchor: lowest risk event per company
    SELECT
        company_name,
        record_id,
        year,
        ROUND(fn_calc_risk_score(ai_replacement_risk, job_security_score, layoff_percentage), 2) AS risk_score,
        1 AS chain_level
    FROM tech_layoffs t
    WHERE (company_name, record_id) IN (
        SELECT company_name, MIN(record_id)
        FROM tech_layoffs
        GROUP BY company_name
    )

    UNION ALL

    -- Recursive: next event for the same company
    SELECT
        nxt.company_name,
        nxt.record_id,
        nxt.year,
        ROUND(fn_calc_risk_score(nxt.ai_replacement_risk, nxt.job_security_score, nxt.layoff_percentage), 2),
        rc.chain_level + 1
    FROM tech_layoffs nxt
    JOIN risk_chain rc
        ON  nxt.company_name = rc.company_name
        AND nxt.record_id > rc.record_id
    WHERE rc.chain_level < 5  -- limit depth
)
SELECT * FROM risk_chain
ORDER BY company_name, chain_level;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q18 🔴 EXPLAIN the difference between WHERE and HAVING with an example.
-- ─────────────────────────────────────────────────────────────────────────────
-- ANSWER:
-- WHERE filters individual rows BEFORE aggregation.
-- HAVING filters aggregated groups AFTER GROUP BY.
-- WHERE is always faster for row-level filters because it reduces data early.

-- WHERE example — filter rows before grouping:
SELECT industry, SUM(layoffs_count) AS total
FROM tech_layoffs
WHERE year >= 2025          -- Only processes rows where year >= 2025
GROUP BY industry;

-- HAVING example — filter after grouping:
SELECT industry, SUM(layoffs_count) AS total
FROM tech_layoffs
GROUP BY industry
HAVING SUM(layoffs_count) > 500000;  -- Only keep groups with > 500K layoffs

-- Combined: WHERE filters rows first, HAVING filters groups after:
SELECT industry, SUM(layoffs_count) AS total
FROM tech_layoffs
WHERE year >= 2025
GROUP BY industry
HAVING SUM(layoffs_count) > 100000;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q19 🔴 How would you find all companies where every single record
--        has a job_security_score above 6.0? (ALL condition)
-- ─────────────────────────────────────────────────────────────────────────────
-- Method 1: Using HAVING with MIN
SELECT company_name
FROM tech_layoffs
GROUP BY company_name
HAVING MIN(job_security_score) > 6.0
ORDER BY company_name;

-- Method 2: Using NOT EXISTS (equivalent, more explicit)
SELECT DISTINCT company_name
FROM tech_layoffs t1
WHERE NOT EXISTS (
    SELECT 1
    FROM tech_layoffs t2
    WHERE t2.company_name = t1.company_name
      AND t2.job_security_score <= 6.0
)
ORDER BY company_name;


-- ─────────────────────────────────────────────────────────────────────────────
-- Q20 🔴 Explain and demonstrate the difference between UNION and UNION ALL.
-- ─────────────────────────────────────────────────────────────────────────────
-- UNION:     removes duplicate rows (sorts + deduplicates — slower)
-- UNION ALL: keeps all rows including duplicates (faster, use when duplicates are OK)

-- UNION — deduplicated
SELECT company_name FROM tech_layoffs WHERE country = 'USA'
UNION
SELECT company_name FROM tech_layoffs WHERE industry = 'AI';

-- UNION ALL — with duplicates (companies in USA AND AI appear twice)
SELECT company_name FROM tech_layoffs WHERE country = 'USA'
UNION ALL
SELECT company_name FROM tech_layoffs WHERE industry = 'AI';

-- Performance note: UNION ALL is always preferred when you know there are no
-- duplicates, or when duplicates are acceptable, because UNION requires a sort.


-- =============================================================================
-- ⚡ SCENARIO QUESTIONS (Real-world Business Problems)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- S1 ⚡ Business: "Which roles should we prioritize hiring in 2026, given
--        AI risk levels and market conditions?"
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    top_hiring_role,
    COUNT(*)                              AS demand_events,
    SUM(open_roles)                       AS total_openings,
    ROUND(AVG(ai_replacement_risk), 2)    AS avg_ai_risk,
    ROUND(AVG(remote_jobs_percentage), 1) AS avg_remote_pct,
    ROUND(AVG(salary_budget_change), 2)   AS avg_salary_change,
    -- Priority score: high demand + low AI risk + good salary change
    ROUND(
        (SUM(open_roles) / 10000.0 * 0.4) +
        ((10 - AVG(ai_replacement_risk)) * 0.4) +
        (CASE WHEN AVG(salary_budget_change) > 0 THEN 1 ELSE 0 END * 0.2),
    3) AS hiring_priority_score
FROM tech_layoffs
WHERE year = 2026
  AND market_condition IN ('Stable', 'Bull Market')
GROUP BY top_hiring_role
ORDER BY hiring_priority_score DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- S2 ⚡ Business: "Which countries are the safest for tech workers right now?"
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    country,
    year,
    ROUND(AVG(job_security_score), 2)     AS avg_job_security,
    ROUND(AVG(employee_sentiment), 2)     AS avg_sentiment,
    ROUND(AVG(remote_jobs_percentage), 1) AS avg_remote_pct,
    SUM(open_roles)                       AS total_openings,
    SUM(layoffs_count)                    AS total_layoffs,
    SUM(open_roles) - SUM(layoffs_count)  AS net_jobs,
    ROUND(AVG(salary_budget_change), 2)   AS avg_salary_trend
FROM tech_layoffs
WHERE year = (SELECT MAX(year) FROM tech_layoffs)
GROUP BY country, year
ORDER BY avg_job_security DESC, net_jobs DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- S3 ⚡ Business: "Build a report to identify industries that are shrinking
--        due to AI automation specifically."
-- ─────────────────────────────────────────────────────────────────────────────
WITH ai_driven AS (
    SELECT
        industry,
        year,
        SUM(CASE WHEN reason_for_layoffs = 'AI Automation' THEN layoffs_count ELSE 0 END) AS ai_layoffs,
        SUM(layoffs_count) AS total_layoffs,
        ROUND(AVG(ai_automation_impact), 2) AS avg_ai_impact,
        ROUND(AVG(ai_replacement_risk), 2)  AS avg_ai_risk
    FROM tech_layoffs
    GROUP BY industry, year
)
SELECT
    industry,
    year,
    ai_layoffs,
    total_layoffs,
    ROUND(100.0 * ai_layoffs / NULLIF(total_layoffs, 0), 1) AS ai_driven_pct,
    avg_ai_impact,
    avg_ai_risk,
    CASE
        WHEN 100.0 * ai_layoffs / NULLIF(total_layoffs, 0) > 40 THEN '🔴 AI-Disrupted'
        WHEN 100.0 * ai_layoffs / NULLIF(total_layoffs, 0) > 20 THEN '🟡 AI-Affected'
        ELSE '🟢 AI-Resilient'
    END AS disruption_label
FROM ai_driven
WHERE total_layoffs > 0
ORDER BY ai_driven_pct DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- S4 ⚡ Write a query to detect sudden spikes: companies where a single year's
--        layoffs exceeded 3× their own historical average.
-- ─────────────────────────────────────────────────────────────────────────────
WITH company_averages AS (
    SELECT
        company_name,
        year,
        SUM(layoffs_count) AS year_layoffs,
        AVG(SUM(layoffs_count)) OVER (
            PARTITION BY company_name
            ORDER BY year
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ) AS historical_avg   -- average of all prior years
    FROM tech_layoffs
    GROUP BY company_name, year
)
SELECT
    company_name,
    year,
    year_layoffs,
    ROUND(historical_avg, 0) AS historical_avg_before,
    ROUND(year_layoffs / NULLIF(historical_avg, 0), 2) AS spike_ratio
FROM company_averages
WHERE year_layoffs > 3 * COALESCE(historical_avg, 0)
  AND historical_avg IS NOT NULL   -- exclude first-year companies
ORDER BY spike_ratio DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- S5 ⚡ "What is the impact of AI adoption on employee sentiment?"
--       Show a correlation view grouped by adoption tier.
-- ─────────────────────────────────────────────────────────────────────────────
SELECT
    CASE
        WHEN ai_adoption_level < 3  THEN 'Low (0–3)'
        WHEN ai_adoption_level < 6  THEN 'Medium (3–6)'
        WHEN ai_adoption_level < 8  THEN 'High (6–8)'
        ELSE                             'Very High (8–10)'
    END AS ai_adoption_tier,
    COUNT(*) AS events,
    ROUND(AVG(employee_sentiment), 2)  AS avg_sentiment,
    ROUND(AVG(job_security_score), 2)  AS avg_security,
    ROUND(AVG(layoff_percentage), 2)   AS avg_layoff_pct,
    ROUND(AVG(revenue_growth_percent), 2) AS avg_revenue_growth
FROM tech_layoffs
GROUP BY
    CASE
        WHEN ai_adoption_level < 3  THEN 'Low (0–3)'
        WHEN ai_adoption_level < 6  THEN 'Medium (3–6)'
        WHEN ai_adoption_level < 8  THEN 'High (6–8)'
        ELSE                             'Very High (8–10)'
    END
ORDER BY ai_adoption_tier;


-- =============================================================================
-- 📋 QUICK REFERENCE: Common Interview Concepts Cheatsheet
-- =============================================================================

/*
CONCEPT                   | KEYWORD/FUNCTION          | NOTES
──────────────────────────┼───────────────────────────┼─────────────────────────
Eliminate duplicates       | DISTINCT / GROUP BY       | DISTINCT is set-based
Find Nth highest           | DENSE_RANK + filter       | Handles ties correctly
Running total              | SUM() OVER (ORDER BY)     | Window function
Previous row value         | LAG(col, n)               | Window function
Conditional count          | COUNT(*) FILTER (WHERE)   | PostgreSQL; CASE in MySQL
Filter aggregates          | HAVING                    | Runs AFTER GROUP BY
Prevent divide-by-zero     | NULLIF(denominator, 0)    | Returns NULL if 0
Replace NULLs              | COALESCE(col, default)    | Returns first non-NULL
String matching            | LIKE '%pattern%'          | Case-sensitive in most DBs
Check existence            | EXISTS / NOT EXISTS       | Handles NULLs safely
Multiple result sets       | UNION ALL                 | Faster than UNION
Reusable subquery          | CTE (WITH clause)         | Readable, maintainable
Time-series comparison     | LAG / LEAD                | Look back/forward N rows
Partition + sort           | PARTITION BY … ORDER BY   | Window function clauses
Median                     | PERCENTILE_CONT(0.5)      | Not AVG!
Standard deviation         | STDDEV() / VAR_POP()      | For outlier detection
Null-safe join             | IS NOT DISTINCT FROM      | PostgreSQL; <=> in MySQL
*/

-- =============================================================================
-- END OF FILE: 09_interview_questions.sql
-- =============================================================================
