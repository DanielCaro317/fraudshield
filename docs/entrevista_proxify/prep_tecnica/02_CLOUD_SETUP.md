# ☁️ CLOUD SETUP GUIDE
## Deploy Fraud RAG System to AWS

**Perfect for**: Production-like environment, showing DevOps skills, final demo

**Prerequisites**: Complete `01_LOCAL_SETUP.md` first and get local version working

---

## When to Deploy to Cloud?

**Do LOCAL first** (Days 1-7):
- Faster development feedback
- Learn concepts
- Test and debug easily
- Zero AWS costs

**Then add CLOUD** (Days 7-14, optional):
- Show production readiness
- Learn AWS services
- Demonstrate DevOps
- Interview demo

---

## AWS Services Used

```
Your Application Stack:

FastAPI App
    ↓
AWS ECS (Elastic Container Service)
    ↓ stores data in
RDS PostgreSQL + pgvector
    ↓ uses
Secrets Manager (for API keys)
    ↓ monitored by
CloudWatch (logs & metrics)
    ↓ fronted by
Application Load Balancer
```

**Cost estimate**: $30-50/month for small demo

---

## Prerequisites

### 1. AWS Account
- Create free tier account: https://aws.amazon.com/free
- Verify email
- Set up billing alerts

### 2. AWS CLI
```bash
# Install
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify
aws --version
# Output: aws-cli/2.x.x
```

### 3. Configure AWS Credentials
```bash
# Get from AWS Console IAM
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Format (json)

# Verify
aws sts get-caller-identity
```

---

## Step 1: Create Docker Image (10 minutes)

### 1.1 Create Dockerfile

Create `Dockerfile`:

```dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install Poetry
RUN curl -sSL https://install.python-poetry.org | python3 - && \
    export PATH="/root/.local/bin:$PATH"

# Copy project files
COPY pyproject.toml poetry.lock* ./

# Install dependencies (no dev)
RUN /root/.local/bin/poetry install --no-dev --no-root

# Copy source code
COPY src/ ./src/

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Run app
CMD ["/root/.local/bin/poetry", "run", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### 1.2 Create Docker Ignore

Create `.dockerignore`:

```
__pycache__
.pytest_cache
.git
.env
.venv
venv
*.pyc
.DS_Store
```

---

## Step 2: AWS RDS PostgreSQL Setup (15 minutes)

### 2.1 Create RDS Database

```bash
# Create security group
aws ec2 create-security-group \
  --group-name fraud-db-sg \
  --description "Security group for fraud detection database"

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=fraud-db-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Allow inbound PostgreSQL (port 5432) from your IP
YOUR_IP=$(curl -s https://checkip.amazonaws.com)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 5432 \
  --cidr ${YOUR_IP}/32

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier fraud-detection-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 15.3 \
  --master-username fraud_admin \
  --master-user-password $(openssl rand -base64 32) \
  --allocated-storage 20 \
  --vpc-security-group-ids $SG_ID \
  --publicly-accessible \
  --storage-type gp3
```

### 2.2 Wait for Database to Be Ready

```bash
# Check status (takes 5-10 minutes)
aws rds describe-db-instances \
  --db-instance-identifier fraud-detection-db \
  --query 'DBInstances[0].DBInstanceStatus'

# When it says "available", get the endpoint
aws rds describe-db-instances \
  --db-instance-identifier fraud-detection-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text
```

### 2.3 Enable pgvector Extension

```bash
# Connect to database (you'll need psql installed)
psql -h <your-db-endpoint> -U fraud_admin -d postgres

# Run in psql:
CREATE EXTENSION IF NOT EXISTS vector;
CREATE DATABASE fraud_detection;
\c fraud_detection
CREATE EXTENSION IF NOT EXISTS vector;
```

---

## Step 3: Secrets Manager Setup (10 minutes)

### 3.1 Store API Key

```bash
# Store Anthropic API key
aws secretsmanager create-secret \
  --name fraud-detection/anthropic-key \
  --secret-string "your_api_key_here"

# Store database password
aws secretsmanager create-secret \
  --name fraud-detection/db-password \
  --secret-string "your_secure_password"
```

### 3.2 Update Application Code

Create `src/config.py` to read from Secrets Manager:

```python
import json
import boto3
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str = None
    anthropic_api_key: str = None
    environment: str = "local"
    
    def __init__(self, **data):
        super().__init__(**data)
        
        # If in cloud, fetch from Secrets Manager
        if self.environment == "cloud":
            client = boto3.client('secretsmanager')
            
            # Get API key
            api_key_secret = client.get_secret_value(
                SecretId='fraud-detection/anthropic-key'
            )
            self.anthropic_api_key = api_key_secret['SecretString']
            
            # Get DB credentials
            db_secret = client.get_secret_value(
                SecretId='fraud-detection/db-password'
            )
            db_pass = json.loads(db_secret['SecretString'])['password']
            
            # Construct database URL
            self.database_url = f"postgresql://fraud_admin:{db_pass}@<your-db-endpoint>:5432/fraud_detection"
    
    class Config:
        env_file = ".env.local"

settings = Settings(environment="cloud")
```

---

## Step 4: ECR Image Repository (10 minutes)

### 4.1 Create ECR Repository

```bash
# Create repository
aws ecr create-repository \
  --repository-name fraud-detection-rag \
  --region us-east-1

# Get repository URI
REPO_URI=$(aws ecr describe-repositories \
  --repository-names fraud-detection-rag \
  --query 'repositories[0].repositoryUri' \
  --output text)

echo "Repository URI: $REPO_URI"
```

### 4.2 Build and Push Image

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin $REPO_URI

# Build image
docker build -t fraud-detection-rag:latest .

# Tag image
docker tag fraud-detection-rag:latest $REPO_URI:latest

# Push to ECR
docker push $REPO_URI:latest
```

---

## Step 5: ECS Cluster & Service (20 minutes)

### 5.1 Create ECS Cluster

```bash
# Create cluster
aws ecs create-cluster \
  --cluster-name fraud-detection-cluster \
  --cluster-settings name=containerInsights,value=enabled

# Create capacity provider (Fargate)
aws ecs create-capacity-provider \
  --name fraud-fargate \
  --auto-scaling-group-provider autoScalingGroupArn=arn:aws:autoscaling:us-east-1:ACCOUNT_ID:autoScalingGroup:*:autoScalingGroupName/*
```

### 5.2 Create Task Definition

Create `ecs-task-definition.json`:

```json
{
  "family": "fraud-detection-rag",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "fraud-detection",
      "image": "YOUR_ECR_REPO_URI:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "ENVIRONMENT",
          "value": "cloud"
        }
      ],
      "secrets": [
        {
          "name": "ANTHROPIC_API_KEY",
          "valueFrom": "arn:aws:secretsmanager:us-east-1:ACCOUNT_ID:secret:fraud-detection/anthropic-key"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/fraud-detection",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "healthCheck": {
        "command": ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      }
    }
  ],
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskRole"
}
```

### 5.3 Register Task Definition

```bash
aws ecs register-task-definition \
  --cli-input-json file://ecs-task-definition.json
```

---

## Step 6: Automated Deployment (GitHub Actions)

### 6.1 Create Deploy Workflow

Create `.github/workflows/deploy-to-ecs.yml`:

```yaml
name: Deploy to ECS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1
      
      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1
      
      - name: Build, tag, and push image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: fraud-detection-rag
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
      
      - name: Update ECS service
        run: |
          aws ecs update-service \
            --cluster fraud-detection-cluster \
            --service fraud-detection-service \
            --force-new-deployment
```

---

## Step 7: Monitoring & Logging (10 minutes)

### 7.1 CloudWatch Logs

```bash
# Create log group
aws logs create-log-group --log-group-name /ecs/fraud-detection

# View logs
aws logs tail /ecs/fraud-detection --follow
```

### 7.2 CloudWatch Alarms

```bash
# Alarm for high error rate
aws cloudwatch put-metric-alarm \
  --alarm-name fraud-detection-errors \
  --alarm-description "Alert when error rate is high" \
  --metric-name HTTPErrorCount \
  --namespace AWS/ECS \
  --statistic Sum \
  --period 60 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

---

## Cloud Deployment Checklist

- [ ] AWS account created
- [ ] AWS CLI configured
- [ ] RDS PostgreSQL created
- [ ] pgvector extension enabled
- [ ] API keys stored in Secrets Manager
- [ ] Dockerfile created
- [ ] Image pushed to ECR
- [ ] ECS cluster created
- [ ] Task definition registered
- [ ] ECS service running
- [ ] CloudWatch logs viewing
- [ ] GitHub Actions deployment working

---

## Accessing Your Cloud App

```bash
# Get load balancer URL
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[0].DNSName' \
  --output text

# Or from ECS service
aws ecs describe-services \
  --cluster fraud-detection-cluster \
  --services fraud-detection-service \
  --query 'services[0].loadBalancers'

# Test endpoint
curl http://<your-load-balancer-url>/health
```

---

## Cost Optimization

### To reduce costs:

1. **Use t3.micro RDS** (included in free tier for 12 months)
2. **Use Fargate Spot** (30-40% cheaper)
3. **Auto-scaling** (scale down when not using)
4. **Stop when done**:
   ```bash
   # Stop ECS service
   aws ecs update-service \
     --cluster fraud-detection-cluster \
     --service fraud-detection-service \
     --desired-count 0
   
   # Delete RDS
   aws rds delete-db-instance \
     --db-instance-identifier fraud-detection-db \
     --skip-final-snapshot
   ```

---

## When to Use Cloud Setup

✅ **Use Cloud for**:
- Production deployment
- Showing DevOps skills
- Final demo to interviewer
- Load testing
- Monitoring & logging practice

❌ **Don't use Cloud for**:
- Initial learning (slower feedback)
- Quick testing (local is faster)
- Every code change (costs add up)

---

## Next Steps

1. **Start with LOCAL** (`01_LOCAL_SETUP.md`)
2. **Get working locally** (Days 1-7)
3. **Then deploy to CLOUD** (Days 7-14, optional)
4. **Document both setups** for interview

---

## Summary

**Local**: Fast, free, perfect for learning
**Cloud**: Production-ready, DevOps skills, final demo

**Recommendation**: Do LOCAL first, add CLOUD later if time permits.

Both are interview-gold! 🚀
