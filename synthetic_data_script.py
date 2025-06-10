# Create synthetic data for a payment transaction database
# Import the necessary libraries
import random
import pandas as pd
from faker import Faker
from datetime import datetime, timedelta

fake = Faker()

# Number of records for each table
NUM_CUSTOMERS = 5000
NUM_CURRENCIES = 1  # Only "NGN"
NUM_TRANSACTION_STATUSES = 3
NUM_RESPONSE_CODES = 5
NUM_PAYMENT_METHODS = 3
NUM_MERCHANT_TYPES = 5
NUM_TERMINAL_TYPES = 3
NUM_MERCHANTS = 500
NUM_TERMINALS = 1000
NUM_TRANSACTIONS = 100000

# Ensure date ranges from 2020 to 2025
def random_date():
    return fake.date_time_between(start_date="-4y", end_date="+1y")

# 1 Generate Customers
customers = {}
customers_list = []
for i in range(1, NUM_CUSTOMERS + 1):
    name = fake.name()
    email = fake.email()
    created_at = random_date()
    customers[i] = (name, email)
    customers_list.append([i, name, fake.phone_number(), email, created_at])

df_customers = pd.DataFrame(customers_list, columns=["customer_id", "customer_name", "phone_number", "email", "created_at"])

# 2 Generate Currencies
currencies = [[1, "NGN"]]
df_currencies = pd.DataFrame(currencies, columns=["currency_id", "currency_code"])

# 3 Generate Transaction Statuses
transaction_statuses = [[i, status] for i, status in enumerate(["Success", "Pending", "Failed"], start=1)]
df_transaction_statuses = pd.DataFrame(transaction_statuses, columns=["status_id", "status_name"])

# 4 Generate Response Codes
response_code_map = {
    "00": "Transaction Approved",
    "05": "Do Not Honor",
    "51": "Insufficient Funds",
    "57": "Transaction Not Permitted",
    "96": "System Malfunction"
}
response_codes = [[i, code, desc] for i, (code, desc) in enumerate(response_code_map.items(), start=1)]
df_response_codes = pd.DataFrame(response_codes, columns=["response_code_id", "response_code", "description"])

# 5 Generate Payment Methods
payment_methods = [[i, method] for i, method in enumerate(["Debit Card", "Bank Transfer", "Online Payment"], start=1)]
df_payment_methods = pd.DataFrame(payment_methods, columns=["payment_method_id", "payment_method_name"])

# 6 Generate Merchant Types
merchant_types = [[i, fake.company()] for i in range(1, NUM_MERCHANT_TYPES + 1)]
df_merchant_types = pd.DataFrame(merchant_types, columns=["merchant_type_id", "merchant_type_name"])

# 7 Generate Terminal Types
terminal_types = [[i, fake.word().capitalize() + " Terminal"] for i in range(1, NUM_TERMINAL_TYPES + 1)]
df_terminal_types = pd.DataFrame(terminal_types, columns=["terminal_type_id", "terminal_type_name"])

# 8 Generate Merchants
merchants = [
    [i + 100, fake.company(), random.randint(1, NUM_MERCHANT_TYPES), fake.city(), random_date()]
    for i in range(NUM_MERCHANTS)
]
df_merchants = pd.DataFrame(merchants, columns=["merchant_id", "merchant_name", "merchant_type_id", "location", "registered_date"])

# 9 Generate Terminals
terminals = [
    [i + 500, random.randint(100, 100 + NUM_MERCHANTS - 1), random.randint(1, NUM_TERMINAL_TYPES), fake.city()]
    for i in range(NUM_TERMINALS)
]
df_terminals = pd.DataFrame(terminals, columns=["terminal_id", "merchant_id", "terminal_type_id", "location"])

# 10 Generate Transactions
transactions = []
for _ in range(NUM_TRANSACTIONS):
    transaction_id = _
    transaction_date = random_date()
    amount = round(random.uniform(10, 500000), 2)
    currency_id = 1  # NGN
    status_id = random.randint(1, NUM_TRANSACTION_STATUSES)
    response_code_id = random.randint(1, NUM_RESPONSE_CODES)
    merchant_id = random.randint(100, 100 + NUM_MERCHANTS - 1)
    terminal_id = random.randint(500, 500 + NUM_TERMINALS - 1)
    payment_method_id = random.randint(1, NUM_PAYMENT_METHODS)
    customer_id = random.randint(1, NUM_CUSTOMERS)
    remarks = fake.sentence(nb_words=4, variable_nb_words=False)
    
    transactions.append([
        transaction_id, transaction_date, amount, currency_id, status_id,
        response_code_id, merchant_id, terminal_id, payment_method_id,
        customer_id, remarks
    ])

df_transactions = pd.DataFrame(transactions, columns=[
    "transaction_id", "transaction_date", "amount", "currency_id", "status_id",
    "response_code_id", "merchant_id", "terminal_id", "payment_method_id",
    "customer_id", "remarks"
])

# Save Data to CSV
df_customers.to_csv("customers.csv", index=False)
df_currencies.to_csv("currencies.csv", index=False)
df_transaction_statuses.to_csv("transaction_statuses.csv", index=False)
df_response_codes.to_csv("response_codes.csv", index=False)
df_payment_methods.to_csv("payment_methods.csv", index=False)
df_merchant_types.to_csv("merchant_types.csv", index=False)
df_terminal_types.to_csv("terminal_types.csv", index=False)
df_merchants.to_csv("merchants.csv", index=False)
df_terminals.to_csv("terminals.csv", index=False)
df_transactions.to_csv("transactions.csv", index=False)

print("Data generated successfully! Ready for SQL import.")
