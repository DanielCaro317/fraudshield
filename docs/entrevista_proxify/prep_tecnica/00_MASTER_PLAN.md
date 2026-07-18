# 🎯 MASTER LEARNING PLAN
## 2-Week Intensive: Build Fraud Detection RAG System While Mastering Technical Concepts

---

## 📁 Project Structure

```
fraud-detection-rag-agent/
├── docs/                          # All documentation
│   ├── 00_MASTER_PLAN.md         # This file
│   ├── 01_LOCAL_SETUP.md         # Local development (desktop/laptop)
│   ├── 02_CLOUD_SETUP.md         # AWS cloud deployment
│   ├── 03_LEARNING_MILESTONES.md # Week-by-week learning track
│   ├── 04_TECHNICAL_PREP.md      # Interview prep reference
│   └── implementation-log.md      # You fill this as you build
│
├── project1-week1/                # Week 1: Foundation & Core Learning
│   ├── src/
│   │   ├── main.py               # FastAPI app
│   │   ├── database.py           # DB connection
│   │   ├── models/
│   │   │   ├── database.py       # SQLAlchemy models
│   │   │   └── schemas.py        # Pydantic validation
│   │   └── config.py             # Settings
│   ├── tests/
│   │   ├── test_api.py
│   │   └── test_validation.py
│   ├── .github/workflows/
│   │   └── ci-cd.yml            # GitHub Actions pipeline
│   ├── pyproject.toml            # Poetry dependencies
│   ├── .env.example              # Environment template
│   └── docker-compose.yml        # Local PostgreSQL
│
├── project2-week2-rag/            # Week 2: RAG + LLM Core
│   ├── src/
│   │   ├── core/
│   │   │   ├── embeddings.py    # Sentence Transformers
│   │   │   ├── rag.py           # pgvector retrieval
│   │   │   ├── llm.py           # Claude integration
│   │   │   └── evaluation.py    # RAGAS metrics
│   │   └── api/
│   │       └── investigate.py   # Investigation endpoint
│   ├── tests/
│   │   ├── test_rag.py
│   │   └── test_ragas.py
│   ├── migrations/
│   │   └── add_pgvector.sql     # Database schema
│   ├── pyproject.toml
│   └── docker-compose.yml
│
└── project3-production/           # Production-ready (optional)
    ├── kubernetes/               # K8s deployment files
    ├── monitoring/               # CloudWatch, logging
    ├── terraform/                # Infrastructure as Code
    └── production-docs/
```

---

## 🎯 2-Week Timeline Overview

### WEEK 1: Foundation + Core Learning (project1-week1)
**Goal**: Build tested API with security, understand Testing, CI/CD, Security

| Day | Focus | Build | Learn | Interview Prep |
|-----|-------|-------|-------|-----------------|
| 1-2 | Setup + Testing | FastAPI + pytest | RAGAS concepts | Test framework basics |
| 3 | Security | DB + Validation | Input security | Pydantic/SQLAlchemy |
| 4 | CI/CD | GitHub Actions | 4-stage pipeline | How to explain pipeline |
| 5 | Integration | Complete tests | Best practices | Record explanations |

**Deliverable**: Working API with 80%+ test coverage, CI/CD pipeline, security validation

### WEEK 2: RAG + LLM + Practice (project2-week2-rag)
**Goal**: Implement RAG, integrate Claude, practice technical explanations

| Day | Focus | Build | Learn | Interview Prep |
|-----|-------|-------|-------|-----------------|
| 6-7 | RAG Pipeline | pgvector + embeddings | RAGAS metrics | Retrieval quality |
| 7 | LLM Integration | Claude API | RAG + LLM flow | Faithfulness/evaluation |
| 8-9 | Testing | RAGAS evaluation | Quality metrics | Mock interviews |
| 10-14 | Polish | Complete system | Refinement | Final practice |

**Deliverable**: Complete fraud RAG system, passing tests, ready to discuss in interview

---

## 🔀 Two Approaches: Local vs Cloud

### 🏠 LOCAL APPROACH (Recommended for Learning)
**Perfect for: Building, testing, learning, interview prep**

```
Your Machine:
├── Docker Desktop (PostgreSQL + pgvector)
├── FastAPI running locally (uvicorn)
├── Tests running locally (pytest)
├── Development in VS Code
└── Free (no AWS costs)
```

**Advantages**:
- ✅ No AWS account needed
- ✅ Fast feedback loop (instant testing)
- ✅ Zero costs
- ✅ Perfect for learning
- ✅ Interview discussion: "I built and tested locally"

**Use**: Days 1-14 (entire learning period)

See: `01_LOCAL_SETUP.md`

---

### ☁️ CLOUD APPROACH (Optional, after local works)
**Perfect for: Production readiness, final demo, showing DevOps skills**

```
AWS:
├── RDS PostgreSQL (managed database)
├── ECS (container orchestration)
├── ECR (image registry)
├── CloudWatch (monitoring)
├── Secrets Manager (secrets)
└── VPC (network isolation)
```

**Advantages**:
- ✅ Production-like environment
- ✅ Learn AWS services
- ✅ Can show working system to interviewer
- ✅ Scales to real traffic
- ✅ Shows DevOps knowledge

