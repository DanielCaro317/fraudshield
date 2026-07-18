# 🎯 LEARNING MILESTONES
## Week-by-Week: What to Build, Learn, Practice

---

## 📅 WEEK 1: Foundation & Core Learning
**Goal**: Build tested API with security, understand Testing, CI/CD, Security

### Daily Time Commitment
- **Morning**: 1 hour (build/code)
- **Afternoon**: 0.5 hour (learning)
- **Evening**: 0.5 hour (practice recording)
- **Total**: 2 hours/day

---

## 📅 DAY 1-2 (Monday-Tuesday): Setup + Testing Fundamentals

### What You'll Build
- Project structure with Poetry
- FastAPI skeleton (health endpoint)
- First pytest tests

### What You'll Learn
- RAGAS concepts (theoretical understanding)
- pytest basics (structure, assertions)
- How to write API tests

### Code Checklist
- [ ] `pyproject.toml` created with dependencies
- [ ] Project folder structure created
- [ ] `src/main.py` with health endpoint
- [ ] `tests/test_api.py` with 2+ tests
- [ ] All tests passing (`poetry run pytest tests/`)

### Learn Content
Read section: **COMPLETE_TECHNICAL_PREP.md → PART 2: Testing Frameworks → Day 1-2**
- Understand RAGAS 4 metrics (just learn, don't implement yet)
- Understand pytest structure
- Understand test naming conventions

### Communication Practice (Record Yourself)
```
"I use pytest for testing API endpoints.
I write tests for happy path, edge cases, and error scenarios.
For this endpoint, I tested that it returns 200 status 
and correct JSON response."
```

**Record yourself saying this 3x. Listen back. Does it sound confident?**

### Time Estimate
- Setup: 2 hours
- Build: 1.5 hours
- Learn: 1 hour
- Practice: 0.5 hour
- **Total: 5 hours**

### Git Commit
```bash
git add .
git commit -m "Day 1-2: FastAPI setup + first pytest tests"
```

---

## 📅 DAY 3 (Wednesday): Database + Security Foundations

### What You'll Build
- PostgreSQL connection (Docker)
- SQLAlchemy ORM models
- Pydantic input validation

### What You'll Learn
- Pydantic input validation (prevents SQL injection)
- SQLAlchemy parameterized queries (safe from injection)
- Database model structure

### Code Checklist
- [ ] `src/database.py` with SQLAlchemy setup
- [ ] `src/models/database.py` with Transaction model
- [ ] `src/models/schemas.py` with Pydantic validation
- [ ] `tests/test_validation.py` testing invalid inputs
- [ ] `docker-compose.yml` running PostgreSQL
- [ ] PostgreSQL health check passing
- [ ] All tests passing

### Learn Content
Read section: **COMPLETE_TECHNICAL_PREP.md → PART 4: Security → Input Validation**
- Understand how Pydantic prevents injection
- Understand parameterized queries
- Understand security layers

### Write Test (Security-focused)
```python
def test_investigation_rejects_invalid_fraud_score():
    """Test input validation prevents invalid data"""
    response = client.post("/api/investigate", 
        json={"transaction_id": "tx_1", "fraud_score": 5.0})
    assert response.status_code == 422  # Validation error
```

### Communication Practice (Record Yourself)
```
"I use Pydantic for input validation. All API requests
are validated before processing. This prevents SQL injection
and other attacks. I also use SQLAlchemy with parameterized
queries, which is safe from injection."
```

**Record 3x. Practice confidence.**

### Time Estimate
- Docker setup: 0.5 hour
- Database code: 1 hour
- Validation: 1 hour
- Tests: 1 hour
- Learn: 0.5 hour
- Practice: 0.5 hour
- **Total: 4.5 hours**

### Git Commit
```bash
git commit -m "Day 3: Database setup + Pydantic validation"
```

---

## 📅 DAY 4 (Thursday): CI/CD Pipeline Setup

### What You'll Build
- GitHub Actions workflow file
- Local linting tools (Black, Ruff, mypy)
- CI/CD pipeline understanding

### What You'll Learn
- 4-stage CI/CD pipeline (Lint → Type Check → Test → Deploy)
- GitHub Actions workflow syntax
- Why each stage matters

### Code Checklist
- [ ] `.github/workflows/ci-cd.yml` created
- [ ] Black installed and working (`poetry run black src/`)
- [ ] Ruff installed and working (`poetry run ruff check src/`)
- [ ] mypy installed and working (`poetry run mypy src/`)
- [ ] All code formatted with Black
- [ ] All tests passing
- [ ] No type errors from mypy

### Understand Each Stage

**Stage 1: Lint (30 seconds)**
```bash
# Run it
poetry run black . --check
poetry run ruff check .

# Understand: Ensures code style is consistent
```

**Stage 2: Type Check (1-2 minutes)**
```bash
# Run it
poetry run mypy src/

# Understand: Finds type errors before runtime
```

**Stage 3: Test (3-5 minutes)**
```bash
# Run it
poetry run pytest tests/ --cov=src

# Understand: Runs all unit tests, checks coverage
```

**Stage 4: Build/Deploy (not in local)**
```
# Understand: Only runs if all above pass
```

### Communication Practice (Record Yourself)
```
"We use GitHub Actions for CI/CD with 4 stages:

1. Lint with Black - ensures code formatting is consistent (30 seconds)

2. Lint with Ruff - catches code style issues (30 seconds)

3. Type check with mypy - finds type errors before runtime (1-2 minutes)

4. Test with pytest - runs all unit and integration tests (3-5 minutes)

Only if all 4 stages pass, we build and deploy.
If any stage fails, the merge is blocked.

For our fraud RAG system, we have 120+ tests
covering API endpoints and RAG logic."
```

**Record 3x.**

### Time Estimate
- Workflow file: 1 hour
- Setup linting: 1 hour
- Run all stages: 0.5 hour
- Learn: 0.5 hour
- Practice: 0.5 hour
- **Total: 3.5 hours**

### Git Commit
```bash
git commit -m "Day 4: GitHub Actions CI/CD setup + linting tools"
```

---

## 📅 DAY 5 (Friday): Complete Week 1 Integration

### What You'll Build
- More comprehensive tests (80%+ coverage)
- Documentation of Week 1
- Communication recordings

### What You'll Learn
- Test best practices
- How to document your work
- How to communicate progress

### Code Checklist
- [ ] 15+ tests (target 80%+ coverage)
- [ ] Happy path tests (valid input)
- [ ] Edge case tests (empty, null, boundary)
- [ ] Security tests (validation)
- [ ] All tests passing
- [ ] Coverage report: `poetry run pytest tests/ --cov=src --cov-report=term-missing`

### Write Tests

Happy path:
```python
def test_valid_investigation_request():
    response = client.post("/api/investigate",
        json={"transaction_id": "tx_1", "fraud_score": 0.85})
    assert response.status_code == 200
```

Edge cases:
```python
def test_empty_transaction_id_rejected():
    response = client.post("/api/investigate",
        json={"transaction_id": "", "fraud_score": 0.5})
    assert response.status_code == 422

def test_boundary_fraud_score_accepted():
    # Test boundary: 0.0 and 1.0 should be valid
    response = client.post("/api/investigate",
        json={"transaction_id": "tx_1", "fraud_score": 0.0})
    assert response.status_code == 200
```

### Document Week 1

Create `docs/implementation-log.md`:

```markdown
# Week 1 Implementation Log

## What We Built
- FastAPI skeleton with health endpoint
- PostgreSQL database models
- Pydantic input validation
- pytest test suite (80%+ coverage)
- GitHub Actions CI/CD pipeline

## What We Learned
- pytest basics (structure, assertions, edge cases)
- Pydantic validation (security layer)
- SQLAlchemy ORM (parameterized queries)
- Black/Ruff/mypy (code quality)
- GitHub Actions (4-stage pipeline)

## Testing Concepts Mastered
- Unit testing with pytest
- Test naming conventions
- Testing happy path + edge cases
- Input validation testing

## Security Concepts Mastered
- Input validation prevents injection
- Parameterized queries prevent SQL injection
- Pydantic enforces data safety

## CI/CD Concepts Mastered
- 4 stages: Lint → Type Check → Test → Build/Deploy
- Why each stage matters
- How to set up GitHub Actions

## Metrics
- Test count: 15+
- Code coverage: 80%+
- All tests passing: ✓
```

### Record 3 Explanations

Record yourself explaining:

1. **Testing**: (60 seconds)
```
"I use pytest for testing. For this fraud RAG API,
I test the happy path (valid input returns 200),
edge cases (invalid fraud_score rejected),
and security (input validation works).
I have 80%+ code coverage across all endpoints."
```

2. **CI/CD**: (60 seconds)
```
"We use GitHub Actions with 4 stages that run
on every pull request. Tests must pass before merge.
This ensures code quality and prevents bugs."
```

3. **Security**: (60 seconds)
```
"We use Pydantic to validate all API inputs.
SQLAlchemy parameterized queries prevent SQL injection.
Environment variables store secrets (not in code)."
```

### Time Estimate
- Write tests: 1.5 hours
- Coverage check: 0.5 hour
- Documentation: 1 hour
- Recording: 1 hour
- **Total: 4 hours**

### Week 1 Checklist
- [ ] FastAPI API with health endpoint
- [ ] pytest tests (80%+ coverage)
- [ ] Pydantic validation working
- [ ] GitHub Actions CI/CD pipeline
- [ ] Black/Ruff/mypy running
- [ ] Can explain: Testing, Security, CI/CD
- [ ] 3 communication recordings done
- [ ] Documentation updated

### Git Commit
```bash
git commit -m "Day 5: Complete Week 1 - tested, documented, recorded"
```

---

## 📅 WEEK 2: RAG + LLM + Deep Practice
**Goal**: Implement RAG, integrate Claude, practice technical interviews

### Daily Time Commitment
- **Morning**: 1.5 hours (build/code)
- **Afternoon**: 1 hour (learning/testing)
- **Evening**: 0.5 hour (interview practice)
- **Total**: 3 hours/day

---

## 📅 DAY 6-7 (Monday-Tuesday): RAG Pipeline + Testing

### What You'll Build
- Embeddings service (Sentence Transformers)
- pgvector semantic search
- RAGAS evaluation metrics
- Tests for RAG quality

### What You'll Learn
- RAGAS 4 metrics (hands-on implementation)
- Embeddings (384-dimensional vectors)
- Cosine similarity search
- How to test RAG quality

### Code Checklist
- [ ] `src/core/embeddings.py` with SentenceTransformer
- [ ] `src/core/rag.py` with pgvector retrieval
- [ ] `src/core/evaluation.py` with RAGAS metrics
- [ ] Database migration for pgvector
- [ ] `tests/test_rag.py` with semantic search tests
- [ ] `tests/test_ragas.py` with quality metrics tests
- [ ] All tests passing
- [ ] Can calculate: retrieval score, faithfulness score

### Key Implementations

Embeddings:
```python
from sentence_transformers import SentenceTransformer

class EmbeddingService:
    def __init__(self):
        self.model = SentenceTransformer("all-MiniLM-L6-v2")
    
    def embed_text(self, text: str) -> list:
        """Convert text to 384-dimensional embedding"""
        embedding = self.model.encode(text, convert_to_numpy=True)
        return embedding.tolist()
```

Retrieval:
```python
def retrieve_cases(self, query: str, top_k: int = 5) -> list:
    query_embedding = embedding_service.embed_text(query)
    results = self.db.execute(text("""
        SELECT id, title, description,
               1 - (embedding <-> :embedding::vector) as similarity
        FROM fraud_cases
        ORDER BY embedding <-> :embedding::vector
        LIMIT :limit
    """), {"embedding": query_embedding, "limit": top_k}).fetchall()
    return results
```

RAGAS:
```python
class RAGEvaluator:
    @staticmethod
    def evaluate_retrieval(query, retrieved_cases, ground_truth_id):
        found = any(c['id'] == ground_truth_id for c in retrieved_cases)
        avg_sim = sum(c['similarity'] for c in retrieved_cases) / len(retrieved_cases)
        return {
            "found_relevant": found,
            "retrieval_score": avg_sim if found else avg_sim * 0.5
        }
```

### Learn Content
Read: **COMPLETE_TECHNICAL_PREP.md → PART 2: Testing → RAGAS Metrics**

Memorize RAGAS 4 metrics:
1. **Retrieval Score** - Find relevant documents? (0.92)
2. **Faithfulness** - Avoid hallucination? (0.94)
3. **Answer Relevance** - Answer the query? (0.91)
4. **Context Precision** - Avoid retrieval waste? (0.88)

### Communication Practice
```
"For RAG retrieval, I:

1. Convert transaction to embedding using Sentence Transformers
   (384-dimensional vector representing the meaning)

2. Store fraud case descriptions as vectors in PostgreSQL pgvector

3. On investigation, query with cosine similarity
   (find vectors closest to query vector)

4. Return top 5 similar cases

This is SEMANTIC search - it finds meaning even with
different wording. 'Wire to Ghana' matches
'International funds to West Africa'.

Advantage over Pinecone: pgvector is included with PostgreSQL,
saves $0 cost vs $500/month for managed service."
```

**Record 3x.**

### Time Estimate
- Embeddings code: 1 hour
- RAG retrieval: 1 hour
- RAGAS evaluation: 1 hour
- Tests: 1.5 hours
- Learn: 1 hour
- Practice: 0.5 hour
- **Total: 6 hours (split across 2 days)**

### Git Commit
```bash
git commit -m "Day 6-7: RAG pipeline + pgvector + RAGAS metrics"
```

---

## 📅 DAY 7 (Tuesday Evening): Claude LLM Integration

### What You'll Build
- Claude API integration
- Investigation endpoint
- Response formatting

### Code Checklist
- [ ] `src/core/llm.py` with Claude API
- [ ] Investigation endpoint working
- [ ] Test for Claude integration
- [ ] Response parsing correct
- [ ] All tests passing

### Implementation

```python
import anthropic

class LLMService:
    def __init__(self):
        self.client = anthropic.Anthropic()
    
    def investigate(self, transaction: dict, cases: list) -> dict:
        cases_context = "\n".join([
            f"Case {i+1}: {case['title']} (similarity: {case['similarity']:.2%})"
            for i, case in enumerate(cases)
        ])
        
        response = self.client.messages.create(
            model="claude-3-sonnet",
            max_tokens=500,
            system="You are a fraud investigator. Analyze transaction based on similar cases.",
            messages=[{
                "role": "user",
                "content": f"""
Transaction: ${transaction['amount']} to {transaction['beneficiary_country']}

Similar cases:
{cases_context}

Recommend action: APPROVE, BLOCK, or ESCALATE?
Risk level: LOW, MEDIUM, HIGH, or CRITICAL?
"""
            }]
        )
        
        return {
            "analysis": response.content[0].text,
            "cases_used": len(cases),
            "model": "claude-3-sonnet"
        }
```

### Time Estimate
- Implementation: 1.5 hours
- Testing: 0.5 hour
- Debugging: 0.5 hour
- **Total: 2.5 hours**

---

## 📅 DAY 8 (Wednesday): Mock Interview #1

### What You'll Do
- Set up mock interview with friend/colleague
- Answer 4 technical questions
- Record entire session
- Review and note weak areas

### Questions to Answer

**Q1: "Tell me about your fraud RAG system" (8 minutes)**
Use complete explanation from Week 2 building:
- System overview
- Architecture
- RAG retrieval
- Claude integration
- Metrics/results

**Q2: "How do you test your system?" (3 minutes)**
Talk about:
- pytest unit tests
- RAGAS metrics (retrieval, faithfulness)
- Test coverage
- Automated testing in CI/CD

**Q3: "Describe your CI/CD pipeline" (2 minutes)**
Reference:
- 4 stages (Lint, Type Check, Test, Deploy)
- GitHub Actions workflow
- How tests block bad code

**Q4: "How do you handle security?" (2 minutes)**
Reference:
- Pydantic validation
- SQLAlchemy parameterized queries
- Secrets management

### Scoring
Rate yourself 0-10 on:
- Clarity (could listener understand?)
- Confidence (did you hesitate?)
- Accuracy (was it technically correct?)
- Examples (did you give specific examples?)

### Time Estimate
- Setup: 0.5 hour
- Interview: 0.5 hour
- Recording: included
- Review: 1 hour
- Notes: 0.5 hour
- **Total: 2.5 hours**

### Deliverable
- Recording of full mock interview
- Scoring notes
- List of weak areas to fix

---

## 📅 DAY 9 (Thursday): Refinement + Mock Interview #2

### What You'll Do
- Focus on weak areas from Day 8
- Practice weak areas 5x each
- Do second mock interview
- Should feel more confident

### Refinement Strategy

Identify weak areas:
- Unclear explanations → re-record clearer version
- Too fast speaking → slow down, pause between thoughts
- Rambling → write out concise answer first
- Missing details → add specific examples

### Recording Sessions

For each weak area:
1. Write out ideal answer
2. Record 5 times
3. Listen to each
4. Keep the best one
5. Compare with ideal

### Mock Interview #2

Should be better than Day 8:
- Smoother explanations
- More confidence
- Specific examples
- Clear communication

### Self-Scoring
- Should be 2-3 points higher than Day 8
- Target: 7/10 on each question
- If not, continue refinement tomorrow

### Time Estimate
- Refinement practice: 2 hours
- Mock interview: 0.5 hour
- Review: 1 hour
- **Total: 3.5 hours**

---

## 📅 DAY 10 (Friday): Final Polish

### What You'll Do
- Practice technical explanations 3x each
- Time yourself on full RAG explanation (should be 8 minutes)
- Practice handling follow-up questions
- Work on confidence

### Practice Full RAG Explanation

Time yourself giving complete explanation:

```
1. System overview (2 min)
2. Document retrieval (2-3 min)
3. LLM integration (2-3 min)
4. Production deployment (2 min)
5. Tradeoffs & improvements (2 min)

Total: 8-10 minutes
```

### Practice Follow-up Questions

Someone asks:
- "Why pgvector instead of Pinecone?" → Answer concisely
- "How did you handle hallucinations?" → Reference faithfulness metric
- "What would you do differently?" → Have 5 improvements ready
- "How would you scale this?" → Think about multiple replicas, read replicas

### Confidence Building

- [ ] Can explain RAG system without notes
- [ ] Can answer follow-ups
- [ ] Speaking clearly, not rambling
- [ ] Using technical terms correctly
- [ ] Referencing actual code/metrics

### Time Estimate
- RAG explanation practice: 1 hour
- Follow-up practice: 1 hour
- Confidence building: 0.5 hour
- **Total: 2.5 hours**

### Week 2 Checklist
- [ ] RAG pipeline implemented
- [ ] Claude integration working
- [ ] RAGAS metrics calculating
- [ ] All tests passing (120+ tests)
- [ ] Mock interview #1 done
- [ ] Mock interview #2 done
- [ ] Weak areas identified and fixed
- [ ] Full RAG explanation: 8 minutes
- [ ] Can answer follow-ups
- [ ] Confident without notes

---

## 📅 DAY 11-14 (Saturday-Tuesday): Final Week

### Day 11: Final Mock
- One more full mock interview
- Should feel confident
- All explanations smooth

### Day 12: Rest
- Don't over-practice
- Review key concepts lightly
- Mental preparation

### Day 13: Light Review
- One final 15-minute practice
- RAGAS 4 metrics review
- CI/CD 4 stages review

### Day 14: Interview Day!
- Eat well
- Sleep well
- 1 light 10-minute review
- Go confidently!

---

## 📊 Success Metrics by End of Week 2

✅ **Working System**
- API endpoints responding
- RAG retrieval working
- Claude investigation working
- All tests passing (120+)
- CI/CD pipeline automated

✅ **Can Explain**
- RAG system end-to-end (8 minutes)
- RAGAS 4 metrics (specifically)
- CI/CD 4 stages (specifically)
- Security 5 pillars (specifically)
- Tradeoff decisions

✅ **Interview Confident**
- Can answer technical questions
- Can discuss architecture
- Can explain design decisions
- Can handle follow-ups
- No "I don't remember" phrases

✅ **Portfolio Ready**
- Code on GitHub
- Tests passing
- Documentation complete
- Deployable to AWS (if chosen)

---

## Total Time Investment

| Week | Daily | Total |
|------|-------|-------|
| Week 1 | 2 hours | 10 hours |
| Week 2 | 3 hours | 21 hours |
| **Total** | **2.5 hrs avg** | **31 hours** |

**Less than 1 week of full-time work.**
**Spread over 2 weeks = sustainable.**

---

## Navigation

**Stuck on Week 1?** Re-read `01_LOCAL_SETUP.md`

**Need learning reference?** Read `04_TECHNICAL_PREP.md`

**Want to deploy to AWS?** Follow `02_CLOUD_SETUP.md` after Day 7

**Ready to interview?** Do Days 8-14 practice

---

## Your Interview Gold

After Week 2, you can say with confidence:

```
"I built a complete fraud detection RAG system from scratch.

Architecture:
- FastAPI backend with Pydantic validation
- PostgreSQL with pgvector semantic search
- Claude API for reasoning
- 80%+ test coverage

Testing:
- pytest with 120+ tests
- RAGAS metrics (retrieval: 0.92, faithfulness: 0.94)
- Automated in GitHub Actions

Security:
- Input validation
- Parameterized queries
- Secrets management

I implemented it, tested it, documented it, and I can
discuss every decision. Here's my code."
```

That's interview gold! 🚀

---

**NOW: Start Day 1-2. Follow the checklist. You've got this!**
