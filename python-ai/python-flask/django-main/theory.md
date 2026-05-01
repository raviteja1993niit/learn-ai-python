# Django + Django REST Framework — Theory & Deep Dive

## 1. MVT Architecture
Django follows the **Model-View-Template (MVT)** pattern:

| MVT Component | Responsibility                      | MVC Equivalent |
|---------------|-------------------------------------|----------------|
| Model         | Data layer, ORM, database schema    | Model          |
| View          | Business logic, request handling    | Controller     |
| Template      | HTML presentation layer             | View           |

Django's URL dispatcher routes requests to views, which use models and return templates.

```
Browser → urls.py → views.py → models.py (DB)
                    ↓
              templates/*.html → Browser
```

## 2. Project Structure
```
myproject/
├── manage.py              # CLI entry point
├── myproject/
│   ├── __init__.py
│   ├── settings.py        # Configuration
│   ├── urls.py            # Root URL routing
│   ├── wsgi.py            # WSGI entry point
│   └── asgi.py            # ASGI entry point
└── myapp/
    ├── __init__.py
    ├── admin.py           # Admin configuration
    ├── apps.py            # App configuration
    ├── models.py          # Database models
    ├── views.py           # View functions/classes
    ├── urls.py            # App URL routing
    ├── forms.py           # Form classes
    ├── serializers.py     # DRF serializers
    ├── tests.py           # Unit tests
    ├── migrations/        # Database migrations
    └── templates/myapp/   # HTML templates
```

## 3. Django Apps
An app is a self-contained module with a specific responsibility.

```bash
python manage.py startapp blog
python manage.py startapp accounts
python manage.py startapp api
```

Register in settings:
```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'rest_framework',
    'corsheaders',
    'blog',
    'accounts',
]
```

AppConfig:
```python
# blog/apps.py
class BlogConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'blog'

    def ready(self):
        import blog.signals  # Connect signals on startup
```

## 4. Models and ORM

### Field Types
```python
from django.db import models

class Article(models.Model):
    # String fields
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    content = models.TextField()
    summary = models.TextField(blank=True)

    # Numeric fields
    views = models.IntegerField(default=0)
    rating = models.FloatField(null=True, blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)

    # Boolean
    is_published = models.BooleanField(default=False)

    # Date/time
    created_at = models.DateTimeField(auto_now_add=True)  # Set once
    updated_at = models.DateTimeField(auto_now=True)      # Updated on save
    published_at = models.DateField(null=True, blank=True)

    # File/image
    image = models.ImageField(upload_to='articles/', null=True, blank=True)
    attachment = models.FileField(upload_to='files/', null=True, blank=True)

    # Relationships
    author = models.ForeignKey('auth.User', on_delete=models.CASCADE,
                               related_name='articles')
    tags = models.ManyToManyField('Tag', blank=True)
    profile = models.OneToOneField('Profile', on_delete=models.SET_NULL,
                                   null=True, blank=True)

    # JSON
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Article'
        verbose_name_plural = 'Articles'
        indexes = [
            models.Index(fields=['slug']),
            models.Index(fields=['author', '-created_at']),
        ]
        constraints = [
            models.UniqueConstraint(fields=['title', 'author'],
                                    name='unique_title_per_author')
        ]

    def __str__(self):
        return self.title

    def get_absolute_url(self):
        from django.urls import reverse
        return reverse('blog:article-detail', kwargs={'slug': self.slug})
```

### on_delete Options
| Option        | Behaviour                              |
|---------------|----------------------------------------|
| CASCADE       | Delete related objects                 |
| SET_NULL      | Set FK to NULL (requires null=True)    |
| SET_DEFAULT   | Set FK to default value                |
| PROTECT       | Prevent deletion if related objects exist |
| DO_NOTHING    | No action (may cause integrity errors) |
| RESTRICT      | Like PROTECT but allows cascade chains |

