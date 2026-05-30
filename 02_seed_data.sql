-- ============================================================
--  BANKING ANALYTICS PLATFORM — Seed / Sample Data
--  Run AFTER 01_schema.sql
-- ============================================================

-- ─────────────────────────────────────────
--  BRANCHES
-- ─────────────────────────────────────────
INSERT INTO branches (branch_name, city, state, region, established_on) VALUES
('Connaught Place Main',    'New Delhi',    'Delhi',             'North', '2005-04-01'),
('Saket Branch',            'New Delhi',    'Delhi',             'North', '2008-07-15'),
('Cyber City Branch',       'Gurugram',     'Haryana',           'North', '2010-03-22'),
('Bandra West Branch',      'Mumbai',       'Maharashtra',       'West',  '2003-11-10'),
('Nariman Point Branch',    'Mumbai',       'Maharashtra',       'West',  '2001-06-05'),
('Koramangala Branch',      'Bengaluru',    'Karnataka',         'South', '2007-09-18'),
('Anna Nagar Branch',       'Chennai',      'Tamil Nadu',        'South', '2009-01-30'),
('Salt Lake Branch',        'Kolkata',      'West Bengal',       'East',  '2006-02-14'),
('Ahmedabad CG Road',       'Ahmedabad',    'Gujarat',           'West',  '2012-05-20'),
('Hyderabad HITEC City',    'Hyderabad',    'Telangana',         'South', '2011-08-08');

-- ─────────────────────────────────────────
--  PRODUCTS
-- ─────────────────────────────────────────
INSERT INTO products (product_name, product_type, interest_rate, min_balance) VALUES
('Classic Savings Account',     'Savings',     3.50,  1000),
('Premium Savings Account',     'Savings',     4.00,  10000),
('Zero Balance Savings',        'Savings',     2.75,  0),
('Business Current Account',    'Current',     0.00,  25000),
('Corporate Current Account',   'Current',     0.00,  100000),
('180-Day Fixed Deposit',       'FD',          6.50,  5000),
('1-Year Fixed Deposit',        'FD',          7.10,  5000),
('3-Year Fixed Deposit',        'FD',          7.50,  10000),
('Home Loan',                   'Loan',        8.40,  0),
('Personal Loan',               'Loan',       13.50,  0),
('Auto Loan',                   'Loan',        9.25,  0),
('Education Loan',              'Loan',        8.80,  0),
('Business Loan',               'Loan',       11.00,  0),
('Classic Credit Card',         'Credit Card', 36.00, 0),
('Premium Credit Card',         'Credit Card', 30.00, 0);

-- ─────────────────────────────────────────
--  EMPLOYEES  (keep small, referential)
-- ─────────────────────────────────────────
INSERT INTO employees (branch_id, first_name, last_name, role, hire_date, salary, manager_id) VALUES
(1, 'Rajesh',   'Kumar',    'Branch Manager',        '2010-06-01', 120000, NULL),
(1, 'Priya',    'Sharma',   'Relationship Manager',  '2015-03-15', 75000,  1),
(1, 'Amit',     'Verma',    'Loan Officer',          '2017-08-20', 68000,  1),
(2, 'Sunita',   'Gupta',    'Branch Manager',        '2012-01-10', 115000, NULL),
(2, 'Ravi',     'Singh',    'Relationship Manager',  '2016-05-22', 72000,  4),
(3, 'Neha',     'Joshi',    'Branch Manager',        '2013-07-01', 118000, NULL),
(3, 'Vikram',   'Patel',    'Loan Officer',          '2018-11-15', 65000,  6),
(4, 'Anita',    'Desai',    'Branch Manager',        '2009-03-20', 125000, NULL),
(4, 'Suresh',   'Nair',     'Relationship Manager',  '2014-09-08', 78000,  8),
(5, 'Kavitha',  'Reddy',    'Branch Manager',        '2011-12-05', 122000, NULL),
(5, 'Mohan',    'Pillai',   'Loan Officer',          '2019-02-28', 62000,  10),
(6, 'Deepak',   'Rao',      'Branch Manager',        '2010-04-12', 121000, NULL),
(7, 'Latha',    'Iyer',     'Branch Manager',        '2014-06-30', 116000, NULL),
(8, 'Bhaskar',  'Das',      'Branch Manager',        '2012-09-17', 114000, NULL),
(9, 'Harsha',   'Shah',     'Branch Manager',        '2015-11-22', 117000, NULL),
(10,'Divya',    'Menon',    'Branch Manager',        '2013-03-08', 119000, NULL);

