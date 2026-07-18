# 📚 TECHNICAL PREP REFERENCE
## Quick Reference for Interview Questions

---

## 🎯 Interview Questions You'll Face

### Q1: "Tell me about your fraud detection RAG system"

**Your Answer Framework** (8-10 minutes):

```
OPENING (30 seconds):
"I built a fraud detection system that combines 
machine learning with RAG. It uses semantic search 
to find similar fraud cases and Claude AI to investigate 
suspicious transactions."

SYSTEM OVERVIEW (2 minutes):
"The system has 3 parts:
1. ML Detection: XGBoost flags suspicious transactions
2. RAG Retrieval: Semantic search finds similar fraud cases  
3. LLM Reasoning: Claude analyzes and recommends action"

ARCHITECTURE DEEP DIVE (3-4 minutes):

Document Ingestion:
"We load fraud case descriptions and convert them to 
384-dimensional embeddings using Sentence Transformers."

Retrieval:
"For each flagged transaction, we convert it to embedding 
and query PostgreSQL pgvector using cosine similarity. 
We retrieve the top 5 most similar cases."

LLM Integration:
"We pass these cases + transaction to Claude with a 
system prompt: 'You are a fraud investigator.' 
Claude analyzes and recommends: BLOCK, ESCALATE, or APPROVE."

Example:
"A wire to Ghana from a new user returned similar 
Case #4521 (romance scam, 0.92 match). Claude 
recommended ESCALATE based on the pattern."

METRICS & RESULTS (1-2 minutes):
"We tracked RAGAS metrics:
- Retrieval Score: 0.92 (finding right cases 92% of time)
- Faithfulness: 0.94 (Claude not hallucinating)
- Answer Relevance: 0.91 (recommendations on-topic)

Performance:
- Latency: p95 = 350ms
- Accuracy: 94% on validation set"

DEPLOYMENT (1 minute):
"Deployed on AWS ECS + RDS PostgreSQL + Claude API.
Handles 1000+ investigations/day.
All tested with pytest (80%+ coverage)."

TRADEOFFS (1 minute):
"Key decision: pgvector vs Pinecone
- Chose pgvector: saves $0 vs $500/month
- Tradeoff: slightly slower (180ms vs 150ms)
- Acceptable for investigation use case (sub-second OK)"

CLOSING (30 seconds):
"I implemented this end-to-end, wrote comprehensive tests,
set up CI/CD automation, and deployed to production.
I can discuss any technical aspect."
```

---

### Q2: "How do you test your RAG system?"

**Answer** (3 minutes):

```
TESTING APPROACH:
"I use a layered testing strategy:

RAGAS METRICS (RAG Quality):
- Retrieval Score: Did we find relevant documents?
  Measured: 0.92 (92% of retrievals were relevant)
  
- Faithfulness: Did Claude hallucinate?
  Measured: 0.94 (94% of answers stick to documents)
  
- Answer Relevance: Did Claude answer the query?
  Measured: 0.91 (91% of answers on-topic)
  
- Context Precision: Did we retrieve waste?
  Measured: 0.88 (88% of retrieved docs were useful)

PYTEST FOR API TESTING:
- Unit tests: Individual functions
- Integration tests: Full API workflow
- Edge cases: Empty input, invalid values
- Security: Input validation works

Example test:
  def test_fraud_score_validation():
      response = client.post('/api/investigate',
          json={'fraud_score': 5.0})  # Invalid: should be 0-1
      assert response.status_code == 422  # Rejected

MLFLOW FOR TRACKING:
- Log RAGAS scores daily
- Alert if retrieval score drops below 0.85
- Alert if faithfulness drops below 0.90
- Track accuracy over time

AUTOMATED TESTING:
- pytest runs on every PR in GitHub Actions
- Must pass before merge allowed
- 120+ tests covering system"
```

---

### Q3: "Describe your CI/CD pipeline"

**Answer** (2 minutes):

