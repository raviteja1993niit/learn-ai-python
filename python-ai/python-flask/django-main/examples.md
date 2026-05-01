# Django + DRF — 20+ Annotated Code Examples

## Example 1: Basic Django Model
```python
# models.py
from django.db import models
from django.contrib.auth.models import User
from django.utils.text import slugify

class Category(models.Model):
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(unique=True, blank=True)

    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name

    class Meta:
        verbose_name_plural = "Categories"
        ordering = ['name']

class Post(models.Model):
    STATUS_CHOICES = [('draft', 'Draft'), ('published', 'Published')]
    title = models.CharField(max_length=200)
    slug = models.SlugField(unique=True)
    author = models.ForeignKey(User, on_delete=models.CASCADE, related_name='posts')
    category = models.ForeignKey(Category, on_delete=models.SET_NULL,
                                  null=True, blank=True)
    content = models.TextField()
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='draft')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    views = models.PositiveIntegerField(default=0)

    def __str__(self):
        return self.title

    class Meta:
        ordering = ['-created_at']
        indexes = [models.Index(fields=['slug']), models.Index(fields=['status', '-created_at'])]
```

## Example 2: ORM Queries — CRUD
```python
from django.db.models import Q, F, Count, Avg
from .models import Post, Category

# CREATE
post = Post.objects.create(
    title="My Post",
    slug="my-post",
    author=user,
    content="Content here",
    status="published"
)

# READ — various filters
all_published = Post.objects.filter(status='published').select_related('author')
by_author = Post.objects.filter(author__username='alice')
recent = Post.objects.order_by('-created_at')[:10]
single = Post.objects.get(slug='my-post')  # Raises DoesNotExist if not found
or_query = Post.objects.filter(
    Q(title__icontains='python') | Q(content__icontains='python')
)

# UPDATE
Post.objects.filter(status='draft').update(status='published')
post.title = "Updated Title"
post.save(update_fields=['title'])
Post.objects.filter(pk=post.pk).update(views=F('views') + 1)  # Atomic increment

# DELETE
Post.objects.filter(status='draft', created_at__lt='2023-01-01').delete()

# AGGREGATION
stats = Post.objects.aggregate(
    total=Count('id'),
    avg_views=Avg('views'),
)
```

## Example 3: Class-Based Views (CBV)
```python
# views.py
from django.views.generic import ListView, DetailView, CreateView, UpdateView, DeleteView
from django.contrib.auth.mixins import LoginRequiredMixin
from django.urls import reverse_lazy
from .models import Post
from .forms import PostForm

class PostListView(ListView):
    model = Post
    template_name = 'blog/post_list.html'
    context_object_name = 'posts'
    paginate_by = 10

    def get_queryset(self):
        qs = Post.objects.filter(status='published').select_related('author')
        q = self.request.GET.get('q')
        if q:
            qs = qs.filter(Q(title__icontains=q) | Q(content__icontains=q))
        return qs

    def get_context_data(self, **kwargs):
        ctx = super().get_context_data(**kwargs)
        ctx['total_posts'] = Post.objects.filter(status='published').count()
        return ctx

class PostDetailView(DetailView):
    model = Post
    template_name = 'blog/post_detail.html'
    slug_field = 'slug'
    context_object_name = 'post'

    def get_object(self):
        obj = super().get_object()
        Post.objects.filter(pk=obj.pk).update(views=F('views') + 1)
        return obj

class PostCreateView(LoginRequiredMixin, CreateView):
    model = Post
    form_class = PostForm
    template_name = 'blog/post_form.html'
    success_url = reverse_lazy('blog:list')

    def form_valid(self, form):
        form.instance.author = self.request.user
        return super().form_valid(form)

class PostUpdateView(LoginRequiredMixin, UpdateView):
    model = Post
    form_class = PostForm
    template_name = 'blog/post_form.html'

    def get_queryset(self):
        return super().get_queryset().filter(author=self.request.user)

class PostDeleteView(LoginRequiredMixin, DeleteView):
    model = Post
    success_url = reverse_lazy('blog:list')

    def get_queryset(self):
        return super().get_queryset().filter(author=self.request.user)
```

