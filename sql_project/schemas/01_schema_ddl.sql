-- =============================================================================
-- FILE: 01_schema_ddl.sql
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: DDL — Table definition, constraints, indexes, lookup tables
-- DIALECT: PostgreSQL (with MySQL/SQLite notes where applicable)
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SECTION 1: Create Database (run as superuser)
-- -----------------------------------------------------------------------------

-- PostgreSQL
CREATE DATABASE tech_layoffs_db
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE   = 'en_US.UTF-8';

-- MySQL equivalent:
-- CREATE DATABASE tech_layoffs_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


-- -----------------------------------------------------------------------------
-- SECTION 2: ENUM / Lookup Tables
-- Best practice: normalize repeating categorical values into lookup tables
-- (Alternative: use CHECK constraints — shown in main table below)
-- -----------------------------------------------------------------------------

CREATE TABLE dim_industry (
    industry_id   SERIAL        PRIMARY KEY,
    industry_name VARCHAR(50)   NOT NULL UNIQUE
);

INSERT INTO dim_industry (industry_name) VALUES
    ('AI'),
    ('Cybersecurity'),
    ('Gaming'),
    ('FinTech'),
    ('Cloud'),
    ('Social Media'),
    ('E-Commerce');


CREATE TABLE dim_country (
    country_id   SERIAL       PRIMARY KEY,
    country_name VARCHAR(60)  NOT NULL UNIQUE,
    region       VARCHAR(30)            -- e.g., 'Asia', 'North America', 'Europe'
);

INSERT INTO dim_country (country_name, region) VALUES
    ('USA',       'North America'),
    ('UK',        'Europe'),
    ('Canada',    'North America'),
    ('India',     'Asia'),
    ('Germany',   'Europe'),
    ('Singapore', 'Asia');


CREATE TABLE dim_company_size (
    size_id     SERIAL       PRIMARY KEY,
    size_label  VARCHAR(20)  NOT NULL UNIQUE,
    min_headcount INT,
    max_headcount INT
);

INSERT INTO dim_company_size (size_label, min_headcount, max_headcount) VALUES
    ('Startup',   1,      500),
    ('Mid-size',  501,    5000),
    ('Big Tech',  5001,   50000),
    ('Enterprise',50001,  NULL);


-- -----------------------------------------------------------------------------
-- SECTION 3: Main Fact Table
-- -----------------------------------------------------------------------------

CREATE TABLE tech_layoffs (

    -- Primary Key
    record_id              VARCHAR(10)     PRIMARY KEY,

    -- Company dimensions (denormalized for query simplicity)
    company_name           VARCHAR(100)    NOT NULL,
    industry               VARCHAR(50)     NOT NULL,
    country                VARCHAR(60)     NOT NULL,
    company_size           VARCHAR(20)     NOT NULL,

    -- Time dimension
    month                  VARCHAR(3)      NOT NULL,  -- 'Jan', 'Feb', ...
    year                   SMALLINT        NOT NULL
                               CHECK (year BETWEEN 2020 AND 2030),

    -- Layoff metrics
    layoffs_count          INT             NOT NULL DEFAULT 0
                               CHECK (layoffs_count >= 0),
    layoff_percentage      NUMERIC(5,2)    NOT NULL
                               CHECK (layoff_percentage BETWEEN 0 AND 100),
    reason_for_layoffs     VARCHAR(60)     NOT NULL,

    -- AI impact scores (0.0 – 10.0 scale)
    ai_automation_impact   NUMERIC(4,1)    CHECK (ai_automation_impact BETWEEN 0 AND 10),
    ai_replacement_risk    NUMERIC(4,1)    CHECK (ai_replacement_risk  BETWEEN 0 AND 10),

    -- Hiring metrics
    open_roles             INT             DEFAULT 0 CHECK (open_roles >= 0),
    hiring_trend           VARCHAR(25)     NOT NULL
                               CHECK (hiring_trend IN (
                                   'Aggressive Hiring', 'Moderate Hiring',
                                   'Hiring Freeze', 'Downsizing'
                               )),
    remote_jobs_percentage NUMERIC(5,2)    CHECK (remote_jobs_percentage BETWEEN 0 AND 100),
    top_hiring_role        VARCHAR(60),

    -- Financial metrics
    stock_growth_percent   NUMERIC(7,2),
    revenue_growth_percent NUMERIC(7,2),
    salary_budget_change   NUMERIC(7,2),

    -- Sentiment / adoption scores
    ai_adoption_level      NUMERIC(4,1)    CHECK (ai_adoption_level   BETWEEN 0 AND 10),
    employee_sentiment     NUMERIC(4,1)    CHECK (employee_sentiment   BETWEEN 0 AND 10),
    job_security_score     NUMERIC(4,1)    CHECK (job_security_score   BETWEEN 0 AND 10),

    -- Market
    market_condition       VARCHAR(20)     NOT NULL
                               CHECK (market_condition IN ('Bull Market','Recession','Stable')),

    -- Audit columns (good practice for production tables)
    created_at             TIMESTAMPTZ     DEFAULT NOW(),
    updated_at             TIMESTAMPTZ     DEFAULT NOW()

);

