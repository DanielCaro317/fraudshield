# 🏠 LOCAL SETUP GUIDE
## Develop & Test Fraud RAG System On Your Machine

**Perfect for**: Learning, testing, interview prep, zero costs

---

## Prerequisites Check

Before starting, verify you have:

```bash
# Check Python 3.10+
python --version
# Output should be: Python 3.10.x or higher

# Check Docker (for PostgreSQL)
docker --version
# Output should be: Docker version 20.x or higher

# Check Git
git --version
# Output should be: git version 2.x or higher
```

If missing any, install:
- **Python**: https://www.python.org/downloads/ (3.10+)
- **Docker**: https://www.docker.com/products/docker-desktop
- **Git**: https://git-scm.com/download

---

## Step 1: Project Setup (15 minutes)

### 1.1 Create Project Directory

```bash
# Create project folder
mkdir fraud-detection-rag-agent
cd fraud-detection-rag-agent

# Initialize git
git init

# Create folder structure
mkdir -p src/{core,models,api}
mkdir -p tests
mkdir -p docs
mkdir -p .github/workflows
```

### 1.2 Install Poetry (Python Package Manager)

```bash
# Install Poetry
curl -sSL https://install.python-poetry.org | python3 -

# Verify installation
poetry --version
# Output: Poetry (version 1.x.x)
```

### 1.3 Create Project Configuration

Create `pyproject.toml`:

```toml
[tool.poetry]
name = "fraud-detection-rag-agent"
version = "0.1.0"
description = "Fraud detection using RAG and Claude AI"
authors = ["Your Name <you@example.com>"]

[tool.poetry.dependencies]
python = "^3.10"
fastapi = "^0.104.0"
uvicorn = "^0.24.0"
pydantic = "^2.5.0"
sqlalchemy = "^2.0.0"
psycopg2-binary = "^2.9.0"
sentence-transformers = "^2.2.0"
pgvector = "^0.2.0"
anthropic = "^0.7.0"
python-dotenv = "^1.0.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.0"
pytest-asyncio = "^0.21.0"
black = "^23.11.0"
ruff = "^0.1.0"
mypy = "^1.7.0"
pytest-cov = "^4.1.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"
```

### 1.4 Install Dependencies

```bash
# Install all dependencies
poetry install

# Verify
poetry show
```

---

## Step 2: PostgreSQL + pgvector Setup (20 minutes)

### 2.1 Create Docker Compose File

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: pgvector/pgvector:pg15-latest
    container_name: fraud-db
    environment:
      POSTGRES_DB: fraud_detection
      POSTGRES_USER: fraud_user
      POSTGRES_PASSWORD: fraud_password_123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U fraud_user -d fraud_detection"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

### 2.2 Start PostgreSQL

```bash
# Start the database
docker-compose up -d

# Verify it's running
docker ps
# You should see: fraud-db running

# Test connection (wait 10 seconds for health check)
sleep 10
docker exec fraud-db psql -U fraud_user -d fraud_detection -c "SELECT version();"
```

### 2.3 Create .env File

Create `.env`:

```bash
# Database
DATABASE_URL=postgresql://fraud_user:fraud_password_123@localhost:5432/fraud_detection

# API
API_HOST=0.0.0.0
API_PORT=8000

# Claude API
ANTHROPIC_API_KEY=your_api_key_here
```

Get your ANTHROPIC_API_KEY:
1. Go to https://console.anthropic.com/
2. Create account / log in
3. Go to API Keys
4. Create new key
5. Copy and paste into `.env`

---

## Step 3: FastAPI Setup (10 minutes)

### 3.1 Create Config File

Create `src/config.py`:

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str
    api_host: str = "0.0.0.0"
    api_port: int = 8000
    anthropic_api_key: str
    
    class Config:
        env_file = ".env"

settings = Settings()
```

### 3.2 Create Database Connection

Create `src/database.py`:

```python
from sqlalchemy import create_engine, event
from sqlalchemy.orm import declarative_base, sessionmaker
from src.config import settings

engine = create_engine(
    settings.database_url,
    echo=False,
    pool_pre_ping=True
)

SessionLocal = sessionmaker(bind=engine, expire_on_commit=False)
Base = declarative_base()

