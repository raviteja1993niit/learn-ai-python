# 🌐 Django + Django REST Framework

## What is Django?
Django is Python's most popular **full-stack web framework** — batteries included.
It provides ORM, admin panel, authentication, URL routing, templating, and security out of the box.

## Why Learn It?
- Required in 70%+ of Python backend job descriptions
- Powers Instagram, Pinterest, Disqus, Mozilla
- Django REST Framework (DRF) is the standard for building REST APIs in Python

## Key Concepts to Learn

### Django Core
| Concept | Description |
|---------|-------------|
| `models.py` | Define database tables using Python classes (ORM) |
| `views.py` | Handle HTTP requests and return responses |
| `urls.py` | URL routing — map URLs to views |
| `templates/` | HTML templates using Jinja2-style Django template language |
| `admin.py` | Register models to auto-generate admin UI |
| `settings.py` | Project configuration (DB, apps, middleware, static files) |
| `forms.py` | Form validation and rendering |
| `migrations/` | Auto-generated DB schema changes |

### Django REST Framework (DRF)
| Concept | Description |
|---------|-------------|
| `Serializers` | Convert model instances ↔ JSON |
| `APIView` | Class-based REST views |
| `ViewSets` + `Routers` | Auto-generate CRUD endpoints |
| `Permissions` | IsAuthenticated, IsAdminUser, custom permissions |
| `JWT Auth` | Token-based auth with `djangorestframework-simplejwt` |
| `Pagination` | PageNumberPagination, CursorPagination |
| `Filtering` | django-filter integration |

## Learning Path
1. **Install**: `pip install django djangorestframework`
2. `django-admin startproject myproject` → `python manage.py startapp myapp`
3. Build: Models → Views → URLs → Templates
4. Add DRF: Serializers → APIView → ViewSets → JWT Auth
5. Deploy: Gunicorn + Nginx + PostgreSQL

## What to Build
- [ ] Blog API (CRUD posts, comments, users)
- [ ] Student Management System (ORM + admin)
- [ ] E-commerce REST API (DRF + JWT + PostgreSQL)
- [ ] ML Model serving via Django API endpoint

## Resources
- https://docs.djangoproject.com/en/stable/intro/tutorial01/
- https://www.django-rest-framework.org/tutorial/quickstart/
- Compare with Flask: Django = full-stack, Flask = micro-framework

## Related Folders
- `python-flask/Flask-Web-Framework-main/` — Flask comparison
- `python-flask/FastAPI-main/` — FastAPI comparison
- `databases/MySQL-With-Python-master/` — Database integration