-- ─────────────────────────────────────────
--  CUSTOMERS  (40 customers)
-- ─────────────────────────────────────────
INSERT INTO customers (branch_id, employee_id, first_name, last_name, dob, gender, city, state, email, phone, kyc_verified, customer_since, segment) VALUES
(1,  2,  'Arjun',     'Mehta',    '1985-04-12', 'M', 'New Delhi',  'Delhi',        'arjun.mehta@email.com',    '9811001001', TRUE,  '2015-01-10', 'HNI'),
(1,  2,  'Pooja',     'Agarwal',  '1990-08-25', 'F', 'New Delhi',  'Delhi',        'pooja.agarwal@email.com',  '9811001002', TRUE,  '2016-03-22', 'Retail'),
(1,  2,  'Sanjay',    'Bansal',   '1978-12-03', 'M', 'New Delhi',  'Delhi',        'sanjay.bansal@email.com',  '9811001003', TRUE,  '2014-06-05', 'HNI'),
(2,  5,  'Meera',     'Kapoor',   '1992-03-17', 'F', 'New Delhi',  'Delhi',        'meera.kapoor@email.com',   '9811001004', TRUE,  '2017-09-14', 'Retail'),
(2,  5,  'Rohit',     'Malhotra', '1988-07-22', 'M', 'New Delhi',  'Delhi',        'rohit.malhotra@email.com', '9811001005', TRUE,  '2016-11-30', 'SME'),
(3,  2,  'Nisha',     'Chawla',   '1995-01-08', 'F', 'Gurugram',   'Haryana',      'nisha.chawla@email.com',   '9811001006', TRUE,  '2018-04-20', 'Retail'),
(3,  2,  'Karan',     'Luthra',   '1983-05-30', 'M', 'Gurugram',   'Haryana',      'karan.luthra@email.com',   '9811001007', TRUE,  '2013-08-15', 'Corporate'),
(4,  9,  'Aishwarya', 'Pillai',   '1991-09-14', 'F', 'Mumbai',     'Maharashtra',  'aish.pillai@email.com',    '9822001001', TRUE,  '2016-02-28', 'HNI'),
(4,  9,  'Vivek',     'Oberoi',   '1979-02-20', 'M', 'Mumbai',     'Maharashtra',  'vivek.oberoi@email.com',   '9822001002', TRUE,  '2012-07-10', 'HNI'),
(4,  9,  'Shreya',    'Jain',     '1994-06-11', 'F', 'Mumbai',     'Maharashtra',  'shreya.jain@email.com',    '9822001003', TRUE,  '2019-05-18', 'Retail'),
(5,  9,  'Mihir',     'Bhatt',    '1986-10-28', 'M', 'Mumbai',     'Maharashtra',  'mihir.bhatt@email.com',    '9822001004', TRUE,  '2014-12-01', 'SME'),
(5,  9,  'Tara',      'Mehta',    '1993-04-05', 'F', 'Mumbai',     'Maharashtra',  'tara.mehta@email.com',     '9822001005', TRUE,  '2018-08-22', 'Retail'),
(6,  2,  'Arun',      'Krishnan', '1980-11-15', 'M', 'Bengaluru',  'Karnataka',    'arun.krishnan@email.com',  '9844001001', TRUE,  '2011-03-07', 'Corporate'),
(6,  2,  'Divya',     'Shetty',   '1989-07-03', 'F', 'Bengaluru',  'Karnataka',    'divya.shetty@email.com',   '9844001002', TRUE,  '2015-10-19', 'HNI'),
(6,  2,  'Prakash',   'Hegde',    '1975-03-22', 'M', 'Bengaluru',  'Karnataka',    'prakash.hegde@email.com',  '9844001003', TRUE,  '2010-06-14', 'SME'),
(7,  2,  'Lakshmi',   'Sundaram', '1987-12-09', 'F', 'Chennai',    'Tamil Nadu',   'lakshmi.s@email.com',      '9841001001', TRUE,  '2014-01-25', 'HNI'),
(7,  2,  'Ganesh',    'Rajan',    '1982-08-17', 'M', 'Chennai',    'Tamil Nadu',   'ganesh.rajan@email.com',   '9841001002', TRUE,  '2012-04-30', 'Retail'),
(7,  2,  'Preethi',   'Kumar',    '1996-02-14', 'F', 'Chennai',    'Tamil Nadu',   'preethi.k@email.com',      '9841001003', FALSE, '2020-09-11', 'Retail'),
(8,  2,  'Subhash',   'Ghosh',    '1977-06-25', 'M', 'Kolkata',    'West Bengal',  'subhash.ghosh@email.com',  '9831001001', TRUE,  '2010-11-08', 'SME'),
(8,  2,  'Rupa',      'Bose',     '1991-10-31', 'F', 'Kolkata',    'West Bengal',  'rupa.bose@email.com',      '9831001002', TRUE,  '2017-07-16', 'Retail'),
(9,  2,  'Nikhil',    'Shah',     '1984-01-19', 'M', 'Ahmedabad',  'Gujarat',      'nikhil.shah@email.com',    '9824001001', TRUE,  '2013-02-03', 'HNI'),
(9,  2,  'Hetal',     'Parekh',   '1993-05-27', 'F', 'Ahmedabad',  'Gujarat',      'hetal.parekh@email.com',   '9824001002', TRUE,  '2018-12-20', 'Retail'),
(9,  2,  'Jignesh',   'Vora',     '1970-09-04', 'M', 'Ahmedabad',  'Gujarat',      'jignesh.vora@email.com',   '9824001003', TRUE,  '2008-05-11', 'Corporate'),
(10, 9,  'Sridhar',   'Reddy',    '1981-03-13', 'M', 'Hyderabad',  'Telangana',    'sridhar.reddy@email.com',  '9840001001', TRUE,  '2012-08-29', 'SME'),
(10, 9,  'Padmaja',   'Rao',      '1990-07-21', 'F', 'Hyderabad',  'Telangana',    'padmaja.rao@email.com',    '9840001002', TRUE,  '2016-04-17', 'Retail'),
(1,  2,  'Tarun',     'Saxena',   '1976-11-02', 'M', 'New Delhi',  'Delhi',        'tarun.saxena@email.com',   '9811001008', TRUE,  '2009-10-05', 'Corporate'),
(4,  9,  'Rina',      'Doshi',    '1988-04-16', 'F', 'Mumbai',     'Maharashtra',  'rina.doshi@email.com',     '9822001006', TRUE,  '2015-06-23', 'Retail'),
(6,  2,  'Sunil',     'Pai',      '1985-09-08', 'M', 'Bengaluru',  'Karnataka',    'sunil.pai@email.com',      '9844001004', TRUE,  '2014-03-12', 'SME'),
(3,  2,  'Ananya',    'Tiwari',   '1997-06-30', 'F', 'Gurugram',   'Haryana',      'ananya.tiwari@email.com',  '9811001009', TRUE,  '2021-01-05', 'Retail'),
(5,  9,  'Fahad',     'Sheikh',   '1983-12-11', 'M', 'Mumbai',     'Maharashtra',  'fahad.sheikh@email.com',   '9822001007', TRUE,  '2013-09-18', 'HNI'),
(7,  2,  'Kavya',     'Nair',     '1995-08-19', 'F', 'Chennai',    'Tamil Nadu',   'kavya.nair@email.com',     '9841001004', TRUE,  '2019-11-27', 'Retail'),
(8,  2,  'Ritesh',    'Chakraborty','1979-04-07','M', 'Kolkata',    'West Bengal',  'ritesh.c@email.com',       '9831001003', TRUE,  '2011-07-21', 'SME'),
(2,  5,  'Swati',     'Rastogi',  '1992-01-24', 'F', 'New Delhi',  'Delhi',        'swati.rastogi@email.com',  '9811001010', TRUE,  '2017-03-09', 'Retail'),
(10, 9,  'Venkat',    'Subramaniam','1980-06-15','M', 'Hyderabad',  'Telangana',    'venkat.sub@email.com',     '9840001003', TRUE,  '2011-12-14', 'Corporate'),
(9,  2,  'Bhavna',    'Trivedi',  '1986-10-03', 'F', 'Ahmedabad',  'Gujarat',      'bhavna.trivedi@email.com', '9824001004', TRUE,  '2015-08-07', 'HNI'),
(1,  3,  'Deepak',    'Pandey',   '1974-07-28', 'M', 'New Delhi',  'Delhi',        'deepak.pandey@email.com',  '9811001011', TRUE,  '2007-05-30', 'HNI'),
(4,  9,  'Sneha',     'Kulkarni', '1993-03-05', 'F', 'Mumbai',     'Maharashtra',  'sneha.k@email.com',        '9822001008', TRUE,  '2018-02-14', 'Retail'),
(6,  2,  'Balu',      'Swamy',    '1977-08-22', 'M', 'Bengaluru',  'Karnataka',    'balu.swamy@email.com',     '9844001005', TRUE,  '2009-09-03', 'SME'),
(3,  7,  'Roshni',    'Arora',    '1991-05-10', 'F', 'Gurugram',   'Haryana',      'roshni.arora@email.com',   '9811001012', TRUE,  '2016-07-28', 'HNI'),
(5,  11, 'Abhimanyu', 'Choudhary','1982-02-17', 'M', 'Mumbai',     'Maharashtra',  'abhi.c@email.com',         '9822001009', TRUE,  '2012-11-06', 'SME');

