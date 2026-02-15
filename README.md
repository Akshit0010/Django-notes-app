# Django Notes Application

A production-ready Django Notes application with full CRUD functionality, MySQL database, Nginx reverse proxy, and Gunicorn WSGI server. The application is fully containerized using Docker for easy deployment.

## Features

- Create, Read, Update, and Delete notes
- Clean and responsive UI using Bootstrap 5
- MySQL database backend
- Nginx as reverse proxy
- Gunicorn as WSGI application server
- Fully containerized with Docker
- Production-ready configuration
- Environment variables support
- Django Admin interface

## Tech Stack

- **Backend**: Django 5.0.2
- **Database**: MySQL 8.0
- **Web Server**: Nginx (Alpine)
- **Application Server**: Gunicorn
- **Frontend**: Bootstrap 5.3.2
- **Containerization**: Docker & Docker Compose

## Project Structure

```
django-notes-app/
├── notesproject/              # Django project settings
│   ├── __init__.py
│   ├── settings.py           # Project settings with environment variables
│   ├── urls.py               # Main URL configuration
│   ├── wsgi.py               # WSGI configuration
│   └── asgi.py               # ASGI configuration
├── notes/                     # Notes application
│   ├── models.py             # Note model
│   ├── views.py              # CRUD views
│   ├── forms.py              # Note form
│   ├── urls.py               # App URL patterns
│   ├── admin.py              # Admin configuration
│   └── templates/            # HTML templates
│       └── notes/
│           ├── note_list.html
│           ├── note_detail.html
│           ├── note_form.html
│           └── note_confirm_delete.html
├── templates/                 # Base templates
│   └── base.html             # Base template with Bootstrap
├── static/                    # Static files directory
├── nginx/                     # Nginx configuration
│   └── nginx.conf            # Nginx reverse proxy config
├── manage.py                  # Django management script
├── requirements.txt           # Python dependencies
├── Dockerfile                 # Docker image for Django app
├── docker-compose.yml         # Docker Compose configuration
├── gunicorn_config.py        # Gunicorn configuration
├── entrypoint.sh             # Docker entrypoint script
├── .env.example              # Example environment variables
└── README.md                 # This file
```

## Prerequisites

- Docker and Docker Compose installed
- Git (for cloning the repository)

For manual deployment on Ubuntu server:
- Python 3.11+
- MySQL 8.0+
- Nginx
- pip and virtualenv

## Quick Start with Docker

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd django-notes-app
```

### 2. Set Up Environment Variables

Copy the example environment file and update it:

```bash
cp .env.example .env
```

Edit `.env` file with your configurations:

```env
SECRET_KEY=your-super-secret-key-here
DEBUG=False
ALLOWED_HOSTS=localhost,127.0.0.1,yourdomain.com

DB_NAME=notes_db
DB_USER=notes_user
DB_PASSWORD=your-secure-password
DB_HOST=db
DB_PORT=3306

MYSQL_ROOT_PASSWORD=your-root-password
```

**Important**: For production, generate a secure SECRET_KEY:

```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 3. Build and Run with Docker Compose

```bash
docker-compose up -d --build
```

This will:
- Build the Django application container
- Start MySQL database
- Run database migrations
- Create a default superuser (username: `admin`, password: `admin123`)
- Collect static files
- Start Gunicorn server
- Start Nginx reverse proxy

### 4. Access the Application

- **Main Application**: http://localhost
- **Django Admin**: http://localhost/admin

Default admin credentials:
- Username: `admin`
- Password: `admin123`

**Important**: Change the default admin password immediately after first login!

### 5. Common Docker Commands

```bash
# View logs
docker-compose logs -f

# Stop containers
docker-compose down

# Restart containers
docker-compose restart

# Access Django shell
docker-compose exec web python manage.py shell

# Create new superuser
docker-compose exec web python manage.py createsuperuser

# Run migrations
docker-compose exec web python manage.py migrate

# Collect static files
docker-compose exec web python manage.py collectstatic --noinput
```

## Manual Deployment on Ubuntu Server

### 1. Update System

```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Install Dependencies

```bash
# Install Python and pip
sudo apt install python3.11 python3.11-venv python3-pip -y

# Install MySQL
sudo apt install mysql-server mysql-client libmysqlclient-dev -y

# Install Nginx
sudo apt install nginx -y

# Install build essentials
sudo apt install build-essential pkg-config -y
```

### 3. Set Up MySQL Database

```bash
sudo mysql -u root -p
```

In MySQL shell:

```sql
CREATE DATABASE notes_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'notes_user'@'localhost' IDENTIFIED BY 'your-secure-password';
GRANT ALL PRIVILEGES ON notes_db.* TO 'notes_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 4. Set Up Application

```bash
# Clone repository
cd /opt
sudo git clone <your-repo-url> django-notes-app
cd django-notes-app

# Create virtual environment
python3.11 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 5. Configure Environment

```bash
# Copy and edit environment file
cp .env.example .env
nano .env
```

Update with your production settings:

```env
SECRET_KEY=your-generated-secret-key
DEBUG=False
ALLOWED_HOSTS=your-server-ip,yourdomain.com

