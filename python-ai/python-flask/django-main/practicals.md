# Django + DRF — 10 Hands-On Projects

## Project 1: Blog Platform
**Goal**: Full blog with Django + DRF backend and browsable API

### Models
- `Post`: title, slug, content, author (FK User), category, status, tags (M2M), views
- `Category`: name, slug
- `Tag`: name, slug
- `Comment`: post (FK), author, content, is_approved

### Features
- CRUD for posts (admin can manage all, users manage own)
- DRF serializers for list view (compact) and detail view (full)
- Filtering: by category, tag, status, author
- Search: full-text on title + content
- Pagination: 10 per page
- Comment system with moderation (is_approved filter)

### Admin
- Post admin with list_editable for status
- Bulk publish/unpublish actions
- Comment inline in Post admin

---

## Project 2: Todo REST API
**Goal**: CRUD API with JWT auth and per-user todos

### Endpoints
```
POST   /api/token/          — Get JWT tokens
POST   /api/token/refresh/  — Refresh access token
GET    /api/todos/           — User's own todos only
POST   /api/todos/           — Create todo
GET    /api/todos/{id}/      — Get todo (must own it)
PUT    /api/todos/{id}/      — Update
DELETE /api/todos/{id}/      — Delete
POST   /api/todos/{id}/done/ — Mark as done (custom action)
GET    /api/todos/stats/     — Aggregation: total, done, pending count
```

### Requirements
- JWT via `djangorestframework-simplejwt`
- `IsOwner` custom permission
- `OrderingFilter` on `due_date`, `priority`, `created_at`
- `SearchFilter` on title + description
- Swagger docs with `drf-spectacular`

---

## Project 3: User Authentication and Profile System
**Goal**: Custom user model with profile, JWT auth, password reset

### Custom User Model
```python
class User(AbstractBaseUser, PermissionsMixin):
    email = models.EmailField(unique=True)  # Login with email, not username
    username = models.CharField(max_length=30, unique=True)
    is_active = models.BooleanField(default=True)
    date_joined = models.DateTimeField(auto_now_add=True)
    USERNAME_FIELD = 'email'
```

### Profile Extension
```python
class Profile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    bio = models.TextField(blank=True)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    website = models.URLField(blank=True)
    location = models.CharField(max_length=100, blank=True)
```

### Endpoints
- Registration with email verification
- Login → JWT tokens
- Profile CRUD: `GET/PUT /api/profile/`
- Change password: `POST /api/auth/change-password/`
- Password reset via email

---

## Project 4: E-commerce Product API
**Goal**: Product catalog with categories, reviews, and orders

### Models
```
Category: name, slug, parent (self FK for subcategories)
Product: name, slug, price, stock, category, images, is_active
Review: product, author, rating (1-5), content, created_at
Order: user, total, status, created_at
OrderItem: order, product, quantity, unit_price
```

### ViewSets
- `ProductViewSet`: list, retrieve, create (admin), update (admin), destroy (admin)
  + `@action: POST /products/{id}/review/`
  + `@action: GET /products/{id}/reviews/`