-- ─────────────────────────────────────────
--  ACCOUNTS
-- ─────────────────────────────────────────
INSERT INTO accounts (customer_id, product_id, branch_id, account_number, opened_on, status, balance, currency) VALUES
-- Savings accounts
(1,  1, 1,  'ACC0000000001', '2015-01-10', 'Active',   485000.00,  'INR'),
(2,  3, 1,  'ACC0000000002', '2016-03-22', 'Active',   12500.00,   'INR'),
(3,  2, 1,  'ACC0000000003', '2014-06-05', 'Active',   1250000.00, 'INR'),
(4,  1, 2,  'ACC0000000004', '2017-09-14', 'Active',   38000.00,   'INR'),
(5,  4, 2,  'ACC0000000005', '2016-11-30', 'Active',   560000.00,  'INR'),
(6,  3, 3,  'ACC0000000006', '2018-04-20', 'Active',   9800.00,    'INR'),
(7,  5, 3,  'ACC0000000007', '2013-08-15', 'Active',   2800000.00, 'INR'),
(8,  2, 4,  'ACC0000000008', '2016-02-28', 'Active',   750000.00,  'INR'),
(9,  2, 4,  'ACC0000000009', '2012-07-10', 'Active',   1800000.00, 'INR'),
(10, 1, 4,  'ACC0000000010', '2019-05-18', 'Active',   22000.00,   'INR'),
(11, 4, 5,  'ACC0000000011', '2014-12-01', 'Active',   890000.00,  'INR'),
(12, 1, 5,  'ACC0000000012', '2018-08-22', 'Active',   31000.00,   'INR'),
(13, 5, 6,  'ACC0000000013', '2011-03-07', 'Active',   3200000.00, 'INR'),
(14, 2, 6,  'ACC0000000014', '2015-10-19', 'Active',   920000.00,  'INR'),
(15, 4, 6,  'ACC0000000015', '2010-06-14', 'Active',   450000.00,  'INR'),
(16, 2, 7,  'ACC0000000016', '2014-01-25', 'Active',   1100000.00, 'INR'),
(17, 1, 7,  'ACC0000000017', '2012-04-30', 'Active',   45000.00,   'INR'),
(18, 3, 7,  'ACC0000000018', '2020-09-11', 'Active',   6500.00,    'INR'),
(19, 4, 8,  'ACC0000000019', '2010-11-08', 'Active',   720000.00,  'INR'),
(20, 1, 8,  'ACC0000000020', '2017-07-16', 'Active',   28000.00,   'INR'),
(21, 2, 9,  'ACC0000000021', '2013-02-03', 'Active',   1650000.00, 'INR'),
(22, 1, 9,  'ACC0000000022', '2018-12-20', 'Active',   19500.00,   'INR'),
(23, 5, 9,  'ACC0000000023', '2008-05-11', 'Active',   4500000.00, 'INR'),
(24, 4, 10, 'ACC0000000024', '2012-08-29', 'Active',   380000.00,  'INR'),
(25, 1, 10, 'ACC0000000025', '2016-04-17', 'Active',   17000.00,   'INR'),
(26, 5, 1,  'ACC0000000026', '2009-10-05', 'Active',   5800000.00, 'INR'),
(27, 1, 4,  'ACC0000000027', '2015-06-23', 'Active',   33000.00,   'INR'),
(28, 4, 6,  'ACC0000000028', '2014-03-12', 'Active',   420000.00,  'INR'),
(29, 3, 3,  'ACC0000000029', '2021-01-05', 'Active',   5000.00,    'INR'),
(30, 2, 5,  'ACC0000000030', '2013-09-18', 'Active',   1420000.00, 'INR'),
(31, 1, 7,  'ACC0000000031', '2019-11-27', 'Active',   14500.00,   'INR'),
(32, 4, 8,  'ACC0000000032', '2011-07-21', 'Active',   510000.00,  'INR'),
(33, 1, 2,  'ACC0000000033', '2017-03-09', 'Active',   41000.00,   'INR'),
(34, 5, 10, 'ACC0000000034', '2011-12-14', 'Active',   2900000.00, 'INR'),
(35, 2, 9,  'ACC0000000035', '2015-08-07', 'Active',   1350000.00, 'INR'),
(36, 2, 1,  'ACC0000000036', '2007-05-30', 'Active',   3750000.00, 'INR'),
(37, 1, 4,  'ACC0000000037', '2018-02-14', 'Active',   24000.00,   'INR'),
(38, 4, 6,  'ACC0000000038', '2009-09-03', 'Active',   630000.00,  'INR'),
(39, 2, 3,  'ACC0000000039', '2016-07-28', 'Active',   880000.00,  'INR'),
(40, 4, 5,  'ACC0000000040', '2012-11-06', 'Active',   730000.00,  'INR'),
-- FD accounts for select HNI customers
(1,  7, 1,  'FD00000000001', '2022-01-15', 'Active',   500000.00,  'INR'),
(3,  8, 1,  'FD00000000002', '2021-06-01', 'Active',   2000000.00, 'INR'),
(9,  7, 4,  'FD00000000003', '2023-03-10', 'Active',   1000000.00, 'INR'),
(26, 8, 1,  'FD00000000004', '2020-11-20', 'Active',   3000000.00, 'INR'),
(23, 7, 9,  'FD00000000005', '2022-08-05', 'Active',   2500000.00, 'INR'),
-- Dormant accounts
(17, 1, 7,  'ACC0000000041', '2015-01-01', 'Dormant',  2300.00,    'INR'),
(18, 1, 7,  'ACC0000000042', '2020-09-11', 'Dormant',  100.00,     'INR');