## Example 4: Function-Based Views with Decorators
```python
from django.shortcuts import render, get_object_or_404, redirect
from django.contrib.auth.decorators import login_required, permission_required
from django.views.decorators.http import require_http_methods, require_POST
from django.contrib import messages
from django.http import JsonResponse

@login_required
@require_http_methods(["GET", "POST"])
def create_post(request):
    if request.method == 'POST':
        form = PostForm(request.POST)
        if form.is_valid():
            post = form.save(commit=False)
            post.author = request.user
            post.save()
            messages.success(request, f"Post '{post.title}' created!")
            return redirect('blog:detail', slug=post.slug)
    else:
        form = PostForm()
    return render(request, 'blog/create.html', {'form': form})

@login_required
@require_POST
def like_post(request, pk):
    post = get_object_or_404(Post, pk=pk)
    liked = post.likes.filter(pk=request.user.pk).exists()
    if liked:
        post.likes.remove(request.user)
    else:
        post.likes.add(request.user)
    return JsonResponse({'likes': post.likes.count(), 'liked': not liked})
```

## Example 5: URL Configuration
```python
# blog/urls.py
from django.urls import path, include
from . import views

app_name = 'blog'

urlpatterns = [
    path('', views.PostListView.as_view(), name='list'),
    path('create/', views.PostCreateView.as_view(), name='create'),
    path('<slug:slug>/', views.PostDetailView.as_view(), name='detail'),
    path('<int:pk>/edit/', views.PostUpdateView.as_view(), name='edit'),
    path('<int:pk>/delete/', views.PostDeleteView.as_view(), name='delete'),
    path('<int:pk>/like/', views.like_post, name='like'),
]

# project/urls.py
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('blog/', include('blog.urls', namespace='blog')),
    path('api/', include('api.urls')),
    path('api/token/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
```

## Example 6: DRF Serializers
```python
# serializers.py
from rest_framework import serializers
from .models import Post, Category
from django.contrib.auth.models import User

class CategorySerializer(serializers.ModelSerializer):
    post_count = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = ['id', 'name', 'slug', 'post_count']
        read_only_fields = ['slug']

    def get_post_count(self, obj):
        return obj.post_set.filter(status='published').count()

class PostListSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.username', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)

    class Meta:
        model = Post
        fields = ['id', 'title', 'slug', 'author_name', 'category_name',
                  'status', 'created_at', 'views']

class PostDetailSerializer(PostListSerializer):
    class Meta(PostListSerializer.Meta):
        fields = PostListSerializer.Meta.fields + ['content']

class PostCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Post
        fields = ['title', 'content', 'category', 'status']

    def validate_title(self, value):
        if len(value) < 5:
            raise serializers.ValidationError("Title must be at least 5 characters")
        return value

    def create(self, validated_data):
        validated_data['author'] = self.context['request'].user
        return super().create(validated_data)
```

## Example 7: DRF ModelViewSet
```python
# views.py (API)
from rest_framework.viewsets import ModelViewSet, ReadOnlyModelViewSet
from rest_framework.permissions import IsAuthenticatedOrReadOnly, IsAuthenticated
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework import status, filters
from django_filters.rest_framework import DjangoFilterBackend

class PostViewSet(ModelViewSet):
    queryset = Post.objects.all().select_related('author', 'category')
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_fields = ['status', 'category', 'author']
    search_fields = ['title', 'content']
    ordering_fields = ['created_at', 'views']
    ordering = ['-created_at']

    def get_serializer_class(self):
        if self.action == 'list':
            return PostListSerializer
        if self.action == 'create':
            return PostCreateSerializer
        return PostDetailSerializer

    def get_queryset(self):
        qs = super().get_queryset()
        if not self.request.user.is_staff:
            qs = qs.filter(status='published')
        return qs

    def perform_create(self, serializer):
        serializer.save(author=self.request.user)

    @action(detail=True, methods=['post'], permission_classes=[IsAuthenticated])
    def publish(self, request, pk=None):
        post = self.get_object()
        if post.author != request.user and not request.user.is_staff:
            return Response({'error': 'Permission denied'}, status=403)
        post.status = 'published'
        post.save()
        return Response({'status': 'published'})

    @action(detail=False, methods=['get'])
    def trending(self, request):
        top = self.get_queryset().order_by('-views')[:5]
        serializer = PostListSerializer(top, many=True)
        return Response(serializer.data)
```

