# FastAPI — Modern Async Python APIs — Theory & Concepts

## 1. FastAPI vs Flask vs Django

| Feature              | FastAPI              | Flask               | Django              |
|----------------------|----------------------|---------------------|---------------------|
| Type hints           | ✅ Core feature      | ❌ Optional         | ❌ Optional         |
| Auto docs            | ✅ OpenAPI/Swagger   | ❌ Need flask-restx | ❌ Need drf-yasg    |
| Async support        | ✅ Native (ASGI)     | ⚠️ Flask 2.x limited| ⚠️ Django 4.x limited|
| Validation           | ✅ Pydantic built-in | ❌ Manual/WTForms   | ✅ Forms/Serializers|
| Speed                | 🚀 Very fast         | ⚡ Fast             | ⚡ Fast             |
| ORM                  | None (bring your own)| None                | Built-in ORM        |
| Best for             | APIs, microservices  | Small APIs, web apps| Full-stack apps     |
| Learning curve       | Medium               | Low                 | Medium-High         |

FastAPI is built on Starlette (ASGI framework) and Pydantic (data validation).
Performance comparable to NodeJS and Go for async workloads.

## 2. ASGI vs WSGI

### WSGI (Web Server Gateway Interface)
- Synchronous interface (PEP 3333)
- One request per thread/process
- Used by: Flask, Django (traditional)
- Server: gunicorn, uWSGI

### ASGI (Async Server Gateway Interface)
- Asynchronous interface
- Handles concurrent connections via event loop
- Supports WebSockets, Server-Sent Events, HTTP/2
- Used by: FastAPI, Starlette, Django Channels
- Server: uvicorn, hypercorn, daphne

```python
# WSGI callable
def application(environ, start_response):
    ...

# ASGI callable
async def application(scope, receive, send):
    ...
```

Why it matters: ASGI can handle thousands of concurrent connections
without creating thousands of threads, making it ideal for I/O-bound workloads.

## 3. Path Operations (Route Decorators)
```python
from fastapi import FastAPI
app = FastAPI()

@app.get("/")           # HTTP GET
@app.post("/items")     # HTTP POST
@app.put("/items/{id}") # HTTP PUT
@app.delete("/items/{id}") # HTTP DELETE
@app.patch("/items/{id}")  # HTTP PATCH
@app.head("/items")     # HTTP HEAD
@app.options("/items")  # HTTP OPTIONS
```

Multiple methods on one handler:
```python
@app.api_route("/items", methods=["GET", "POST"])
async def items():
    ...
```

## 4. Path Parameters, Query Parameters, Request Body

### Path Parameters
```python
@app.get("/users/{user_id}")
async def get_user(user_id: int):    # auto-validated as int
    return {"user_id": user_id}

@app.get("/files/{file_path:path}")  # path converter
async def get_file(file_path: str):
    ...
```

### Query Parameters
```python
@app.get("/items")
async def list_items(
    skip: int = 0,
    limit: int = 10,
    q: str | None = None,    # optional
    active: bool = True
):
    ...
# GET /items?skip=20&limit=5&q=laptop
```

### Request Body (Pydantic model)
```python
from pydantic import BaseModel

class Item(BaseModel):
    name: str
    price: float
    is_offer: bool = False

@app.post("/items")
async def create_item(item: Item):
    return item
```

### Combined
```python
@app.put("/items/{item_id}")
async def update_item(
    item_id: int,          # path param
    q: str | None = None,  # query param
    item: Item | None = None  # body
):
    ...
```

## 5. Pydantic Models
Pydantic v2 is the default in FastAPI >= 0.100.

```python
from pydantic import BaseModel, Field, field_validator, model_validator
from typing import Optional, List
from datetime import datetime

class Address(BaseModel):
    street: str
    city: str
    country: str = "US"

class User(BaseModel):
    id: int
    name: str = Field(..., min_length=1, max_length=50, description="Full name")
    email: str = Field(..., pattern=r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$')
    age: Optional[int] = Field(None, ge=0, le=120)
    score: float = Field(default=0.0, ge=0.0, le=100.0)
    tags: List[str] = []
    address: Optional[Address] = None
    created_at: datetime = Field(default_factory=datetime.utcnow)

    @field_validator('name')
    @classmethod
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('Name cannot be blank')
        return v.title()

    @model_validator(mode='after')
    def check_age_email(self):
        if self.age and self.age < 18:
            if 'student' not in self.email:
                raise ValueError('Users under 18 must use student email')
        return self

# Serialization
user = User(id=1, name="alice", email="alice@example.com")
print(user.model_dump())
print(user.model_dump_json())
```

### Field Types
```python
from pydantic import BaseModel, HttpUrl, EmailStr, SecretStr, PositiveInt

class Config(BaseModel):
    url: HttpUrl
    email: EmailStr
    password: SecretStr
    count: PositiveInt
    data: dict[str, list[int]]
```

## 6. Automatic OpenAPI Documentation
FastAPI generates docs automatically:
- **Swagger UI**: `http://localhost:8000/docs`
- **ReDoc**: `http://localhost:8000/redoc`
- **OpenAPI JSON**: `http://localhost:8000/openapi.json`

Customizing docs:
```python
app = FastAPI(
    title="My ML API",
    description="Serves predictions from trained models",
    version="1.0.0",
    docs_url="/documentation",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

@app.get("/items", tags=["Items"], summary="List all items",
         response_description="A list of items")
async def list_items():
    ...
```