-- ─────────────────────────────────────────
--  TRANSACTIONS  (representative sample)
-- ─────────────────────────────────────────
INSERT INTO transactions (account_id, txn_date, txn_type, channel, amount, balance_after, description) VALUES
-- Customer 1 (Arjun Mehta, HNI)
(1, '2024-01-05 09:30:00', 'Credit',  'Net Banking', 100000, 485000, 'Salary Credit'),
(1, '2024-01-12 14:22:00', 'Debit',   'UPI',          25000, 460000, 'Rent Payment'),
(1, '2024-01-20 11:05:00', 'Debit',   'ATM',          10000, 450000, 'ATM Withdrawal'),
(1, '2024-02-05 09:30:00', 'Credit',  'Net Banking', 100000, 550000, 'Salary Credit'),
(1, '2024-02-15 16:40:00', 'Transfer','Net Banking',  50000, 500000, 'Transfer to FD'),
(1, '2024-03-05 09:30:00', 'Credit',  'Net Banking', 100000, 600000, 'Salary Credit'),
(1, '2024-03-18 10:15:00', 'Debit',   'Mobile',       35000, 565000, 'Investment Purchase'),
(1, '2024-04-05 09:30:00', 'Credit',  'Net Banking', 100000, 665000, 'Salary Credit'),
(1, '2024-04-22 13:50:00', 'Debit',   'Net Banking', 180000, 485000, 'Property Tax'),
-- Customer 3 (Sanjay Bansal, HNI)
(3, '2024-01-03 10:00:00', 'Credit',  'NEFT',        500000, 1250000, 'Business Receipts'),
(3, '2024-01-18 15:30:00', 'Debit',   'RTGS',        300000,  950000, 'Vendor Payment'),
(3, '2024-02-03 10:00:00', 'Credit',  'NEFT',        500000, 1450000, 'Business Receipts'),
(3, '2024-02-20 12:00:00', 'Debit',   'Net Banking', 200000, 1250000, 'Tax Payment'),
(3, '2024-03-03 10:00:00', 'Credit',  'NEFT',        500000, 1750000, 'Business Receipts'),
(3, '2024-03-25 09:45:00', 'Debit',   'RTGS',        500000, 1250000, 'Equipment Purchase'),
-- Customer 9 (Vivek Oberoi, HNI)
(9, '2024-01-08 11:00:00', 'Credit',  'NEFT',        250000, 1800000, 'Investment Returns'),
(9, '2024-01-25 14:30:00', 'Debit',   'Net Banking', 100000, 1700000, 'Insurance Premium'),
(9, '2024-02-08 11:00:00', 'Credit',  'NEFT',        250000, 1950000, 'Investment Returns'),
(9, '2024-02-28 16:00:00', 'Debit',   'RTGS',        500000, 1450000, 'Property Purchase'),
(9, '2024-03-08 11:00:00', 'Credit',  'NEFT',        250000, 1700000, 'Investment Returns'),
-- Retail customers
(2, '2024-01-02 08:00:00', 'Credit',  'Net Banking',  35000,  35000, 'Salary Credit'),
(2, '2024-01-10 12:00:00', 'Debit',   'UPI',           8000,  27000, 'Online Shopping'),
(2, '2024-01-15 18:30:00', 'Debit',   'ATM',           5000,  22000, 'Cash Withdrawal'),
(2, '2024-02-02 08:00:00', 'Credit',  'Net Banking',  35000,  57000, 'Salary Credit'),
(2, '2024-02-12 11:00:00', 'Debit',   'UPI',          10000,  47000, 'Bill Payment'),
(4, '2024-01-01 09:00:00', 'Credit',  'Net Banking',  42000,  42000, 'Salary Credit'),
(4, '2024-01-14 20:00:00', 'Debit',   'Mobile',       12000,  30000, 'EMI Payment'),
(4, '2024-02-01 09:00:00', 'Credit',  'Net Banking',  42000,  72000, 'Salary Credit'),
(4, '2024-02-14 20:00:00', 'Debit',   'Mobile',       12000,  60000, 'EMI Payment'),
(4, '2024-03-01 09:00:00', 'Credit',  'Net Banking',  42000, 102000, 'Salary Credit'),
-- SME customers
(5, '2024-01-05 10:00:00', 'Credit',  'NEFT',        150000, 560000, 'Client Payment'),
(5, '2024-01-18 11:30:00', 'Debit',   'NEFT',         80000, 480000, 'Supplier Payment'),
(5, '2024-02-05 10:00:00', 'Credit',  'NEFT',        200000, 680000, 'Client Payment'),
(5, '2024-02-22 14:00:00', 'Debit',   'Net Banking', 120000, 560000, 'Salary Disbursement'),
(5, '2024-03-05 10:00:00', 'Credit',  'NEFT',        175000, 735000, 'Client Payment'),
(11,'2024-01-07 09:30:00', 'Credit',  'NEFT',        120000, 890000, 'Invoice Payment'),
(11,'2024-01-20 14:00:00', 'Debit',   'NEFT',         70000, 820000, 'Rent & Utilities'),
(11,'2024-02-07 09:30:00', 'Credit',  'NEFT',        140000, 960000, 'Invoice Payment'),
(11,'2024-02-24 15:30:00', 'Debit',   'Net Banking',  90000, 870000, 'Staff Salaries'),
-- Large transactions (flagged)
(7,  '2024-01-10 22:45:00', 'Credit', 'Branch',     1500000, 4300000, 'Cash Deposit'),
(7,  '2024-01-11 09:00:00', 'Debit',  'RTGS',       1400000, 2900000, 'Fund Transfer Out'),
(26, '2024-02-14 23:30:00', 'Credit', 'Branch',     2000000, 7800000, 'Cash Deposit'),
(26, '2024-02-15 08:00:00', 'Debit',  'RTGS',       1900000, 5900000, 'Fund Transfer Out'),
(23, '2024-03-05 21:00:00', 'Credit', 'Branch',     1000000, 5500000, 'Cash Deposit'),
-- Interest credits (quarterly)
(1,  '2024-03-31 00:01:00', 'Interest','Branch',      4250,  489250, 'Quarterly Interest'),
(3,  '2024-03-31 00:01:00', 'Interest','Branch',     10950, 1260950, 'Quarterly Interest'),
(41, '2024-03-31 00:01:00', 'Interest','Branch',      8750,  508750, 'FD Interest Credit'),
(42, '2024-03-31 00:01:00', 'Interest','Branch',     35500, 2035500, 'FD Interest Credit'),
-- Fee deductions
(2,  '2024-03-31 00:02:00', 'Fee',    'Branch',        250,  12250, 'Account Maintenance Fee'),
(6,  '2024-03-31 00:02:00', 'Fee',    'Branch',        250,   9550, 'Account Maintenance Fee'),
(18, '2024-03-31 00:02:00', 'Fee',    'Branch',        250,   6250, 'Account Maintenance Fee');

