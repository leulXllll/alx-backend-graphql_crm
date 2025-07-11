#!/bin/bash

# Get the directory of the script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change to the Django project directory (assuming manage.py is one level up from crm/cron_jobs)
if [ -d "$SCRIPT_DIR/../.." ]; then
    cd "$SCRIPT_DIR/../.." || exit 1
    cwd=$(pwd)
    echo "Changed to directory: $cwd"
else
    echo "Error: Could not change to Django project directory" | tee -a /tmp/customer_cleanup_log.txt
    exit 1
fi

# Execute Django command to delete customers with no orders in the past year
python manage.py shell -c "from django.utils import timezone; from datetime import timedelta; from crm.models import Customer; deleted_count, _ = Customer.objects.filter(orders__isnull=True, created_at__lt=timezone.now() - timedelta(days=365)).delete(); print(f'Deleted {deleted_count} inactive customers')" | tee -a /tmp/customer_cleanup_log.txt

# Append timestamp to log
echo "Cleanup executed at $(date)" >> /tmp/customer_cleanup_log.txt