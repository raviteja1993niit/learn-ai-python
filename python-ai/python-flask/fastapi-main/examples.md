# FastAPI — 20+ Annotated Code Examples

## Example 1: Minimal FastAPI App
```python
from fastapi import FastAPI

app = FastAPI(title="My API", version="1.0.0")

@app.get("/")
async def root():
    return {"message": "Hello FastAPI!"}

@app.get("/items/{item_id}")
async def get_item(item_id: int, q: str | None = None):
    result = {"item_id": item_id}
    if q:
        result["q"] = q
    return result

# Run: uvicorn main:app --reload
```

## Example 2: Pydantic Request and Response Models
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, EmailStr
from typing import Optional, List
from datetime import datetime

app = FastAPI()

class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=30)
    email: EmailStr
    age: Optional[int] = Field(None, ge=0, le=120)
    bio: str = Field(default="", max_length=500)

class UserOut(BaseModel):
    id: int
    username: str
    email: str
    created_at: datetime

    model_config = {"from_attributes": True}

users_db = {}

@app.post("/users", response_model=UserOut, status_code=201)
async def create_user(user: UserCreate):
    new_id = len(users_db) + 1
    db_user = {
        "id": new_id,
        "username": user.username,
        "email": user.email,
        "created_at": datetime.utcnow()
    }
    users_db[new_id] = db_user
    return db_user

@app.get("/users/{user_id}", response_model=UserOut)
async def get_user(user_id: int):
    if user_id not in users_db:
        raise HTTPException(status_code=404, detail=f"User {user_id} not found")
    return users_db[user_id]
```

## Example 3: Query Parameters and Filtering
```python
from fastapi import FastAPI, Query
from typing import Optional, List

app = FastAPI()

ITEMS = [{"id": i, "name": f"Item {i}", "category": "A" if i % 2 == 0 else "B",
          "price": i * 10.5} for i in range(1, 51)]

@app.get("/items")
async def list_items(
    skip: int = Query(0, ge=0, description="Number of items to skip"),
    limit: int = Query(10, ge=1, le=100, description="Max items to return"),
    category: Optional[str] = Query(None, description="Filter by category"),
    min_price: Optional[float] = Query(None, ge=0),
    max_price: Optional[float] = Query(None, ge=0),
    sort_by: str = Query("id", regex="^(id|name|price)$"),
):
    results = ITEMS.copy()
    if category:
        results = [i for i in results if i["category"] == category]
    if min_price is not None:
        results = [i for i in results if i["price"] >= min_price]
    if max_price is not None:
        results = [i for i in results if i["price"] <= max_price]
    results.sort(key=lambda x: x[sort_by])
    return {
        "items": results[skip:skip + limit],
        "total": len(results),
        "skip": skip,
        "limit": limit
    }
```

## Example 4: Dependency Injection
```python
from fastapi import FastAPI, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Generator

app = FastAPI()

# Database dependency
def get_db() -> Generator:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pagination dependency
class PaginationParams:
    def __init__(
        self,
        skip: int = Query(0, ge=0),
        limit: int = Query(10, ge=1, le=100)
    ):
        self.skip = skip
        self.limit = limit

# API key auth dependency
API_KEYS = {"key123": "alice", "key456": "bob"}

def get_api_key(x_api_key: str = Header(...)):
    if x_api_key not in API_KEYS:
        raise HTTPException(status_code=403, detail="Invalid API Key")
    return API_KEYS[x_api_key]

@app.get("/items")
async def list_items(
    pagination: PaginationParams = Depends(),
    db: Session = Depends(get_db),
    current_user: str = Depends(get_api_key)
):
    items = db.query(Item).offset(pagination.skip).limit(pagination.limit).all()
    return {"items": items, "user": current_user}
```

## Example 5: JWT Authentication
```python
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel
from datetime import datetime, timedelta

SECRET_KEY = "your-256-bit-secret"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30

app = FastAPI()
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")

class Token(BaseModel):
    access_token: str
    token_type: str

def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    return username

@app.post("/token", response_model=Token)
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    user = authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=400, detail="Incorrect credentials")
    token = create_access_token({"sub": form_data.username})
    return Token(access_token=token, token_type="bearer")

@app.get("/users/me")
async def get_me(current_user: str = Depends(get_current_user)):
    return {"username": current_user}
```

## Example 6: File Upload with Validation
```python
from fastapi import FastAPI, UploadFile, File, HTTPException
import aiofiles
import os

app = FastAPI()

ALLOWED_TYPES = {"image/jpeg", "image/png", "image/gif", "application/pdf"}
MAX_SIZE_MB = 5