## 5. ORM Queries

### Basic CRUD
```python
# Create
article = Article.objects.create(title="Hello", author=user)
article = Article(title="Hello", author=user)
article.save()

# Read
Article.objects.all()                         # QuerySet of all
Article.objects.get(id=1)                     # Single or raises DoesNotExist
Article.objects.filter(is_published=True)     # Filtered QuerySet
Article.objects.exclude(is_published=False)   # Exclude
Article.objects.first()                       # First or None
Article.objects.last()                        # Last or None
Article.objects.count()                       # Integer count
Article.objects.exists()                      # Boolean

# Update
Article.objects.filter(author=user).update(is_published=True)
article.title = "Updated"
article.save(update_fields=['title'])

# Delete
Article.objects.filter(is_published=False).delete()
article.delete()
```

### Advanced Filtering
```python
from django.db.models import Q, F, Value, Count, Sum, Avg, Max, Min
from django.db.models.functions import Lower, Concat

# Q objects (complex queries)
Article.objects.filter(
    Q(title__icontains='python') | Q(content__icontains='python')
)
Article.objects.filter(~Q(is_published=False))  # NOT

# Field lookups
Article.objects.filter(
    title__startswith='Hello',
    title__icontains='world',      # case insensitive
    views__gt=100,                  # greater than
    views__gte=100,                 # greater than or equal
    views__lt=1000,
    views__range=(100, 500),
    created_at__year=2024,
    created_at__date__gte='2024-01-01',
    tags__name__in=['python', 'django'],  # related model
    author__isnull=False,
)

# F objects (reference other fields)
Article.objects.filter(views__gt=F('likes'))
Article.objects.update(views=F('views') + 1)

# Annotations
Article.objects.annotate(
    comment_count=Count('comments'),
    total_views=Sum('views')
).filter(comment_count__gt=5)

# Aggregations
from django.db.models import Avg
Article.objects.aggregate(
    avg_views=Avg('views'),
    max_views=Max('views'),
    total=Count('id')
)

# Select related (JOIN for FK)
Article.objects.select_related('author', 'author__profile')

# Prefetch related (separate query for M2M)
Article.objects.prefetch_related('tags', 'comments')
```

## 6. Views: Function-Based and Class-Based

### Function-Based Views (FBV)
```python
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse

@login_required
def article_list(request):
    articles = Article.objects.filter(is_published=True)
    return render(request, 'blog/list.html', {'articles': articles})

def article_detail(request, slug):
    article = get_object_or_404(Article, slug=slug, is_published=True)
    article.views = F('views') + 1
    article.save(update_fields=['views'])
    return render(request, 'blog/detail.html', {'article': article})
```

### Class-Based Views (CBV)
```python
from django.views.generic import (
    ListView, DetailView, CreateView, UpdateView, DeleteView
)
from django.contrib.auth.mixins import LoginRequiredMixin, PermissionRequiredMixin
from django.urls import reverse_lazy

class ArticleListView(ListView):
    model = Article
    template_name = 'blog/list.html'
    context_object_name = 'articles'
    paginate_by = 10

    def get_queryset(self):
        return Article.objects.filter(is_published=True).order_by('-created_at')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['total'] = self.get_queryset().count()
        return context

class ArticleCreateView(LoginRequiredMixin, CreateView):
    model = Article
    fields = ['title', 'content', 'tags']
    success_url = reverse_lazy('blog:list')

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)

class ArticleDeleteView(LoginRequiredMixin, DeleteView):
    model = Article
    success_url = reverse_lazy('blog:list')

    def get_queryset(self):
        # Only allow deleting own articles
        return super().get_queryset().filter(author=self.request.user)
```

