# Complete File Reference

This document describes every file in the Django Notes application.

## Project Root Files

### `manage.py`
Django's command-line utility for administrative tasks.
- Used to run migrations, create superusers, run the server, etc.
- Standard Django file, no modifications needed.

### `requirements.txt`
Python package dependencies.
```
Django==5.0.2           # Web framework
mysqlclient==2.2.4      # MySQL database adapter
gunicorn==21.2.0        # WSGI application server
python-dotenv==1.0.1    # Environment variable management
whitenoise==6.6.0       # Static file serving
```

### `.env.example`
Template for environment variables. Copy to `.env` before running.
```env
SECRET_KEY=...              # Django secret key
DEBUG=False                 # Debug mode (False for production)
ALLOWED_HOSTS=...           # Allowed domain names

DB_NAME=notes_db            # Database name
DB_USER=notes_user          # Database user
DB_PASSWORD=...             # Database password
DB_HOST=db                  # Database host (or localhost)
DB_PORT=3306                # Database port

MYSQL_ROOT_PASSWORD=...     # MySQL root password
```

### `.env`
Actual environment variables file (created from .env.example).
Update with your specific settings before running.

### `.gitignore`
Git ignore rules - prevents committing:
- Python bytecode (`__pycache__/`, `*.pyc`)
- Virtual environment (`venv/`)
- Environment variables (`.env`)
- Database files (`db.sqlite3`)
- Static files (`staticfiles/`)
- Log files (`*.log`)

### `Dockerfile`
Docker image definition for the Django application.
- Uses Python 3.11 slim base image
- Installs MySQL client and build tools
- Copies code and requirements
- Collects static files
- Exposes port 8000 for Gunicorn

### `docker-compose.yml`
Multi-container orchestration file.
- **db**: MySQL 8.0 database service
- **web**: Django application with Gunicorn
- **nginx**: Nginx reverse proxy
- **Volumes**: Persistent storage for database, static files, media
- **Networks**: Internal communication between services
- **Health checks**: Ensures services are ready before starting dependents

### `entrypoint.sh`
Docker startup script that runs when container starts.
Steps:
1. Waits for MySQL to be ready
2. Runs database migrations
3. Creates default admin user (admin/admin123) if not exists
4. Collects static files
5. Starts Gunicorn server

### `gunicorn_config.py`
Gunicorn WSGI server configuration.
```python
bind = "0.0.0.0:8000"           # Listen on all interfaces, port 8000
workers = cpu_count * 2 + 1     # Optimal worker count
worker_class = "sync"           # Synchronous worker
max_requests = 1000             # Restart worker after 1000 requests
timeout = 30                    # Worker timeout
keepalive = 2                   # Keep-alive timeout
accesslog = "-"                 # Log to stdout
errorlog = "-"                  # Log to stderr
```

### `Makefile`
Convenient commands for development.
```bash
make build          # Build Docker images
make up             # Start containers
make down           # Stop containers
make restart        # Restart containers
make logs           # View logs
make migrate        # Run migrations
make createsuperuser # Create admin user
make collectstatic  # Collect static files
```

### `start.sh`
Quick start script for development.
- Checks if .env exists
- Builds Docker images
- Starts containers
- Displays access information

---

## Django Project Configuration (`notesproject/`)

### `notesproject/__init__.py`
Empty Python package marker file.

### `notesproject/settings.py`
Main Django configuration file.
```python
# Core settings
SECRET_KEY          # Secret key for cryptographic operations
DEBUG              # Debug mode (False in production)
ALLOWED_HOSTS      # Allowed domain names

# Installed apps
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'notes',  # Our notes app
]

# Middleware stack
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # Static file serving
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# Database configuration (MySQL)
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'notes_db',
        'USER': 'notes_user',
        'PASSWORD': '...',
        'HOST': 'db',  # or localhost
        'PORT': '3306',
    }
}

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = 'staticfiles/'
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Security settings (production)
SECURE_SSL_REDIRECT = False  # Set to True with HTTPS
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_BROWSER_XSS_FILTER = True
```

