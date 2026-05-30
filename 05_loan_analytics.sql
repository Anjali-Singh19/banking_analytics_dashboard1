-- ============================================================
--  BANKING ANALYTICS — Loan Portfolio Analytics
--  Concepts: Amortisation logic, NPA aging, Cohort analysis,
--            FIRST_VALUE / LAST_VALUE, recursive loan health
-- ============================================================


-- ─────────────────────────────────────────
--  Q12. Loan Portfolio Summary with Risk Buckets
--  Business Use: Credit risk dashboard KPIs
--  Window: SUM() OVER, RATIO_TO_REPORT equivalent
-- ─────────────────────────────────────────
WITH loan_health AS (
    SELECT
        l.loan_id,
        l.loan_type,
        l.status,
        l.sanctioned_amt,
        l.outstanding_amt,
        l.emi_amount,
        l.interest_rate,
        l.due_date,
        c.customer_id,
        c.first_name || ' ' || c.last_name          AS customer_name,
        c.segment,
        b.branch_name,
        b.region,
        -- Payment stats
        COUNT(lp.payment_id)                         AS payments_made,
        COALESCE(SUM(lp.amount_paid),    0)          AS total_paid,
        COALESCE(MAX(lp.days_overdue),   0)          AS max_days_overdue,
        COALESCE(SUM(lp.penalty),        0)          AS total_penalties,
        COALESCE(MAX(lp.paid_on),        NULL)       AS last_payment_date,
        -- DPD bucket
        CASE
            WHEN l.status = 'NPA'                    THEN 'NPA'
            WHEN l.status = 'Written-Off'            THEN 'Written-Off'
            WHEN COALESCE(MAX(lp.days_overdue), 0) = 0           THEN 'Standard'
            WHEN COALESCE(MAX(lp.days_overdue), 0) BETWEEN 1 AND 30  THEN 'SMA-0'
            WHEN COALESCE(MAX(lp.days_overdue), 0) BETWEEN 31 AND 60 THEN 'SMA-1'
            WHEN COALESCE(MAX(lp.days_overdue), 0) BETWEEN 61 AND 90 THEN 'SMA-2'
            ELSE 'NPA'
        END                                          AS dpd_bucket
    FROM loans l
    JOIN customers c      ON c.customer_id = l.customer_id
    JOIN branches b       ON b.branch_id   = l.branch_id
    LEFT JOIN loan_payments lp ON lp.loan_id = l.loan_id
    WHERE l.status != 'Closed'
    GROUP BY
        l.loan_id, l.loan_type, l.status, l.sanctioned_amt,
        l.outstanding_amt, l.emi_amount, l.interest_rate,
        l.due_date, c.customer_id, customer_name, c.segment,
        b.branch_name, b.region
)
SELECT
    customer_name,
    segment,
    branch_name,
    region,
    loan_type,
    dpd_bucket,
    ROUND(sanctioned_amt, 2)                                        AS sanctioned_amt,
    ROUND(outstanding_amt, 2)                                       AS outstanding_amt,
    ROUND(total_paid, 2)                                            AS total_paid,
    max_days_overdue,
    ROUND(total_penalties, 2)                                       AS total_penalties,
    last_payment_date,
    -- Portfolio share
    ROUND(outstanding_amt * 100.0
          / SUM(outstanding_amt) OVER (), 2)                        AS pct_of_total_book,
    -- Region share
    ROUND(outstanding_amt * 100.0
          / SUM(outstanding_amt) OVER (PARTITION BY region), 2)    AS pct_of_region_book,
    -- Rank by exposure within loan type
    RANK() OVER (PARTITION BY loan_type ORDER BY outstanding_amt DESC)
                                                                    AS rank_in_loan_type
FROM loan_health
ORDER BY outstanding_amt DESC;


