-- ============================================================
--  BANKING ANALYTICS — Branch Performance & Revenue Analytics
--  Concepts: Multi-level aggregation, YoY comparisons,
--            Contribution analysis, GROUPING SETS
-- ============================================================


-- ─────────────────────────────────────────
--  Q16. Branch Scorecard — Deposits, Loans, Fees
--  Business Use: Monthly MIS report for management
--  Window: RANK(), SUM() OVER multi-level
-- ─────────────────────────────────────────
WITH branch_deposits AS (
    SELECT
        a.branch_id,
        SUM(a.balance)                      AS total_deposits,
        COUNT(DISTINCT a.customer_id)       AS deposit_customers,
        COUNT(a.account_id)                 AS deposit_accounts
    FROM accounts a
    WHERE a.status = 'Active'
      AND (SELECT product_type FROM products p WHERE p.product_id = a.product_id)
          IN ('Savings','Current','FD')
    GROUP BY a.branch_id
),
branch_loans AS (
    SELECT
        l.branch_id,
        SUM(l.outstanding_amt)              AS total_loan_book,
        SUM(l.sanctioned_amt)               AS total_sanctioned,
        COUNT(l.loan_id)                    AS loan_count,
        COUNT(CASE WHEN l.status='NPA' THEN 1 END) AS npa_count,
        SUM(CASE WHEN l.status='NPA' THEN l.outstanding_amt ELSE 0 END)
                                            AS npa_amount
    FROM loans l
    GROUP BY l.branch_id
),
branch_fees AS (
    SELECT
        a.branch_id,
        SUM(t.amount)                       AS total_fee_income
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE t.txn_type = 'Fee'
    GROUP BY a.branch_id
),
branch_interest_income AS (
    SELECT
        a.branch_id,
        SUM(t.amount)                       AS total_interest_credited
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    WHERE t.txn_type = 'Interest'
    GROUP BY a.branch_id
)
SELECT
    b.branch_name,
    b.city,
    b.region,
    -- Deposits
    ROUND(COALESCE(bd.total_deposits, 0), 2)            AS total_deposits,
    COALESCE(bd.deposit_customers, 0)                   AS deposit_customers,
    -- Loans
    ROUND(COALESCE(bl.total_loan_book, 0), 2)           AS total_loan_book,
    COALESCE(bl.loan_count, 0)                          AS loan_count,
    ROUND(COALESCE(bl.npa_amount, 0), 2)                AS npa_amount,
    ROUND(
        COALESCE(bl.npa_amount, 0) * 100.0
        / NULLIF(bl.total_loan_book, 0), 2
    )                                                   AS npa_ratio_pct,
    -- Revenue
    ROUND(COALESCE(bf.total_fee_income, 0), 2)          AS fee_income,
    ROUND(COALESCE(bi.total_interest_credited, 0), 2)   AS interest_income,
    -- Credit-Deposit (CD) Ratio
    ROUND(
        COALESCE(bl.total_loan_book, 0) * 100.0
        / NULLIF(bd.total_deposits, 0), 2
    )                                                   AS cd_ratio_pct,
    -- Rankings
    RANK() OVER (ORDER BY COALESCE(bd.total_deposits, 0) DESC)
                                                        AS deposit_rank,
    RANK() OVER (ORDER BY COALESCE(bl.total_loan_book, 0) DESC)
                                                        AS loan_book_rank,
    RANK() OVER (PARTITION BY b.region
                 ORDER BY COALESCE(bd.total_deposits, 0) DESC)
                                                        AS deposit_rank_in_region,
    -- Share of total deposits
    ROUND(
        COALESCE(bd.total_deposits, 0) * 100.0
        / SUM(COALESCE(bd.total_deposits, 0)) OVER (), 2
    )                                                   AS deposit_share_pct
FROM branches b
LEFT JOIN branch_deposits        bd ON bd.branch_id = b.branch_id
LEFT JOIN branch_loans           bl ON bl.branch_id = b.branch_id
LEFT JOIN branch_fees            bf ON bf.branch_id = b.branch_id
LEFT JOIN branch_interest_income bi ON bi.branch_id = b.branch_id
ORDER BY total_deposits DESC;