@app.post("/upload")
async def upload(file: UploadFile = File(...)):
    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(400, f"File type '{file.content_type}' not allowed")

    content = await file.read()
    size_mb = len(content) / (1024 * 1024)
    if size_mb > MAX_SIZE_MB:
        raise HTTPException(400, f"File too large: {size_mb:.1f}MB (max {MAX_SIZE_MB}MB)")

    os.makedirs("uploads", exist_ok=True)
    safe_name = file.filename.replace(" ", "_")
    path = f"uploads/{safe_name}"

    async with aiofiles.open(path, 'wb') as f:
        await f.write(content)

    return {"filename": file.filename, "size_mb": round(size_mb, 2), "path": path}
```

## Example 7: Background Tasks
```python
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
import time

app = FastAPI()

def process_report(report_id: int, email: str):
    """Runs after response is sent"""
    time.sleep(5)  # Simulate heavy computation
    print(f"Report {report_id} generated, emailing {email}")

class ReportRequest(BaseModel):
    title: str
    email: str

@app.post("/reports", status_code=202)
async def create_report(
    req: ReportRequest,
    background_tasks: BackgroundTasks
):
    report_id = 42  # Create DB record
    background_tasks.add_task(process_report, report_id, req.email)
    return {
        "report_id": report_id,
        "status": "processing",
        "message": f"Report queued. Results will be emailed to {req.email}"
    }
```

## Example 8: WebSocket Chat
```python
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from typing import List

app = FastAPI()

class ConnectionManager:
    def __init__(self):
        self.active: List[WebSocket] = []

    async def connect(self, ws: WebSocket):
        await ws.accept()
        self.active.append(ws)

    def disconnect(self, ws: WebSocket):
        self.active.remove(ws)

    async def broadcast(self, message: str):
        for connection in self.active:
            await connection.send_text(message)

manager = ConnectionManager()

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    await manager.connect(websocket)
    await manager.broadcast(f"{client_id} joined the chat")
    try:
        while True:
            data = await websocket.receive_text()
            await manager.broadcast(f"{client_id}: {data}")
    except WebSocketDisconnect:
        manager.disconnect(websocket)
        await manager.broadcast(f"{client_id} left the chat")
```

## Example 9: Custom Middleware
```python
from fastapi import FastAPI, Request
from starlette.middleware.base import BaseHTTPMiddleware
from fastapi.middleware.cors import CORSMiddleware
import time
import logging

app = FastAPI()

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://myapp.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom timing middleware
class TimingMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start = time.time()
        response = await call_next(request)
        process_time = (time.time() - start) * 1000
        response.headers["X-Process-Time"] = f"{process_time:.1f}ms"
        logging.info(f"{request.method} {request.url.path} "
                     f"-> {response.status_code} in {process_time:.1f}ms")
        return response

app.add_middleware(TimingMiddleware)
```

## Example 10: ML Prediction with Pydantic Validation
```python
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field, field_validator
import joblib
import numpy as np

app = FastAPI(title="ML Prediction API")

class PredictionRequest(BaseModel):
    age: int = Field(..., ge=18, le=65, description="Applicant age")
    salary: float = Field(..., ge=0, description="Annual salary in USD")
    experience: int = Field(..., ge=0, le=50, description="Years of experience")
    education: str = Field(..., description="Education level")

    @field_validator('education')
    @classmethod
    def validate_education(cls, v):
        valid = ['high_school', 'bachelor', 'master', 'phd']
        if v not in valid:
            raise ValueError(f"Must be one of: {valid}")
        return v

class PredictionResponse(BaseModel):
    prediction: int
    probability: float
    label: str
    model_version: str = "1.0.0"

model = joblib.load("models/hiring_model.pkl")
EDU_MAP = {'high_school': 0, 'bachelor': 1, 'master': 2, 'phd': 3}

@app.post("/predict", response_model=PredictionResponse)
async def predict(req: PredictionRequest):
    features = np.array([[
        req.age, req.salary, req.experience, EDU_MAP[req.education]
    ]])
    pred = int(model.predict(features)[0])
    prob = float(model.predict_proba(features).max())
    return PredictionResponse(
        prediction=pred,
        probability=round(prob, 4),
        label="Hired" if pred == 1 else "Not Hired"
    )
```

## Example 11: APIRouter with Tags
```python
from fastapi import APIRouter, FastAPI, Depends, HTTPException

app = FastAPI()

# Users router
users_router = APIRouter(prefix="/users", tags=["Users"])

@users_router.get("/", summary="List all users")
async def list_users():
    return []

@users_router.post("/", status_code=201, summary="Create user")
async def create_user(user: UserCreate):
    return user

