#!/bin/bash

LOG_FILE="/tmp/customer_cleanup_log.txt"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


PROJECT_ROOT=$(dirname $(dirname "$SCRIPT_DIR"))

if [ ! -f "$PROJECT_ROOT/manage.py" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') Error: manage.py not found at $PROJECT_ROOT/manage.py. Please ensure the script is placed correctly or adjust PROJECT_ROOT." >> "$LOG_FILE"
    exit 1
fi

cd "$PROJECT_ROOT" || { echo "$(date '+%Y-%m-%d %H:%M:%S') Error: Could not change to project root directory $PROJECT_ROOT." >> "$LOG_FILE"; exit 1; }


python manage.py shell -c '
import os
import sys
from datetime import timedelta
from django.utils import timezone
from django.db.models import Q
from django.apps import apps

# Define the path for the log file (must match the shell script's LOG_FILE)
log_file_path = "/tmp/customer_cleanup_log.txt"

try:
    # Attempt to get the Customer and Order models from the "crm" app.
    # This assumes your Django app containing these models is named "crm".
    Customer = apps.get_model("crm", "Customer")
    Order = apps.get_model("crm", "Order")
except LookupError:
    # If models are not found, log an error message and exit the Python script.
    with open(log_file_path, "a") as f:
        timestamp = timezone.now().strftime("%Y-%m-%d %H:%M:%S")
        f.write(f"[{timestamp}] Error: Customer or Order model not found in \"crm\" app. Please ensure your models are correctly defined and \"crm\" is in INSTALLED_APPS.\\n")
    sys.exit(1) # Exit the Python script, which will cause the shell command to exit.

# Calculate the date one year ago from the current time (timezone-aware).
one_year_ago = timezone.now() - timedelta(days=365)


customers_to_delete = Customer.objects.exclude(order__order_date__gte=one_year_ago)

# Perform the deletion and capture the number of deleted objects.

num_deleted, _ = customers_to_delete.delete()

# Format the timestamp for the log entry.
timestamp = timezone.now().strftime("%Y-%m-%d %H:%M:%S")

# Create the log message.
log_message = f"[{timestamp}] Deleted {num_deleted} inactive customers.\\n"

# Append the log message to the specified log file.
with open(log_file_path, "a") as f:
    f.write(log_message)

# Optional: Print a confirmation to stdout (useful for debugging cron jobs).
# print(f"Cleanup script finished. Logged {num_deleted} deleted customers to {log_file_path}.")
'