-- ─────────────────────────────────────────
--  Q13. EMI Payment Consistency Score
--  Business Use: Credit scoring input, NPA early warning
--  Window: COUNT() OVER, LAG() chain for streak detection
-- ─────────────────────────────────────────
WITH payment_sequence AS (
    SELECT
        lp.loan_id,
        lp.paid_on,
        lp.amount_paid,
        lp.days_overdue,
        lp.penalty,
        l.emi_amount,
        l.customer_id,
        c.first_name || ' ' || c.last_name  AS customer_name,
        c.segment,
        l.loan_type,
        l.status                            AS loan_status,
        ROW_NUMBER() OVER (
            PARTITION BY lp.loan_id ORDER BY lp.paid_on
        )                                   AS payment_no,
        -- Was this payment on time?
        CASE WHEN lp.days_overdue = 0 THEN 1 ELSE 0 END
                                            AS on_time_flag,
        LAG(lp.days_overdue, 1) OVER (
            PARTITION BY lp.loan_id ORDER BY lp.paid_on
        )                                   AS prev_overdue_1,
        LAG(lp.days_overdue, 2) OVER (
            PARTITION BY lp.loan_id ORDER BY lp.paid_on
        )                                   AS prev_overdue_2
    FROM loan_payments lp
    JOIN loans     l ON l.loan_id     = lp.loan_id
    JOIN customers c ON c.customer_id = l.customer_id
),
loan_scores AS (
    SELECT
        loan_id,
        customer_name,
        segment,
        loan_type,
        loan_status,
        COUNT(*)                                      AS total_payments,
        SUM(on_time_flag)                             AS on_time_payments,
        SUM(days_overdue)                             AS total_overdue_days,
        MAX(days_overdue)                             AS max_single_overdue,
        SUM(penalty)                                  AS total_penalties_paid,
        ROUND(
            SUM(on_time_flag) * 100.0 / NULLIF(COUNT(*), 0), 2
        )                                             AS on_time_pct,
        -- Consecutive on-time streak (last 3 payments)
        CASE
            WHEN MAX(CASE WHEN payment_no = total_payments
                          THEN on_time_flag END) = 1
             AND MAX(CASE WHEN payment_no = total_payments - 1
                          THEN on_time_flag END) = 1
             AND MAX(CASE WHEN payment_no = total_payments - 2
                          THEN on_time_flag END) = 1
            THEN 'Consistent (3+)'
            WHEN MAX(CASE WHEN payment_no = total_payments
                          THEN on_time_flag END) = 1
            THEN 'Recent On-Time'
            ELSE 'Irregular'
        END                                           AS recent_payment_pattern
    FROM (
        SELECT *, MAX(payment_no) OVER (PARTITION BY loan_id) AS total_payments
        FROM payment_sequence
    ) x
    GROUP BY loan_id, customer_name, segment, loan_type, loan_status
)
SELECT
    customer_name,
    segment,
    loan_type,
    loan_status,
    total_payments,
    on_time_payments,
    on_time_pct,
    max_single_overdue,
    total_penalties_paid,
    recent_payment_pattern,
    -- Composite payment score (0-100)
    ROUND(
        LEAST(100,
            on_time_pct * 0.6
            + GREATEST(0, 100 - total_overdue_days * 2) * 0.3
            + CASE recent_payment_pattern
                WHEN 'Consistent (3+)' THEN 10
                WHEN 'Recent On-Time'  THEN 5
                ELSE 0
              END
        ), 2
    )                                               AS payment_health_score,
    RANK() OVER (ORDER BY on_time_pct DESC, max_single_overdue)
                                                    AS payment_rank
FROM loan_scores
ORDER BY payment_health_score DESC;