## Example 8: DRF Router and URL Registration
```python
# api/urls.py
from rest_framework.routers import DefaultRouter
from .views import PostViewSet, UserViewSet, CategoryViewSet

router = DefaultRouter()
router.register('posts', PostViewSet, basename='post')
router.register('users', UserViewSet, basename='user')
router.register('categories', CategoryViewSet, basename='category')

urlpatterns = router.urls
# Generates:
# GET/POST  /api/posts/
# GET/PUT/PATCH/DELETE  /api/posts/{pk}/
# POST  /api/posts/{pk}/publish/
# GET   /api/posts/trending/
```

## Example 9: Custom Permissions
```python
from rest_framework.permissions import BasePermission, SAFE_METHODS

class IsOwnerOrReadOnly(BasePermission):
    """Allow read to anyone, write only to the object owner"""
    def has_object_permission(self, request, view, obj):
        if request.method in SAFE_METHODS:
            return True
        return obj.author == request.user

class IsAdminOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        return bool(request.user and request.user.is_staff)

class IsOwnerOrAdmin(BasePermission):
    def has_object_permission(self, request, view, obj):
        return request.user.is_staff or obj.author == request.user
```

## Example 10: JWT Authentication Setup
```python
# settings.py
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticatedOrReadOnly',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 10,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
}

from datetime import timedelta
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=1),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'ALGORITHM': 'HS256',
}

# Usage:
# POST /api/token/  {"username": "...", "password": "..."}
# -> {"access": "...", "refresh": "..."}
# POST /api/token/refresh/  {"refresh": "..."}
# -> {"access": "..."}
```

## Example 11: Django Admin Customization
```python
from django.contrib import admin
from django.utils.html import format_html
from .models import Post, Category

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'slug', 'post_count']
    prepopulated_fields = {'slug': ('name',)}
    search_fields = ['name']

    def post_count(self, obj):
        return obj.post_set.count()
    post_count.short_description = "# Posts"

class PostAdmin(admin.ModelAdmin):
    list_display = ['title', 'author', 'category', 'status', 'views',
                    'created_at', 'thumbnail_preview']
    list_filter = ['status', 'category', 'created_at']
    search_fields = ['title', 'content', 'author__username']
    prepopulated_fields = {'slug': ('title',)}
    date_hierarchy = 'created_at'
    list_editable = ['status']
    readonly_fields = ['views', 'created_at', 'updated_at']
    raw_id_fields = ['author']

    def thumbnail_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" height="50"/>', obj.image.url)
        return "No image"

    actions = ['publish', 'unpublish']

    def publish(self, request, queryset):
        count = queryset.update(status='published')
        self.message_user(request, f"{count} posts published.")
    publish.short_description = "Publish selected posts"

    def unpublish(self, request, queryset):
        queryset.update(status='draft')

admin.site.register(Post, PostAdmin)
```