```
GITHUB ACTIONS 4-STAGE PIPELINE:

TRIGGER:
"Pipeline runs on:
- Every push to main/develop
- Every pull request

STAGE 1 - LINT (30 seconds):
- Black: Code formatting
- Ruff: Code linting
- Ensures consistent style

STAGE 2 - TYPE CHECK (1-2 minutes):
- mypy: Finds type errors
- Prevents runtime errors
- Example: int = "string" → caught

STAGE 3 - TEST (3-5 minutes):
- pytest: 120+ unit + integration tests
- Coverage report (target: 80%+)
- Must pass before deployment
- If ANY test fails → merge blocked

STAGE 4 - BUILD & DEPLOY (only if all above pass):
- Build Docker image
- Push to ECR
- Deploy to ECS
- Takes 5-10 minutes

WORKFLOW:
Code change → All 4 stages run → If pass: auto-deploy → Production updated

RESULT:
- Code → Production in ~15 minutes
- Zero manual deployment steps
- No bad code reaches production
- Any team member can deploy safely"
```

---

### Q4: "How do you handle security?"

**Answer** (2-3 minutes):

```
5 SECURITY LAYERS:

1. AUTHENTICATION & AUTHORIZATION (AWS IAM):
   "Only authorized analysts access fraud data
    Developers cannot access production
    Role-based access control"

2. ENCRYPTION:
   "In Transit: All API calls use TLS/HTTPS
    At Rest: Database encrypted with AES-256
    Even if DB stolen, data is useless without key"

3. SECRETS MANAGEMENT (AWS Secrets Manager):
   "API keys: NEVER in code
    Database passwords: NEVER in code
    Stored in Secrets Manager
    Rotated automatically"

4. INPUT VALIDATION (Pydantic):
   "All API requests validated before processing
    Example: fraud_score must be 0.0-1.0
    Invalid input rejected with 422 error
    Prevents SQL injection, XSS, etc."

5. COMPLIANCE (Banking/PCI-DSS):
   "Data encryption (✓)
    Access logs (✓)
    Audit trails (✓)
    Data deletion procedures (✓)
    Regular security audits (✓)"

KEY POINT:
"Defense in depth: even if one layer fails,
others protect the system."
```

---

### Q5: "Why pgvector instead of Pinecone?"

**Answer** (1-2 minutes):

```
COST:
- Pinecone: $200-500/month at scale
- pgvector: $0 extra (included with PostgreSQL)
- Result: 10x cost savings

OPERATIONAL SIMPLICITY:
- One database (PostgreSQL) vs. two
- Single backup/security strategy
- Easier to manage and monitor

PERFORMANCE TRADEOFF:
- pgvector: 180ms average latency
- Pinecone: 150ms average latency
- Difference: 30ms (acceptable for fraud investigation)

WHEN I'D CHOOSE PINECONE:
- If latency < 100ms was critical
- If scale > 10 million documents
- If we wanted managed service (no ops burden)

OUR DECISION:
"For fraud investigation, cost matters and 
30ms latency is acceptable. pgvector was the 
right choice for our constraints."
```

---

### Q6: "What would you do differently?"

**Answer** (1-2 minutes):

```
IMPROVEMENTS:

1. Fine-tune embeddings:
   "Currently use generic Sentence Transformers
    Could fine-tune on fraud case descriptions
    Would improve semantic similarity"

2. Multi-step reasoning:
   "Claude reasons in one step
    Complex investigations could use multi-step:
    - Step 1: Classify transaction type
    - Step 2: Analyze similar cases
    - Step 3: Generate recommendation"

3. Analyst feedback loop:
   "Collect which recommendations analysts agreed with
    Use as training signal to improve prompts
    Currently: static prompt"

4. A/B test prompts:
   "Different prompts might perform differently
    Could test: 'You are a risk analyst' vs 'investigator'
    Measure which gets better accuracy"

5. Confidence scoring:
   "Return confidence with recommendation
    Current: BLOCK (no confidence)
    Better: BLOCK (confidence: 0.92)"

6. Response caching:
   "Cache similar cases
    Repeated patterns hit cache
    Reduces latency"
```

---

## 📋 QUICK REFERENCE: 4 METRICS TO MEMORIZE

### RAGAS Metrics (0-1 scale)

```
RETRIEVAL SCORE: 0.92
├─ Question: Did we find RELEVANT documents?
├─ Example: Searched for "wire fraud" → found romance scam cases
└─ You say: "We're finding relevant cases 92% of the time"

FAITHFULNESS: 0.94
├─ Question: Did Claude HALLUCINATE or stick to documents?
├─ Example: Doc says "$5", Claude says "$50" = hallucination
└─ You say: "Claude references documents 94% of the time"

ANSWER RELEVANCE: 0.91
├─ Question: Did Claude actually ANSWER the query?
├─ Example: Asked for risk level, Claude gave random analysis
└─ You say: "91% of answers address the actual query"

CONTEXT PRECISION: 0.88
├─ Question: Did we retrieve WASTE documents?
├─ Example: Retrieved 10 docs, only 2 useful = low precision
└─ You say: "88% of what we retrieved was actually useful"
```