-- ─────────────────────────────────────────
--  Q14. Loan Disbursement Cohort Analysis
--  Business Use: Vintage analysis — how do loans age?
--  Window: SUM() OVER PARTITION BY cohort
-- ─────────────────────────────────────────
WITH cohorts AS (
    SELECT
        l.loan_id,
        l.loan_type,
        l.status,
        l.sanctioned_amt,
        l.outstanding_amt,
        l.disbursed_on,
        DATE_TRUNC('year', l.disbursed_on)::DATE    AS cohort_year,
        DATE_PART('year', AGE(NOW(), l.disbursed_on))::INT
                                                    AS loan_age_years,
        CASE WHEN l.status = 'NPA' THEN l.outstanding_amt ELSE 0 END
                                                    AS npa_amount
    FROM loans l
)
SELECT
    cohort_year,
    loan_type,
    COUNT(*)                                                         AS loan_count,
    ROUND(SUM(sanctioned_amt), 2)                                   AS total_sanctioned,
    ROUND(SUM(outstanding_amt), 2)                                  AS total_outstanding,
    ROUND(SUM(npa_amount), 2)                                       AS npa_outstanding,
    ROUND(
        SUM(npa_amount) * 100.0 / NULLIF(SUM(sanctioned_amt), 0), 2
    )                                                                AS npa_ratio_pct,
    -- Running NPA exposure by cohort
    ROUND(SUM(SUM(npa_amount)) OVER (
        PARTITION BY loan_type
        ORDER BY cohort_year
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ), 2)                                                            AS cumulative_npa_by_type,
    ROUND(AVG(loan_age_years), 1)                                   AS avg_loan_age_years
FROM cohorts
GROUP BY cohort_year, loan_type
ORDER BY cohort_year, loan_type;


-- ─────────────────────────────────────────
--  Q15. Branch-wise Loan Officer Performance
--  Business Use: Staff productivity, incentive computation
--  Window: DENSE_RANK(), FIRST_VALUE(), SUM() OVER
-- ─────────────────────────────────────────
WITH officer_metrics AS (
    SELECT
        e.employee_id,
        e.first_name || ' ' || e.last_name      AS officer_name,
        e.role,
        b.branch_name,
        b.region,
        COUNT(l.loan_id)                         AS loans_sanctioned,
        ROUND(SUM(l.sanctioned_amt), 2)          AS total_sanctioned_amt,
        ROUND(AVG(l.sanctioned_amt), 2)          AS avg_loan_size,
        ROUND(AVG(l.interest_rate), 2)           AS avg_interest_rate,
        COUNT(CASE WHEN l.status = 'NPA'   THEN 1 END)  AS npa_loans,
        COUNT(CASE WHEN l.status = 'Active' THEN 1 END) AS active_loans,
        ROUND(
            COALESCE(SUM(CASE WHEN l.status = 'NPA'
                         THEN l.outstanding_amt END), 0)
            * 100.0 / NULLIF(SUM(l.sanctioned_amt), 0), 2
        )                                        AS npa_rate_pct
    FROM employees e
    JOIN branches b ON b.branch_id   = e.branch_id
    JOIN loans    l ON l.employee_id = e.employee_id
    GROUP BY e.employee_id, officer_name, e.role, b.branch_name, b.region
)
SELECT
    officer_name,
    role,
    branch_name,
    region,
    loans_sanctioned,
    total_sanctioned_amt,
    avg_loan_size,
    avg_interest_rate,
    npa_loans,
    npa_rate_pct,
    -- Rank within region
    DENSE_RANK() OVER (
        PARTITION BY region
        ORDER BY total_sanctioned_amt DESC
    )                                            AS rank_in_region,
    -- Top performer's amount in that region (benchmark)
    FIRST_VALUE(total_sanctioned_amt) OVER (
        PARTITION BY region
        ORDER BY total_sanctioned_amt DESC
    )                                            AS region_top_amount,
    -- Gap from top performer
    ROUND(
        FIRST_VALUE(total_sanctioned_amt) OVER (
            PARTITION BY region ORDER BY total_sanctioned_amt DESC
        ) - total_sanctioned_amt, 2
    )                                            AS gap_from_top,
    -- Share of region's total book
    ROUND(
        total_sanctioned_amt * 100.0
        / SUM(total_sanctioned_amt) OVER (PARTITION BY region), 2
    )                                            AS pct_of_region_book
FROM officer_metrics
ORDER BY region, rank_in_region;
