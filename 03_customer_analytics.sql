-- ============================================================
--  BANKING ANALYTICS — Customer & Account Analytics
--  Concepts: CTEs, Window Functions, Aggregations, CASE
-- ============================================================


-- ─────────────────────────────────────────
--  Q1. Customer Lifetime Value (CLV) Ranking
--  Business Use: Identify top customers by total relationship value
--  Window: RANK() OVER, SUM() OVER
-- ─────────────────────────────────────────
WITH customer_balances AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name          AS customer_name,
        c.segment,
        b.branch_name,
        COUNT(DISTINCT a.account_id)                AS total_accounts,
        COALESCE(SUM(a.balance), 0)                 AS total_deposit_balance,
        COALESCE(SUM(l.outstanding_amt), 0)         AS total_loan_outstanding,
        COALESCE(SUM(a.balance), 0)
            + COALESCE(SUM(l.outstanding_amt), 0)   AS relationship_value
    FROM customers c
    JOIN branches b        ON b.branch_id    = c.branch_id
    LEFT JOIN accounts a   ON a.customer_id  = c.customer_id AND a.status = 'Active'
    LEFT JOIN loans l      ON l.customer_id  = c.customer_id AND l.status = 'Active'
    GROUP BY c.customer_id, customer_name, c.segment, b.branch_name
)
SELECT
    customer_name,
    segment,
    branch_name,
    total_accounts,
    total_deposit_balance,
    total_loan_outstanding,
    relationship_value,
    RANK()        OVER (ORDER BY relationship_value DESC)            AS overall_rank,
    RANK()        OVER (PARTITION BY segment ORDER BY relationship_value DESC) AS rank_in_segment,
    ROUND(
        relationship_value * 100.0
        / SUM(relationship_value) OVER (), 2
    )                                                                AS pct_of_total_book
FROM customer_balances
ORDER BY relationship_value DESC;


-- ─────────────────────────────────────────
--  Q2. Customer Segmentation by Activity Score
--  Business Use: RFM-style scoring for marketing campaigns
--  Window: ROW_NUMBER(), NTILE(), COUNT() OVER
-- ─────────────────────────────────────────
WITH txn_stats AS (
    SELECT
        a.customer_id,
        COUNT(t.txn_id)                                  AS txn_count_6m,
        SUM(CASE WHEN t.txn_type = 'Credit' THEN t.amount ELSE 0 END)
                                                         AS total_inflow,
        SUM(CASE WHEN t.txn_type = 'Debit'  THEN t.amount ELSE 0 END)
                                                         AS total_outflow,
        MAX(t.txn_date)                                  AS last_txn_date,
        DATE_PART('day', NOW() - MAX(t.txn_date))        AS days_since_last_txn
    FROM accounts a
    JOIN transactions t ON t.account_id = a.account_id
    WHERE t.txn_date >= NOW() - INTERVAL '6 months'
    GROUP BY a.customer_id
),
scored AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name  AS customer_name,
        c.segment,
        ts.txn_count_6m,
        ts.total_inflow,
        ts.total_outflow,
        ts.days_since_last_txn,
        -- Frequency score 1-4 (quartile)
        NTILE(4) OVER (ORDER BY ts.txn_count_6m)         AS frequency_score,
        -- Monetary score 1-4
        NTILE(4) OVER (ORDER BY ts.total_inflow)         AS monetary_score,
        -- Recency score 4-1 (lower days = better)
        5 - NTILE(4) OVER (ORDER BY ts.days_since_last_txn) AS recency_score
    FROM customers c
    JOIN txn_stats ts ON ts.customer_id = c.customer_id
)
SELECT
    customer_name,
    segment,
    txn_count_6m,
    ROUND(total_inflow,  2)                                AS total_inflow,
    ROUND(total_outflow, 2)                                AS total_outflow,
    days_since_last_txn::INT                               AS days_since_last_txn,
    recency_score,
    frequency_score,
    monetary_score,
    (recency_score + frequency_score + monetary_score)     AS rfm_total_score,
    CASE
        WHEN (recency_score + frequency_score + monetary_score) >= 10 THEN 'Champions'
        WHEN (recency_score + frequency_score + monetary_score) >= 8  THEN 'Loyal'
        WHEN (recency_score + frequency_score + monetary_score) >= 6  THEN 'Potential Loyalist'
        WHEN (recency_score + frequency_score + monetary_score) >= 4  THEN 'At Risk'
        ELSE 'Lost'
    END                                                    AS rfm_segment
FROM scored
ORDER BY rfm_total_score DESC;


