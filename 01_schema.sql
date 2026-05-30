-- ============================================================
--  BANKING ANALYTICS PLATFORM — Schema Definition
--  Database: PostgreSQL 15+
--  Author:   Banking Analytics Project
--  Purpose:  Portfolio project for Data Analytics roles
-- ============================================================

-- ─────────────────────────────────────────
--  EXTENSIONS
-- ─────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ─────────────────────────────────────────
--  DROP TABLES (clean re-run)
-- ─────────────────────────────────────────
DROP TABLE IF EXISTS loan_payments       CASCADE;
DROP TABLE IF EXISTS loans               CASCADE;
DROP TABLE IF EXISTS transactions        CASCADE;
DROP TABLE IF EXISTS accounts            CASCADE;
DROP TABLE IF EXISTS customers           CASCADE;
DROP TABLE IF EXISTS branches            CASCADE;
DROP TABLE IF EXISTS employees           CASCADE;
DROP TABLE IF EXISTS products            CASCADE;
DROP TABLE IF EXISTS risk_flags          CASCADE;

-- ─────────────────────────────────────────
--  1. BRANCHES
-- ─────────────────────────────────────────
CREATE TABLE branches (
    branch_id       SERIAL PRIMARY KEY,
    branch_name     VARCHAR(100)  NOT NULL,
    city            VARCHAR(60)   NOT NULL,
    state           VARCHAR(60)   NOT NULL,
    region          VARCHAR(30)   NOT NULL  CHECK (region IN ('North','South','East','West')),
    established_on  DATE          NOT NULL,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE
);

-- ─────────────────────────────────────────
--  2. EMPLOYEES
-- ─────────────────────────────────────────
CREATE TABLE employees (
    employee_id     SERIAL PRIMARY KEY,
    branch_id       INT           REFERENCES branches(branch_id),
    first_name      VARCHAR(50)   NOT NULL,
    last_name       VARCHAR(50)   NOT NULL,
    role            VARCHAR(50)   NOT NULL,   -- 'Relationship Manager','Loan Officer','Teller', etc.
    hire_date       DATE          NOT NULL,
    salary          NUMERIC(12,2) NOT NULL,
    manager_id      INT           REFERENCES employees(employee_id)
);

-- ─────────────────────────────────────────
--  3. PRODUCTS  (banking products offered)
-- ─────────────────────────────────────────
CREATE TABLE products (
    product_id      SERIAL PRIMARY KEY,
    product_name    VARCHAR(80)   NOT NULL,
    product_type    VARCHAR(30)   NOT NULL  CHECK (product_type IN ('Savings','Current','FD','Loan','Credit Card')),
    interest_rate   NUMERIC(5,2),           -- annual %
    min_balance     NUMERIC(12,2) DEFAULT 0
);

-- ─────────────────────────────────────────
--  4. CUSTOMERS
-- ─────────────────────────────────────────
CREATE TABLE customers (
    customer_id     SERIAL PRIMARY KEY,
    branch_id       INT           REFERENCES branches(branch_id),
    employee_id     INT           REFERENCES employees(employee_id),  -- assigned RM
    first_name      VARCHAR(50)   NOT NULL,
    last_name       VARCHAR(50)   NOT NULL,
    dob             DATE          NOT NULL,
    gender          CHAR(1)       CHECK (gender IN ('M','F','O')),
    city            VARCHAR(60),
    state           VARCHAR(60),
    email           VARCHAR(120)  UNIQUE,
    phone           VARCHAR(15),
    kyc_verified    BOOLEAN       NOT NULL DEFAULT FALSE,
    customer_since  DATE          NOT NULL,
    segment         VARCHAR(20)   NOT NULL CHECK (segment IN ('Retail','HNI','Corporate','SME'))
);

-- ─────────────────────────────────────────
--  5. ACCOUNTS
-- ─────────────────────────────────────────
CREATE TABLE accounts (
    account_id      SERIAL PRIMARY KEY,
    customer_id     INT           NOT NULL REFERENCES customers(customer_id),
    product_id      INT           NOT NULL REFERENCES products(product_id),
    branch_id       INT           NOT NULL REFERENCES branches(branch_id),
    account_number  VARCHAR(20)   NOT NULL UNIQUE,
    opened_on       DATE          NOT NULL,
    closed_on       DATE,
    status          VARCHAR(15)   NOT NULL CHECK (status IN ('Active','Dormant','Closed','Frozen')),
    balance         NUMERIC(15,2) NOT NULL DEFAULT 0,
    currency        CHAR(3)       NOT NULL DEFAULT 'INR'
);