@users_router.get("/{user_id}")
async def get_user(user_id: int):
    return {"id": user_id}

# Items router
items_router = APIRouter(prefix="/items", tags=["Items"])

@items_router.get("/")
async def list_items():
    return []

# Register routers
app.include_router(users_router)
app.include_router(items_router)
app.include_router(
    auth_router,
    prefix="/auth",
    tags=["Authentication"],
    dependencies=[Depends(verify_api_key)]
)
```

## Example 12: Error Handling and Custom Exceptions
```python
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

app = FastAPI()

class ModelNotLoadedException(Exception):
    pass

class PredictionException(Exception):
    def __init__(self, detail: str):
        self.detail = detail

@app.exception_handler(ModelNotLoadedException)
async def model_not_loaded_handler(request: Request, exc: ModelNotLoadedException):
    return JSONResponse(
        status_code=503,
        content={"error": "Model not available", "message": "Please retry later"}
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=422,
        content={
            "error": "Validation Error",
            "details": exc.errors(),
            "body": exc.body
        }
    )

@app.exception_handler(PredictionException)
async def prediction_exception_handler(request: Request, exc: PredictionException):
    return JSONResponse(status_code=500, content={"error": exc.detail})
```

## Example 13: Database with SQLAlchemy
```python
from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy import create_engine, Column, Integer, String, Boolean
from sqlalchemy.orm import DeclarativeBase, sessionmaker, Session
from pydantic import BaseModel

SQLALCHEMY_DATABASE_URL = "sqlite:///./todos.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

class Base(DeclarativeBase):
    pass

class TodoDB(Base):
    __tablename__ = "todos"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(200), nullable=False)
    done = Column(Boolean, default=False)

Base.metadata.create_all(bind=engine)
app = FastAPI()

class TodoCreate(BaseModel):
    title: str

class TodoOut(BaseModel):
    id: int
    title: str
    done: bool
    model_config = {"from_attributes": True}

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.get("/todos", response_model=list[TodoOut])
def list_todos(db: Session = Depends(get_db)):
    return db.query(TodoDB).all()

@app.post("/todos", response_model=TodoOut, status_code=201)
def create_todo(todo: TodoCreate, db: Session = Depends(get_db)):
    db_todo = TodoDB(title=todo.title)
    db.add(db_todo)
    db.commit()
    db.refresh(db_todo)
    return db_todo

@app.delete("/todos/{todo_id}", status_code=204)
def delete_todo(todo_id: int, db: Session = Depends(get_db)):
    todo = db.query(TodoDB).filter(TodoDB.id == todo_id).first()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    db.delete(todo)
    db.commit()
```

## Example 14: Streaming Response
```python
from fastapi import FastAPI
from fastapi.responses import StreamingResponse
import asyncio

app = FastAPI()

async def generate_tokens(prompt: str):
    """Simulate streaming LLM output"""
    words = f"Response to: {prompt}. This is a streaming example.".split()
    for word in words:
        yield word + " "
        await asyncio.sleep(0.1)

@app.post("/stream")
async def stream_response(prompt: str):
    return StreamingResponse(
        generate_tokens(prompt),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-cache"}
    )

# Large file download
@app.get("/download-large-file")
async def download():
    async def generate():
        for i in range(10000):
            yield f"row_{i},data_{i},value_{i}\n".encode()

    return StreamingResponse(
        generate(),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=large.csv"}
    )
```

## Example 15: Rate Limiting with slowapi
```python
from fastapi import FastAPI, Request
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

limiter = Limiter(key_func=get_remote_address)
app = FastAPI()
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

@app.get("/predict")
@limiter.limit("30/minute")
async def predict(request: Request):
    return {"prediction": 1}

@app.get("/health")
async def health():  # No rate limit
    return {"status": "ok"}
```

## Example 16: Testing FastAPI with TestClient
```python
from fastapi.testclient import TestClient
import pytest
from main import app

client = TestClient(app)

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert "message" in response.json()

