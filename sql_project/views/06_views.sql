-- =============================================================================
-- FILE: 06_views.sql
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: Reusable views — simple views, aggregated views, and
--              materialized views for BI/reporting dashboards
-- =============================================================================


-- =============================================================================
-- SECTION 1: Operational / Reporting Views
-- =============================================================================

-- VIEW 1: Executive summary — one row per industry per year
CREATE OR REPLACE VIEW vw_industry_annual_summary AS
SELECT
    industry,
    year,
    COUNT(*)                              AS total_events,
    COUNT(DISTINCT company_name)          AS unique_companies,
    SUM(layoffs_count)                    AS total_layoffs,
    ROUND(AVG(layoff_percentage), 2)      AS avg_layoff_pct,
    SUM(open_roles)                       AS total_open_roles,
    ROUND(AVG(ai_adoption_level), 2)      AS avg_ai_adoption,
    ROUND(AVG(ai_replacement_risk), 2)    AS avg_ai_risk,
    ROUND(AVG(employee_sentiment), 2)     AS avg_sentiment,
    ROUND(AVG(job_security_score), 2)     AS avg_job_security,
    ROUND(AVG(revenue_growth_percent), 2) AS avg_revenue_growth,
    SUM(CASE WHEN hiring_trend = 'Aggressive Hiring' THEN 1 ELSE 0 END) AS aggressive_hiring_events,
    SUM(CASE WHEN hiring_trend = 'Hiring Freeze'     THEN 1 ELSE 0 END) AS hiring_freeze_events
FROM tech_layoffs
WHERE is_deleted = FALSE
GROUP BY industry, year;

COMMENT ON VIEW vw_industry_annual_summary IS
    'Aggregated yearly KPIs per industry — safe for exec dashboards';


-- VIEW 2: Country-level hiring health dashboard
CREATE OR REPLACE VIEW vw_country_hiring_health AS
SELECT
    country,
    year,
    COUNT(*)                              AS events,
    SUM(layoffs_count)                    AS total_layoffs,
    SUM(open_roles)                       AS total_open_roles,
    ROUND(AVG(remote_jobs_percentage), 1) AS avg_remote_pct,
    ROUND(AVG(job_security_score), 2)     AS avg_security,
    ROUND(AVG(employee_sentiment), 2)     AS avg_sentiment,
    -- Net hiring signal: positive = more hiring than layoffs
    SUM(open_roles) - SUM(layoffs_count)  AS net_headcount_signal,
    CASE
        WHEN SUM(open_roles) > SUM(layoffs_count) * 1.5 THEN 'Expanding'
        WHEN SUM(open_roles) > SUM(layoffs_count)       THEN 'Recovering'
        WHEN SUM(open_roles) > SUM(layoffs_count) * 0.5 THEN 'Contracting'
        ELSE                                                  'Severe Contraction'
    END AS hiring_health_label
FROM tech_layoffs
WHERE is_deleted = FALSE
GROUP BY country, year;


-- VIEW 3: Company risk profile (point-in-time snapshot for latest year)
CREATE OR REPLACE VIEW vw_company_risk_profile AS
SELECT
    company_name,
    industry,
    country,
    company_size,
    ROUND(AVG(ai_replacement_risk), 2)   AS avg_ai_replacement_risk,
    ROUND(AVG(ai_automation_impact), 2)  AS avg_ai_automation_impact,
    ROUND(AVG(job_security_score), 2)    AS avg_job_security,
    ROUND(AVG(employee_sentiment), 2)    AS avg_sentiment,
    ROUND(AVG(layoff_percentage), 2)     AS avg_layoff_pct,
    COUNT(*)                             AS total_events,
    SUM(layoffs_count)                   AS total_layoffs,
    MAX(year)                            AS latest_year,
    -- Composite risk score (weighted)
    ROUND(
        (AVG(ai_replacement_risk) * 0.35) +
        ((10 - AVG(job_security_score)) * 0.35) +
        (AVG(layoff_percentage) / 10 * 0.30),
    2) AS composite_risk_score
FROM tech_layoffs
WHERE is_deleted = FALSE
GROUP BY company_name, industry, country, company_size;


-- VIEW 4: Top hiring roles demand tracker
CREATE OR REPLACE VIEW vw_role_demand AS
SELECT
    top_hiring_role                        AS role,
    industry,
    year,
    COUNT(*)                               AS demand_events,
    SUM(open_roles)                        AS total_openings,
    ROUND(AVG(remote_jobs_percentage), 1)  AS avg_remote_pct,
    ROUND(AVG(salary_budget_change), 2)    AS avg_salary_budget_change,
    ROUND(AVG(ai_replacement_risk), 2)     AS avg_ai_risk_for_role
FROM tech_layoffs
WHERE is_deleted = FALSE
GROUP BY top_hiring_role, industry, year;


-- VIEW 5: Market condition financial correlations
CREATE OR REPLACE VIEW vw_market_financials AS
SELECT
    market_condition,
    industry,
    year,
    COUNT(*)                              AS events,
    ROUND(AVG(stock_growth_percent), 2)   AS avg_stock_growth,
    ROUND(AVG(revenue_growth_percent), 2) AS avg_revenue_growth,
    ROUND(AVG(salary_budget_change), 2)   AS avg_salary_budget_chg,
    ROUND(AVG(layoff_percentage), 2)      AS avg_layoff_pct,
    ROUND(AVG(employee_sentiment), 2)     AS avg_sentiment
FROM tech_layoffs
WHERE is_deleted = FALSE
GROUP BY market_condition, industry, year;


-- =============================================================================
-- SECTION 2: View Usage Examples
-- =============================================================================

-- Example A: Use exec summary view to find top industries by AI risk in 2025
SELECT
    industry,
    avg_ai_risk,
    total_layoffs,
    avg_sentiment
FROM vw_industry_annual_summary
WHERE year = 2025
ORDER BY avg_ai_risk DESC
LIMIT 5;


-- Example B: Countries with the best net hiring health in 2026
SELECT
    country,
    net_headcount_signal,
    hiring_health_label,
    avg_remote_pct
FROM vw_country_hiring_health
WHERE year = 2026
ORDER BY net_headcount_signal DESC;


-- Example C: Highest-risk companies across all time
SELECT
    company_name,
    industry,
    composite_risk_score,
    avg_ai_replacement_risk,
    avg_job_security
FROM vw_company_risk_profile
WHERE composite_risk_score > 7.0
ORDER BY composite_risk_score DESC
LIMIT 10;


-- Example D: Fastest-growing roles by remote opportunity
SELECT
    role,
    SUM(total_openings)   AS total_openings,
    AVG(avg_remote_pct)   AS avg_remote,
    AVG(avg_salary_budget_change) AS avg_salary_change
FROM vw_role_demand
WHERE year >= 2025
GROUP BY role
ORDER BY total_openings DESC;


-- =============================================================================
-- SECTION 3: Drop Views (cleanup)
-- =============================================================================
-- Run only if you need to rebuild:
/*
DROP VIEW IF EXISTS vw_industry_annual_summary;
DROP VIEW IF EXISTS vw_country_hiring_health;
DROP VIEW IF EXISTS vw_company_risk_profile;
DROP VIEW IF EXISTS vw_role_demand;
DROP VIEW IF EXISTS vw_market_financials;
*/


-- =============================================================================
-- END OF FILE: 06_views.sql
-- =============================================================================
