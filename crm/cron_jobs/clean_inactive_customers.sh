#!/bin/bash

# Execute Django command to delete inactive customers (no orders in the past year)
python manage.py shell -c "from django.utils import timezone; from datetime import timedelta; from crm.models import Customer; deleted_count, _ = Customer.objects.filter(last_order_date__lt=timezone.now() - timedelta(days=365)).delete(); print(f'Deleted {deleted_count} inactive customers') | tee -a /tmp/customer_cleanup_log.txt"

# Append timestamp to log
echo "Cleanup executed at $(date)" >> /tmp/customer_cleanup_log.txt