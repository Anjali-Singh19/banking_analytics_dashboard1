-- ============================================================
--  BANKING ANALYTICS — Reusable Views
--  Run AFTER schema + seed data
-- ============================================================

-- ─────────────────────────────────────────
--  V1. Customer 360 — full snapshot per customer
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_customer_360 AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name          AS customer_name,
    c.segment,
    c.email,
    c.phone,
    c.kyc_verified,
    c.customer_since,
    DATE_PART('year', AGE(NOW(), c.dob))::INT   AS age,
    b.branch_name,
    b.region,
    e.first_name || ' ' || e.last_name          AS relationship_manager,
    COUNT(DISTINCT a.account_id)                AS total_accounts,
    COALESCE(SUM(CASE WHEN a.status='Active' THEN a.balance END), 0)
                                                AS total_balance,
    COUNT(DISTINCT l.loan_id)                   AS total_loans,
    COALESCE(SUM(CASE WHEN l.status='Active' THEN l.outstanding_amt END), 0)
                                                AS total_loan_outstanding,
    COUNT(DISTINCT rf.flag_id)                  AS risk_flags,
    MAX(t.txn_date)                             AS last_transaction_date
FROM customers c
JOIN branches   b  ON b.branch_id   = c.branch_id
LEFT JOIN employees  e  ON e.employee_id = c.employee_id
LEFT JOIN accounts   a  ON a.customer_id = c.customer_id
LEFT JOIN loans      l  ON l.customer_id = c.customer_id
LEFT JOIN transactions t ON t.account_id = a.account_id
LEFT JOIN risk_flags rf  ON rf.customer_id = c.customer_id
GROUP BY
    c.customer_id, customer_name, c.segment, c.email, c.phone,
    c.kyc_verified, c.customer_since, c.dob,
    b.branch_name, b.region, relationship_manager;

-- ─────────────────────────────────────────
--  V2. Daily Transaction Summary
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_daily_txn_summary AS
SELECT
    t.txn_date::DATE                            AS txn_date,
    b.region,
    b.branch_name,
    t.txn_type,
    t.channel,
    COUNT(t.txn_id)                             AS txn_count,
    ROUND(SUM(t.amount), 2)                     AS total_volume,
    ROUND(AVG(t.amount), 2)                     AS avg_amount,
    ROUND(MAX(t.amount), 2)                     AS max_amount,
    SUM(CASE WHEN t.is_flagged THEN 1 ELSE 0 END) AS flagged_count
FROM transactions t
JOIN accounts a ON a.account_id = t.account_id
JOIN branches b ON b.branch_id  = a.branch_id
GROUP BY t.txn_date::DATE, b.region, b.branch_name, t.txn_type, t.channel;

-- ─────────────────────────────────────────
--  V3. Live Loan Health Dashboard
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_loan_health AS
SELECT
    l.loan_id,
    c.first_name || ' ' || c.last_name          AS customer_name,
    c.segment,
    b.branch_name,
    b.region,
    l.loan_type,
    l.status,
    ROUND(l.sanctioned_amt, 2)                  AS sanctioned_amt,
    ROUND(l.outstanding_amt, 2)                 AS outstanding_amt,
    ROUND(l.emi_amount, 2)                      AS emi_amount,
    l.interest_rate,
    l.disbursed_on,
    l.due_date,
    COALESCE(MAX(lp.days_overdue), 0)           AS max_dpd,
    COALESCE(SUM(lp.penalty), 0)                AS total_penalty,
    CASE
        WHEN l.status = 'NPA'                               THEN 'NPA'
        WHEN COALESCE(MAX(lp.days_overdue),0) = 0           THEN 'Standard'
        WHEN COALESCE(MAX(lp.days_overdue),0) BETWEEN 1 AND 30  THEN 'SMA-0'
        WHEN COALESCE(MAX(lp.days_overdue),0) BETWEEN 31 AND 60 THEN 'SMA-1'
        WHEN COALESCE(MAX(lp.days_overdue),0) BETWEEN 61 AND 90 THEN 'SMA-2'
        ELSE 'NPA'
    END                                         AS dpd_bucket
FROM loans l
JOIN customers c        ON c.customer_id = l.customer_id
JOIN branches  b        ON b.branch_id   = l.branch_id
LEFT JOIN loan_payments lp ON lp.loan_id = l.loan_id
GROUP BY
    l.loan_id, customer_name, c.segment, b.branch_name, b.region,
    l.loan_type, l.status, l.sanctioned_amt, l.outstanding_amt,
    l.emi_amount, l.interest_rate, l.disbursed_on, l.due_date;

-- ─────────────────────────────────────────
--  V4. NPA Watch List
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_npa_watchlist AS
SELECT
    customer_name,
    segment,
    branch_name,
    region,
    loan_type,
    outstanding_amt,
    max_dpd,
    total_penalty,
    dpd_bucket,
    RANK() OVER (ORDER BY outstanding_amt DESC) AS exposure_rank
FROM vw_loan_health
WHERE dpd_bucket IN ('NPA','SMA-2','SMA-1');

-- ─────────────────────────────────────────
--  V5. Branch KPI Snapshot
-- ─────────────────────────────────────────
CREATE OR REPLACE VIEW vw_branch_kpi AS
SELECT
    b.branch_id,
    b.branch_name,
    b.region,
    COUNT(DISTINCT c.customer_id)               AS total_customers,
    COUNT(DISTINCT a.account_id)                AS total_accounts,
    ROUND(SUM(a.balance), 2)                    AS total_deposits,
    COUNT(DISTINCT l.loan_id)                   AS total_loans,
    ROUND(SUM(l.outstanding_amt), 2)            AS total_loan_book,
    ROUND(
        SUM(l.outstanding_amt) * 100.0
        / NULLIF(SUM(a.balance), 0), 2
    )                                           AS cd_ratio_pct,
    COUNT(DISTINCT rf.flag_id)                  AS open_risk_flags
FROM branches b
LEFT JOIN customers  c  ON c.branch_id   = b.branch_id
LEFT JOIN accounts   a  ON a.branch_id   = b.branch_id AND a.status = 'Active'
LEFT JOIN loans      l  ON l.branch_id   = b.branch_id AND l.status = 'Active'
LEFT JOIN risk_flags rf ON rf.customer_id = c.customer_id AND rf.resolved = FALSE
GROUP BY b.branch_id, b.branch_name, b.region;
