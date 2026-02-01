# SPCS Deployment Guide for Churn Prediction Model

This guide explains how to build and deploy the churn prediction ML model to Snowpark Container Services (SPCS).

## Prerequisites

1. **Docker Desktop** installed and running
2. **Snowflake account** with SPCS enabled
3. **ACCOUNTADMIN** role or appropriate privileges
4. Completed SQL scripts `01-04` (database, data, semantic view, search service)

## Configuration

Before deploying, get your repository URL from Snowflake:

```sql
USE ROLE ACCOUNTADMIN;
SHOW IMAGE REPOSITORIES IN SCHEMA TELECOM_DEMO.SPCS;
-- Note the 'repository_url' column value, e.g.:
-- <orgname>-<accountname>.registry.snowflakecomputing.com/telecom_demo/spcs/churn_model_repo
```

Set these variables in your terminal (adjust to your setup):

```bash
# REQUIRED: Set these to match your Snowflake setup
export REGISTRY_HOST="<orgname>-<accountname>.registry.snowflakecomputing.com"  # e.g., myorg-myacct.registry.snowflakecomputing.com
export SNOWFLAKE_USER="<your_username>"  # Your Snowflake username
export REPO_PATH="telecom_demo/spcs/churn_model_repo"
export IMAGE_NAME="churn-predictor"
export IMAGE_TAG="latest"
```

## Quick Deploy (Script)

The easiest way to deploy is using the provided script:

```bash
# 1. Edit the script to add your Snowflake account details
nano deploy_to_spcs.sh

# 2. Update these variables at the top of the script:
SNOWFLAKE_ACCOUNT="your_account"    # e.g., "xy12345"
SNOWFLAKE_ORG="your_org"            # e.g., "myorg" (leave empty if not using org)
SNOWFLAKE_USER="your_username"

# 3. Make executable and run
chmod +x deploy_to_spcs.sh
./deploy_to_spcs.sh
```

## Manual Deployment Steps

### Step 1: Prepare Snowflake Infrastructure

Run in Snowflake:
```sql
USE ROLE ACCOUNTADMIN;

-- Create image repository
CREATE DATABASE IF NOT EXISTS TELECOM_DEMO;
CREATE SCHEMA IF NOT EXISTS TELECOM_DEMO.SPCS;
CREATE IMAGE REPOSITORY IF NOT EXISTS TELECOM_DEMO.SPCS.CHURN_MODEL_REPO;

-- Get repository URL
SHOW IMAGE REPOSITORIES IN SCHEMA TELECOM_DEMO.SPCS;
-- Note the 'repository_url' column value
```

### Step 2: Build Docker Image

```bash
# Navigate to ml_model directory
cd telecom_retention_demo/ml_model

# Build for linux/amd64 (required for SPCS)
docker build --platform linux/amd64 -t churn-predictor:latest .
```

### Step 3: Test Locally (Optional but Recommended)

```bash
# Run container
docker run -d --name churn-test -p 8000:8000 churn-predictor:latest

# Test health endpoint
curl http://localhost:8000/health

# Test prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "CUST-TEST",
    "avg_data_usage_pct": 25,
    "data_usage_trend": -0.3,
    "avg_voice_usage_pct": 40,
    "avg_days_inactive": 8,
    "avg_signal_strength": -92,
    "total_dropped_calls": 5,
    "coverage_issues_count": 2,
    "complaint_count": 3,
    "negative_sentiment_count": 2,
    "avg_nps_score": 4,
    "tenure_months": 18,
    "monthly_fee": 75,
    "payment_issues_count": 1,
    "customer_segment": "Standard",
    "contract_months_remaining": 2
  }'

# Expected output: JSON with churn_probability, risk_category, etc.

# Cleanup
docker stop churn-test && docker rm churn-test
```

### Step 4: Push to Snowflake Registry

**Important for Mac/zsh users:** Use the `push_image.sh` script or set variables to avoid shell interpretation issues with colons in image tags.

**Option A: Using the push script (Recommended)**
```bash
# Edit push_image.sh to set your variables, then run:
chmod +x push_image.sh
./push_image.sh
```

**Option B: Using environment variables**
```bash
# Set your registry details (get from SHOW IMAGE REPOSITORIES)
export REGISTRY_HOST="<orgname>-<accountname>.registry.snowflakecomputing.com"
export SNOWFLAKE_USER="<your_username>"
export REPO_PATH="telecom_demo/spcs/churn_model_repo"
export FULL_IMAGE="$REGISTRY_HOST/$REPO_PATH/churn-predictor:latest"

# Login to Snowflake container registry
docker login $REGISTRY_HOST -u $SNOWFLAKE_USER
# Enter your Snowflake password when prompted

# Tag image for Snowflake
docker tag churn-predictor:latest $FULL_IMAGE

# Push to Snowflake
docker push $FULL_IMAGE
```

**Troubleshooting zsh errors:**
- If you get `zsh: unknown file attribute: h`, the shell is misinterpreting the `:latest` tag
- Always use environment variables or the push script instead of typing URLs directly
- Alternative: run `bash` first to switch to bash shell, run commands, then `exit`

### Step 5: Create Compute Pool

```sql
-- Create compute pool for the service
CREATE COMPUTE POOL IF NOT EXISTS TELECOM_CHURN_POOL
    MIN_NODES = 1
    MAX_NODES = 2
    INSTANCE_FAMILY = CPU_X64_XS
    AUTO_RESUME = TRUE
    AUTO_SUSPEND_SECS = 300
    COMMENT = 'Compute pool for telecom churn prediction model';

-- Wait for pool to be ready (may take 1-2 minutes)
DESCRIBE COMPUTE POOL TELECOM_CHURN_POOL;
-- Status should show 'ACTIVE' or 'IDLE'
```