-- ─────────────────────────────────────────
--  6. TRANSACTIONS
-- ─────────────────────────────────────────
CREATE TABLE transactions (
    txn_id          SERIAL PRIMARY KEY,
    account_id      INT           NOT NULL REFERENCES accounts(account_id),
    txn_date        TIMESTAMP     NOT NULL DEFAULT NOW(),
    txn_type        VARCHAR(20)   NOT NULL CHECK (txn_type IN ('Credit','Debit','Transfer','Fee','Interest','Reversal')),
    channel         VARCHAR(20)   NOT NULL CHECK (channel IN ('Branch','ATM','Net Banking','Mobile','UPI','NEFT','RTGS')),
    amount          NUMERIC(15,2) NOT NULL CHECK (amount > 0),
    balance_after   NUMERIC(15,2) NOT NULL,
    reference_no    VARCHAR(30),
    description     VARCHAR(200),
    is_flagged      BOOLEAN       NOT NULL DEFAULT FALSE
);

-- ─────────────────────────────────────────
--  7. LOANS
-- ─────────────────────────────────────────
CREATE TABLE loans (
    loan_id         SERIAL PRIMARY KEY,
    customer_id     INT           NOT NULL REFERENCES customers(customer_id),
    employee_id     INT           REFERENCES employees(employee_id),  -- loan officer
    branch_id       INT           NOT NULL REFERENCES branches(branch_id),
    loan_type       VARCHAR(30)   NOT NULL CHECK (loan_type IN ('Home','Auto','Personal','Education','Business')),
    sanctioned_amt  NUMERIC(15,2) NOT NULL,
    outstanding_amt NUMERIC(15,2) NOT NULL,
    interest_rate   NUMERIC(5,2)  NOT NULL,
    tenure_months   INT           NOT NULL,
    disbursed_on    DATE          NOT NULL,
    due_date        DATE          NOT NULL,
    status          VARCHAR(15)   NOT NULL CHECK (status IN ('Active','Closed','NPA','Written-Off')),
    emi_amount      NUMERIC(12,2) NOT NULL
);

-- ─────────────────────────────────────────
--  8. LOAN PAYMENTS
-- ─────────────────────────────────────────
CREATE TABLE loan_payments (
    payment_id      SERIAL PRIMARY KEY,
    loan_id         INT           NOT NULL REFERENCES loans(loan_id),
    paid_on         DATE          NOT NULL,
    amount_paid     NUMERIC(12,2) NOT NULL,
    principal_part  NUMERIC(12,2) NOT NULL,
    interest_part   NUMERIC(12,2) NOT NULL,
    penalty         NUMERIC(10,2) NOT NULL DEFAULT 0,
    days_overdue    INT           NOT NULL DEFAULT 0,
    payment_method  VARCHAR(20)   CHECK (payment_method IN ('Auto-debit','NEFT','Branch','UPI'))
);

-- ─────────────────────────────────────────
--  9. RISK FLAGS
-- ─────────────────────────────────────────
CREATE TABLE risk_flags (
    flag_id         SERIAL PRIMARY KEY,
    customer_id     INT           NOT NULL REFERENCES customers(customer_id),
    txn_id          INT           REFERENCES transactions(txn_id),
    flag_type       VARCHAR(40)   NOT NULL,  -- 'Large Cash Deposit','Structuring','Rapid Movement', etc.
    flagged_on      TIMESTAMP     NOT NULL DEFAULT NOW(),
    severity        VARCHAR(10)   NOT NULL CHECK (severity IN ('Low','Medium','High')),
    resolved        BOOLEAN       NOT NULL DEFAULT FALSE
);

-- ─────────────────────────────────────────
--  INDEXES  (analytical query performance)
-- ─────────────────────────────────────────
CREATE INDEX idx_txn_account      ON transactions(account_id);
CREATE INDEX idx_txn_date         ON transactions(txn_date);
CREATE INDEX idx_txn_type         ON transactions(txn_type);
CREATE INDEX idx_loan_customer    ON loans(customer_id);
CREATE INDEX idx_loan_status      ON loans(status);
CREATE INDEX idx_acct_customer    ON accounts(customer_id);
CREATE INDEX idx_acct_status      ON accounts(status);
CREATE INDEX idx_risk_customer    ON risk_flags(customer_id);
CREATE INDEX idx_lp_loan          ON loan_payments(loan_id);
CREATE INDEX idx_lp_date          ON loan_payments(paid_on);