## 7. Response Models
```python
class ItemOut(BaseModel):
    id: int
    name: str
    # price NOT included — hidden from response

@app.post("/items", response_model=ItemOut, status_code=201)
async def create_item(item: Item):
    # Even if you return extra fields, FastAPI filters to ItemOut
    return {"id": 1, **item.model_dump()}

# List response
@app.get("/items", response_model=List[ItemOut])
async def list_items():
    return items_db

# Exclude unset fields
@app.patch("/items/{id}", response_model=ItemOut,
           response_model_exclude_unset=True)
async def patch_item(id: int, item: Item):
    ...
```

## 8. Dependency Injection with Depends()
Dependencies are functions that run before your path operation:

```python
from fastapi import Depends, HTTPException, Header

# Simple dependency
def get_db():
    db = SessionLocal()
    try:
        yield db    # yield makes it a context manager
    finally:
        db.close()

# Auth dependency
async def get_current_user(
    authorization: str = Header(...),
    db: Session = Depends(get_db)
):
    token = authorization.replace("Bearer ", "")
    user = verify_token(token, db)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token")
    return user

# Use in route
@app.get("/users/me")
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user

# Class-based dependency
class Pagination:
    def __init__(self, skip: int = 0, limit: int = 100):
        self.skip = skip
        self.limit = limit

@app.get("/items")
async def list_items(pagination: Pagination = Depends()):
    return items[pagination.skip:pagination.skip + pagination.limit]
```

## 9. Async Endpoints: async def vs def
```python
# Use async def when:
# - Calling async libraries (aiohttp, asyncpg, motor)
# - I/O bound operations
@app.get("/async-data")
async def get_async_data():
    result = await some_async_db_call()
    return result

# Use def when:
# - CPU-bound operations
# - Using sync libraries (sync SQLAlchemy, requests)
# FastAPI runs sync def in a thread pool automatically
@app.get("/sync-data")
def get_sync_data():
    return cpu_intensive_computation()
```

**Rule of thumb**: Use `async def` for I/O, `def` for CPU or when using sync libraries.

## 10. Background Tasks
Run tasks after returning the response:

```python
from fastapi import BackgroundTasks
import smtplib

def send_email(email: str, message: str):
    # Runs after response is sent
    print(f"Sending email to {email}")

@app.post("/register")
async def register(user: UserCreate, background_tasks: BackgroundTasks):
    new_user = create_user(user)
    background_tasks.add_task(send_email, user.email, "Welcome!")
    return {"message": "User created"}

# For heavier tasks, use Celery or FastAPI's built-in task queuing
```

## 11. Middleware
```python
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://myapp.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# GZip compression
app.add_middleware(GZipMiddleware, minimum_size=1000)

# Custom middleware
class TimingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        import time
        start = time.time()
        response = await call_next(request)
        duration = time.time() - start
        response.headers["X-Process-Time"] = str(duration)
        return response

app.add_middleware(TimingMiddleware)
```

## 12. Security: OAuth2 and JWT
```python
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import jwt, JWTError

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")
SECRET_KEY = "secret"
ALGORITHM = "HS256"

def create_token(data: dict):
    return jwt.encode(data, SECRET_KEY, algorithm=ALGORITHM)

def verify_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None

@app.post("/token")
async def login(form: OAuth2PasswordRequestForm = Depends()):
    user = authenticate(form.username, form.password)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect credentials")
    token = create_token({"sub": user.username})
    return {"access_token": token, "token_type": "bearer"}

async def get_current_user(token: str = Depends(oauth2_scheme)):
    username = verify_token(token)
    if not username:
        raise HTTPException(status_code=401, detail="Invalid token")
    return username
```

## 13. File Upload
```python
from fastapi import UploadFile, File
import aiofiles

@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    # File metadata
    print(file.filename, file.content_type, file.size)

    # Save to disk
    async with aiofiles.open(f"uploads/{file.filename}", "wb") as out:
        content = await file.read()
        await out.write(content)

    return {"filename": file.filename}

# Multiple files
@app.post("/upload-multiple")
async def upload_multiple(files: list[UploadFile] = File(...)):
    return [{"filename": f.filename} for f in files]
```

## 14. WebSockets
```python
from fastapi import WebSocket

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: int):
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            await websocket.send_text(f"Echo: {data}")
    except Exception:
        await websocket.close()
```

## 15. Testing FastAPI
```python
from fastapi.testclient import TestClient
import pytest

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Hello"}

def test_create_item():
    response = client.post("/items", json={"name": "test", "price": 9.99})
    assert response.status_code == 201
    assert response.json()["name"] == "test"

# Async testing with httpx
import pytest
import httpx

@pytest.mark.anyio
async def test_async():
    async with httpx.AsyncClient(app=app, base_url="http://test") as ac:
        response = await ac.get("/")
    assert response.status_code == 200
```

## 16. Database Integration

### SQLAlchemy (sync)
```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session

engine = create_engine("sqlite:///./test.db")
SessionLocal = sessionmaker(bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/users/{id}")
def get_user(id: int, db: Session = Depends(get_db)):
    return db.query(User).filter(User.id == id).first()
```

### SQLAlchemy Async
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

engine = create_async_engine("postgresql+asyncpg://user:pass@localhost/db")
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
```

## 17. Deployment with uvicorn and gunicorn
```bash
# Development
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Production (multiple workers)
gunicorn main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker \
  --bind 0.0.0.0:8000

# Docker
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install fastapi uvicorn[standard] gunicorn
COPY . .
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Workers formula: `(2 × CPU cores) + 1`

## 18. APIRouter (Blueprint equivalent)
```python
# routers/users.py
from fastapi import APIRouter
router = APIRouter(prefix="/users", tags=["users"])

@router.get("/")
async def list_users(): ...

@router.get("/{user_id}")
async def get_user(user_id: int): ...

# main.py
from routers import users, items
app.include_router(users.router)
app.include_router(items.router)
```