## 7. URL Routing
```python
# blog/urls.py
from django.urls import path, re_path, include
from . import views

app_name = 'blog'

urlpatterns = [
    path('', views.ArticleListView.as_view(), name='list'),
    path('<slug:slug>/', views.article_detail, name='detail'),
    path('create/', views.ArticleCreateView.as_view(), name='create'),
    path('<int:pk>/edit/', views.ArticleUpdateView.as_view(), name='edit'),
    path('<int:pk>/delete/', views.ArticleDeleteView.as_view(), name='delete'),
    re_path(r'^archive/(?P<year>[0-9]{4})/$', views.archive, name='archive'),
]

# myproject/urls.py
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('blog/', include('blog.urls', namespace='blog')),
    path('api/v1/', include('api.urls')),
    path('api-auth/', include('rest_framework.urls')),
]
```

## 8. Templates
```django
{# base.html #}
{% load static %}
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="{% static 'css/style.css' %}">
  <title>{% block title %}Site{% endblock %}</title>
</head>
<body>
  {% include "partials/navbar.html" %}
  {% block content %}{% endblock %}
  {% block scripts %}{% endblock %}
</body>
</html>

{# blog/list.html #}
{% extends "base.html" %}
{% block content %}
  {% for article in page_obj %}
    <article>
      <h2><a href="{{ article.get_absolute_url }}">{{ article.title }}</a></h2>
      <time>{{ article.created_at|date:"M d, Y" }}</time>
      <p>{{ article.content|truncatewords:50 }}</p>
    </article>
  {% empty %}
    <p>No articles yet.</p>
  {% endfor %}
  {% include "partials/pagination.html" with page=page_obj %}
{% endblock %}
```

## 9. Forms and ModelForms
```python
from django import forms
from .models import Article

class ArticleForm(forms.ModelForm):
    class Meta:
        model = Article
        fields = ['title', 'content', 'tags', 'is_published']
        widgets = {
            'content': forms.Textarea(attrs={'rows': 10, 'class': 'editor'}),
        }
        labels = {'is_published': 'Publish immediately'}

    def clean_title(self):
        title = self.cleaned_data.get('title')
        if len(title) < 5:
            raise forms.ValidationError("Title too short (min 5 chars)")
        return title

    def clean(self):
        cleaned = super().clean()
        if cleaned.get('is_published') and not cleaned.get('content'):
            raise forms.ValidationError("Cannot publish without content")
        return cleaned
```

## 10. Django Admin
```python
from django.contrib import admin
from .models import Article, Tag

@admin.register(Tag)
class TagAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug']
    prepopulated_fields = {'slug': ('name',)}

class CommentInline(admin.TabularInline):
    model = Comment
    extra = 0

@admin.register(Article)
class ArticleAdmin(admin.ModelAdmin):
    list_display = ['title', 'author', 'is_published', 'views', 'created_at']
    list_filter = ['is_published', 'created_at', 'author']
    search_fields = ['title', 'content', 'author__username']
    prepopulated_fields = {'slug': ('title',)}
    date_hierarchy = 'created_at'
    ordering = ['-created_at']
    inlines = [CommentInline]
    list_editable = ['is_published']
    readonly_fields = ['views', 'created_at', 'updated_at']

    actions = ['publish_articles']

    def publish_articles(self, request, queryset):
        queryset.update(is_published=True)
    publish_articles.short_description = "Publish selected articles"
```

## 11. Django REST Framework (DRF)

### Serializers
```python
from rest_framework import serializers
from .models import Article

class ArticleSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.username', read_only=True)
    comment_count = serializers.SerializerMethodField()
    url = serializers.HyperlinkedIdentityField(view_name='api:article-detail')

    class Meta:
        model = Article
        fields = ['id', 'title', 'content', 'author', 'author_name',
                  'is_published', 'created_at', 'comment_count', 'url']
        read_only_fields = ['created_at']
        extra_kwargs = {
            'author': {'write_only': True}
        }

    def get_comment_count(self, obj):
        return obj.comments.count()

    def validate_title(self, value):
        if len(value) < 5:
            raise serializers.ValidationError("Title too short")
        return value
```

