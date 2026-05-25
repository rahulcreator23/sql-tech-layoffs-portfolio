-- =============================================================================
-- FILE: 02_sample_data.sql
-- PROJECT: Tech Layoffs & Hiring Trends SQL Portfolio
-- DESCRIPTION: Sample INSERT statements — 50 rows from the 12,000-row dataset
-- NOTE: For the full dataset, use COPY (PostgreSQL) or LOAD DATA (MySQL)
-- =============================================================================


-- Full dataset load — PostgreSQL COPY command:
-- COPY tech_layoffs (record_id, company_name, industry, country, company_size,
--     month, year, layoffs_count, layoff_percentage, reason_for_layoffs,
--     ai_automation_impact, ai_replacement_risk, open_roles, hiring_trend,
--     remote_jobs_percentage, top_hiring_role, stock_growth_percent,
--     revenue_growth_percent, salary_budget_change, ai_adoption_level,
--     employee_sentiment, job_security_score, market_condition)
-- FROM '/path/to/tech_layoffs_hiring_trends_elite_v2.csv'
-- WITH (FORMAT csv, HEADER true, NULL '');

-- MySQL equivalent:
-- LOAD DATA INFILE '/path/to/tech_layoffs_hiring_trends_elite_v2.csv'
-- INTO TABLE tech_layoffs FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n' IGNORE 1 ROWS;


-- -----------------------------------------------------------------------------
-- Sample INSERT: 50 rows (columns: record_id, company_name, industry, country,
-- company_size, month, year, layoffs_count, layoff_percentage, reason_for_layoffs,
-- ai_automation_impact, ai_replacement_risk, open_roles, hiring_trend,
-- remote_jobs_percentage, top_hiring_role, stock_growth_percent,
-- revenue_growth_percent, salary_budget_change, ai_adoption_level,
-- employee_sentiment, job_security_score, market_condition)
-- -----------------------------------------------------------------------------