**Use**: Days 7-14 (optional, after local proven)

See: `02_CLOUD_SETUP.md`

---

## 📚 Documentation Files

### 1. **00_MASTER_PLAN.md** (This File)
Overview, structure, timeline

### 2. **01_LOCAL_SETUP.md**
Step-by-step local development setup:
- Install Docker, Poetry, dependencies
- Run PostgreSQL locally
- Start FastAPI server
- Run tests locally
- Setup linting tools locally

### 3. **02_CLOUD_SETUP.md** (Optional)
AWS deployment:
- AWS RDS setup
- ECS cluster setup
- GitHub Actions for AWS deployment
- Monitoring and logging
- Cost estimates

### 4. **03_LEARNING_MILESTONES.md**
Week-by-week:
- Day-by-day tasks
- What to build
- What to learn
- Communication practice
- Recording yourself

### 5. **04_TECHNICAL_PREP.md**
Interview preparation reference:
- RAGAS 4 metrics (quick reference)
- CI/CD 4 stages (quick reference)
- Security 5 pillars (quick reference)
- RAG system explanation template
- Mock interview Q&A

---

## 🚀 Quick Start (TODAY)

### Step 1: Choose Your Approach
**Recommended**: Start with LOCAL for speed and learning

### Step 2: Read Documentation
1. Read this file (MASTER_PLAN) ← You are here
2. Read `01_LOCAL_SETUP.md` (or `02_CLOUD_SETUP.md` if choosing cloud)
3. Read `03_LEARNING_MILESTONES.md` for today's tasks

### Step 3: Day 1 Action
Follow `03_LEARNING_MILESTONES.md` → Day 1-2 tasks

**Time commitment**: 
- Week 1: 2 hours/day (10 hours total)
- Week 2: 2-3 hours/day (14-20 hours total)
- Total: 24-30 hours over 2 weeks

**Outcome**: Interview-ready fraud RAG system + confident technical explanations

---

## 🎯 Interview Gold by End of Week 2

You'll be able to say:

```
"I built a complete fraud detection RAG system from scratch.

ARCHITECTURE:
- FastAPI backend with Pydantic validation
- PostgreSQL with pgvector for semantic search
- Claude API for investigation reasoning
- 80%+ test coverage with pytest

TESTING:
- pytest unit and integration tests
- RAGAS metrics (retrieval: 0.92, faithfulness: 0.94)
- Test coverage: 80%+
- All tests automated in CI/CD

CI/CD:
- GitHub Actions 4-stage pipeline
- Lint → Type Check → Test → Deploy
- Tests run automatically on every PR

SECURITY:
- Pydantic input validation
- SQLAlchemy parameterized queries
- Environment variables for secrets
- AWS IAM in production version

DEPLOYMENT:
(Local version)
- FastAPI on uvicorn
- PostgreSQL in Docker
- Running on my machine

(Cloud version - optional)
- AWS ECS for FastAPI
- AWS RDS for PostgreSQL
- AWS Secrets Manager
- CloudWatch monitoring

All code tested, documented, and ready to discuss."
```

---

## 📊 Success Metrics

By end of Week 2, you'll have:

✅ **Working system** - Fraud investigation working end-to-end
✅ **Tests passing** - 80%+ coverage, all tests green
✅ **CI/CD running** - GitHub Actions pipeline working
✅ **Can explain** - Each technical concept clearly
✅ **Portfolio ready** - Code ready to show interviewer
✅ **Interview confident** - Practice explanations recorded

---

## 🗺️ Navigation Guide

**I want to...**

| Goal | Go To |
|------|-------|
| Start local development | `01_LOCAL_SETUP.md` |
| Deploy to AWS | `02_CLOUD_SETUP.md` |
| See daily tasks | `03_LEARNING_MILESTONES.md` |
| Prepare for interview | `04_TECHNICAL_PREP.md` |
| Track my progress | `implementation-log.md` (you create/update) |
| Understand Week 1 project | `project1-week1/` folder |
| Understand Week 2 project | `project2-week2-rag/` folder |

---

## 🚨 Common Questions

**Q: Should I do Local or Cloud?**
A: Start with LOCAL for speed. Cloud is optional after local works.

**Q: How much time per day?**
A: 2-3 hours focused work. Better to do 2 hours daily than 8 hours once.

**Q: Do I need AWS account?**
A: Not for local approach. Optional for cloud approach.

**Q: Can I show this to interviewer?**
A: Yes! Both local and cloud versions are interview-ready.

**Q: What if I get stuck?**
A: Each doc has troubleshooting section. Read step-by-step carefully.

---

## ✅ Checklist to Start

- [ ] Read this MASTER_PLAN.md (you're doing it now)
- [ ] Read `01_LOCAL_SETUP.md` (next step)
- [ ] Read `03_LEARNING_MILESTONES.md` (understand today's tasks)
- [ ] Follow Day 1-2 setup tasks
- [ ] Record your first communication practice
- [ ] Commit to 2 weeks

---

## 🎬 Next Step

**Go read**: `01_LOCAL_SETUP.md` (if doing local)
or
`02_CLOUD_SETUP.md` (if doing cloud)

Then come back to `03_LEARNING_MILESTONES.md` for today's specific tasks.

Let's build this! 🚀
