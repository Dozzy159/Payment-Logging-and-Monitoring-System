
-- Create the database for the payment logging and monitoring system
DROP DATABASE IF EXISTS PaymentLoggingDB;
CREATE DATABASE PaymentLoggingDB;
USE PaymentLoggingDB;

-- Create the Customers Table
CREATE TABLE Customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15), -- (000-0000-0000)
    email VARCHAR(255), -- (%.%@gmail.com)
    created_at DATETIME DEFAULT GETDATE()
);

-- Create the Currencies Table
CREATE TABLE Currencies (
    currency_id INT IDENTITY(1,1) PRIMARY KEY,
    currency_code VARCHAR(3) UNIQUE NOT NULL -- (NGN)
);

-- Create the TransactionStatus Table
CREATE TABLE TransactionStatus (
    status_id INT IDENTITY(1,1) PRIMARY KEY,
    status_name VARCHAR(50) UNIQUE NOT NULL -- (Failed, Pending, Success)
);

-- Create the ResponseCodes Table
CREATE TABLE ResponseCodes (
    response_code_id INT IDENTITY(1,1) PRIMARY KEY,
    response_code VARCHAR(5) UNIQUE NOT NULL, -- (00, 05, 51, 57, 96)
    description VARCHAR(255) NOT NULL -- (Transaction Approved, Do Not Honor, Insufficient Funds, Transaction Not Permitted, System Malfunction)
);

-- Create the PaymentMethods Table
CREATE TABLE PaymentMethods (
    payment_method_id INT IDENTITY(1,1) PRIMARY KEY,
    payment_method_name VARCHAR(50) UNIQUE NOT NULL -- (Debit Card, Bank Transfer, Online Payment)
);

-- Create the MerchantTypes Table
CREATE TABLE MerchantTypes (
    merchant_type_id INT IDENTITY(1,1) PRIMARY KEY,
    merchant_type_name VARCHAR(50) UNIQUE NOT NULL
);

-- Create the TerminalTypes Table
CREATE TABLE TerminalTypes (
    terminal_type_id INT IDENTITY(1,1) PRIMARY KEY,
    terminal_type_name VARCHAR(50) UNIQUE NOT NULL
);

-- Create the Merchants Table
CREATE TABLE Merchants (
    merchant_id INT IDENTITY(100,1) PRIMARY KEY,
    merchant_name NVARCHAR(255) NOT NULL,
    merchant_type_id INT NOT NULL,
    location NVARCHAR(255),
    registered_date DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (merchant_type_id) REFERENCES MerchantTypes(merchant_type_id)
);

-- Create the Terminals Table
CREATE TABLE Terminals (
    terminal_id INT IDENTITY(500,1) PRIMARY KEY,
    merchant_id INT NOT NULL,
    terminal_type_id INT NOT NULL,
    location VARCHAR(255),
    FOREIGN KEY (merchant_id) REFERENCES Merchants(merchant_id),
    FOREIGN KEY (terminal_type_id) REFERENCES TerminalTypes(terminal_type_id)
);

-- Create the Transactions Table
CREATE TABLE Transactions (
    transaction_id INT IDENTITY(1,1) PRIMARY KEY,
    transaction_date DATETIME DEFAULT GETDATE(),
    amount DECIMAL(18,2) NOT NULL,
    currency_id INT NOT NULL,
    status_id INT NOT NULL,
    response_code_id INT NOT NULL,
    merchant_id INT NOT NULL,
    terminal_id INT NOT NULL,
    payment_method_id INT NOT NULL,
    customer_id INT NULL,
    remarks NVARCHAR(255),
    FOREIGN KEY (currency_id) REFERENCES Currencies(currency_id),
    FOREIGN KEY (status_id) REFERENCES TransactionStatus(status_id),
    FOREIGN KEY (response_code_id) REFERENCES ResponseCodes(response_code_id),
    FOREIGN KEY (merchant_id) REFERENCES Merchants(merchant_id),
    FOREIGN KEY (terminal_id) REFERENCES Terminals(terminal_id),
    FOREIGN KEY (payment_method_id) REFERENCES PaymentMethods(payment_method_id),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- Create the TransactionLogs Table
CREATE TABLE TransactionLogs (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id INT NOT NULL,
    status_id INT NOT NULL,
    response_code_id INT NOT NULL,
    changed_at DATETIME DEFAULT GETDATE(),
    changed_by VARCHAR(255), -- Can store system/user modifying it
    remarks NVARCHAR(255),
    FOREIGN KEY (transaction_id) REFERENCES Transactions(transaction_id),
    FOREIGN KEY (status_id) REFERENCES TransactionStatus(status_id),
    FOREIGN KEY (response_code_id) REFERENCES ResponseCodes(response_code_id)
);

-- Create the ErrorLogs Table
CREATE TABLE ErrorLogs (
    error_id INT IDENTITY(1,1) PRIMARY KEY,
    transaction_id INT NULL,
    error_message NVARCHAR(255) NOT NULL,
    error_code VARCHAR(10) NOT NULL, 
    occurred_at DATETIME DEFAULT GETDATE()
);


-- Create Indexes for faster query speed on data retrieval
CREATE INDEX idx_transaction_date ON Transactions(transaction_date);
CREATE INDEX idx_status_id ON Transactions(status_id);
CREATE INDEX idx_customer_id ON Transactions(customer_id);

-- Create a view to aggregate data for easy ETL to Power BI
CREATE VIEW vw_TransactionSummary AS 
SELECT 
    t.transaction_id,
    t.transaction_date,
    t.amount,
    c.currency_code,
    ts.status_name,
    rc.response_code,
    rc.description AS response_description,
    pm.payment_method_name,
    m.merchant_name,
    cu.customer_name
FROM Transactions t
INNER JOIN Currencies c
	ON t.currency_id = c.currency_id
INNER JOIN TransactionStatus ts 
	ON t.status_id = ts.status_id
INNER JOIN ResponseCodes rc 
	ON t.response_code_id = rc.response_code_id
INNER JOIN PaymentMethods pm 
	ON t.payment_method_id = pm.payment_method_id
INNER JOIN Merchants m 
	ON t.merchant_id = m.merchant_id
LEFT JOIN Customers cu 
	ON t.customer_id = cu.customer_id;

-- Alter the TransactionLogs Table to contain Previous Transaction Status
ALTER TABLE TransactionLogs ADD old_status_id INT NULL;

-- Update the old_status_id column
UPDATE tl
SET old_status_id = t.status_id
FROM TransactionLogs tl
INNER JOIN Transactions t 
	ON tl.transaction_id = t.transaction_id
WHERE tl.old_status_id IS NULL;

-- Status Change Trigger
CREATE TRIGGER trg_TransactionStatusChange
ON Transactions
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO TransactionLogs (transaction_id, old_status_id, status_id, response_code_id, changed_at, changed_by, remarks)
    SELECT 
        d.transaction_id, 
        d.status_id AS old_status_id,  -- Captures the previous status
        i.status_id AS status_id,      -- Captures the new status
        i.response_code_id,            -- Captures the response code
        GETDATE(), 
        SUSER_NAME(),                  -- Captures the user making the change
        'Status updated'
    FROM deleted d
    INNER JOIN inserted i 
		ON d.transaction_id = i.transaction_id
    WHERE d.status_id <> i.status_id;  -- Only log the actual changes
END;

