
USE PaymentLoggingDB;

-- Stored Procedure for Transaction Summary (Success/Failure Rates)
CREATE PROCEDURE GetTransactionSummary
AS
BEGIN
    SELECT 
        FORMAT(transaction_date, 'yyyy-MM') AS transaction_month,
        COUNT(transaction_id) AS total_transactions,
        SUM(CASE WHEN status_id = 1 THEN 1 ELSE 0 END) AS successful_transactions,
        SUM(CASE WHEN status_id = 3 THEN 1 ELSE 0 END) AS failed_transactions,
        ROUND(
            CAST(SUM(CASE WHEN status_id = 1 THEN 1 ELSE 0 END) AS FLOAT) /
            NULLIF(COUNT(transaction_id), 0) * 100, 2
        ) AS success_rate
    FROM Transactions
    GROUP BY FORMAT(transaction_date, 'yyyy-MM')
	ORDER BY transaction_month;
END;

EXEC GetTransactionSummary;


-- Stored Procedure for Fraud Detection
CREATE PROCEDURE DetectPotentialFraud
AS
BEGIN
    SET NOCOUNT ON;

    -- Declare reusable date variables
    DECLARE @Yesterday DATETIME = DATEADD(day, -1, GETDATE());
    DECLARE @TimeWindowMinutes INT = 10;
    DECLARE @TransactionThreshold INT = 5;
    DECLARE @FailedTransactionThreshold INT = 3;
    
    -- Table variable for storing suspicious transactions
    DECLARE @SuspiciousTransactions TABLE (
        TransactionID INT,
        CustomerID INT,
        CustomerName VARCHAR(255),
        TransactionAmount DECIMAL(18,2),
        TransactionDate DATETIME,
        SuspicionReason NVARCHAR(500)
    );

    -- 1. Rapid Transactions in a Short Period
    INSERT INTO @SuspiciousTransactions
    SELECT 
        t1.transaction_id, t1.customer_id, c.customer_name, t1.amount, t1.transaction_date,
        'Rapid transactions: ' + CAST(COUNT(*) AS VARCHAR) + ' within ' + CAST(@TimeWindowMinutes AS VARCHAR) + ' minutes'
    FROM Transactions t1
    INNER JOIN Customers c ON t1.customer_id = c.customer_id
    INNER JOIN Transactions t2 
        ON t1.customer_id = t2.customer_id
        AND t2.transaction_date BETWEEN DATEADD(minute, -@TimeWindowMinutes, t1.transaction_date) AND t1.transaction_date
    GROUP BY t1.transaction_id, t1.customer_id, t1.transaction_date, c.customer_name, t1.amount
    HAVING COUNT(*) > @TransactionThreshold;

    -- 2. Multiple Failed Transactions in a Short Period
    INSERT INTO @SuspiciousTransactions
    SELECT 
        t1.transaction_id, t1.customer_id, c.customer_name, t1.amount, t1.transaction_date,
        'Rapid failed transactions: ' + CAST(COUNT(*) AS VARCHAR) + ' within ' + CAST(@TimeWindowMinutes AS VARCHAR) + ' minutes'
    FROM Transactions t1
    INNER JOIN Customers c ON t1.customer_id = c.customer_id
    INNER JOIN Transactions t2 
        ON t1.customer_id = t2.customer_id
        AND t2.transaction_date BETWEEN DATEADD(minute, -@TimeWindowMinutes, t1.transaction_date) AND t1.transaction_date
    INNER JOIN TransactionStatus ts ON t1.status_id = ts.status_id
    WHERE ts.status_name = 'Failed'
    GROUP BY t1.transaction_id, t1.customer_id, t1.transaction_date, c.customer_name, t1.amount
    HAVING COUNT(*) > @FailedTransactionThreshold;

    -- 3. Off-Hours Transactions (Unusual Activity Hours)
    INSERT INTO @SuspiciousTransactions
    SELECT 
        t.transaction_id, t.customer_id, c.customer_name, t.amount, t.transaction_date,
        'Off-hours transaction outside normal activity patterns'
    FROM Transactions t
    INNER JOIN Customers c ON t.customer_id = c.customer_id
    WHERE (DATEPART(HOUR, t.transaction_date) BETWEEN 23 AND 4)
    AND t.transaction_date > @Yesterday
    AND NOT EXISTS (
        -- Check if the customer normally transacts at this hour
        SELECT 1 
        FROM Transactions prev
        WHERE prev.customer_id = t.customer_id
        AND DATEPART(HOUR, prev.transaction_date) = DATEPART(HOUR, t.transaction_date)
        AND prev.transaction_date BETWEEN DATEADD(month, -3, t.transaction_date) AND DATEADD(day, -1, t.transaction_date)
    );

    -- 4. Transactions Exceeding 3x Customer’s Average Amount
    INSERT INTO @SuspiciousTransactions
    SELECT 
        t.transaction_id, t.customer_id, c.customer_name, t.amount, t.transaction_date,
        'Amount exceeds 3x customer average: Current $' + CAST(t.amount AS VARCHAR) + ' vs Avg $' + CAST(avg_amount AS VARCHAR)
    FROM Transactions t
    INNER JOIN Customers c ON t.customer_id = c.customer_id
    CROSS APPLY (
        SELECT AVG(amount) AS avg_amount
        FROM Transactions
        WHERE customer_id = t.customer_id
        AND transaction_date BETWEEN DATEADD(month, -6, GETDATE()) AND @Yesterday
    ) AS customer_avg
    WHERE t.amount > customer_avg.avg_amount * 3
    AND t.transaction_date > @Yesterday;

    -- 5. Output Consolidated Suspicious Transactions with Prioritization
    SELECT 
        st.TransactionID,
        st.CustomerID,
        st.CustomerName,
        st.TransactionAmount,
        st.TransactionDate,
        COUNT(*) AS FlagCount,
        STRING_AGG(st.SuspicionReason, '; ') AS AllSuspicionReasons
    FROM @SuspiciousTransactions st
    INNER JOIN Customers c ON st.CustomerID = c.customer_id
    GROUP BY st.TransactionID, st.CustomerID, st.CustomerName, st.TransactionAmount, st.TransactionDate
    ORDER BY COUNT(*) DESC, st.TransactionAmount DESC;

END;



EXEC DetectPotentialFraud;

