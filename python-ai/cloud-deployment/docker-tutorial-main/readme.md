# 🐳 Docker — Containerize Everything

## What is Docker?
Docker packages your application + all its dependencies into a **container** that
runs identically on any machine — dev, staging, production.

## Core Concepts
| Concept | Description |
|---------|-------------|
| **Image** | Blueprint — built from a Dockerfile |
| **Container** | Running instance of an image |
| **Dockerfile** | Instructions to build an image |
| **docker-compose** | Run multi-container apps (app + DB + Redis) |
| **Registry** | Docker Hub — store and share images |
| **Volume** | Persistent storage for containers |
| **Network** | Communication between containers |

## ML App Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
```

## Essential Commands
```bash
docker build -t my-ml-app .          # build image
docker run -p 5000:5000 my-ml-app    # run container
docker ps                             # list running containers
docker logs <container_id>            # view logs
docker exec -it <id> bash             # shell into container
docker-compose up -d                  # start all services
docker push username/my-ml-app        # push to Docker Hub
```

## docker-compose.yml for ML App
```yaml
version: "3.8"
services:
  app:
    build: .
    ports: ["5000:5000"]
    depends_on: [db, redis]
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: secret
  redis:
    image: redis:7
```

## Learning Path
1. Install Docker Desktop
2. Run `docker run hello-world`
3. Dockerize your Flask app
4. Add PostgreSQL with docker-compose
5. Push to Docker Hub
6. Deploy Docker container to AWS ECS / Beanstalk

## What to Build
- [ ] Dockerize the Car Price Flask app
- [ ] Multi-container: Flask + PostgreSQL + Redis
- [ ] Docker image for LangChain RAG app

## Related Folders
- `cloud-deployment/Kubernet-Dockers-master/` — Kubernetes (next step after Docker)
- `python-flask/Flask-Web-Framework-main/` — app to containerize
- `cloud-deployment/beanstalk-main/` — deploy Docker to AWS Beanstalk