-- =============================================================================
-- FILE: 07_stored_procedures.sql
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: Stored procedures, user-defined functions, and transactions
-- DIALECT: PostgreSQL (MySQL equivalents noted in comments)
-- =============================================================================


-- =============================================================================
-- SECTION 1: User-Defined Functions (UDFs)
-- =============================================================================

-- FUNCTION 1: Calculate composite risk score for a single row
CREATE OR REPLACE FUNCTION fn_calc_risk_score(
    p_ai_risk         NUMERIC,
    p_job_security    NUMERIC,
    p_layoff_pct      NUMERIC
) RETURNS NUMERIC AS $$
BEGIN
    -- Weighted risk: AI risk (35%) + inverse job security (35%) + layoff severity (30%)
    RETURN ROUND(
        (p_ai_risk * 0.35) +
        ((10 - p_job_security) * 0.35) +
        (LEAST(p_layoff_pct, 100) / 10 * 0.30),
    2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Usage:
-- SELECT company_name, fn_calc_risk_score(ai_replacement_risk, job_security_score, layoff_percentage) AS risk
-- FROM tech_layoffs ORDER BY risk DESC LIMIT 10;


-- FUNCTION 2: Classify a hiring trend as 'Growth', 'Stable', or 'Decline'
CREATE OR REPLACE FUNCTION fn_classify_hiring(p_trend VARCHAR)
RETURNS VARCHAR AS $$
BEGIN
    RETURN CASE p_trend
        WHEN 'Aggressive Hiring' THEN 'Growth'
        WHEN 'Moderate Hiring'   THEN 'Stable'
        WHEN 'Hiring Freeze'     THEN 'Decline'
        WHEN 'Downsizing'        THEN 'Decline'
        ELSE 'Unknown'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- FUNCTION 3: Returns table — top N companies by layoffs in a given industry/year
CREATE OR REPLACE FUNCTION fn_top_companies_by_layoffs(
    p_industry  VARCHAR,
    p_year      INT,
    p_top_n     INT DEFAULT 5
)
RETURNS TABLE (
    company_name    VARCHAR,
    country         VARCHAR,
    layoffs_count   INT,
    layoff_pct      NUMERIC,
    hiring_trend    VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.company_name,
        t.country,
        t.layoffs_count,
        t.layoff_percentage,
        t.hiring_trend
    FROM tech_layoffs t
    WHERE t.industry = p_industry
      AND t.year = p_year
    ORDER BY t.layoffs_count DESC
    LIMIT p_top_n;
END;
$$ LANGUAGE plpgsql STABLE;

-- Usage:
-- SELECT * FROM fn_top_companies_by_layoffs('AI', 2025, 10);


-- =============================================================================
-- SECTION 2: Stored Procedures (with transactions and error handling)
-- =============================================================================

-- PROCEDURE 1: Upsert a layoff record (INSERT or UPDATE if exists)
CREATE OR REPLACE PROCEDURE sp_upsert_layoff_record(
    p_record_id              VARCHAR,
    p_company_name           VARCHAR,
    p_industry               VARCHAR,
    p_country                VARCHAR,
    p_company_size           VARCHAR,
    p_month                  VARCHAR,
    p_year                   INT,
    p_layoffs_count          INT,
    p_layoff_percentage      NUMERIC,
    p_reason_for_layoffs     VARCHAR,
    p_ai_automation_impact   NUMERIC,
    p_ai_replacement_risk    NUMERIC,
    p_open_roles             INT,
    p_hiring_trend           VARCHAR,
    p_remote_jobs_percentage NUMERIC,
    p_top_hiring_role        VARCHAR,
    p_market_condition       VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO tech_layoffs (
        record_id, company_name, industry, country, company_size,
        month, year, layoffs_count, layoff_percentage, reason_for_layoffs,
        ai_automation_impact, ai_replacement_risk, open_roles, hiring_trend,
        remote_jobs_percentage, top_hiring_role, market_condition
    ) VALUES (
        p_record_id, p_company_name, p_industry, p_country, p_company_size,
        p_month, p_year, p_layoffs_count, p_layoff_percentage, p_reason_for_layoffs,
        p_ai_automation_impact, p_ai_replacement_risk, p_open_roles, p_hiring_trend,
        p_remote_jobs_percentage, p_top_hiring_role, p_market_condition
    )
    ON CONFLICT (record_id) DO UPDATE SET
        company_name           = EXCLUDED.company_name,
        layoffs_count          = EXCLUDED.layoffs_count,
        layoff_percentage      = EXCLUDED.layoff_percentage,
        open_roles             = EXCLUDED.open_roles,
        hiring_trend           = EXCLUDED.hiring_trend,
        ai_automation_impact   = EXCLUDED.ai_automation_impact,
        ai_replacement_risk    = EXCLUDED.ai_replacement_risk,
        market_condition       = EXCLUDED.market_condition,
        updated_at             = NOW();

    RAISE NOTICE 'Record % upserted successfully.', p_record_id;

EXCEPTION
    WHEN check_violation THEN
        RAISE EXCEPTION 'Constraint violation for record %: %', p_record_id, SQLERRM;
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Unexpected error upserting %: %', p_record_id, SQLERRM;
END;
$$;

-- Usage:
-- CALL sp_upsert_layoff_record('T9999', 'TestCo', 'AI', 'USA', 'Startup',
--     'Jan', 2026, 500, 5.0, 'Cost Cutting', 7.0, 6.5, 200, 'Moderate Hiring',
--     40.0, 'ML Engineer', 'Stable');


-- PROCEDURE 2: Soft-delete records older than N years
CREATE OR REPLACE PROCEDURE sp_soft_delete_old_records(
    p_cutoff_year INT,
    OUT p_deleted_count INT
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE tech_layoffs
    SET    is_deleted = TRUE,
           updated_at = NOW()
    WHERE  year < p_cutoff_year
      AND  is_deleted = FALSE;

    GET DIAGNOSTICS p_deleted_count = ROW_COUNT;

    RAISE NOTICE '% records soft-deleted (year < %).', p_deleted_count, p_cutoff_year;
END;
$$;

-- Usage:
-- CALL sp_soft_delete_old_records(2023, NULL);


-- PROCEDURE 3: Batch update AI risk scores for an industry
CREATE OR REPLACE PROCEDURE sp_update_ai_risk_by_industry(
    p_industry        VARCHAR,
    p_risk_adjustment NUMERIC   -- positive or negative adjustment
)
LANGUAGE plpgsql AS $$
DECLARE
    v_rows_affected INT;
BEGIN
    -- Validate: prevent adjustment outside bounds
    IF ABS(p_risk_adjustment) > 5 THEN
        RAISE EXCEPTION 'Risk adjustment % exceeds allowed range [-5, +5]', p_risk_adjustment;
    END IF;

    UPDATE tech_layoffs
    SET
        ai_replacement_risk = LEAST(10, GREATEST(0,
            ai_replacement_risk + p_risk_adjustment
        )),
        updated_at = NOW()
    WHERE industry = p_industry
      AND is_deleted = FALSE;

    GET DIAGNOSTICS v_rows_affected = ROW_COUNT;
    RAISE NOTICE 'Updated AI risk for % rows in industry %.', v_rows_affected, p_industry;
END;
$$;


-- PROCEDURE 4: Generate a company trend report (uses transaction savepoints)
CREATE OR REPLACE PROCEDURE sp_generate_company_report(
    p_company_name  VARCHAR,
    p_out_table     VARCHAR DEFAULT 'rpt_company_trend'
)
LANGUAGE plpgsql AS $$
DECLARE
    v_sql TEXT;
BEGIN
    -- Create report table if it doesn't exist
    v_sql := FORMAT(
        'CREATE TABLE IF NOT EXISTS %I (
            company_name  VARCHAR,
            year          INT,
            total_layoffs BIGINT,
            avg_ai_risk   NUMERIC,
            avg_sentiment NUMERIC,
            net_signal    BIGINT,
            generated_at  TIMESTAMPTZ DEFAULT NOW()
        )', p_out_table
    );
    EXECUTE v_sql;

    -- Savepoint before inserting
    SAVEPOINT sp_before_insert;

    v_sql := FORMAT(
        'INSERT INTO %I (company_name, year, total_layoffs, avg_ai_risk, avg_sentiment, net_signal)
         SELECT
             company_name,
             year,
             SUM(layoffs_count),
             ROUND(AVG(ai_replacement_risk), 2),
             ROUND(AVG(employee_sentiment), 2),
             SUM(open_roles) - SUM(layoffs_count)
         FROM tech_layoffs
         WHERE company_name = $1
           AND is_deleted = FALSE
         GROUP BY company_name, year
         ORDER BY year',
        p_out_table
    );
    EXECUTE v_sql USING p_company_name;

    RAISE NOTICE 'Report for company % written to table %.', p_company_name, p_out_table;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO sp_before_insert;
        RAISE EXCEPTION 'Report generation failed for %: %', p_company_name, SQLERRM;
END;
$$;


-- =============================================================================
-- SECTION 3: Transaction Control Examples
-- =============================================================================

-- Example: Transfer-style transaction — record a major industry restructuring
BEGIN;

    SAVEPOINT sp_phase1;

    -- Phase 1: Mark old records as processed
    UPDATE tech_layoffs
    SET data_quality_flag = 'REVIEWED'
    WHERE industry = 'AI'
      AND year = 2024
      AND layoffs_count > 10000;

    SAVEPOINT sp_phase2;

    -- Phase 2: Insert a summary record (hypothetical audit log pattern)
    INSERT INTO tech_layoffs (
        record_id, company_name, industry, country, company_size,
        month, year, layoffs_count, layoff_percentage, reason_for_layoffs,
        open_roles, hiring_trend, market_condition
    ) VALUES (
        'AUDIT_001', 'SYSTEM_REVIEW', 'AI', 'USA', 'Enterprise',
        'Jan', 2024, 0, 0.0, 'Restructuring',
        0, 'Hiring Freeze', 'Stable'
    );

    -- If all good, commit
    COMMIT;

-- On error:
-- ROLLBACK TO sp_phase1;
-- ROLLBACK;


-- =============================================================================
-- END OF FILE: 07_stored_procedures.sql
-- =============================================================================
