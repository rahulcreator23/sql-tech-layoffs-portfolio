# 🧠 Tech Layoffs & Hiring Trends — SQL Portfolio Project

> A production-grade SQL project built on a **12,000-row** real-world dataset covering tech layoffs, AI automation impact, hiring trends, and market conditions across 6 countries and 7 industries (2024–2026).

---

## 📁 Project Structure

```
sql_project/
├── README.md                          ← You are here
├── schemas/
│   └── 01_schema_ddl.sql              ← Table design, constraints, indexes
├── data_samples/
│   └── 02_sample_data.sql             ← Sample INSERT statements (50 rows)
├── queries/
│   ├── 03_basic_queries.sql           ← Beginner: SELECT, WHERE, GROUP BY
│   └── 04_intermediate_queries.sql    ← Mid: JOINs, subqueries, CASE, aggregations
├── advanced/
│   └── 05_advanced_analytics.sql      ← Expert: Window functions, CTEs, pivots
├── views/
│   └── 06_views.sql                   ← Reusable views for BI/reporting
├── procedures/
│   └── 07_stored_procedures.sql       ← Stored procedures & functions
├── optimization/
│   └── 08_performance_tuning.sql      ← Indexes, EXPLAIN, query optimization
└── interview/
    └── 09_interview_questions.sql     ← 30+ real interview Q&As with answers
```

---

## 📊 Dataset Overview

| Column | Type | Description |
|---|---|---|
| `record_id` | VARCHAR | Unique identifier (T0, T1, ...) |
| `company_name` | VARCHAR | Company name |
| `industry` | VARCHAR | AI, FinTech, Gaming, Cloud, etc. |
| `country` | VARCHAR | USA, UK, India, Canada, Germany, Singapore |
| `company_size` | VARCHAR | Startup / Mid-size / Big Tech / Enterprise |
| `month` | VARCHAR | Month of event |
| `year` | INT | Year (2023–2026) |
| `layoffs_count` | INT | Number of employees laid off |
| `layoff_percentage` | DECIMAL | % of workforce laid off |
| `reason_for_layoffs` | VARCHAR | AI Automation, Cost Cutting, etc. |
| `ai_automation_impact` | DECIMAL | Score 0–10 |
| `ai_replacement_risk` | DECIMAL | Score 0–10 |
| `open_roles` | INT | Current open job postings |
| `hiring_trend` | VARCHAR | Aggressive Hiring / Moderate / Freeze / Downsizing |
| `remote_jobs_percentage` | DECIMAL | % of roles that are remote |
| `top_hiring_role` | VARCHAR | Most in-demand role |
| `stock_growth_percent` | DECIMAL | YoY stock growth % |
| `revenue_growth_percent` | DECIMAL | YoY revenue growth % |
| `salary_budget_change` | DECIMAL | Change in salary budget % |
| `ai_adoption_level` | DECIMAL | AI adoption score 0–10 |
| `employee_sentiment` | DECIMAL | Sentiment score 0–10 |
| `job_security_score` | DECIMAL | Security score 0–10 |
| `market_condition` | VARCHAR | Bull Market / Recession / Stable |

---

## 🎯 Skills Demonstrated

| Category | Topics |
|---|---|
| **DDL** | CREATE TABLE, ALTER, constraints, indexes |
| **DML** | INSERT, UPDATE, DELETE, UPSERT |
| **Querying** | SELECT, WHERE, ORDER BY, LIMIT, DISTINCT |
| **Aggregation** | GROUP BY, HAVING, COUNT, SUM, AVG, MIN, MAX |
| **Joins** | INNER, LEFT, RIGHT, FULL OUTER, SELF, CROSS |
| **Subqueries** | Correlated, scalar, EXISTS, IN |
| **Window Functions** | ROW_NUMBER, RANK, DENSE_RANK, LAG, LEAD, NTILE |
| **CTEs** | Recursive CTEs, chained CTEs, CTE vs subquery |
| **Views** | Simple views, materialized views |
| **Stored Procedures** | Parameters, error handling, transactions |
| **Performance** | EXPLAIN ANALYZE, index tuning, query rewrites |
| **Analytics** | Cohort analysis, YoY comparison, running totals, pivoting |

---

## 🚀 How to Run

### PostgreSQL
```bash
psql -U your_user -d your_db -f schemas/01_schema_ddl.sql
psql -U your_user -d your_db -f data_samples/02_sample_data.sql
```

### MySQL / MariaDB
```bash
mysql -u your_user -p your_db < schemas/01_schema_ddl.sql
```

### SQLite (quick test)
```bash
sqlite3 layoffs.db < schemas/01_schema_ddl.sql
```

> **Note:** Queries are written in standard SQL (ANSI-compliant). Dialect-specific notes are added inline as comments where syntax differs between PostgreSQL, MySQL, and SQLite.

---

## 💼 Interview Readiness

The `interview/09_interview_questions.sql` file contains **30+ curated questions** organized by difficulty:

- 🟢 **Easy** — Filtering, aggregation, basic joins
- 🟡 **Medium** — Window functions, subqueries, CTEs
- 🔴 **Hard** — Optimization, complex analytics, edge cases
- ⚡ **Scenario** — Real-world business problem solving

---

## 👤 Rahul Prasad

Built as a SQL portfolio project to demonstrate data analysis skills on real-world tech industry data.

**Connect on LinkedIn:** www.linkedin.com/in/
rahul-prasad-1a9577257
 
**GitHub:** https://github.com/rahulcreator23
