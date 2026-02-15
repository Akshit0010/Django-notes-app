#!/bin/bash

set -e

echo "Waiting for MySQL to be ready..."
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 1
done
echo "MySQL is ready!"

echo "Running database migrations..."
python manage.py migrate --noinput

echo "Creating superuser if not exists..."
python manage.py shell << END
from django.contrib.auth import get_user_model
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
    print('Superuser created: username=admin, password=admin123')
else:
    print('Superuser already exists')
END

echo "Collecting static files..."
python manage.py collectstatic --noinput

echo "Starting Gunicorn..."
exec gunicorn notesproject.wsgi:application -c gunicorn_config.py
