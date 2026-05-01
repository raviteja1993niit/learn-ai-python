# 🌿 Celery — Distributed Task Queue

## What is Celery?
Celery is an **asynchronous task queue** for Python. It offloads long-running tasks
(ML training, email sending, PDF generation) to background workers.

## Architecture
```
[Web App (Flask/Django)] → [Message Broker (Redis/RabbitMQ)] → [Celery Workers]
```

## Key Code
```python
from celery import Celery
import redis

app = Celery("tasks", broker="redis://localhost:6379/0",
             backend="redis://localhost:6379/1")

@app.task
def train_ml_model(dataset_path, params):
    # Long-running ML training — runs in background
    model = train(dataset_path, params)
    return {"accuracy": model.score, "model_path": save(model)}

# In Flask route — fire and forget
result = train_ml_model.delay("data.csv", {"n_estimators": 100})
task_id = result.id  # return to user immediately

# Check status
result = AsyncResult(task_id)
print(result.status)  # PENDING, STARTED, SUCCESS, FAILURE
print(result.result)  # final return value
```

## ML Use Cases
- Background model training triggered from web app
- Scheduled model retraining (Celery Beat)
- Async batch predictions
- Email notifications when training completes

## Learning Path
1. `pip install celery redis`
2. Run Redis: `docker run -d -p 6379:6379 redis`
3. Basic task: `@app.task` + `.delay()`
4. Monitor with Flower: `celery flower`
5. Integrate with Flask app

## What to Build
- [ ] Flask app that triggers async ML training
- [ ] Scheduled model retraining every night (Celery Beat)
- [ ] Batch prediction queue

## Related Folders
- `python-flask/Flask-Web-Framework-main/` — Flask integration
- `cloud-deployment/mlops-main/` — MLOps pipeline