# FastAPI — 10 Hands-On Projects

## Project 1: CRUD Todo API
**Goal**: Full REST CRUD with Pydantic validation and SQLite

### Requirements
- Pydantic models: `TodoCreate`, `TodoUpdate`, `TodoOut`
- SQLAlchemy ORM with async session
- Endpoints: GET/POST /todos, GET/PUT/DELETE /todos/{id}
- Filter by `?done=true&limit=10&skip=0`
- Auto-generated Swagger docs at /docs

### Models
```python
class TodoCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str = Field(default="", max_length=1000)
    priority: int = Field(1, ge=1, le=5)

class TodoUpdate(BaseModel):
    title: Optional[str] = None
    done: Optional[bool] = None
    priority: Optional[int] = Field(None, ge=1, le=5)
```

### Hints
- Use `status_code=201` for POST, `status_code=204` for DELETE
- Return `None` with 204 (no response body)
- Use `response_model_exclude_unset=True` for PATCH endpoints

---

## Project 2: ML Prediction API with Pydantic Validation
**Goal**: Serve a sklearn model with strict Pydantic input/output validation

### Steps
1. Train hiring classifier → save pipeline
2. Define strict Pydantic schemas with validators
3. Build FastAPI app with `/predict`, `/batch-predict`, `/health`
4. Test with TestClient

### Schema Design
```python
class PredictionInput(BaseModel):
    age: int = Field(..., ge=18, le=65)
    salary: float = Field(..., gt=0)
    experience: int = Field(..., ge=0, le=50)
    education: Literal["high_school", "bachelor", "master", "phd"]

class PredictionOutput(BaseModel):
    prediction: int
    probability: float = Field(..., ge=0, le=1)
    label: str
    processing_time_ms: float
```

### Bonus
- Add `Depends()` for model loading
- Return 503 if model not loaded
- Add `/batch-predict` accepting `List[PredictionInput]`

---

## Project 3: User Authentication System with JWT
**Goal**: Full auth system with registration, login, protected routes

### Endpoints
```
POST /auth/register   — Register new user (hashed password)
POST /auth/login      — Returns JWT access + refresh tokens
POST /auth/refresh    — Get new access token from refresh token
GET  /users/me        — Protected: return current user
GET  /users           — Admin only
```

### Tech Stack
- `passlib[bcrypt]` for password hashing
- `python-jose[cryptography]` for JWT
- SQLAlchemy for users table
- Custom `get_current_user` dependency

### Hints
```python
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"])
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")

class CurrentUser:
    def __init__(self, db=Depends(get_db), token=Depends(oauth2_scheme)):
        ...
```

---

## Project 4: File Upload and Processing Service
**Goal**: Upload, store, process, and download files

### Endpoints
```
POST /files/upload           — Upload file, return file_id
GET  /files/{file_id}        — Get file metadata
GET  /files/{file_id}/download — Download the file
DELETE /files/{file_id}      — Delete file
POST /files/{file_id}/process — Background task: process CSV/image
GET  /files/{file_id}/status  — Processing status
```

### Hints
- Use `UploadFile` with content type validation
- Store file metadata in SQLite
- Use `BackgroundTasks` for file processing
- Return file with `FileResponse` for downloads

```python
from fastapi.responses import FileResponse
import aiofiles

@app.post("/files/upload")
async def upload(file: UploadFile = File(...), bg: BackgroundTasks = ...):
    file_id = uuid.uuid4().hex
    async with aiofiles.open(f"uploads/{file_id}", "wb") as f:
        await f.write(await file.read())
    bg.add_task(process_file, file_id)
    return {"file_id": file_id}
```

---

## Project 5: Real-Time Chat with WebSockets
**Goal**: Build a multi-room chat server with WebSockets

### Requirements
- Multiple named rooms
- Join/leave room notifications
- Persist last 50 messages per room
- REST API: GET /rooms, GET /rooms/{name}/history
- WebSocket: ws://host/ws/{room}/{username}

### ConnectionManager
```python
class RoomManager:
    def __init__(self):
        self.rooms: dict[str, list[WebSocket]] = {}

    async def join(self, room: str, ws: WebSocket):
        await ws.accept()
        self.rooms.setdefault(room, []).append(ws)

    async def broadcast_room(self, room: str, msg: str):
        for ws in self.rooms.get(room, []):
            try:
                await ws.send_text(msg)
            except:
                pass
```