-- Comment the table and key columns (useful in tools like DBeaver, pgAdmin)
COMMENT ON TABLE tech_layoffs IS
    'Fact table: one row per company-month layoff/hiring event, 2023–2026';
COMMENT ON COLUMN tech_layoffs.ai_automation_impact IS
    'Score 0–10: how much AI automation drove this event';
COMMENT ON COLUMN tech_layoffs.ai_replacement_risk IS
    'Score 0–10: likelihood that AI replaces roles in this company';


-- -----------------------------------------------------------------------------
-- SECTION 4: Indexes
-- Strategy: index columns used in WHERE, JOIN, ORDER BY, GROUP BY
-- -----------------------------------------------------------------------------

-- Composite index for the most common filter pattern: country + year
CREATE INDEX idx_layoffs_country_year
    ON tech_layoffs (country, year);

-- Index for industry-level roll-ups
CREATE INDEX idx_layoffs_industry
    ON tech_layoffs (industry);

-- Index for time-series queries
CREATE INDEX idx_layoffs_year_month
    ON tech_layoffs (year, month);

-- Partial index: only rows with a hiring freeze (selective, small index)
CREATE INDEX idx_layoffs_freeze
    ON tech_layoffs (company_name, year)
    WHERE hiring_trend = 'Hiring Freeze';

-- Index for AI risk analysis queries
CREATE INDEX idx_layoffs_ai_risk
    ON tech_layoffs (ai_replacement_risk, ai_adoption_level);

-- Full-text index on company name (PostgreSQL)
CREATE INDEX idx_layoffs_company_name
    ON tech_layoffs USING GIN (to_tsvector('english', company_name));

-- MySQL equivalent:
-- CREATE FULLTEXT INDEX idx_layoffs_company_name ON tech_layoffs (company_name);


-- -----------------------------------------------------------------------------
-- SECTION 5: ALTER TABLE examples (demonstrating schema evolution)
-- -----------------------------------------------------------------------------

-- Add a computed/derived column for net workforce change
ALTER TABLE tech_layoffs
    ADD COLUMN net_headcount_change INT
        GENERATED ALWAYS AS (open_roles - layoffs_count) STORED;
-- MySQL: use AS (open_roles - layoffs_count) STORED
-- SQLite: does not support generated columns before version 3.31

-- Add a soft-delete flag (production best practice)
ALTER TABLE tech_layoffs
    ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT FALSE;

-- Add a data quality flag
ALTER TABLE tech_layoffs
    ADD COLUMN data_quality_flag VARCHAR(20) DEFAULT 'VALIDATED';


-- -----------------------------------------------------------------------------
-- SECTION 6: Trigger — auto-update updated_at on row change (PostgreSQL)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_layoffs_updated_at
    BEFORE UPDATE ON tech_layoffs
    FOR EACH ROW
    EXECUTE FUNCTION fn_set_updated_at();


-- -----------------------------------------------------------------------------
-- SECTION 7: Materialized View (PostgreSQL) for performance
-- Refreshed on demand; avoid hitting base table for dashboards
-- -----------------------------------------------------------------------------

CREATE MATERIALIZED VIEW mv_industry_summary AS
SELECT
    industry,
    year,
    COUNT(*)                          AS event_count,
    SUM(layoffs_count)                AS total_layoffs,
    ROUND(AVG(layoff_percentage), 2)  AS avg_layoff_pct,
    SUM(open_roles)                   AS total_open_roles,
    ROUND(AVG(ai_adoption_level), 2)  AS avg_ai_adoption,
    ROUND(AVG(employee_sentiment), 2) AS avg_sentiment
FROM tech_layoffs
WHERE is_deleted = FALSE
GROUP BY industry, year
ORDER BY year DESC, total_layoffs DESC;

-- Refresh when base data changes:
-- REFRESH MATERIALIZED VIEW CONCURRENTLY mv_industry_summary;

-- Index on the materialized view
CREATE INDEX idx_mv_industry_year
    ON mv_industry_summary (industry, year);


-- =============================================================================
-- END OF FILE: 01_schema_ddl.sql
-- =============================================================================
