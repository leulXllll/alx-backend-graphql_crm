#!/usr/bin/env python
from gql import Client, gql
from gql.transport.requests import RequestsHTTPTransport
from datetime import datetime, timedelta
import os

# Set up GraphQL client
transport = RequestsHTTPTransport(url="http://localhost:8000/graphql")
client = Client(transport=transport, fetch_schema_from_transport=True)

# GraphQL query for orders within the last 7 days
query = gql("""
    query {
        orders(orderDate_Gte: "%s") {
            id
            customer {
                email
            }
            orderDate
        }
    }
""" % (datetime.now() - timedelta(days=7)).isoformat())

# Execute query
try:
    result = client.execute(query)
    orders = result.get("orders", [])
    
    # Log to file
    with open("/tmp/order_reminders_log.txt", "a") as log_file:
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        for order in orders:
            log_file.write(f"{timestamp} - Order ID: {order['id']}, Customer Email: {order['customer']['email']}\n")
    
    print("Order reminders processed!")
except Exception as e:
    with open("/tmp/order_reminders_log.txt", "a") as log_file:
        log_file.write(f"{datetime.now().strftime('%Y-%m-%d %H:%M:%S')} - Error: {str(e)}\n")
    print("Order reminders processed!")