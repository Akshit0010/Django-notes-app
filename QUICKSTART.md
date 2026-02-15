# Quick Start Guide

Get your Django Notes application running in minutes!

## Prerequisites

- Docker and Docker Compose installed
- Git installed
- Internet connection

## 5-Minute Setup

### 1. Get the Code

```bash
git clone <your-repo-url>
cd django-notes-app
```

### 2. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` if needed (the defaults work for local development).

### 3. Start the Application

**Option A: Using the start script**

```bash
chmod +x start.sh
./start.sh
```

**Option B: Using Make**

```bash
make build
make up
```

**Option C: Using Docker Compose directly**

```bash
docker-compose up -d --build
```

### 4. Access Your Application

- **Main App**: http://localhost
- **Admin Panel**: http://localhost/admin

**Default Admin Login:**
- Username: `admin`
- Password: `admin123`

## Common Commands

### View Logs
```bash
docker-compose logs -f
```

### Stop Application
```bash
docker-compose down
```

### Restart Application
```bash
docker-compose restart
```

### Access Django Shell
```bash
docker-compose exec web python manage.py shell
```

### Create New Superuser
```bash
docker-compose exec web python manage.py createsuperuser
```

### Run Migrations
```bash
docker-compose exec web python manage.py migrate
```

## Verify Installation

1. Open http://localhost in your browser
2. You should see the Notes application homepage
3. Click "Create New Note" to add your first note
4. Access admin panel at http://localhost/admin

## Troubleshooting

### Containers won't start

```bash
docker-compose down
docker-compose up -d --build
```

### Port 80 already in use

Edit `docker-compose.yml` and change:
```yaml
ports:
  - "8080:80"  # Changed from 80:80
```

Then access at http://localhost:8080

### Database connection issues

```bash
docker-compose down
docker-compose up -d
```

Wait 30 seconds for MySQL to initialize, then:

```bash
docker-compose restart web
```

## Next Steps

- Change the default admin password
- Read the full README.md for detailed information
- Check DEPLOYMENT.md for production deployment
- Customize the templates in `notes/templates/`

## Support

For detailed documentation, see:
- [README.md](README.md) - Full documentation
- [DEPLOYMENT.md](DEPLOYMENT.md) - Production deployment guide

---

Happy note-taking!