- `OrderViewSet`: create (user), list (user's own), retrieve
  + `@action: POST /orders/{id}/cancel/`

### Permissions
- Anyone can read products
- Authenticated users can create reviews and orders
- Admin can manage products

---

## Project 5: Social Feed API
**Goal**: Twitter-like feed with posts, follows, and likes

### Models
```
Post: author, content (max 280 chars), created_at, likes (M2M User)
Follow: follower, following (both FK User), created_at
```

### Endpoints
```
POST /api/posts/                 — Create post
GET  /api/posts/feed/            — Posts from users you follow (custom action)
GET  /api/posts/?author=username — Filter by user
POST /api/posts/{id}/like/       — Toggle like
GET  /api/posts/{id}/likes/      — List users who liked
POST /api/users/{id}/follow/     — Follow/unfollow user
GET  /api/users/{id}/followers/  — Follower list
GET  /api/users/{id}/following/  — Following list
```

### Hints
- Feed: `Post.objects.filter(author__followers__follower=request.user)`
- Use `annotate(like_count=Count('likes'), liked_by_me=...)` for efficiency

---

## Project 6: Library Management System
**Goal**: Book catalog + borrowing system

### Models
- `Book`: title, isbn, author, publisher, copies_total, copies_available
- `Member`: user (FK), membership_expiry, borrow_limit (default 3)
- `BorrowRecord`: member, book, borrowed_at, due_date, returned_at, fine

### Business Logic
- Borrow: check copies_available > 0 and member hasn't exceeded limit
- Return: calculate fine if overdue (e.g., ₹5/day)
- Admin report: overdue books, total fines, most borrowed

### Celery Task
```python
@shared_task
def send_overdue_reminders():
    overdue = BorrowRecord.objects.filter(
        due_date__lt=date.today(), returned_at__isnull=True
    )
    for record in overdue:
        send_mail(f"Book overdue: {record.book.title}", ...)
```

---

## Project 7: ML Model API with DRF
**Goal**: Serve a trained ML model through Django REST Framework

### Structure
```
ml_app/
├── models.py       — PredictionLog model
├── serializers.py  — PredictionInput, PredictionOutput serializers
├── views.py        — PredictAPIView, PredictionHistoryView
├── permissions.py  — IsAPIKeyValid
└── tasks.py        — Celery tasks for batch predictions
```

### Endpoints
```
POST /api/ml/predict/         — Single prediction
POST /api/ml/batch/           — Batch prediction (file upload)
GET  /api/ml/predictions/     — Prediction history (paginated)
GET  /api/ml/stats/           — Aggregated prediction statistics
```

### PredictionLog Model
```python
class PredictionLog(models.Model):
    timestamp = models.DateTimeField(auto_now_add=True)
    inputs = models.JSONField()
    prediction = models.IntegerField()
    probability = models.FloatField()
    model_version = models.CharField(max_length=20)
    latency_ms = models.FloatField()
    client_ip = models.GenericIPAddressField(null=True)
```

---

## Project 8: Event Management System
**Goal**: Create and manage events with registration

### Models
```
Event: title, description, organizer, start_date, end_date,
       venue, max_attendees, is_published, price
Registration: event, attendee, registered_at, status (confirmed/cancelled)
```

### Endpoints
- `GET /api/events/?date_from=&date_to=&category=` — Browse events
- `POST /api/events/{id}/register/` — Register for event
- `DELETE /api/events/{id}/cancel/` — Cancel registration
- `GET /api/events/my-events/` — Events I'm attending
- `GET /api/events/organized/` — Events I'm organizing

### Signals
```python
@receiver(post_save, sender=Registration)
def send_confirmation_email(sender, instance, created, **kwargs):
    if created and instance.status == 'confirmed':
        send_mail("Registration confirmed", ...)
```

---

## Project 9: Custom Template Tags and Context Processors
**Goal**: Practice Django templating advanced features

### Custom Template Tags
```python
# blog/templatetags/blog_tags.py
from django import template
from ..models import Post, Category

register = template.Library()

@register.inclusion_tag('blog/partials/recent_posts.html')
def recent_posts(count=5):
    posts = Post.objects.filter(status='published').order_by('-created_at')[:count]
    return {'posts': posts}

@register.filter
def reading_time(content):
    words = len(content.split())
    minutes = words // 200
    return f"{max(1, minutes)} min read"

@register.simple_tag
def url_replace(request, field, value):
    d = request.GET.copy()
    d[field] = value
    return d.urlencode()
```

### Context Processor
```python
def site_config(request):
    return {
        'SITE_NAME': settings.SITE_NAME,
        'CURRENT_YEAR': datetime.now().year,
        'CATEGORIES': Category.objects.annotate(count=Count('post')).filter(count__gt=0)
    }
```

---

## Project 10: Deployment to Production
**Goal**: Deploy Django app with PostgreSQL and WhiteNoise

### Steps
1. Switch to PostgreSQL:
```python
DATABASES = {'default': dj_database_url.config(default='postgresql://...')}
```

2. Static files with WhiteNoise:
```python
MIDDLEWARE = ['whitenoise.middleware.WhiteNoiseMiddleware', ...]
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
```

3. Production settings:
```python
DEBUG = False
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')
SECRET_KEY = os.environ['SECRET_KEY']
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
```

4. Deploy to Railway/Render:
```
# Procfile
web: gunicorn myproject.wsgi:application --workers 2
release: python manage.py migrate
```

5. Run management commands:
```bash
python manage.py collectstatic --noinput
python manage.py migrate
python manage.py createsuperuser
```