# Enable pgvector
@event.listens_for(engine, "connect")
def load_pgvector(dbapi_conn, connection_record):
    dbapi_conn.execute("CREATE EXTENSION IF NOT EXISTS vector")

async def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### 3.3 Create Main FastAPI App

Create `src/main.py`:

```python
from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from src.database import Base, engine, get_db

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Fraud Detection RAG Agent",
    description="Investigate fraudulent transactions using RAG and Claude AI",
    version="0.1.0"
)

@app.get("/health")
async def health():
    """Health check endpoint"""
    return {"status": "ok", "service": "fraud-detection-rag"}

@app.get("/ready")
async def ready(db: Session = Depends(get_db)):
    """Readiness check (includes database)"""
    try:
        db.execute("SELECT 1")
        return {"status": "ready", "database": "connected"}
    except Exception as e:
        return {"status": "not_ready", "error": str(e)}, 503

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

---

## Step 4: Pydantic Models & Validation (15 minutes)

### 4.1 Create Database Models

Create `src/models/database.py`:

```python
from sqlalchemy import Column, String, Float, DateTime, Integer
from datetime import datetime
from src.database import Base

class Transaction(Base):
    __tablename__ = "transactions"
    
    id = Column(String, primary_key=True)
    user_id = Column(String, nullable=False, index=True)
    amount = Column(Float, nullable=False)
    beneficiary_country = Column(String(2))
    timestamp = Column(DateTime, default=datetime.utcnow)
    ml_fraud_score = Column(Float)
    status = Column(String(20), default="pending")

class FraudCase(Base):
    __tablename__ = "fraud_cases"
    
    id = Column(String, primary_key=True)
    title = Column(String, nullable=False)
    description = Column(String)
    case_type = Column(String(50))
```

### 4.2 Create Pydantic Schemas

Create `src/models/schemas.py`:

```python
from pydantic import BaseModel, Field

class InvestigateRequest(BaseModel):
    """Request to investigate a transaction (VALIDATED)"""
    transaction_id: str = Field(..., min_length=1, description="Transaction ID")
    fraud_score: float = Field(..., ge=0.0, le=1.0, description="Fraud score 0-1")
    user_id: str = Field(..., min_length=1)
    amount: float = Field(..., gt=0)
    beneficiary_country: str = Field(..., min_length=2, max_length=2)

class InvestigateResponse(BaseModel):
    """Response with investigation results"""
    transaction_id: str
    risk_level: str  # LOW, MEDIUM, HIGH, CRITICAL
    recommendation: str  # APPROVE, BLOCK, ESCALATE
    reasoning: str
    similar_cases_count: int
```

---

## Step 5: Write First Tests (20 minutes)

### 5.1 Create Test File

Create `tests/test_api.py`:

```python
import pytest
from fastapi.testclient import TestClient
from src.main import app

client = TestClient(app)