## Example 12: Django Signals
```python
# signals.py
from django.db.models.signals import post_save, pre_delete
from django.dispatch import receiver
from django.core.mail import send_mail
from .models import Post

@receiver(post_save, sender=Post)
def notify_on_publish(sender, instance, created, **kwargs):
    if not created and instance.status == 'published':
        send_mail(
            subject=f'New Post: {instance.title}',
            message=f'A new post has been published: {instance.title}',
            from_email='noreply@blog.com',
            recipient_list=['editor@blog.com'],
            fail_silently=True
        )

@receiver(post_save, sender='auth.User')
def create_profile(sender, instance, created, **kwargs):
    if created:
        from profiles.models import Profile
        Profile.objects.create(user=instance)
```

## Example 13: Django Forms with Bootstrap
```python
# forms.py
from django import forms
from .models import Post

class PostForm(forms.ModelForm):
    class Meta:
        model = Post
        fields = ['title', 'content', 'category', 'status']
        widgets = {
            'title': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': 'Post title...'
            }),
            'content': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 15,
                'id': 'editor'
            }),
            'category': forms.Select(attrs={'class': 'form-select'}),
            'status': forms.Select(attrs={'class': 'form-select'}),
        }

    def clean_title(self):
        title = self.cleaned_data.get('title', '')
        if Post.objects.filter(title__iexact=title).exclude(pk=self.instance.pk).exists():
            raise forms.ValidationError("A post with this title already exists.")
        return title
```

## Example 14: Pagination in DRF
```python
# pagination.py
from rest_framework.pagination import PageNumberPagination, CursorPagination

class StandardPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'per_page'
    max_page_size = 100
    page_query_param = 'page'

    def get_paginated_response(self, data):
        from rest_framework.response import Response
        return Response({
            'count': self.page.paginator.count,
            'total_pages': self.page.paginator.num_pages,
            'next': self.get_next_link(),
            'previous': self.get_previous_link(),
            'results': data
        })

class PostCursorPagination(CursorPagination):
    page_size = 20
    ordering = '-created_at'
    cursor_query_param = 'cursor'
```

## Example 15: Django + DRF Testing
```python
# tests.py
from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient, APITestCase
from rest_framework_simplejwt.tokens import RefreshToken
from .models import Post, Category

class PostAPITestCase(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='testuser', password='pass123')
        self.admin = User.objects.create_superuser('admin', 'a@a.com', 'admin123')
        self.category = Category.objects.create(name='Tech', slug='tech')
        self.post = Post.objects.create(
            title='Test Post', slug='test-post',
            author=self.user, content='Content', status='published'
        )

    def get_token(self, user):
        refresh = RefreshToken.for_user(user)
        return str(refresh.access_token)

    def test_list_posts_anonymous(self):
        response = self.client.get('/api/posts/')
        self.assertEqual(response.status_code, 200)

    def test_create_post_requires_auth(self):
        response = self.client.post('/api/posts/', {'title': 'New', 'content': 'Body'})
        self.assertEqual(response.status_code, 401)

    def test_create_post_authenticated(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.get_token(self.user)}')
        response = self.client.post('/api/posts/', {
            'title': 'New Post Title',
            'content': 'Some content here',
            'status': 'draft'
        })
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data['author_name'], 'testuser')

    def test_delete_own_post(self):
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.get_token(self.user)}')
        response = self.client.delete(f'/api/posts/{self.post.pk}/')
        self.assertEqual(response.status_code, 204)

    def test_cannot_delete_other_post(self):
        other_user = User.objects.create_user(username='other', password='pass')
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {self.get_token(other_user)}')
        response = self.client.delete(f'/api/posts/{self.post.pk}/')
        self.assertIn(response.status_code, [403, 404])
```

