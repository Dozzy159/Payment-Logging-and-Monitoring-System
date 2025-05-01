
USE PaymentLoggingDB;

-- Remove duplicate transactions
WITH CTE AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY transaction_date DESC) AS row_num
    FROM Transactions
)
DELETE FROM CTE WHERE row_num > 1;

-- Total Transactions
SELECT COUNT(*) AS total_transactions 
FROM Transactions;

-- Transaction Success vs Failure Rate
SELECT ts.status_name, COUNT(t.transaction_id) AS count_of_transactions,
	   ROUND(COUNT(t.transaction_id) * 100.0 / (SELECT COUNT(*) FROM Transactions), 2) AS percentage_of_transactions
FROM Transactions t
INNER JOIN TransactionStatus ts 
	ON t.status_id = ts.status_id
GROUP BY ts.status_name
ORDER BY percentage_of_transactions DESC;

-- Common Failure Reasons
SELECT error_message, COUNT(transaction_id) AS failure_count
FROM ErrorLogs
GROUP BY error_message
ORDER BY failure_count DESC;

-- Transactions per Payment Method
SELECT pm.payment_method_name, COUNT(t.transaction_id) AS total_transactions
FROM Transactions t
INNER JOIN PaymentMethods pm
	ON t.payment_method_id = pm.payment_method_id
GROUP BY pm.payment_method_name
ORDER BY total_transactions DESC;

-- Revenue per Merchant
SELECT m.merchant_name, SUM(t.amount) AS total_revenue
FROM Transactions t
INNER JOIN Merchants m 
	ON t.merchant_id = m.merchant_id
WHERE t.status_id = (SELECT status_id FROM TransactionStatus WHERE status_name = 'Success')
GROUP BY m.merchant_name
ORDER BY total_revenue DESC;

-- Daily Transaction Trends
SELECT CAST(transaction_date AS DATE) AS transaction_day, COUNT(transaction_id) AS total_transactions
FROM Transactions
GROUP BY CAST(transaction_date AS DATE)
ORDER BY total_transactions DESC;

-- Monthly Transaction Trends
SELECT YEAR(transaction_date) AS transaction_year, MONTH(transaction_date) AS transaction_month,
	   COUNT(transaction_id) AS total_transactions, SUM(amount) AS total_revenue
FROM Transactions
GROUP BY YEAR(transaction_date), MONTH(transaction_date)
ORDER BY transaction_year, transaction_month;

-- Failed transactions per Merchant
SELECT m.merchant_name, COUNT(t.transaction_id) AS failed_transactions
FROM Transactions t
INNER JOIN Merchants m 
	ON t.merchant_id = m.merchant_id
WHERE t.status_id = (SELECT status_id FROM TransactionStatus WHERE status_name = 'Failed')
GROUP BY m.merchant_name
ORDER BY failed_transactions DESC;

-- Peak Transaction Times
SELECT DATEPART(HOUR, transaction_date) AS transaction_hour, COUNT(transaction_id) AS transaction_count
FROM Transactions
GROUP BY DATEPART(HOUR, transaction_date)
ORDER BY transaction_hour;

-- High-Risk Terminals
SELECT tm.terminal_type_name, COUNT(t.transaction_id) AS failed_transactions
FROM Transactions t
INNER JOIN Terminals ter 
	ON t.terminal_id = ter.terminal_id
INNER JOIN TerminalTypes tm 
	ON ter.terminal_type_id = tm.terminal_type_id
WHERE t.status_id = (SELECT status_id FROM TransactionStatus WHERE status_name = 'Failed')
GROUP BY tm.terminal_type_name
ORDER BY failed_transactions DESC;

-- High-Value Customers
SELECT c.customer_name, COUNT(t.transaction_id) AS total_transactions, SUM(t.amount) AS total_spent
FROM Transactions t
INNER JOIN Customers c 
	ON t.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY total_transactions DESC;