INSERT INTO tech_layoffs (
    record_id, company_name, industry, country, company_size,
    month, year, layoffs_count, layoff_percentage, reason_for_layoffs,
    ai_automation_impact, ai_replacement_risk, open_roles, hiring_trend,
    remote_jobs_percentage, top_hiring_role, stock_growth_percent,
    revenue_growth_percent, salary_budget_change, ai_adoption_level,
    employee_sentiment, job_security_score, market_condition
) VALUES
('T0', 'Microsoft', 'AI', 'Singapore', 'Enterprise', 'Mar', 2026, 860, 1.8, 'AI Automation', 6.4, 5.0, 5426, 'Moderate Hiring', 46.7, 'ML Engineer', -25.7, 30.3, 4.9, 4.4, 8.7, 8.6, 'Bull Market'),
('T1', 'Palantir', 'AI', 'Canada', 'Big Tech', 'Feb', 2024, 955, 1.8, 'Cost Cutting', 0.9, 1.1, 9666, 'Moderate Hiring', 58.9, 'ML Engineer', -5.6, 6.1, 1.5, 1.0, 8.2, 7.2, 'Bull Market'),
('T2', 'Anthropic', 'Cybersecurity', 'USA', 'Mid-size', 'Apr', 2025, 18912, 9.5, 'Overhiring Correction', 7.1, 3.9, 437, 'Hiring Freeze', 85.4, 'Frontend Developer', 7.0, -23.6, -14.9, 5.6, 4.5, 5.9, 'Recession'),
('T3', 'Spotify', 'Gaming', 'USA', 'Mid-size', 'Jun', 2025, 18159, 9.1, 'Cost Cutting', 10.4, 7.4, 1075, 'Hiring Freeze', 44.0, 'Frontend Developer', 31.6, -22.3, -1.6, 6.5, 5.4, 4.7, 'Recession'),
('T4', 'Uber', 'Gaming', 'UK', 'Startup', 'Feb', 2025, 815, 3.3, 'Market Slowdown', 11.4, 10.0, 537, 'Moderate Hiring', 53.2, 'Frontend Developer', 85.3, 26.6, 9.8, 9.3, 6.7, 5.8, 'Bull Market'),
('T5', 'Databricks', 'FinTech', 'USA', 'Big Tech', 'Jul', 2024, 3568, 32.7, 'Overhiring Correction', 0.9, 8.4, 642, 'Downsizing', 66.9, 'Data Scientist', 36.8, 53.7, 15.2, 1.1, 7.7, 5.4, 'Recession'),
('T6', 'Adobe', 'Gaming', 'Singapore', 'Enterprise', 'Dec', 2024, 3454, 29.4, 'AI Automation', 6.7, 10.0, 1620, 'Downsizing', 47.8, 'Product Manager', 51.3, 39.7, 10.8, 5.0, 6.9, 4.2, 'Recession'),
('T7', 'Airbnb', 'Gaming', 'UK', 'Startup', 'Jul', 2025, 1038, 1.1, 'Restructuring', 6.2, 5.8, 763, 'Moderate Hiring', 55.1, 'Data Scientist', -26.2, 26.4, 13.9, 5.7, 6.5, 8.4, 'Bull Market'),
('T8', 'Intel', 'Cloud', 'UK', 'Enterprise', 'Dec', 2026, 1819, 9.3, 'AI Automation', 9.5, 10.0, 5347, 'Moderate Hiring', 27.5, 'Cloud Engineer', 74.2, 2.6, -6.1, 6.4, 5.8, 6.0, 'Bull Market'),
('T9', 'Databricks', 'Social Media', 'India', 'Mid-size', 'Jul', 2025, 1306, 4.3, 'Overhiring Correction', 5.1, 3.5, 5775, 'Moderate Hiring', 52.7, 'DevOps Engineer', 48.5, -2.1, -5.5, 3.4, 5.3, 6.2, 'Bull Market'),
('T10', 'Airbnb', 'Social Media', 'UK', 'Startup', 'Jun', 2025, 1136, 0.6, 'Market Slowdown', 5.3, 5.4, 1836, 'Hiring Freeze', 32.8, 'Software Engineer', 37.3, 17.7, 0.9, 6.0, 6.6, 8.2, 'Bull Market'),
('T11', 'Amazon', 'Cloud', 'Canada', 'Enterprise', 'Jul', 2026, 1153, 5.3, 'Restructuring', 3.5, 4.8, 3710, 'Hiring Freeze', 70.9, 'DevOps Engineer', 53.3, 6.3, 5.2, 3.2, 7.3, 6.8, 'Bull Market'),
('T12', 'Apple', 'FinTech', 'India', 'Mid-size', 'Dec', 2026, 10339, 24.3, 'Restructuring', 2.5, 6.6, 452, 'Downsizing', 66.9, 'Cloud Engineer', 2.1, -16.8, -4.3, 1.8, 4.1, 3.8, 'Recession'),
('T13', 'Stripe', 'E-Commerce', 'UK', 'Mid-size', 'Feb', 2024, 1802, 3.4, 'AI Automation', 6.2, 10.0, 5930, 'Moderate Hiring', 28.3, 'DevOps Engineer', 87.6, 18.9, 6.0, 8.5, 9.3, 7.2, 'Bull Market'),
('T14', 'Apple', 'Social Media', 'India', 'Big Tech', 'Jul', 2025, 8158, 18.8, 'Overhiring Correction', 5.9, 10.0, 201, 'Hiring Freeze', 42.4, 'Data Scientist', 69.9, 54.5, 24.9, 6.0, 7.8, 5.9, 'Recession'),
('T15', 'SAP', 'Cybersecurity', 'UK', 'Startup', 'Nov', 2026, 6592, 29.2, 'Market Slowdown', 2.7, 8.9, 871, 'Hiring Freeze', 45.9, 'Data Scientist', -21.3, -23.5, -16.1, 4.4, 2.7, 2.3, 'Recession'),
('T16', 'Salesforce', 'AI', 'UK', 'Big Tech', 'Jan', 2026, 1218, 6.6, 'Market Slowdown', 9.4, 5.4, 4446, 'Moderate Hiring', 30.0, 'Data Scientist', 87.2, 16.4, 16.6, 7.7, 6.7, 6.5, 'Bull Market'),
('T17', 'Anthropic', 'Gaming', 'India', 'Startup', 'Nov', 2026, 8022, 23.8, 'Overhiring Correction', 5.5, 10.0, 596, 'Downsizing', 71.5, 'Cloud Engineer', 89.3, 14.9, -2.2, 6.8, 7.1, 4.6, 'Recession'),
('T18', 'Uber', 'Cloud', 'UK', 'Mid-size', 'Oct', 2025, 4420, 21.7, 'Restructuring', 16.0, 10.0, 240, 'Hiring Freeze', 34.5, 'Software Engineer', -8.8, 16.2, 2.2, 9.6, 5.3, 5.0, 'Recession'),
('T19', 'Google', 'AI', 'UK', 'Enterprise', 'Apr', 2026, 625, 6.2, 'AI Automation', 15.9, 7.3, 2409, 'Moderate Hiring', 35.8, 'ML Engineer', -26.6, 35.3, 18.0, 9.4, 6.7, 6.8, 'Bull Market'),
('T20', 'Amazon', 'Social Media', 'Germany', 'Startup', 'Mar', 2026, 11647, 37.2, 'Restructuring', 3.8, 10.0, 370, 'Downsizing', 15.7, 'ML Engineer', -38.1, 50.4, 1.2, 3.3, 5.9, 3.7, 'Recession'),
('T21', 'Palantir', 'Cloud', 'UK', 'Big Tech', 'Dec', 2025, 50, 4.7, 'Restructuring', 8.4, 6.8, 1915, 'Hiring Freeze', 13.1, 'Product Manager', 27.5, 2.8, 9.8, 7.0, 5.8, 7.2, 'Bull Market'),
('T22', 'Intel', 'E-Commerce', 'Canada', 'Big Tech', 'Apr', 2024, 773, 0.5, 'Market Slowdown', 6.0, 6.0, 4564, 'Moderate Hiring', 87.6, 'Product Manager', -39.5, 8.9, 4.6, 5.1, 8.2, 6.5, 'Bull Market'),
('T23', 'Google', 'Cybersecurity', 'Canada', 'Mid-size', 'Jan', 2024, 6949, 34.8, 'AI Automation', 3.7, 8.1, 562, 'Downsizing', 45.4, 'Product Manager', -32.3, -9.5, -4.2, 2.7, 4.5, 2.6, 'Recession'),
('T24', 'Airbnb', 'AI', 'USA', 'Enterprise', 'May', 2026, 580, 6.1, 'Restructuring', 7.3, 5.8, 8253, 'Moderate Hiring', 11.2, 'ML Engineer', -38.8, -21.5, 0.1, 6.9, 6.7, 5.5, 'Bull Market'),
('T25', 'Uber', 'Cybersecurity', 'India', 'Big Tech', 'Jul', 2024, 2479, 8.1, 'AI Automation', 1.9, 4.1, 3049, 'Hiring Freeze', 30.9, 'DevOps Engineer', 81.0, 17.6, 6.3, 1.9, 7.6, 7.1, 'Bull Market'),
('T26', 'Microsoft', 'Social Media', 'Germany', 'Enterprise', 'Aug', 2026, 6501, 1.5, 'AI Automation', 11.8, 10.0, 3946, 'Moderate Hiring', 61.5, 'Frontend Developer', 28.7, 55.0, 24.0, 9.5, 10.0, 8.3, 'Stable'),
('T27', 'Microsoft', 'AI', 'Germany', 'Enterprise', 'Apr', 2024, 2444, 2.1, 'Overhiring Correction', 2.8, 2.4, 9967, 'Aggressive Hiring', 40.8, 'ML Engineer', 1.0, -2.8, -0.4, 2.8, 7.5, 6.9, 'Bull Market'),
('T28', 'SAP', 'Cloud', 'Germany', 'Mid-size', 'Apr', 2024, 828, 14.7, 'Restructuring', 8.6, 10.0, 2986, 'Moderate Hiring', 89.2, 'DevOps Engineer', 5.2, 41.0, 13.5, 9.4, 8.8, 6.5, 'Stable'),
('T29', 'Palantir', 'AI', 'USA', 'Startup', 'Mar', 2025, 1548, 7.4, 'Restructuring', 4.2, 5.9, 9787, 'Moderate Hiring', 76.1, 'ML Engineer', 75.9, 8.1, -6.3, 4.9, 8.3, 5.5, 'Bull Market'),
('T30', 'OpenAI', 'Cloud', 'Germany', 'Startup', 'Jan', 2025, 717, 6.8, 'Market Slowdown', 4.4, 3.6, 3340, 'Hiring Freeze', 33.5, 'Frontend Developer', 45.8, 39.0, 21.3, 3.9, 8.8, 7.0, 'Bull Market'),
('T31', 'SAP', 'FinTech', 'Germany', 'Big Tech', 'May', 2024, 2445, 5.5, 'AI Automation', 5.9, 8.0, 5046, 'Moderate Hiring', 21.4, 'Product Manager', 38.5, -16.4, -13.8, 5.4, 6.9, 4.5, 'Bull Market'),
('T32', 'Stripe', 'Social Media', 'Canada', 'Startup', 'Jan', 2024, 18924, 24.4, 'Overhiring Correction', 7.2, 10.0, 1415, 'Hiring Freeze', 75.0, 'Cybersecurity Analyst', 88.1, 39.0, 10.0, 8.4, 4.6, 5.3, 'Recession'),
('T33', 'OpenAI', 'Cybersecurity', 'Canada', 'Mid-size', 'Mar', 2024, 90, 2.5, 'Overhiring Correction', 5.8, 5.1, 5049, 'Moderate Hiring', 47.5, 'Data Scientist', -29.0, -15.0, -0.8, 6.0, 7.3, 6.4, 'Bull Market'),
('T34', 'Amazon', 'Social Media', 'India', 'Big Tech', 'Oct', 2026, 1214, 4.8, 'AI Automation', 6.7, 10.0, 2305, 'Moderate Hiring', 11.0, 'Product Manager', -39.2, 50.7, 24.2, 9.7, 10.0, 6.2, 'Bull Market'),
('T35', 'Databricks', 'AI', 'Germany', 'Enterprise', 'Nov', 2026, 5751, 2.3, 'Market Slowdown', 4.7, 3.9, 4584, 'Moderate Hiring', 60.2, 'ML Engineer', 76.7, -21.1, -10.5, 6.0, 8.0, 7.1, 'Stable'),
('T36', 'Airbnb', 'FinTech', 'Germany', 'Mid-size', 'Aug', 2025, 1667, 18.7, 'AI Automation', 4.0, 9.1, 1389, 'Downsizing', 56.7, 'Cloud Engineer', 86.5, 58.8, 24.4, 5.1, 7.4, 5.7, 'Recession'),
('T37', 'Google', 'E-Commerce', 'Canada', 'Startup', 'Sep', 2025, 924, 1.3, 'Cost Cutting', 5.7, 10.0, 5004, 'Moderate Hiring', 59.1, 'Product Manager', 80.9, 48.6, 14.1, 8.3, 6.5, 7.1, 'Bull Market'),
('T38', 'Intel', 'AI', 'India', 'Enterprise', 'Aug', 2026, 323, 17.7, 'Market Slowdown', 8.4, 10.0, 7970, 'Aggressive Hiring', 77.4, 'ML Engineer', 18.3, 10.3, -1.6, 8.3, 4.1, 5.3, 'Stable'),
('T39', 'Databricks', 'Gaming', 'Singapore', 'Startup', 'Nov', 2024, 10860, 39.9, 'Cost Cutting', 10.1, 10.0, 1531, 'Downsizing', 40.2, 'Cloud Engineer', -17.3, -3.6, -13.8, 8.3, 2.5, 2.7, 'Recession'),
('T40', 'Spotify', 'AI', 'USA', 'Mid-size', 'Oct', 2024, 2181, 7.1, 'Market Slowdown', 5.7, 10.0, 1770, 'Moderate Hiring', 51.6, 'Data Scientist', 29.5, 22.7, 18.4, 7.8, 6.7, 5.2, 'Stable'),
('T41', 'Uber', 'Social Media', 'Singapore', 'Enterprise', 'May', 2024, 12470, 33.1, 'AI Automation', 1.7, 9.9, 1777, 'Downsizing', 11.2, 'DevOps Engineer', 34.6, 8.3, -7.2, 1.3, 6.2, 2.7, 'Recession'),
('T42', 'Oracle', 'Gaming', 'UK', 'Startup', 'Mar', 2026, 1358, 4.0, 'Market Slowdown', 7.2, 10.0, 337, 'Hiring Freeze', 84.1, 'Cybersecurity Analyst', -10.1, 14.0, 16.8, 5.6, 7.1, 5.7, 'Bull Market'),
('T43', 'Netflix', 'Social Media', 'Germany', 'Big Tech', 'Feb', 2024, 13015, 18.9, 'Cost Cutting', 8.0, 10.0, 1447, 'Hiring Freeze', 65.8, 'Software Engineer', 49.0, 10.0, 9.2, 6.7, 5.8, 5.4, 'Recession'),
('T44', 'Palantir', 'AI', 'UK', 'Mid-size', 'Jan', 2025, 3222, 1.7, 'Market Slowdown', 5.0, 4.0, 7981, 'Aggressive Hiring', 19.7, 'ML Engineer', -17.1, 6.0, 5.2, 6.4, 7.8, 6.3, 'Stable'),
('T45', 'Meta', 'FinTech', 'India', 'Mid-size', 'Jun', 2026, 6240, 30.0, 'Restructuring', 9.5, 10.0, 386, 'Hiring Freeze', 32.2, 'Data Scientist', 56.0, -9.3, -14.4, 8.2, 3.8, 2.7, 'Recession'),
('T46', 'Databricks', 'Social Media', 'India', 'Mid-size', 'Jul', 2024, 2125, 4.6, 'Cost Cutting', 9.4, 3.5, 5326, 'Aggressive Hiring', 65.0, 'ML Engineer', 56.2, -22.4, 0.3, 6.6, 5.4, 6.0, 'Bull Market'),
('T47', 'Salesforce', 'Gaming', 'Germany', 'Mid-size', 'Dec', 2024, 5850, 7.4, 'Restructuring', 1.2, 1.9, 325, 'Hiring Freeze', 19.6, 'ML Engineer', 35.1, 32.7, 17.6, 1.9, 7.4, 7.0, 'Stable'),
('T48', 'Meta', 'Gaming', 'Germany', 'Mid-size', 'Jun', 2025, 2081, 5.6, 'Cost Cutting', 7.2, 6.8, 2860, 'Moderate Hiring', 39.0, 'DevOps Engineer', 32.1, 5.3, 13.1, 5.8, 7.1, 5.7, 'Bull Market'),
('T49', 'Airbnb', 'AI', 'Singapore', 'Mid-size', 'May', 2024, 1833, 7.2, 'Market Slowdown', 2.2, 2.4, 4735, 'Hiring Freeze', 81.7, 'Data Scientist', 25.8, 9.9, 12.4, 1.9, 5.2, 6.9, 'Stable');


-- Verify the insert
SELECT COUNT(*) AS rows_inserted FROM tech_layoffs;

-- =============================================================================
-- END OF FILE: 02_sample_data.sql
-- =============================================================================