## Example 16: ML Model API with Django REST Framework
```python
# ml_api/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from pydantic import BaseModel, validator
import joblib
import numpy as np
from django.conf import settings

model = joblib.load(settings.ML_MODEL_PATH)

class MLPredictView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        data = request.data
        required = ['age', 'salary', 'experience']
        missing = [f for f in required if f not in data]
        if missing:
            return Response({'errors': [f"Missing: {f}" for f in missing]},
                            status=status.HTTP_422_UNPROCESSABLE_ENTITY)
        try:
            features = np.array([[float(data['age']),
                                   float(data['salary']),
                                   float(data['experience'])]])
            prediction = int(model.predict(features)[0])
            probability = float(model.predict_proba(features).max())
        except (ValueError, TypeError) as e:
            return Response({'error': f'Invalid input: {e}'}, status=400)

        return Response({
            'prediction': prediction,
            'probability': round(probability, 4),
            'label': 'Hired' if prediction == 1 else 'Rejected'
        })

# urls.py
urlpatterns = [
    path('api/ml/predict/', MLPredictView.as_view(), name='ml-predict'),
]
```

## Example 17: Django Settings Structure
```python
# settings/base.py
from pathlib import Path
import os

BASE_DIR = Path(__file__).resolve().parent.parent.parent
SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-insecure-key')
DEBUG = False
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'corsheaders',
    'django_filters',
    'blog',
]
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'blog'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
    }
}
STATIC_ROOT = BASE_DIR / 'staticfiles'
MEDIA_ROOT = BASE_DIR / 'media'
MEDIA_URL = '/media/'

# settings/development.py
from .base import *
DEBUG = True
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3',
                          'NAME': BASE_DIR / 'db.sqlite3'}}

# settings/production.py
from .base import *
import dj_database_url
DATABASES = {'default': dj_database_url.config()}
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')
```

## Example 18: Custom Management Command
```python
# management/commands/seed_data.py
from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from blog.models import Post, Category
import random

class Command(BaseCommand):
    help = 'Seed the database with sample data'

    def add_arguments(self, parser):
        parser.add_argument('--posts', type=int, default=10)

    def handle(self, *args, **options):
        n = options['posts']
        user, _ = User.objects.get_or_create(username='admin',
                                              defaults={'is_staff': True})
        cat, _ = Category.objects.get_or_create(name='General', slug='general')
        for i in range(n):
            Post.objects.create(
                title=f'Sample Post {i}',
                slug=f'sample-post-{i}',
                author=user,
                category=cat,
                content=f'Content for post {i}.' * 5,
                status='published',
                views=random.randint(0, 1000)
            )
        self.stdout.write(self.style.SUCCESS(f'Created {n} posts'))
```

## Example 19: Select Related and Prefetch Related
```python
# Inefficient (N+1 query problem)
posts = Post.objects.all()
for post in posts:
    print(post.author.username)  # Separate DB query for each post!

# Efficient with select_related (JOIN)
posts = Post.objects.select_related('author', 'category').all()
for post in posts:
    print(post.author.username)  # No extra query

# Many-to-many: use prefetch_related
posts = Post.objects.prefetch_related('tags', 'comments').all()
for post in posts:
    print([t.name for t in post.tags.all()])  # No extra query

# Combined
posts = Post.objects.select_related('author').prefetch_related('tags').filter(
    status='published'
).annotate(comment_count=Count('comments'))
```

## Example 20: DRF Nested Serializers
```python
class CommentSerializer(serializers.ModelSerializer):
    author_name = serializers.CharField(source='author.username', read_only=True)

    class Meta:
        model = Comment
        fields = ['id', 'author_name', 'content', 'created_at']

class PostDetailSerializer(serializers.ModelSerializer):
    author = serializers.StringRelatedField()
    category = CategorySerializer(read_only=True)
    comments = CommentSerializer(many=True, read_only=True)
    comment_count = serializers.SerializerMethodField()
    tags = serializers.SlugRelatedField(many=True, slug_field='name',
                                         queryset=Tag.objects.all())

    class Meta:
        model = Post
        fields = ['id', 'title', 'slug', 'author', 'category', 'content',
                  'status', 'tags', 'views', 'comment_count', 'comments',
                  'created_at', 'updated_at']
        read_only_fields = ['author', 'slug', 'views', 'created_at', 'updated_at']

    def get_comment_count(self, obj):
        return obj.comments.count()
```