-- Mark suspicious transactions
UPDATE transactions SET is_flagged = TRUE
WHERE account_id IN (7, 26, 23)
  AND amount >= 1000000;

-- ─────────────────────────────────────────
--  LOANS
-- ─────────────────────────────────────────
INSERT INTO loans (customer_id, employee_id, branch_id, loan_type, sanctioned_amt, outstanding_amt, interest_rate, tenure_months, disbursed_on, due_date, status, emi_amount) VALUES
(1,  3,  1, 'Home',      8000000, 6200000, 8.40, 240, '2018-06-01', '2038-06-01', 'Active',    69000),
(2,  3,  1, 'Personal',   300000,  180000,13.50,  36, '2022-03-15', '2025-03-15', 'Active',    10200),
(4,  3,  2, 'Personal',   200000,   50000,13.50,  24, '2022-06-01', '2024-06-01', 'Active',     9600),
(5,  3,  2, 'Business',  2000000, 1500000,11.00,  60, '2021-01-10', '2026-01-10', 'Active',    43500),
(6,  7,  3, 'Auto',       800000,  620000, 9.25,  60, '2021-08-20', '2026-08-20', 'Active',    16700),
(8,  3,  4, 'Home',      6500000, 5800000, 8.40, 240, '2020-03-01', '2040-03-01', 'Active',    56000),
(9,  3,  4, 'Home',     12000000,10500000, 8.25, 240, '2019-05-15', '2039-05-15', 'Active',   102000),
(11, 11, 5, 'Business',  3000000, 2200000,11.00,  84, '2020-07-01', '2027-07-01', 'Active',    51000),
(13, 3,  6, 'Business',  5000000, 4100000,10.50,  84, '2021-02-15', '2028-02-15', 'Active',    83000),
(14, 3,  6, 'Home',      4500000, 4000000, 8.50, 240, '2022-04-01', '2042-04-01', 'Active',    39000),
(15, 7,  6, 'Business',  1500000,  800000,11.50,  48, '2021-05-01', '2025-05-01', 'Active',    38500),
(16, 3,  7, 'Home',      3500000, 3100000, 8.60, 180, '2021-10-01', '2036-10-01', 'Active',    34500),
(19, 3,  8, 'Business',  2500000, 1800000,11.20,  60, '2020-12-01', '2025-12-01', 'Active',    54000),
(21, 3,  9, 'Home',      5000000, 4400000, 8.30, 240, '2021-08-10', '2041-08-10', 'Active',    43500),
(24, 11, 10,'Business',  1800000,  900000,11.80,  48, '2021-07-01', '2025-07-01', 'Active',    47000),
(26, 3,  1, 'Home',     15000000,13500000, 8.10, 240, '2018-01-15', '2038-01-15', 'Active',   127000),
(30, 3,  5, 'Home',      7000000, 6300000, 8.45, 240, '2020-10-01', '2040-10-01', 'Active',    61000),
(32, 7,  8, 'Business',  1200000,  300000,12.00,  36, '2021-09-01', '2024-09-01', 'Active',    39800),
(35, 3,  9, 'Home',      4000000, 3600000, 8.55, 180, '2022-01-01', '2037-01-01', 'Active',    39200),
(36, 3,  1, 'Home',      9000000, 7800000, 8.20, 240, '2016-06-01', '2036-06-01', 'Active',    77000),
-- NPA loans
(17, 3,  7, 'Personal',   150000,  145000,14.00,  24, '2022-09-01', '2024-09-01', 'NPA',        7500),
(20, 3,  8, 'Auto',       600000,  580000, 9.50,  48, '2022-01-01', '2026-01-01', 'NPA',       15000),
-- Closed loans
(3,  3,  1, 'Personal',   500000,       0,13.00,  36, '2020-01-01', '2023-01-01', 'Closed',    16800),
(7,  7,  3, 'Auto',      1200000,       0, 9.00,  48, '2019-03-01', '2023-03-01', 'Closed',    29800);