def test_health_endpoint():
    """Test health endpoint returns 200"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

def test_ready_endpoint():
    """Test ready endpoint (requires database)"""
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"

def test_invalid_fraud_score_rejected():
    """Test input validation (SECURITY)"""
    response = client.post("/api/investigate", 
        json={
            "transaction_id": "tx_1",
            "fraud_score": 5.0,  # Invalid: should be 0-1
            "user_id": "user_1",
            "amount": 100.0,
            "beneficiary_country": "US"
        }
    )
    assert response.status_code == 422  # Validation error

def test_valid_investigation_request():
    """Test valid investigation request"""
    response = client.post("/api/investigate",
        json={
            "transaction_id": "tx_1",
            "fraud_score": 0.85,  # Valid
            "user_id": "user_1",
            "amount": 1000.0,
            "beneficiary_country": "GH"
        }
    )
    # Endpoint not implemented yet, so 404 is expected
    assert response.status_code in [200, 404]
```

### 5.2 Run Tests

```bash
# Run tests
poetry run pytest tests/ -v

# Output should show tests running
# ✓ test_health_endpoint
# ✓ test_ready_endpoint
# ✓ test_invalid_fraud_score_rejected
```

---

## Step 6: Setup Linting & Code Quality (15 minutes)

### 6.1 Configure Black (Formatter)

```bash
# Format your code
poetry run black src/ tests/

# Check without formatting
poetry run black --check src/ tests/
```

### 6.2 Configure Ruff (Linter)

```bash
# Check for linting issues
poetry run ruff check src/ tests/

# Fix auto-fixable issues
poetry run ruff check --fix src/ tests/
```

### 6.3 Configure mypy (Type Checker)

Create `pyproject.toml` additions:

```toml
[tool.mypy]
python_version = "3.10"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = false

[tool.black]
line-length = 88
target-version = ['py310']

[tool.ruff]
line-length = 88
target-version = "py310"
```

Run type check:

```bash
poetry run mypy src/
```

---

## Step 7: GitHub Actions CI/CD Setup (10 minutes)

### 7.1 Create GitHub Actions Workflow

Create `.github/workflows/ci-cd.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: pgvector/pgvector:pg15-latest
        env:
          POSTGRES_DB: fraud_detection
          POSTGRES_USER: fraud_user
          POSTGRES_PASSWORD: fraud_password_123
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install Poetry
        run: curl -sSL https://install.python-poetry.org | python3 -
      
      - name: Install dependencies
        run: poetry install
      
      - name: Lint with Black
        run: poetry run black --check src/ tests/
      
      - name: Lint with Ruff
        run: poetry run ruff check src/ tests/
      
      - name: Type check with mypy
        run: poetry run mypy src/
      
      - name: Run tests
        run: poetry run pytest tests/ --cov=src
        env:
          DATABASE_URL: postgresql://fraud_user:fraud_password_123@localhost:5432/fraud_detection
          ANTHROPIC_API_KEY: dummy_key_for_tests
```

---

## Step 8: Start Development (5 minutes)

### 8.1 Run FastAPI Server

```bash
# Terminal 1: Start FastAPI
poetry run uvicorn src.main:app --reload --host 0.0.0.0 --port 8000

# Output:
# INFO:     Uvicorn running on http://0.0.0.0:8000
# INFO:     Application startup complete
```

### 8.2 Test in Another Terminal

```bash
# Terminal 2: Test the API
curl http://localhost:8000/health

# Output:
# {"status":"ok","service":"fraud-detection-rag"}
```

### 8.3 View API Documentation

Open browser: http://localhost:8000/docs

You'll see interactive Swagger documentation!

---

## Daily Workflow

### Morning
```bash
# Update your code
# (Edit files in src/)

# Format code
poetry run black src/

# Check linting
poetry run ruff check src/

# Type check
poetry run mypy src/
```

### Throughout Day
```bash
# Run tests (watch mode)
poetry run pytest tests/ --watch

# Or run specific test
poetry run pytest tests/test_api.py::test_health_endpoint -v
```

### Before Committing
```bash
# Full quality check
poetry run black --check src/ tests/
poetry run ruff check src/ tests/
poetry run mypy src/
poetry run pytest tests/ --cov=src
```

---

## Troubleshooting

### PostgreSQL won't connect
```bash
# Check if running
docker ps | grep fraud-db

# Restart if needed
docker-compose restart postgres

# Wait for health check
sleep 10

# Test connection
docker exec fraud-db psql -U fraud_user -d fraud_detection -c "SELECT 1"
```

### Poetry lock issues
```bash
# Remove lock file and reinstall
rm poetry.lock
poetry install
```

### Tests failing
```bash
# Check database is running
docker ps | grep fraud-db

# Check environment variables
cat .env

# Run single test with output
poetry run pytest tests/test_api.py::test_health_endpoint -v -s
```

### Port 8000 in use
```bash
# Use different port
poetry run uvicorn src.main:app --reload --port 8001
```

---

## Next Steps

Once this is working:

1. **Read**: `03_LEARNING_MILESTONES.md` for today's tasks
2. **Continue**: Follow Day 1-2 milestones
3. **Build**: Add more endpoints and tests
4. **Record**: Communication practice explanations

---

## Summary

You now have:
- ✅ Project structure ready
- ✅ FastAPI server running
- ✅ PostgreSQL with pgvector
- ✅ Pydantic validation
- ✅ pytest testing
- ✅ Code quality tools (Black, Ruff, mypy)
- ✅ GitHub Actions CI/CD
- ✅ API documentation at /docs

**Time spent**: ~90 minutes
**Next**: Read `03_LEARNING_MILESTONES.md` for Day 1-2 tasks

Let's build! 🚀