### `notesproject/urls.py`
Main URL router for the project.
```python
urlpatterns = [
    path('admin/', admin.site.urls),        # /admin/
    path('', include('notes.urls')),        # / and /note/*
]
```

### `notesproject/wsgi.py`
WSGI application entry point.
- Used by Gunicorn to run the application
- Creates the WSGI application instance

### `notesproject/asgi.py`
ASGI application entry point (for async support).
- Not used in this basic setup but available for future enhancements

---

## Notes Application (`notes/`)

### `notes/__init__.py`
Empty Python package marker file.

### `notes/apps.py`
Application configuration.
```python
class NotesConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'notes'
```

### `notes/models.py`
Database models defining the data structure.

**Note Model:**
```python
class Note(models.Model):
    title = CharField(max_length=200)        # Note title
    description = TextField()                # Note content
    created_at = DateTimeField(auto_now_add=True)  # Auto-set on creation
    updated_at = DateTimeField(auto_now=True)      # Auto-updated on save

    class Meta:
        ordering = ['-created_at']  # Sort by newest first
```

### `notes/views.py`
CRUD view functions.

**Functions:**
- `note_list()` - Display all notes
- `note_detail(pk)` - Show single note details
- `note_create()` - Create new note (GET: show form, POST: save)
- `note_update(pk)` - Edit existing note
- `note_delete(pk)` - Delete note with confirmation

All views:
- Use Django shortcuts (render, redirect, get_object_or_404)
- Display success messages
- Return appropriate templates
- Handle both GET and POST requests

### `notes/forms.py`
Django form for Note model.

**NoteForm:**
```python
class NoteForm(forms.ModelForm):
    class Meta:
        model = Note
        fields = ['title', 'description']
        widgets = {
            'title': TextInput(attrs={'class': 'form-control'}),
            'description': Textarea(attrs={'class': 'form-control', 'rows': 5}),
        }
```
- Uses Bootstrap CSS classes
- Auto-generates HTML form fields
- Built-in validation

### `notes/urls.py`
URL patterns for the notes app.

```python
path('', notes.note_list, name='note_list')                    # /
path('note/<int:pk>/', notes.note_detail, name='note_detail')  # /note/1/
path('note/create/', notes.note_create, name='note_create')    # /note/create/
path('note/<int:pk>/update/', notes.note_update, name='note_update')  # /note/1/update/
path('note/<int:pk>/delete/', notes.note_delete, name='note_delete')  # /note/1/delete/
```

### `notes/admin.py`
Django admin interface configuration.

**NoteAdmin:**
- `list_display`: Shows title, created_at, updated_at in list view
- `list_filter`: Filter by creation/update date
- `search_fields`: Search by title and description
- `readonly_fields`: Can't edit timestamps (auto-set)
- `date_hierarchy`: Navigate by date in admin

---

## Templates (`templates/`)

### `templates/base.html`
Base template extended by all pages.

**Includes:**
- HTML5 doctype and meta tags
- Bootstrap 5.3.2 CSS from CDN
- Bootstrap Icons font
- Custom CSS styles:
  - Blue gradient primary color
  - Light gray background gradient
  - Card hover animations
  - Button transitions
  - Bootstrap form styling
- Navigation bar with logo and menu
- Message alerts system
- Block for page content
- Bootstrap JS bundle

**Navigation:**
- Logo/Home link
- All Notes link
- New Note link
- Admin link
- Mobile responsive hamburger menu

**Styles:**
```css
--primary-color: #2563eb           /* Blue */
--secondary-color: #64748b         /* Gray */

.card:hover {
    transform: translateY(-5px);   /* Lift effect */
    box-shadow: enhanced;          /* More shadow */
}

.btn-primary:hover {
    transform: translateY(-2px);   /* Button lift */
    box-shadow: glow;              /* Blue glow */
}
```