---

## 📋 QUICK REFERENCE: 4 CI/CD STAGES

```
STAGE 1: LINT (Black/Ruff)
├─ Time: 30 seconds
├─ Purpose: Consistent code style
├─ Fails if: Code doesn't match style guide
└─ You say: "Ensures everyone's code looks the same"

STAGE 2: TYPE CHECK (mypy)
├─ Time: 1-2 minutes
├─ Purpose: Find type errors before runtime
├─ Fails if: Type mismatch (int = "string")
└─ You say: "Catches bugs before they run"

STAGE 3: TEST (pytest)
├─ Time: 3-5 minutes
├─ Purpose: Verify code works correctly
├─ Fails if: Any test fails
└─ You say: "Must pass 120+ tests before merge"

STAGE 4: BUILD & DEPLOY (Docker/ECS)
├─ Time: 5-10 minutes
├─ Purpose: Package and deploy to production
├─ Runs only if: All above stages pass
└─ You say: "Only happens if code is high quality"
```

---

## 📋 QUICK REFERENCE: 5 SECURITY PILLARS

```
1. AUTHENTICATION (Who are you?)
   └─ AWS IAM: Role-based access control

2. AUTHORIZATION (Are you allowed?)
   └─ IAM policies: Fine-grained permissions

3. ENCRYPTION
   ├─ In Transit: TLS/HTTPS
   └─ At Rest: AES-256

4. SECRETS MANAGEMENT
   └─ AWS Secrets Manager: No secrets in code

5. COMPLIANCE
   ├─ PCI-DSS (banking)
   ├─ HIPAA (health)
   └─ GDPR (EU)
```

---

## 🎙️ DELIVERY TIPS

### Speak Like This:
```
"I [specific action] because [clear reason].
The result was [metric/outcome]."

Example:
"I chose pgvector over Pinecone because it saves 
10x cost. The result was $0 additional infrastructure cost."
```

### Don't Speak Like This:
```
❌ "I kind of maybe used something like..."
❌ "I remember there was..."
❌ "I feel like..."
❌ "This is a very huge topic, it's difficult..."
```

### Confidence Checklist:
- [ ] Steady eye contact
- [ ] Speak slowly, not nervously fast
- [ ] Pause between thoughts (don't ramble)
- [ ] Use specific names (Claude, not "the AI")
- [ ] Use numbers (0.92, not "pretty good")
- [ ] Say "I don't know but I can learn" (not "I don't remember")

---

## 📊 Answer Quality Levels

### 🟢 7-8/10 (INTERVIEW GOLD)
- Clear explanation
- Specific examples
- Technical accuracy
- No hedging
- Uses numbers/metrics

### 🟡 5-6/10 (ACCEPTABLE)
- Mostly clear
- Some vagueness
- Missing one detail
- Light hedging
- General language

### 🔴 3-4/10 (WEAK)
- Unclear explanation
- No specific examples
- Technical gaps
- Lots of hedging
- No metrics

---

## 🎯 Before Interview (Day Before)

**1 Hour Before Call:**
- [ ] Drink water
- [ ] Review RAGAS 4 metrics (read list 2x)
- [ ] Review CI/CD 4 stages (read list 2x)
- [ ] Breathe deeply
- [ ] Tell yourself: "I know this material"

**5 Minutes Before Call:**
- [ ] Camera on, good lighting
- [ ] Quiet room
- [ ] Notes nearby but NOT visible
- [ ] Have code/repo open in background

---

## 💪 Your Advantage

You have:
- ✅ Real working code
- ✅ Real test coverage metrics
- ✅ Real system architecture
- ✅ Real RAGAS metrics
- ✅ Real CI/CD pipeline

You can say: "I built this. Here's my code. Here are my metrics."

Most candidates just have theory.

You have proof. 🚀

---

## 🔗 Use This Document

- **Before answering**: Glance at framework
- **Practicing**: Read full answer, then practice without reading
- **Interview prep**: Quick reference 1 hour before

Not cue cards. You've internalized this by now.

---

**Good luck! You've got this.** 💪