---

## Project 6: Product Catalog API with Search
**Goal**: Full-featured product catalog with filtering and full-text search

### Features
- Products with categories (many-to-many), price range, stock
- Filtering: `?category=electronics&min_price=100&max_price=1000&in_stock=true`
- Search: `?q=laptop` (search name + description)
- Sorting: `?sort_by=price&order=asc`
- Cursor-based pagination
- Bulk create: `POST /products/bulk` accepting a list

### Hints
```python
@app.get("/products")
async def list_products(
    q: Optional[str] = Query(None, min_length=2),
    category: Optional[str] = None,
    min_price: Optional[float] = Query(None, ge=0),
    max_price: Optional[float] = Query(None, ge=0),
    in_stock: Optional[bool] = None,
    sort_by: str = Query("name", regex="^(name|price|created_at)$"),
    order: str = Query("asc", regex="^(asc|desc)$"),
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: Session = Depends(get_db)
):
```

---

## Project 7: API Rate Limiter + API Keys
**Goal**: Secure FastAPI with API keys and per-key rate limiting

### Requirements
- Generate API keys (POST /admin/keys)
- Verify key on every request
- Tier-based limits: free=100/day, premium=10000/day
- Track usage per key in Redis or SQLite
- `GET /usage` returns current key's usage stats

### Custom Dependency
```python
from fastapi import Security
from fastapi.security.api_key import APIKeyHeader

api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)

async def verify_api_key(
    api_key: str = Security(api_key_header),
    db: Session = Depends(get_db)
):
    if not api_key:
        raise HTTPException(401, "API key required")
    key_record = db.query(APIKey).filter_by(key=api_key).first()
    if not key_record:
        raise HTTPException(403, "Invalid API key")
    return key_record
```

---

## Project 8: Notification Service
**Goal**: Background notifications with WebSocket push and email

### Architecture
```
Client → POST /notifications → DB → Background task
Background task → email (sync) + WebSocket push (async)
Client connects to ws://host/ws/notifications → receives live updates
```

### Requirements
- `POST /notifications` — create notification (runs in background)
- `GET /notifications` — paginated list, with read/unread filter
- `PATCH /notifications/{id}/read` — mark as read
- `WS /ws/notifications` — real-time push for new notifications

---

## Project 9: ML Microservice with Async DB
**Goal**: Production FastAPI ML service with async SQLAlchemy

### Stack
- FastAPI + async SQLAlchemy + asyncpg (PostgreSQL)
- Alembic for migrations
- Pydantic v2 for schemas
- pytest-asyncio for async tests

### Setup
```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

DATABASE_URL = "postgresql+asyncpg://user:pass@localhost/mldb"
engine = create_async_engine(DATABASE_URL)
async_session = sessionmaker(engine, class_=AsyncSession)

@asynccontextmanager
async def lifespan(app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield

app = FastAPI(lifespan=lifespan)
```

### Endpoints
- `POST /predict` — async prediction + log to DB
- `GET /predictions` — paginated prediction history
- `GET /stats` — async aggregate statistics

---

## Project 10: API Gateway Pattern
**Goal**: Build an API gateway that routes to multiple microservices

### Architecture
```
Client → FastAPI Gateway
    ├── /api/users/*   → User Service (localhost:8001)
    ├── /api/products/* → Product Service (localhost:8002)
    └── /api/ml/*      → ML Service (localhost:8003)
```

### Requirements
- Route requests to downstream services with `httpx.AsyncClient`
- Add authentication at gateway level
- Add request/response logging
- Circuit breaker: if downstream fails 3 times, return 503 for 60s
- Load balancing: round-robin across multiple instances

### Hints
```python
import httpx

async def proxy_request(service_url: str, path: str, request: Request):
    async with httpx.AsyncClient() as client:
        resp = await client.request(
            method=request.method,
            url=f"{service_url}{path}",
            headers=dict(request.headers),
            content=await request.body()
        )
        return Response(resp.content, status_code=resp.status_code,
                       headers=dict(resp.headers))
```