-- ─────────────────────────────────────────
--  Q3. Month-over-Month Account Balance Change
--  Business Use: Track deposit growth per customer
--  Window: LAG(), LEAD(), SUM() OVER (PARTITION BY ... ORDER BY ...)
-- ─────────────────────────────────────────
WITH monthly_balances AS (
    SELECT
        a.customer_id,
        c.first_name || ' ' || c.last_name           AS customer_name,
        c.segment,
        DATE_TRUNC('month', t.txn_date)::DATE         AS txn_month,
        -- Running balance at end of each month (last balance_after in month)
        LAST_VALUE(t.balance_after)
            OVER (
                PARTITION BY a.account_id,
                             DATE_TRUNC('month', t.txn_date)
                ORDER BY t.txn_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            )                                         AS eom_balance
    FROM accounts a
    JOIN customers c    ON c.customer_id = a.customer_id
    JOIN transactions t ON t.account_id  = a.account_id
),
monthly_agg AS (
    SELECT
        customer_id,
        customer_name,
        segment,
        txn_month,
        MAX(eom_balance)   AS eom_balance   -- collapse duplicates per month
    FROM monthly_balances
    GROUP BY customer_id, customer_name, segment, txn_month
)
SELECT
    customer_name,
    segment,
    txn_month,
    ROUND(eom_balance, 2)                                          AS eom_balance,
    ROUND(
        LAG(eom_balance) OVER (PARTITION BY customer_id ORDER BY txn_month),
    2)                                                             AS prev_month_balance,
    ROUND(
        eom_balance - LAG(eom_balance) OVER (
            PARTITION BY customer_id ORDER BY txn_month
        ), 2
    )                                                              AS mom_change,
    ROUND(
        (eom_balance - LAG(eom_balance) OVER (
            PARTITION BY customer_id ORDER BY txn_month
        )) * 100.0
        / NULLIF(LAG(eom_balance) OVER (
            PARTITION BY customer_id ORDER BY txn_month
        ), 0), 2
    )                                                              AS mom_pct_change
FROM monthly_agg
ORDER BY customer_id, txn_month;


-- ─────────────────────────────────────────
--  Q4. Dormant Account Detection
--  Business Use: Reactivation campaign targeting
--  Window: DATEDIFF via DATE_PART, ROW_NUMBER()
-- ─────────────────────────────────────────
WITH last_activity AS (
    SELECT
        a.account_id,
        a.account_number,
        a.status,
        a.balance,
        c.customer_id,
        c.first_name || ' ' || c.last_name          AS customer_name,
        c.email,
        c.phone,
        c.segment,
        p.product_name,
        p.product_type,
        MAX(t.txn_date)                             AS last_txn_date,
        DATE_PART('day', NOW() - MAX(t.txn_date))   AS days_inactive
    FROM accounts a
    JOIN customers c    ON c.customer_id = a.customer_id
    JOIN products  p    ON p.product_id  = a.product_id
    LEFT JOIN transactions t ON t.account_id = a.account_id
    WHERE a.status IN ('Active', 'Dormant')
    GROUP BY
        a.account_id, a.account_number, a.status, a.balance,
        c.customer_id, customer_name, c.email, c.phone, c.segment,
        p.product_name, p.product_type
)
SELECT
    account_number,
    customer_name,
    email,
    segment,
    product_type,
    ROUND(balance, 2)           AS current_balance,
    last_txn_date::DATE,
    days_inactive::INT,
    CASE
        WHEN days_inactive > 365 THEN 'Critically Dormant (>1 yr)'
        WHEN days_inactive > 180 THEN 'Dormant (6-12 months)'
        WHEN days_inactive > 90  THEN 'At Risk (3-6 months)'
        ELSE 'Active'
    END                         AS dormancy_status,
    ROW_NUMBER() OVER (
        PARTITION BY segment ORDER BY days_inactive DESC
    )                           AS rank_dormant_in_segment
FROM last_activity
WHERE days_inactive > 90
ORDER BY days_inactive DESC;


-- ─────────────────────────────────────────
--  Q5. Customer Product Holdings (Cross-sell Gap Analysis)
--  Business Use: Identify customers missing key products
--  Window: COUNT() OVER PARTITION, STRING_AGG
-- ─────────────────────────────────────────
WITH customer_products AS (
    SELECT
        c.customer_id,
        c.first_name || ' ' || c.last_name     AS customer_name,
        c.segment,
        STRING_AGG(DISTINCT p.product_type, ', '
            ORDER BY p.product_type)            AS products_held,
        COUNT(DISTINCT p.product_type)          AS product_count,
        MAX(CASE WHEN p.product_type = 'Savings'      THEN 1 ELSE 0 END) AS has_savings,
        MAX(CASE WHEN p.product_type = 'Current'      THEN 1 ELSE 0 END) AS has_current,
        MAX(CASE WHEN p.product_type = 'FD'           THEN 1 ELSE 0 END) AS has_fd,
        MAX(CASE WHEN p.product_type = 'Loan'         THEN 1 ELSE 0 END) AS has_loan,
        MAX(CASE WHEN p.product_type = 'Credit Card'  THEN 1 ELSE 0 END) AS has_credit_card
    FROM customers c
    JOIN accounts a  ON a.customer_id = c.customer_id AND a.status = 'Active'
    JOIN products p  ON p.product_id  = a.product_id
    GROUP BY c.customer_id, customer_name, c.segment
)
SELECT
    customer_name,
    segment,
    products_held,
    product_count,
    AVG(product_count) OVER (PARTITION BY segment)  AS avg_products_in_segment,
    -- Cross-sell opportunities
    CASE WHEN has_savings     = 0 THEN 'Savings Account; '     ELSE '' END ||
    CASE WHEN has_fd          = 0 THEN 'Fixed Deposit; '        ELSE '' END ||
    CASE WHEN has_loan        = 0 THEN 'Loan Product; '         ELSE '' END ||
    CASE WHEN has_credit_card = 0 THEN 'Credit Card; '          ELSE '' END  AS cross_sell_opportunities,
    product_count * 1.0 / 5                         AS penetration_ratio
FROM customer_products
ORDER BY product_count ASC, segment;
