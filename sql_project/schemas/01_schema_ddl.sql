-- =============================================================================
-- FILE: 01_schema_ddl.sql (MySQL Version)
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: DDL — Table definition, constraints, indexes, lookup tables
-- DIALECT: MySQL 8.0+
-- =============================================================================


-- -----------------------------------------------------------------------------
-- SECTION 1: Create Database (run as superuser)
-- -----------------------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS tech_layoffs_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE tech_layoffs_db;


-- -----------------------------------------------------------------------------
-- SECTION 2: ENUM / Lookup Tables
-- Best practice: normalize repeating categorical values into lookup tables
-- -----------------------------------------------------------------------------

CREATE TABLE dim_industry (
    industry_id   INT           NOT NULL AUTO_INCREMENT,
    industry_name VARCHAR(50)   NOT NULL UNIQUE,
    PRIMARY KEY (industry_id)
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
    country_id   INT          NOT NULL AUTO_INCREMENT,
    country_name VARCHAR(60)  NOT NULL UNIQUE,
    region       VARCHAR(30),
    PRIMARY KEY (country_id)
);

INSERT INTO dim_country (country_name, region) VALUES
    ('USA',       'North America'),
    ('UK',        'Europe'),
    ('Canada',    'North America'),
    ('India',     'Asia'),
    ('Germany',   'Europe'),
    ('Singapore', 'Asia');


CREATE TABLE dim_company_size (
    size_id        INT          NOT NULL AUTO_INCREMENT,
    size_label     VARCHAR(20)  NOT NULL UNIQUE,
    min_headcount  INT,
    max_headcount  INT,
    PRIMARY KEY (size_id)
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
    year                   SMALLINT        NOT NULL,
                               CHECK (year BETWEEN 2020 AND 2030),

    -- Layoff metrics
    layoffs_count          INT             NOT NULL DEFAULT 0,
                               CHECK (layoffs_count >= 0),
    layoff_percentage      DECIMAL(5,2)    NOT NULL,
                               CHECK (layoff_percentage BETWEEN 0 AND 100),
    reason_for_layoffs     VARCHAR(60)     NOT NULL,

    -- AI impact scores (0.0 – 10.0 scale)
    ai_automation_impact   DECIMAL(4,1)    CHECK (ai_automation_impact BETWEEN 0 AND 10),
    ai_replacement_risk    DECIMAL(4,1)    CHECK (ai_replacement_risk  BETWEEN 0 AND 10),

    -- Hiring metrics
    open_roles             INT             DEFAULT 0 CHECK (open_roles >= 0),
    hiring_trend           VARCHAR(25)     NOT NULL,
    remote_jobs_percentage DECIMAL(5,2)    CHECK (remote_jobs_percentage BETWEEN 0 AND 100),
    top_hiring_role        VARCHAR(60),

    -- Financial metrics
    stock_growth_percent   DECIMAL(7,2),
    revenue_growth_percent DECIMAL(7,2),
    salary_budget_change   DECIMAL(7,2),

    -- Sentiment / adoption scores
    ai_adoption_level      DECIMAL(4,1)    CHECK (ai_adoption_level   BETWEEN 0 AND 10),
    employee_sentiment     DECIMAL(4,1)    CHECK (employee_sentiment   BETWEEN 0 AND 10),
    job_security_score     DECIMAL(4,1)    CHECK (job_security_score   BETWEEN 0 AND 10),

    -- Market
    market_condition       VARCHAR(20)     NOT NULL,

    -- Audit columns (good practice for production tables)
    created_at             TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMP       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP

);

-- Add CHECK constraints using separate ALTER statements (MySQL 8.0.16+)
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_year CHECK (year BETWEEN 2020 AND 2030);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_layoffs_count CHECK (layoffs_count >= 0);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_layoff_percentage CHECK (layoff_percentage BETWEEN 0 AND 100);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_ai_automation_impact CHECK (ai_automation_impact BETWEEN 0 AND 10);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_ai_replacement_risk CHECK (ai_replacement_risk BETWEEN 0 AND 10);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_open_roles CHECK (open_roles >= 0);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_remote_jobs_percentage CHECK (remote_jobs_percentage BETWEEN 0 AND 100);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_ai_adoption_level CHECK (ai_adoption_level BETWEEN 0 AND 10);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_employee_sentiment CHECK (employee_sentiment BETWEEN 0 AND 10);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_job_security_score CHECK (job_security_score BETWEEN 0 AND 10);
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_hiring_trend CHECK (hiring_trend IN (
    'Aggressive Hiring', 'Moderate Hiring', 'Hiring Freeze', 'Downsizing'
));
ALTER TABLE tech_layoffs ADD CONSTRAINT chk_market_condition CHECK (market_condition IN ('Bull Market','Recession','Stable'));

-- Comment the table and key columns (MySQL alternative to PostgreSQL COMMENT)
ALTER TABLE tech_layoffs COMMENT = 'Fact table: one row per company-month layoff/hiring event, 2023–2026';


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

-- Partial index equivalent (MySQL doesn't have partial indexes, using filtered index comment)
-- For MySQL 8.0+, you can use functional indexes or just a regular index
CREATE INDEX idx_layoffs_freeze
    ON tech_layoffs (company_name, year);

-- Index for AI risk analysis queries
CREATE INDEX idx_layoffs_ai_risk
    ON tech_layoffs (ai_replacement_risk, ai_adoption_level);

-- Full-text index on company name (MySQL)
CREATE FULLTEXT INDEX idx_layoffs_company_name
    ON tech_layoffs (company_name);


-- -----------------------------------------------------------------------------
-- SECTION 5: ALTER TABLE examples (demonstrating schema evolution)
-- -----------------------------------------------------------------------------

-- Add a computed/derived column for net workforce change (MySQL syntax)
ALTER TABLE tech_layoffs
    ADD COLUMN net_headcount_change INT
        GENERATED ALWAYS AS (open_roles - layoffs_count) STORED;

-- Add a soft-delete flag (production best practice)
ALTER TABLE tech_layoffs
    ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT FALSE;

-- Add a data quality flag
ALTER TABLE tech_layoffs
    ADD COLUMN data_quality_flag VARCHAR(20) DEFAULT 'VALIDATED';


-- -----------------------------------------------------------------------------
-- SECTION 6: Trigger — auto-update updated_at on row change (MySQL)
-- -----------------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER trg_layoffs_before_update
    BEFORE UPDATE ON tech_layoffs
    FOR EACH ROW
BEGIN
    SET NEW.updated_at = NOW();
END$$

DELIMITER ;


-- -----------------------------------------------------------------------------
-- SECTION 7: View for industry summary (MySQL doesn't have materialized views)
-- Use a regular view, or create a table + scheduled event for materialized equivalent
-- -----------------------------------------------------------------------------

CREATE VIEW v_industry_summary AS
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


-- -----------------------------------------------------------------------------
-- SECTION 8: Stored Procedure Example (MySQL alternative to PostgreSQL functions)
-- -----------------------------------------------------------------------------

DELIMITER $$

CREATE PROCEDURE sp_refresh_industry_summary()
BEGIN
    -- For MySQL, simply query the view
    -- Or if you want a materialized approach, truncate and repopulate a summary table
    SELECT * FROM v_industry_summary;
END$$

DELIMITER ;


-- =============================================================================
-- END OF FILE: 01_schema_ddl.sql (MySQL Version)
-- =============================================================================