DB_NAME=notes_db
DB_USER=notes_user
DB_PASSWORD=your-secure-password
DB_HOST=localhost
DB_PORT=3306
```

### 6. Run Django Setup

```bash
# Run migrations
python manage.py migrate

# Create superuser
python manage.py createsuperuser

# Collect static files
python manage.py collectstatic --noinput

# Test the application
python manage.py runserver 0.0.0.0:8000
```

### 7. Set Up Gunicorn as Systemd Service

Create service file:

```bash
sudo nano /etc/systemd/system/gunicorn.service
```

Add this configuration:

```ini
[Unit]
Description=Gunicorn daemon for Django Notes App
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/django-notes-app
Environment="PATH=/opt/django-notes-app/venv/bin"
EnvironmentFile=/opt/django-notes-app/.env
ExecStart=/opt/django-notes-app/venv/bin/gunicorn \
          --config /opt/django-notes-app/gunicorn_config.py \
          notesproject.wsgi:application

[Install]
WantedBy=multi-user.target
```

Set permissions and start service:

```bash
sudo chown -R www-data:www-data /opt/django-notes-app
sudo systemctl daemon-reload
sudo systemctl start gunicorn
sudo systemctl enable gunicorn
sudo systemctl status gunicorn
```

### 8. Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/django-notes
```

Add this configuration:

```nginx
upstream django_app {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name your-server-ip yourdomain.com;
    client_max_body_size 10M;

    location / {
        proxy_pass http://django_app;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
    }

    location /static/ {
        alias /opt/django-notes-app/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias /opt/django-notes-app/media/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/django-notes /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable nginx
```

### 9. Set Up Firewall

```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw enable
```

### 10. Optional: Set Up SSL with Let's Encrypt

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d yourdomain.com
```

## Usage

### Creating a Note

1. Navigate to the home page
2. Click "Create New Note" button
3. Fill in the title and description
4. Click "Create Note"

### Viewing Notes

- All notes are displayed on the home page
- Click "View" button on any note to see full details

### Editing a Note

1. Click "Edit" button on a note
2. Update the title or description
3. Click "Update Note"

### Deleting a Note

1. Click "Delete" button on a note
2. Confirm deletion on the confirmation page

## API Endpoints

- `/` - List all notes
- `/note/<id>/` - View single note
- `/note/create/` - Create new note
- `/note/<id>/update/` - Update existing note
- `/note/<id>/delete/` - Delete note
- `/admin/` - Django admin interface

## Database Schema

### Note Model

| Field | Type | Description |
|-------|------|-------------|
| id | Integer | Primary key (auto-generated) |
| title | CharField(200) | Note title |
| description | TextField | Note content |
| created_at | DateTimeField | Automatic creation timestamp |
| updated_at | DateTimeField | Automatic update timestamp |

## Troubleshooting

### Database Connection Issues

```bash
# Check MySQL is running
sudo systemctl status mysql

# Test database connection
docker-compose exec web python manage.py dbshell
```

### Static Files Not Loading

```bash
# Collect static files again
docker-compose exec web python manage.py collectstatic --noinput

# Or for manual deployment
python manage.py collectstatic --noinput
```

### Gunicorn Not Starting

```bash
# Check logs
sudo journalctl -u gunicorn -f

# Restart service
sudo systemctl restart gunicorn
```

### Nginx Errors

```bash
# Check Nginx configuration
sudo nginx -t

# View error logs
sudo tail -f /var/log/nginx/error.log
```

## Maintenance

### Backup Database

```bash
# Docker deployment
docker-compose exec db mysqldump -u notes_user -p notes_db > backup.sql

# Manual deployment
mysqldump -u notes_user -p notes_db > backup.sql
```

### Restore Database

```bash
# Docker deployment
docker-compose exec -T db mysql -u notes_user -p notes_db < backup.sql

# Manual deployment
mysql -u notes_user -p notes_db < backup.sql
```

### Update Application

```bash
# Docker deployment
git pull origin main
docker-compose down
docker-compose up -d --build

# Manual deployment
git pull origin main
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart gunicorn
```

## Security Recommendations

1. **Change default admin password** immediately after first login
2. **Use strong SECRET_KEY** in production
3. **Set DEBUG=False** in production
4. **Use HTTPS** with SSL certificate
5. **Regular security updates** for all packages
6. **Set up database backups**
7. **Configure proper firewall rules**
8. **Use strong database passwords**
9. **Limit ALLOWED_HOSTS** to your domain only
10. **Regular security audits**

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is open source and available under the MIT License.

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review Django documentation: https://docs.djangoproject.com/

## Acknowledgments

- Django Framework
- Bootstrap
- Nginx
- Gunicorn
- MySQL
- Docker

---

**Note**: This is a production-ready setup, but always review and adjust security settings based on your specific requirements.