-- ─────────────────────────────────────────
--  LOAN PAYMENTS
-- ─────────────────────────────────────────
INSERT INTO loan_payments (loan_id, paid_on, amount_paid, principal_part, interest_part, penalty, days_overdue, payment_method) VALUES
-- Loan 1 (Arjun Mehta - Home Loan) - regular
(1, '2024-01-01', 69000, 23700, 45300, 0, 0,  'Auto-debit'),
(1, '2024-02-01', 69000, 23900, 45100, 0, 0,  'Auto-debit'),
(1, '2024-03-01', 69000, 24100, 44900, 0, 0,  'Auto-debit'),
(1, '2024-04-01', 69000, 24300, 44700, 0, 0,  'Auto-debit'),
-- Loan 2 (Pooja - Personal Loan)
(2, '2024-01-15', 10200,  6400,  3800, 0, 0,  'Auto-debit'),
(2, '2024-02-15', 10200,  6470,  3730, 0, 0,  'Auto-debit'),
(2, '2024-03-15', 10200,  6540,  3660, 0, 0,  'Auto-debit'),
-- Loan 6 (Aishwarya - Home Loan)
(6, '2024-01-01', 56000, 15200, 40800, 0, 0,  'Auto-debit'),
(6, '2024-02-01', 56000, 15300, 40700, 0, 0,  'Auto-debit'),
(6, '2024-03-01', 56000, 15400, 40600, 0, 0,  'Auto-debit'),
-- Loan 7 (Vivek Oberoi - Home Loan)
(7, '2024-01-01',102000, 29500, 72500, 0, 0,  'Auto-debit'),
(7, '2024-02-01',102000, 29700, 72300, 0, 0,  'Auto-debit'),
(7, '2024-03-01',102000, 29900, 72100, 0, 0,  'Auto-debit'),
-- NPA Loan 21 (Ganesh - Personal Loan) - missed payments
(21,'2024-01-25',  7500,  3500,  4000, 500,  25, 'Branch'),
-- NPA Loan 22 (Rupa - Auto Loan)
(22,'2024-02-10', 15000,  8000,  7000, 750,  40, 'Branch'),
-- Large loans regular payments
(16,'2024-01-01',127000, 40200, 86800,   0,  0,  'Auto-debit'),
(16,'2024-02-01',127000, 40500, 86500,   0,  0,  'Auto-debit'),
(16,'2024-03-01',127000, 40800, 86200,   0,  0,  'Auto-debit'),
(20,'2024-01-01', 77000, 21000, 56000,   0,  0,  'Auto-debit'),
(20,'2024-02-01', 77000, 21200, 55800,   0,  0,  'Auto-debit'),
-- Business loans
(8, '2024-01-01', 51000, 18700, 32300,   0,  0,  'NEFT'),
(8, '2024-02-01', 51000, 18900, 32100,   0,  0,  'NEFT'),
(8, '2024-03-01', 51000, 19100, 31900,   0,  0,  'NEFT'),
(9, '2024-01-01', 83000, 25700, 57300,   0,  0,  'NEFT'),
(9, '2024-02-01', 83000, 25900, 57100,   0,  0,  'NEFT'),
(9, '2024-03-01', 83000, 26100, 56900,   0,  0,  'NEFT');

-- ─────────────────────────────────────────
--  RISK FLAGS
-- ─────────────────────────────────────────
INSERT INTO risk_flags (customer_id, txn_id, flag_type, flagged_on, severity, resolved) VALUES
(7,  46, 'Large Cash Deposit',     '2024-01-10 23:00:00', 'High',   FALSE),
(7,  47, 'Rapid Fund Movement',    '2024-01-11 09:30:00', 'High',   FALSE),
(26, 48, 'Large Cash Deposit',     '2024-02-14 23:45:00', 'High',   FALSE),
(26, 49, 'Rapid Fund Movement',    '2024-02-15 08:30:00', 'High',   FALSE),
(23, 50, 'Unusual Hours Activity', '2024-03-05 21:15:00', 'Medium', TRUE),
(17, NULL,'Repeated Late Payments','2024-02-28 10:00:00', 'Medium', FALSE),
(20, NULL,'NPA Risk - Auto Loan',  '2024-03-15 11:00:00', 'High',   FALSE);