---

## Notes App Templates (`notes/templates/notes/`)

### `notes/templates/notes/note_list.html`
Homepage showing all notes in a responsive grid.

**Layout:**
- Header with "My Notes" title and "Create New Note" button
- Grid of note cards (3 columns on desktop)
- Each card shows:
  - Note title
  - First 20 words of description
  - Creation date
  - Update date (if different from creation)
  - View, Edit, Delete buttons
- Empty state message if no notes exist

**Features:**
- Responsive grid (col-md-6 col-lg-4)
- Card hover animations
- Truncated descriptions
- Color-coded timestamps

### `notes/templates/notes/note_detail.html`
Full note view page.

**Content:**
- Back to notes link
- Full note title (large)
- Creation and update timestamps as badges
- Full description with preserved formatting
- Edit and Delete buttons
- Horizontal separator line

**Features:**
- Full untruncated text
- Preserved line breaks
- Multiple action buttons
- Back navigation

### `notes/templates/notes/note_form.html`
Create and edit note form (same template for both).

**Content:**
- Back to notes link
- Title showing "Create Note" or "Update Note"
- Form with CSRF token
- Title input field with validation errors
- Description textarea with validation errors
- Submit button (Create/Update)
- Cancel button

**Features:**
- Context variable `action` determines title
- Inline error messages below fields
- Required field indicators
- Form styling with Bootstrap classes

### `notes/templates/notes/note_confirm_delete.html`
Delete confirmation page.

**Content:**
- Back to notes link
- Warning icon and title
- Alert box warning about permanent deletion
- Preview of the note being deleted
- Confirmation buttons: "Yes, Delete" and "Cancel"

**Features:**
- Warning styling
- Double confirmation
- Preview of target note
- Safe cancel option

---

## Nginx Configuration (`nginx/`)

### `nginx/nginx.conf`
Reverse proxy configuration.

```nginx
upstream django_app {
    server web:8000;  # Points to Gunicorn
}

server {
    listen 80;
    server_name localhost;
    client_max_body_size 10M;

    location / {
        proxy_pass http://django_app;           # Forward to Django
        proxy_set_header X-Forwarded-For ...    # Original IP
        proxy_set_header Host ...               # Original host
        proxy_set_header X-Real-IP ...          # Real client IP
    }

    location /static/ {
        alias /app/staticfiles/;                # Static files
        expires 30d;                            # Cache for 30 days
    }

    location /media/ {
        alias /app/media/;                      # User uploaded files
        expires 30d;
    }
}
```

**Functions:**
- Listens on port 80
- Routes all requests to Django via Gunicorn
- Serves static files (CSS, JS, icons) directly
- Serves media files (user uploads) directly
- Sets proper HTTP headers
- Implements caching

---

## Static Files (`static/`)

### `static/.gitkeep`
Empty marker file to keep the directory in Git.
- Actual static files are collected during `collectstatic`
- Bootstrap CSS/JS come from CDN (not stored locally)

---

## Documentation Files

### `README.md`
Complete project documentation.
- Overview of the application
- Tech stack details
- Project structure
- Quick start with Docker
- Manual deployment on Ubuntu
- Usage guide
- Troubleshooting
- Security recommendations

### `QUICKSTART.md`
Fast setup guide for development.
- Prerequisites
- 5-minute setup steps
- Common commands
- Verification steps
- Next steps

### `DEPLOYMENT.md`
Production deployment guide.
- Pre-deployment checklist
- Docker deployment instructions
- Manual Ubuntu deployment (step-by-step)
- AWS EC2 deployment
- Security hardening
- Monitoring and logging
- Backup strategy
- Maintenance tasks
- Troubleshooting
- Performance optimization

### `PREVIEW.md`
Visual preview of the application (this file demonstrates the UI).
- ASCII diagrams of each page
- Feature descriptions
- Design details
- Navigation flow
- Database schema
- How to access the app

### `FILE_REFERENCE.md`
This file - complete reference for all project files.

