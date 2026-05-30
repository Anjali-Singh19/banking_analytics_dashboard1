-- ============================================================
--  BANKING ANALYTICS — Transaction Analytics
--  Concepts: Running totals, Moving averages, Percentiles,
--            Gap detection, Pivot, Fraud pattern detection
-- ============================================================


-- ─────────────────────────────────────────
--  Q6. Running Balance & Cumulative Cash Flow per Account
--  Business Use: Audit trail, liquidity monitoring
--  Window: SUM() OVER (ORDER BY), ROW_NUMBER()
-- ─────────────────────────────────────────
SELECT
    t.txn_id,
    a.account_number,
    c.first_name || ' ' || c.last_name                      AS customer_name,
    t.txn_date::DATE,
    t.txn_type,
    t.channel,
    ROUND(t.amount, 2)                                      AS amount,
    ROUND(t.balance_after, 2)                               AS balance_after,
    -- Cumulative credits for this account
    ROUND(SUM(CASE WHEN t.txn_type IN ('Credit','Interest')
               THEN t.amount ELSE 0 END)
          OVER (PARTITION BY t.account_id ORDER BY t.txn_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2)
                                                            AS cumulative_inflow,
    -- Cumulative debits
    ROUND(SUM(CASE WHEN t.txn_type IN ('Debit','Fee','Transfer')
               THEN t.amount ELSE 0 END)
          OVER (PARTITION BY t.account_id ORDER BY t.txn_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2)
                                                            AS cumulative_outflow,
    -- Net running position
    ROUND(SUM(CASE WHEN t.txn_type IN ('Credit','Interest') THEN  t.amount
                   WHEN t.txn_type IN ('Debit','Fee','Transfer') THEN -t.amount
                   ELSE 0 END)
          OVER (PARTITION BY t.account_id ORDER BY t.txn_date
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2)
                                                            AS running_net_flow,
    ROW_NUMBER() OVER (PARTITION BY t.account_id ORDER BY t.txn_date)
                                                            AS txn_sequence
FROM transactions t
JOIN accounts a  ON a.account_id  = t.account_id
JOIN customers c ON c.customer_id = a.customer_id
ORDER BY a.account_number, t.txn_date;


-- ─────────────────────────────────────────
--  Q7. 3-Month Moving Average Transaction Volume (Branch-level)
--  Business Use: Trend smoothing, seasonality detection
--  Window: AVG() OVER with ROWS frame
-- ─────────────────────────────────────────
WITH monthly_branch_txns AS (
    SELECT
        b.branch_id,
        b.branch_name,
        b.region,
        DATE_TRUNC('month', t.txn_date)::DATE   AS txn_month,
        COUNT(t.txn_id)                          AS txn_count,
        ROUND(SUM(t.amount), 2)                  AS total_volume,
        ROUND(AVG(t.amount), 2)                  AS avg_txn_size
    FROM transactions t
    JOIN accounts a  ON a.account_id = t.account_id
    JOIN branches b  ON b.branch_id  = a.branch_id
    GROUP BY b.branch_id, b.branch_name, b.region,
             DATE_TRUNC('month', t.txn_date)
)
SELECT
    branch_name,
    region,
    txn_month,
    txn_count,
    total_volume,
    avg_txn_size,
    -- 3-month moving average
    ROUND(AVG(txn_count) OVER (
        PARTITION BY branch_id
        ORDER BY txn_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1)                                       AS moving_avg_3m_count,
    ROUND(AVG(total_volume) OVER (
        PARTITION BY branch_id
        ORDER BY txn_month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2)                                       AS moving_avg_3m_volume,
    -- Month-on-month volume growth
    ROUND(
        (total_volume - LAG(total_volume) OVER (
            PARTITION BY branch_id ORDER BY txn_month
        )) * 100.0
        / NULLIF(LAG(total_volume) OVER (
            PARTITION BY branch_id ORDER BY txn_month
        ), 0), 2
    )                                           AS mom_volume_growth_pct
FROM monthly_branch_txns
ORDER BY branch_name, txn_month;


-- ─────────────────────────────────────────
--  Q8. Transaction Channel Shift Analysis (Pivot)
--  Business Use: Digital adoption tracking
--  Window: SUM() OVER PARTITION, PERCENT_RANK()
-- ─────────────────────────────────────────
WITH channel_monthly AS (
    SELECT
        DATE_TRUNC('month', txn_date)::DATE AS txn_month,
        channel,
        COUNT(*)                            AS txn_count,
        ROUND(SUM(amount), 2)               AS volume
    FROM transactions
    WHERE txn_type NOT IN ('Interest', 'Fee')
    GROUP BY DATE_TRUNC('month', txn_date), channel
)
SELECT
    txn_month,
    -- Pivot channels
    SUM(CASE WHEN channel = 'Branch'      THEN txn_count ELSE 0 END)  AS branch_count,
    SUM(CASE WHEN channel = 'ATM'         THEN txn_count ELSE 0 END)  AS atm_count,
    SUM(CASE WHEN channel = 'Net Banking' THEN txn_count ELSE 0 END)  AS netbanking_count,
    SUM(CASE WHEN channel = 'Mobile'      THEN txn_count ELSE 0 END)  AS mobile_count,
    SUM(CASE WHEN channel = 'UPI'         THEN txn_count ELSE 0 END)  AS upi_count,
    SUM(CASE WHEN channel = 'NEFT'        THEN txn_count ELSE 0 END)  AS neft_count,
    SUM(CASE WHEN channel = 'RTGS'        THEN txn_count ELSE 0 END)  AS rtgs_count,
    SUM(txn_count)                                                     AS total_count,
    -- Digital ratio: everything except Branch & ATM
    ROUND(
        SUM(CASE WHEN channel NOT IN ('Branch','ATM') THEN txn_count ELSE 0 END)
        * 100.0 / NULLIF(SUM(txn_count), 0), 2
    )                                                                  AS digital_adoption_pct
FROM channel_monthly
GROUP BY txn_month
ORDER BY txn_month;


-- ─────────────────────────────────────────
--  Q9. High-Value Transaction Percentile Analysis
--  Business Use: Threshold setting for alerts, outlier detection
--  Window: PERCENT_RANK(), CUME_DIST(), NTILE(), PERCENTILE_CONT()
-- ─────────────────────────────────────────
WITH txn_base AS (
    SELECT
        t.txn_id,
        c.first_name || ' ' || c.last_name  AS customer_name,
        c.segment,
        t.txn_type,
        t.channel,
        t.amount,
        t.txn_date,
        t.is_flagged
    FROM transactions t
    JOIN accounts  a ON a.account_id  = t.account_id
    JOIN customers c ON c.customer_id = a.customer_id
    WHERE t.txn_type IN ('Credit', 'Debit', 'Transfer')
)
SELECT
    txn_id,
    customer_name,
    segment,
    txn_type,
    channel,
    ROUND(amount, 2)                                                   AS amount,
    txn_date::DATE,
    is_flagged,
    ROUND(PERCENT_RANK() OVER (ORDER BY amount) * 100, 2)             AS percentile_rank,
    ROUND(CUME_DIST()    OVER (ORDER BY amount) * 100, 2)             AS cumulative_dist,
    NTILE(10)            OVER (ORDER BY amount)                       AS decile,
    -- Segment-level percentile
    ROUND(PERCENT_RANK() OVER (
        PARTITION BY segment ORDER BY amount
    ) * 100, 2)                                                        AS pct_rank_in_segment,
    -- Flag if above 95th percentile for its type
    CASE
        WHEN PERCENT_RANK() OVER (
            PARTITION BY txn_type ORDER BY amount
        ) >= 0.95 THEN 'High-Value Alert'
        ELSE 'Normal'
    END                                                                AS alert_flag
FROM txn_base
ORDER BY amount DESC;


-- ─────────────────────────────────────────
--  Q10. Consecutive Days with No Transaction (Gap Analysis)
--  Business Use: Identify sudden cessation of activity
--  Window: LAG(), DATE subtraction, LEAD()
-- ─────────────────────────────────────────
WITH daily_txns AS (
    SELECT DISTINCT
        a.customer_id,
        c.first_name || ' ' || c.last_name  AS customer_name,
        t.txn_date::DATE                    AS activity_date
    FROM transactions t
    JOIN accounts  a ON a.account_id  = t.account_id
    JOIN customers c ON c.customer_id = a.customer_id
),
gaps AS (
    SELECT
        customer_id,
        customer_name,
        activity_date,
        LAG(activity_date) OVER (
            PARTITION BY customer_id ORDER BY activity_date
        )                                   AS prev_activity_date,
        activity_date - LAG(activity_date) OVER (
            PARTITION BY customer_id ORDER BY activity_date
        )                                   AS gap_days
    FROM daily_txns
)
SELECT
    customer_name,
    prev_activity_date,
    activity_date            AS next_activity_date,
    gap_days,
    CASE
        WHEN gap_days > 60  THEN 'Critical Gap (>60 days)'
        WHEN gap_days > 30  THEN 'Long Gap (30-60 days)'
        WHEN gap_days > 14  THEN 'Medium Gap (14-30 days)'
        ELSE 'Normal'
    END                      AS gap_category
FROM gaps
WHERE gap_days > 14
ORDER BY gap_days DESC;


-- ─────────────────────────────────────────
--  Q11. Suspicious Transaction Pattern Detection
--  Business Use: AML — structuring & rapid movement detection
--  Window: SUM() OVER sliding 24h, COUNT() OVER, LAG()
-- ─────────────────────────────────────────
WITH flagged_accounts AS (
    SELECT
        t.txn_id,
        t.account_id,
        c.customer_id,
        c.first_name || ' ' || c.last_name          AS customer_name,
        c.segment,
        t.txn_date,
        t.txn_type,
        t.channel,
        t.amount,
        t.is_flagged,
        -- Sum of credits in last 24 hours (sliding window)
        SUM(CASE WHEN t.txn_type = 'Credit' THEN t.amount ELSE 0 END)
            OVER (
                PARTITION BY t.account_id
                ORDER BY t.txn_date
                RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
            )                                       AS credits_24h,
        -- Number of transactions in last 24 hours
        COUNT(*) OVER (
            PARTITION BY t.account_id
            ORDER BY t.txn_date
            RANGE BETWEEN INTERVAL '24 hours' PRECEDING AND CURRENT ROW
        )                                           AS txn_count_24h,
        -- Time since last transaction (minutes)
        DATE_PART('minute',
            t.txn_date - LAG(t.txn_date) OVER (
                PARTITION BY t.account_id ORDER BY t.txn_date
            )
        )                                           AS mins_since_last_txn,
        -- Large debit soon after large credit
        LAG(t.amount)    OVER (PARTITION BY t.account_id ORDER BY t.txn_date)
                                                    AS prev_txn_amount,
        LAG(t.txn_type)  OVER (PARTITION BY t.account_id ORDER BY t.txn_date)
                                                    AS prev_txn_type
    FROM transactions t
    JOIN accounts  a ON a.account_id  = t.account_id
    JOIN customers c ON c.customer_id = a.customer_id
)
SELECT
    customer_name,
    segment,
    txn_date,
    txn_type,
    channel,
    ROUND(amount, 2)               AS amount,
    ROUND(credits_24h, 2)          AS credits_24h_window,
    txn_count_24h,
    mins_since_last_txn::INT       AS mins_since_last_txn,
    ROUND(prev_txn_amount, 2)      AS prev_txn_amount,
    prev_txn_type,
    -- Pattern classification
    CASE
        WHEN credits_24h > 500000                          THEN 'Structuring Risk'
        WHEN txn_count_24h > 5                             THEN 'High Frequency'
        WHEN txn_type = 'Debit'
             AND prev_txn_type = 'Credit'
             AND amount >= prev_txn_amount * 0.90          THEN 'Rapid Fund Sweep'
        WHEN mins_since_last_txn < 5 AND amount > 100000  THEN 'Rapid Large Txn'
        ELSE 'Monitor'
    END                            AS aml_pattern,
    is_flagged
FROM flagged_accounts
WHERE
    credits_24h > 500000
    OR txn_count_24h > 5
    OR (txn_type = 'Debit' AND prev_txn_type = 'Credit' AND amount >= prev_txn_amount * 0.90)
ORDER BY txn_date DESC;
