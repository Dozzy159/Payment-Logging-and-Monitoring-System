# 💳 Payment Transaction Logging & Monitoring System

**📅 Project**
**📍 Type:** Personal Project 
**🛠️ Technologies Used:** SQL Server, T-SQL, Python (Faker), Power BI

---

## 🧾 Project Overview

This project is a robust SQL-based system designed to **log, monitor, and analyze electronic fund transfers (EFTs)** across multiple payment channels including **POS terminals, ATMs, and online gateways**. It simulates a real-world transaction environment to detect fraud, monitor system performance, and visualize transaction trends using **Power BI**.

---

## 🚀 Key Features

- **Database Design:** Built a relational database schema to track transactions, merchants, terminals, customers, payment methods, and error logs.
- **Data Simulation:** Used Python's `Faker` library to generate realistic transactional and customer data.
- **Transaction Logging:** Logged transactions with timestamps, status codes, response codes, payment methods, and more.
- **Stored Procedures:**
  - `GetTransactionSummary`: Summarizes monthly transaction success and failure rates.
  - `DetectPotentialFraud`: Identifies suspicious activities such as off-hour transactions and abnormal spending patterns.
- **Trigger Logic:** Captures changes in transaction statuses in a dedicated log table for auditability.
- **Performance Optimization:** Indexed high-volume tables for faster data retrieval and reporting.
- **Data Visualization:** Created a Power BI view and dashboard for monitoring transaction metrics in real-time.

---

## 🗃️ Database Schema

The system includes the following tables:
- `Customers`, `Merchants`, `Terminals`, `Transactions`, `TransactionStatus`, `ResponseCodes`, `PaymentMethods`, `ErrorLogs`, and more.
- Relationships are enforced via foreign keys, with cascaded updates for integrity.
- Indexes are created on key columns such as `transaction_date`, `status_id`, and `customer_id`.

---

## 📊 Sample Analytics & Reports

- **Transaction Success Rate** by month and payment method.
- **Top Merchants** by revenue and failed transactions.
- **Daily and Hourly Trends** of transaction volume.
- **Common Error Messages** and failure reasons.
- **High-Risk Terminals** based on failure concentration.
- **High-Value Customers** by spend volume and frequency.

---

## 🧠 Fraud Detection Logic

The `DetectPotentialFraud` procedure flags:
1. **Rapid Transactions** within short time intervals.
2. **Multiple Failures** in a short window.
3. **Transactions During Off-Hours**.
4. **Spikes in Transaction Amounts** beyond customer average.

Each flag is logged with descriptive reasoning and prioritized by severity.

---