-- ─────────────────────────────────────────
--  Q17. Year-over-Year Branch Growth (YoY)
--  Business Use: Annual performance review
--  Window: LAG() across years, CASE for YoY delta
-- ─────────────────────────────────────────
WITH yearly_branch_metrics AS (
    SELECT
        b.branch_id,
        b.branch_name,
        b.region,
        DATE_PART('year', t.txn_date)::INT  AS txn_year,
        COUNT(t.txn_id)                     AS txn_count,
        ROUND(SUM(t.amount), 2)             AS total_volume,
        COUNT(DISTINCT a.customer_id)       AS active_customers
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    JOIN branches b ON b.branch_id  = a.branch_id
    GROUP BY b.branch_id, b.branch_name, b.region,
             DATE_PART('year', t.txn_date)
)
SELECT
    branch_name,
    region,
    txn_year,
    txn_count,
    total_volume,
    active_customers,
    -- Prior year values
    LAG(txn_count)        OVER (PARTITION BY branch_id ORDER BY txn_year)
                                                            AS prev_year_count,
    LAG(total_volume)     OVER (PARTITION BY branch_id ORDER BY txn_year)
                                                            AS prev_year_volume,
    -- YoY growth
    ROUND(
        (txn_count - LAG(txn_count) OVER (
            PARTITION BY branch_id ORDER BY txn_year
        )) * 100.0
        / NULLIF(LAG(txn_count) OVER (
            PARTITION BY branch_id ORDER BY txn_year
        ), 0), 2
    )                                                       AS yoy_txn_growth_pct,
    ROUND(
        (total_volume - LAG(total_volume) OVER (
            PARTITION BY branch_id ORDER BY txn_year
        )) * 100.0
        / NULLIF(LAG(total_volume) OVER (
            PARTITION BY branch_id ORDER BY txn_year
        ), 0), 2
    )                                                       AS yoy_volume_growth_pct,
    -- Cumulative volume since branch inception
    ROUND(SUM(total_volume) OVER (
        PARTITION BY branch_id ORDER BY txn_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                                   AS cumulative_volume
FROM yearly_branch_metrics
ORDER BY branch_name, txn_year;


-- ─────────────────────────────────────────
--  Q18. Interest Income Forecast (Simple Projection)
--  Business Use: Revenue planning, deposit pricing
--  Window: AVG() OVER for trend-based projection
-- ─────────────────────────────────────────
WITH monthly_interest AS (
    SELECT
        DATE_TRUNC('month', t.txn_date)::DATE   AS month,
        p.product_type,
        ROUND(SUM(t.amount), 2)                 AS interest_income,
        COUNT(DISTINCT a.account_id)            AS accounts_earning
    FROM transactions t
    JOIN accounts a ON a.account_id = t.account_id
    JOIN products p ON p.product_id = a.product_id
    WHERE t.txn_type = 'Interest'
    GROUP BY DATE_TRUNC('month', t.txn_date), p.product_type
)
SELECT
    month,
    product_type,
    interest_income,
    accounts_earning,
    -- 3-month moving average (trend)
    ROUND(AVG(interest_income) OVER (
        PARTITION BY product_type
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                       AS trend_3m_avg,
    -- Growth momentum
    ROUND(
        (interest_income - LAG(interest_income) OVER (
            PARTITION BY product_type ORDER BY month
        )) * 100.0
        / NULLIF(LAG(interest_income) OVER (
            PARTITION BY product_type ORDER BY month
        ), 0), 2
    )                                           AS mom_growth_pct,
    -- Simple next-month projection using trend
    ROUND(AVG(interest_income) OVER (
        PARTITION BY product_type
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) * 1.02, 2)                                AS projected_next_month
FROM monthly_interest
ORDER BY product_type, month;


-- ─────────────────────────────────────────
--  Q19. GROUPING SETS — Multi-Dimensional Revenue Summary
--  Business Use: Flexible roll-up for dashboards
-- ─────────────────────────────────────────
SELECT
    COALESCE(b.region,       'ALL REGIONS')   AS region,
    COALESCE(b.branch_name,  'ALL BRANCHES')  AS branch_name,
    COALESCE(p.product_type, 'ALL PRODUCTS')  AS product_type,
    COUNT(DISTINCT a.customer_id)             AS customer_count,
    COUNT(a.account_id)                       AS account_count,
    ROUND(SUM(a.balance), 2)                  AS total_balance,
    ROUND(AVG(a.balance), 2)                  AS avg_balance
FROM accounts a
JOIN branches b ON b.branch_id = a.branch_id
JOIN products p ON p.product_id = a.product_id
WHERE a.status = 'Active'
GROUP BY GROUPING SETS (
    (b.region, b.branch_name, p.product_type),  -- Most detailed
    (b.region, p.product_type),                  -- By region + product
    (b.region),                                  -- By region only
    (p.product_type),                            -- By product only
    ()                                           -- Grand total
)
ORDER BY
    GROUPING(b.region),
    GROUPING(b.branch_name),
    GROUPING(p.product_type),
    region, branch_name, product_type;


-- ─────────────────────────────────────────
--  Q20. Employee Hierarchy & Team Performance
--  Business Use: Org chart, managerial span-of-control
--  Technique: Recursive CTE
-- ─────────────────────────────────────────
WITH RECURSIVE org_chart AS (
    -- Anchor: top-level (no manager)
    SELECT
        employee_id,
        first_name || ' ' || last_name  AS employee_name,
        role,
        branch_id,
        manager_id,
        salary,
        0                               AS level,
        CAST(first_name || ' ' || last_name AS TEXT) AS hierarchy_path
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive: employees with managers
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name,
        e.role,
        e.branch_id,
        e.manager_id,
        e.salary,
        oc.level + 1,
        oc.hierarchy_path || ' → ' || e.first_name || ' ' || e.last_name
    FROM employees e
    JOIN org_chart oc ON oc.employee_id = e.manager_id
)
SELECT
    REPEAT('  ', level) || employee_name   AS org_chart,
    role,
    level                                  AS hierarchy_level,
    salary,
    hierarchy_path,
    -- Team salary cost (sum of all subordinates)
    SUM(salary) OVER (
        PARTITION BY COALESCE(manager_id, employee_id)
    )                                      AS team_salary_cost,
    COUNT(*) OVER (
        PARTITION BY COALESCE(manager_id, employee_id)
    )                                      AS team_size
FROM org_chart
ORDER BY hierarchy_path;
