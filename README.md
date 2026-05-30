# banking_analytics_dashboard1
# 🏦 Banking Analytics SQL Project

> **A production-grade SQL portfolio project for Data Analytics roles**  
> Domain: Finance & Banking | Database: PostgreSQL 15+

---

## 📌 Project Overview

This project simulates a **real-world banking analytics platform** built entirely in SQL. It covers a full data pipeline — from schema design and seed data to complex analytical queries used in day-to-day banking operations.

It demonstrates mastery of the SQL skills most valued in data analytics interviews:

| Skill | Where Used |
|---|---|
| Window Functions | All query files |
| CTEs (Common Table Expressions) | All query files |
| Recursive CTEs | Q20 – Org Chart |
| GROUPING SETS / ROLLUP | Q19 – Multi-Dimensional Revenue |
| Subqueries & Correlated Queries | Q5, Q12 |
| CASE / Conditional Aggregation | Q8, Q12, Q13 |
| LAG / LEAD | Q3, Q7, Q10, Q11 |
| RANK / DENSE_RANK / ROW_NUMBER | Q1, Q2, Q13, Q15 |
| FIRST_VALUE / LAST_VALUE | Q3, Q15 |
| NTILE / PERCENT_RANK / CUME_DIST | Q2, Q9 |
| Sliding Window Frames (ROWS/RANGE)| Q6, Q7, Q11 |
| Reusable Views | views/07_views.sql |

---

## 🗂️ Project Structure

```
banking_sql_project/
│
├── schema/
│   ├── 01_schema.sql         ← Tables, indexes, constraints
│   └── 02_seed_data.sql      ← 40 customers, 10 branches, ~300 rows
│
├── queries/
│   ├── 03_customer_analytics.sql    ← CLV, RFM, Dormancy, Cross-sell
│   ├── 04_transaction_analytics.sql ← Running totals, Moving avg, AML
│   ├── 05_loan_analytics.sql        ← NPA buckets, Cohort, EMI health
│   └── 06_branch_revenue_analytics.sql ← Scorecards, YoY, Org chart
│
├── views/
│   └── 07_views.sql          ← 5 reusable views for dashboarding
│
└── README.md                 ← This file
```

---

## 🚀 How to Run

### Prerequisites
- PostgreSQL 15+ (or use [supabase.com](https://supabase.com) free tier online)
- psql CLI or pgAdmin / DBeaver

### Step-by-step

```bash
# 1. Create a new database
createdb banking_analytics

# 2. Connect
psql -d banking_analytics

# 3. Run in order
\i schema/01_schema.sql
\i schema/02_seed_data.sql
\i views/07_views.sql

# 4. Run any analytical query
\i queries/03_customer_analytics.sql
```

---

## 📊 Entity Relationship Diagram

```
branches ─────────────── employees
   │                         │
   │                         │
customers ───────────── accounts ──────── transactions
   │                         │
   │                         │
loans ──────── loan_payments  └── products
   │
risk_flags
```

**Key Relationships:**
- 1 Branch → Many Customers, Employees, Accounts, Loans
- 1 Customer → Many Accounts, Loans, Risk Flags
- 1 Account → Many Transactions
- 1 Loan → Many Loan Payments

---

## 🔍 Query Highlights

### Q1 – Customer Lifetime Value Ranking
Ranks customers by total relationship value (deposits + loans) using `RANK()` both globally and within each segment. Shows % share of total book.

### Q2 – RFM Segmentation
Computes Recency, Frequency, Monetary scores using `NTILE(4)` quartiles. Classifies customers as Champions, Loyal, At Risk, etc.

### Q3 – Month-over-Month Balance Change
Uses `LAG()` and `LAST_VALUE()` with a full-frame window to track each customer's deposit trajectory.

### Q6 – Running Balance & Cumulative Cash Flow
Uses `SUM() OVER (ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)` to produce a per-account running ledger — exactly what auditors need.

### Q7 – 3-Month Moving Average (Branch Volume)
Smooths monthly transaction volumes using `AVG() OVER (ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)` to eliminate noise and reveal trends.

### Q11 – AML / Suspicious Pattern Detection
Uses a `RANGE BETWEEN INTERVAL '24 hours' PRECEDING` sliding window to detect structuring, rapid fund sweeps, and high-frequency activity in real time.

### Q13 – EMI Payment Consistency Score
Chains `LAG()` across payment history to detect streaks and computes a composite 0–100 payment health score — a direct credit scoring input.

### Q19 – GROUPING SETS Revenue Pivot
Produces subtotals at region × branch × product, region × product, region-only, product-only, and grand total — all in one query.

### Q20 – Recursive CTE Org Chart
Walks the `manager_id` self-join to build a full employee hierarchy with indented display and team-level salary aggregation.

---

## 🏗️ Schema Design Decisions

| Decision | Rationale |
|---|---|
| `NUMERIC(15,2)` for money | Avoids floating-point rounding errors |
| `CHECK` constraints on enums | Enforces domain integrity without lookup tables |
| Separate `loan_payments` table | Supports full payment history & DPD tracking |
| `risk_flags` table | Decoupled from transactions for flexibility |
| Indexes on FK + date columns | Optimises window function partitioning |

---

## 📈 Business KPIs Covered

- **Deposits:** Total AUM, product mix, dormancy rate, CD ratio
- **Loans:** NPA ratio, DPD buckets (SMA-0/1/2/NPA), vintage cohort
- **Revenue:** Fee income, interest income, YoY branch growth
- **Risk:** AML flags, payment health scores, overdue aging
- **CX:** RFM segments, cross-sell gaps, digital adoption %


## 🛠️ Tech Stack

- **Database:** PostgreSQL 15
- **GUI Tools:** pgAdmin 4 / DBeaver (both free)
- **Cloud Option:** Supabase (free PostgreSQL hosting)
- **Visualisation:** Connect to Metabase / Power BI / Tableau via JDBC

---