def test_create_and_get_user():
    # Create
    create_resp = client.post("/users", json={
        "username": "testuser",
        "email": "test@example.com"
    })
    assert create_resp.status_code == 201
    user_id = create_resp.json()["id"]

    # Get
    get_resp = client.get(f"/users/{user_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["username"] == "testuser"

def test_validation_error():
    resp = client.post("/users", json={"username": "a"})  # Too short
    assert resp.status_code == 422

def test_not_found():
    resp = client.get("/users/9999")
    assert resp.status_code == 404

def test_predict_valid():
    resp = client.post("/predict", json={
        "age": 30, "salary": 70000, "experience": 5, "education": "bachelor"
    })
    assert resp.status_code == 200
    assert "prediction" in resp.json()
    assert "probability" in resp.json()

def test_predict_invalid():
    resp = client.post("/predict", json={"age": 5})  # Below minimum age
    assert resp.status_code == 422
```

## Example 17: Health Check and Startup Events
```python
from fastapi import FastAPI
from contextlib import asynccontextmanager
import joblib
import time

model = None
start_time = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    global model, start_time
    print("Loading model...")
    model = joblib.load("models/model.pkl")
    start_time = time.time()
    print("Model loaded!")
    yield
    # Shutdown
    print("Shutting down, cleaning up...")

app = FastAPI(lifespan=lifespan)

@app.get("/health")
async def health():
    return {
        "status": "ok" if model is not None else "degraded",
        "model_loaded": model is not None,
        "uptime_seconds": round(time.time() - start_time, 0) if start_time else 0,
    }
```

## Example 18: Pagination with Link Headers
```python
from fastapi import FastAPI, Query, Response, Request
from math import ceil

app = FastAPI()
DATA = list(range(1, 201))

@app.get("/numbers")
async def get_numbers(
    request: Request,
    response: Response,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100)
):
    total = len(DATA)
    total_pages = ceil(total / per_page)
    start = (page - 1) * per_page
    items = DATA[start:start + per_page]

    base_url = str(request.base_url).rstrip('/')
    links = [f'<{base_url}/numbers?page={total_pages}&per_page={per_page}>; rel="last"']
    if page < total_pages:
        links.append(f'<{base_url}/numbers?page={page+1}&per_page={per_page}>; rel="next"')
    if page > 1:
        links.append(f'<{base_url}/numbers?page={page-1}&per_page={per_page}>; rel="prev"')

    response.headers["Link"] = ", ".join(links)
    response.headers["X-Total-Count"] = str(total)
    response.headers["X-Total-Pages"] = str(total_pages)

    return {"items": items, "page": page, "total": total}
```

## Example 19: Response Caching
```python
from fastapi import FastAPI
from fastapi.responses import JSONResponse
import hashlib, json, time
from functools import lru_cache

app = FastAPI()

# Simple in-memory cache
cache = {}
CACHE_TTL = 60  # seconds

def get_cached(key: str):
    if key in cache:
        data, timestamp = cache[key]
        if time.time() - timestamp < CACHE_TTL:
            return data
        del cache[key]
    return None

def set_cached(key: str, data):
    cache[key] = (data, time.time())

@app.get("/stats")
async def get_stats(category: str):
    cache_key = f"stats_{category}"
    cached = get_cached(cache_key)
    if cached:
        return JSONResponse(content=cached, headers={"X-Cache": "HIT"})

    # Expensive computation
    result = {"category": category, "count": 42, "avg": 3.14}
    set_cached(cache_key, result)
    return JSONResponse(content=result, headers={"X-Cache": "MISS"})
```

## Example 20: Full CRUD API with Nested Models
```python
from fastapi import FastAPI, HTTPException, Depends, status
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

app = FastAPI()

class TagBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)

class PostCreate(BaseModel):
    title: str = Field(..., min_length=5, max_length=200)
    content: str = Field(..., min_length=1)
    tags: List[str] = Field(default_factory=list, max_length=5)
    is_published: bool = False

class PostUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=5)
    content: Optional[str] = None
    is_published: Optional[bool] = None

class PostOut(BaseModel):
    id: int
    title: str
    content: str
    tags: List[str]
    is_published: bool
    created_at: datetime

posts_db: dict[int, dict] = {}
_next_id = 1

@app.get("/posts", response_model=List[PostOut])
async def list_posts(published_only: bool = False):
    posts = list(posts_db.values())
    if published_only:
        posts = [p for p in posts if p["is_published"]]
    return posts

@app.post("/posts", response_model=PostOut, status_code=201)
async def create_post(post: PostCreate):
    global _next_id
    new_post = {
        "id": _next_id,
        **post.model_dump(),
        "created_at": datetime.utcnow()
    }
    posts_db[_next_id] = new_post
    _next_id += 1
    return new_post

@app.patch("/posts/{post_id}", response_model=PostOut)
async def update_post(post_id: int, update: PostUpdate):
    if post_id not in posts_db:
        raise HTTPException(status_code=404, detail="Post not found")
    post = posts_db[post_id]
    update_data = update.model_dump(exclude_unset=True)
    post.update(update_data)
    return post

@app.delete("/posts/{post_id}", status_code=204)
async def delete_post(post_id: int):
    if post_id not in posts_db:
        raise HTTPException(status_code=404, detail="Post not found")
    del posts_db[post_id]
```