---

## Development Workflow

### Creating a Note
1. User visits http://localhost
2. Clicks "Create New Note"
3. Browser requests `/note/create/`
4. Django view `note_create()` renders `note_form.html` with empty form
5. User fills title and description
6. Browser POSTs to `/note/create/`
7. `note_create()` validates form and saves to database
8. Redirect to home with success message

### Viewing Notes
1. User visits http://localhost or clicks "All Notes"
2. Browser requests `/`
3. Django view `note_list()` queries all notes
4. Renders `note_list.html` with note cards
5. Database returns all notes sorted by creation date (newest first)

### Editing a Note
1. User clicks "Edit" on a note card
2. Browser requests `/note/1/update/`
3. Django view `note_update()` loads note with pk=1
4. Renders `note_form.html` with pre-filled form
5. User modifies content
6. Browser POSTs to `/note/1/update/`
7. View saves changes and redirects to note detail

### Deleting a Note
1. User clicks "Delete" on a note
2. Browser requests `/note/1/delete/`
3. Django view `note_delete()` shows confirmation page
4. User confirms deletion
5. Browser POSTs to `/note/1/delete/`
6. View deletes note and redirects to home

---

## Database Initialization

When `entrypoint.sh` runs (Docker startup):

```bash
# 1. Wait for MySQL
while ! nc -z $DB_HOST $DB_PORT; do
  sleep 1
done

# 2. Run migrations
python manage.py migrate
# Creates all Django tables including notes_note table

# 3. Create admin user
python manage.py shell << END
User = get_user_model()
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@example.com', 'admin123')
END

# 4. Collect static files
python manage.py collectstatic --noinput

# 5. Start Gunicorn
gunicorn notesproject.wsgi:application -c gunicorn_config.py
```

This ensures:
- Database is ready
- All tables are created
- Default admin user exists
- Static files are available
- Server is running and ready

---

## Request Flow

```
User Request
    ↓
Nginx (port 80) ← Reverse proxy
    ↓
Gunicorn (port 8000) ← Application server
    ↓
Django ← Web framework
    ↓
URL Router (urls.py) ← Route matching
    ↓
View Function (views.py) ← Business logic
    ↓
Model (models.py) ← Database query
    ↓
MySQL ← Database
    ↓
(Return data)
    ↓
Template (*.html) ← Render HTML
    ↓
Gunicorn ← Return HTTP response
    ↓
Nginx ← Forward to client
    ↓
User Browser ← Display page
```

---

## Security Features Implemented

1. **CSRF Protection**: `{% csrf_token %}` in all forms
2. **XSS Filtering**: Django template auto-escaping
3. **SQL Injection Prevention**: Django ORM with parameterized queries
4. **Secure Cookies**: `SESSION_COOKIE_SECURE = True`
5. **Security Headers**: `X_FRAME_OPTIONS = 'DENY'`
6. **Environment Variables**: Secrets in .env, not in code
7. **Admin Panel**: Protected with authentication
8. **Debug Mode**: Disabled in production (`DEBUG=False`)

---

## Performance Optimizations

1. **Gunicorn Workers**: Calculated based on CPU count
2. **Static File Caching**: 30-day expiration in Nginx
3. **WhiteNoise**: Efficient static file serving
4. **Request Pooling**: Gunicorn connection management
5. **Worker Restart**: Fresh workers every 1000 requests
6. **Timeout Management**: Prevents hung processes
7. **Database Indexing**: Django handles automatically

---

## Summary

This complete Django Notes application includes:
- ✅ Full CRUD functionality
- ✅ MySQL database integration
- ✅ Responsive Bootstrap 5 UI
- ✅ Production-ready configuration
- ✅ Docker containerization
- ✅ Nginx reverse proxy
- ✅ Gunicorn WSGI server
- ✅ Admin interface
- ✅ Security best practices
- ✅ Comprehensive documentation

All files are production-ready and follow Django best practices!