### APIView and ViewSets
```python
from rest_framework.views import APIView
from rest_framework.viewsets import ModelViewSet
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import action

# APIView (manual)
class ArticleListAPIView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        articles = Article.objects.all()
        serializer = ArticleSerializer(articles, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = ArticleSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(author=request.user)
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# ModelViewSet (auto CRUD)
class ArticleViewSet(ModelViewSet):
    queryset = Article.objects.all()
    serializer_class = ArticleSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        if self.request.query_params.get('mine'):
            qs = qs.filter(author=self.request.user)
        return qs

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    @action(detail=True, methods=['post'])
    def publish(self, request, pk=None):
        article = self.get_object()
        article.is_published = True
        article.save()
        return Response({'status': 'published'})
```

### Routers
```python
from rest_framework.routers import DefaultRouter
router = DefaultRouter()
router.register('articles', ArticleViewSet, basename='article')
router.register('users', UserViewSet, basename='user')
urlpatterns = router.urls
```

## 12. DRF Permissions
```python
from rest_framework.permissions import BasePermission, SAFE_METHODS

class IsOwnerOrReadOnly(BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        return obj.author == request.user

class IsAdminOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        return request.user.is_staff
```

## 13. JWT Authentication with DRF
```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10
}

# urls.py
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
urlpatterns += [
    path('api/token/', TokenObtainPairView.as_view()),
    path('api/token/refresh/', TokenRefreshView.as_view()),
]
```

## 14. Signals
```python
from django.db.models.signals import post_save, pre_delete, m2m_changed
from django.dispatch import receiver

@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        Profile.objects.create(user=instance)

@receiver(pre_delete, sender=Article)
def log_deletion(sender, instance, **kwargs):
    logger.info(f"Article {instance.id} being deleted by...")
```

## 15. Celery for Async Tasks
```python
# celery.py
from celery import Celery
app = Celery('myproject')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# tasks.py
from celery import shared_task

@shared_task
def send_welcome_email(user_id):
    user = User.objects.get(id=user_id)
    send_mail(...)

# In views
send_welcome_email.delay(user.id)
```

## 16. Testing in Django
```python
from django.test import TestCase, Client
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import RefreshToken

class ArticleTestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user('test', password='test123')
        self.article = Article.objects.create(
            title="Test Article", author=self.user, is_published=True
        )
        self.client = Client()

    def test_article_list(self):
        response = self.client.get('/blog/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Test Article")

class APITestCase(TestCase):
    def setUp(self):
        self.user = User.objects.create_user('api_user', password='pass')
        self.client = APIClient()
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {refresh.access_token}')

    def test_create_article(self):
        response = self.client.post('/api/articles/', {
            'title': 'API Article',
            'content': 'Content here'
        })
        self.assertEqual(response.status_code, 201)
```

## 17. Migrations
```bash
python manage.py makemigrations      # Create migration files
python manage.py migrate             # Apply migrations
python manage.py migrate blog 0003   # Migrate to specific version
python manage.py showmigrations      # Show migration state
python manage.py sqlmigrate blog 0001 # Show SQL for migration
python manage.py migrate blog zero   # Undo all blog migrations
```

## 18. Deployment
```bash
# settings/production.py
DEBUG = False
ALLOWED_HOSTS = ['mysite.com', 'www.mysite.com']
DATABASES = {'default': dj_database_url.config()}
STATIC_ROOT = BASE_DIR / 'staticfiles'
DEFAULT_FILE_STORAGE = 'storages.backends.s3boto3.S3Boto3Storage'

# collectstatic
python manage.py collectstatic

# gunicorn
gunicorn myproject.wsgi:application --workers 4 --bind 0.0.0.0:8000

# whitenoise for static files
MIDDLEWARE = ['whitenoise.middleware.WhiteNoiseMiddleware', ...]
```