### Step 6: Create SPCS Service

```sql
-- Verify image was uploaded
SHOW IMAGES IN IMAGE REPOSITORY TELECOM_DEMO.SPCS.CHURN_MODEL_REPO;

-- Create the service
CREATE SERVICE IF NOT EXISTS TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE
    IN COMPUTE POOL TELECOM_CHURN_POOL
    FROM SPECIFICATION $$
spec:
  containers:
  - name: churn-predictor
    image: /telecom_demo/spcs/churn_model_repo/churn-predictor:latest
    resources:
      requests:
        memory: 1Gi
        cpu: 0.5
      limits:
        memory: 2Gi
        cpu: 1
    readinessProbe:
      path: /health
      port: 8000
  endpoints:
  - name: predict
    port: 8000
    public: false
$$
    MIN_INSTANCES = 1
    MAX_INSTANCES = 2
    COMMENT = 'Churn prediction ML model service';
```

### Step 7: Verify Service Status

```sql
-- Check service status
SHOW SERVICES IN SCHEMA TELECOM_DEMO.SPCS;

-- Get detailed status
CALL SYSTEM$GET_SERVICE_STATUS('TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE');
-- Should show status: READY

-- View logs if troubleshooting needed
CALL SYSTEM$GET_SERVICE_LOGS('TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE', 0, 'churn-predictor', 100);
```

### Step 8: Create Service Function

```sql
-- Create function to call the service from SQL
CREATE OR REPLACE FUNCTION TELECOM_DEMO.CUSTOMER_RETENTION.PREDICT_CHURN_SPCS(
    CUSTOMER_ID VARCHAR,
    AVG_DATA_USAGE_PCT FLOAT,
    DATA_USAGE_TREND FLOAT,
    AVG_VOICE_USAGE_PCT FLOAT,
    AVG_DAYS_INACTIVE INT,
    AVG_SIGNAL_STRENGTH INT,
    TOTAL_DROPPED_CALLS INT,
    COVERAGE_ISSUES_COUNT INT,
    COMPLAINT_COUNT INT,
    NEGATIVE_SENTIMENT_COUNT INT,
    AVG_NPS_SCORE FLOAT,
    TENURE_MONTHS INT,
    MONTHLY_FEE FLOAT,
    PAYMENT_ISSUES_COUNT INT,
    CUSTOMER_SEGMENT VARCHAR,
    CONTRACT_MONTHS_REMAINING INT
)
RETURNS VARIANT
SERVICE = TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE
ENDPOINT = predict
AS '/predict';
```

### Step 9: Test the Service

```sql
-- Test with a sample prediction
SELECT TELECOM_DEMO.CUSTOMER_RETENTION.PREDICT_CHURN_SPCS(
    'CUST-000001',    -- customer_id
    25.0,             -- avg_data_usage_pct
    -0.3,             -- data_usage_trend
    40.0,             -- avg_voice_usage_pct
    8,                -- avg_days_inactive
    -92,              -- avg_signal_strength
    5,                -- total_dropped_calls
    2,                -- coverage_issues_count
    3,                -- complaint_count
    2,                -- negative_sentiment_count
    4.0,              -- avg_nps_score
    18,               -- tenure_months
    75.0,             -- monthly_fee
    1,                -- payment_issues_count
    'Standard',       -- customer_segment
    2                 -- contract_months_remaining
) AS prediction;
```

## Troubleshooting

### Docker/Shell Issues (Mac zsh)

**Error: `zsh: unknown file attribute: h`**
- Cause: zsh interprets `:latest` as a modifier
- Solution: Use environment variables or the `push_image.sh` script
- Alternative: Switch to bash temporarily with `bash` command

**Error: `invalid reference format`**
- Cause: Special characters or markdown links copied from chat/docs
- Solution: Type commands manually or use the script files

**Error: `Authorization Failure` when pushing**
- Solution: Run `docker login` first with your registry host and Snowflake credentials

### Image Push Fails
```bash
# Ensure you're logged in
docker login $REGISTRY_HOST -u $SNOWFLAKE_USER

# Check image exists locally
docker images | grep churn-predictor

# Verify using variables
echo $FULL_IMAGE
docker push $FULL_IMAGE
```

### Service Won't Start
```sql
-- Check compute pool status
DESCRIBE COMPUTE POOL TELECOM_CHURN_POOL;

-- Check service logs
CALL SYSTEM$GET_SERVICE_LOGS('TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE', 0, 'churn-predictor', 100);

-- Common issues:
-- 1. Image not found: verify image was pushed correctly
-- 2. Out of memory: increase memory limits in spec
-- 3. Health check failing: verify /health endpoint works
```

### Service Function Returns NULL
```sql
-- Check service is running
CALL SYSTEM$GET_SERVICE_STATUS('TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE');

-- Verify endpoint name matches
-- The function uses 'predict' endpoint, ensure spec has same name

-- Check for errors in logs
CALL SYSTEM$GET_SERVICE_LOGS('TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE', 0, 'churn-predictor', 50);
```

## Alternative: Rule-Based Prediction

If SPCS deployment is not possible, use the rule-based stored procedure instead:

```sql
-- The demo includes this alternative that works without SPCS
CALL TELECOM_DEMO.CUSTOMER_RETENTION.CALCULATE_CHURN_RISK('CUST-000001');
```

This provides similar functionality using SQL-based rules instead of ML.

## Cleanup

To remove SPCS resources:
```sql
-- Drop service
DROP SERVICE IF EXISTS TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE;

-- Suspend compute pool (to save costs)
ALTER COMPUTE POOL TELECOM_CHURN_POOL SUSPEND;

-- Or drop compute pool entirely
DROP COMPUTE POOL IF EXISTS TELECOM_CHURN_POOL;
```
