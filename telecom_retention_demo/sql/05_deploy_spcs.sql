--------------------------------------------------------------------------------
-- TELECOM CUSTOMER RETENTION DEMO - SPCS DEPLOYMENT
-- Deploys the churn prediction ML model to Snowpark Container Services
--------------------------------------------------------------------------------

USE ROLE ACCOUNTADMIN;

--------------------------------------------------------------------------------
-- Step 1: Create Image Repository
--------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS TELECOM_DEMO;
CREATE SCHEMA IF NOT EXISTS TELECOM_DEMO.SPCS;

CREATE IMAGE REPOSITORY IF NOT EXISTS TELECOM_DEMO.SPCS.CHURN_MODEL_REPO;

-- Get repository URL for docker push
SHOW IMAGE REPOSITORIES IN SCHEMA TELECOM_DEMO.SPCS;
-- Note the repository_url from output, e.g.: <org>-<account>.registry.snowflakecomputing.com/telecom_demo/spcs/churn_model_repo

--------------------------------------------------------------------------------
-- Step 2: Create Compute Pool (if not exists)
--------------------------------------------------------------------------------
CREATE COMPUTE POOL IF NOT EXISTS TELECOM_CHURN_POOL
    MIN_NODES = 1
    MAX_NODES = 2
    INSTANCE_FAMILY = CPU_X64_XS
    AUTO_RESUME = TRUE
    AUTO_SUSPEND_SECS = 300
    COMMENT = 'Compute pool for telecom churn prediction model';

-- Wait for compute pool to be ready
DESCRIBE COMPUTE POOL TELECOM_CHURN_POOL;
-- Status should be 'ACTIVE' or 'IDLE'

--------------------------------------------------------------------------------
-- Step 3: Create Service Spec Stage
--------------------------------------------------------------------------------
CREATE STAGE IF NOT EXISTS TELECOM_DEMO.SPCS.SERVICE_SPECS
    DIRECTORY = (ENABLE = TRUE);

-- The spec.yaml file should be uploaded to this stage
-- PUT file:///path/to/service_spec.yaml @TELECOM_DEMO.SPCS.SERVICE_SPECS

--------------------------------------------------------------------------------
-- Step 4: Create the SPCS Service
--------------------------------------------------------------------------------
/*
Before running this, you need to:
1. Build and push the Docker image:
   
   # Get registry URL
   SHOW IMAGE REPOSITORIES;
   
   # Login to registry
   docker login <org>-<account>.registry.snowflakecomputing.com -u <username>
   
   # Build image
   cd ml_model
   docker build -t churn-predictor:latest .
   
   # Tag for Snowflake
   docker tag churn-predictor:latest \
     <org>-<account>.registry.snowflakecomputing.com/telecom_demo/spcs/churn_model_repo/churn-predictor:latest
   
   # Push to Snowflake
   docker push \
     <org>-<account>.registry.snowflakecomputing.com/telecom_demo/spcs/churn_model_repo/churn-predictor:latest
*/

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

-- Check service status
SHOW SERVICES IN SCHEMA TELECOM_DEMO.SPCS;
CALL SYSTEM$GET_SERVICE_STATUS('TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE');

-- Get service logs (for debugging)
CALL SYSTEM$GET_SERVICE_LOGS('TELECOM_DEMO.SPCS.CHURN_PREDICTION_SERVICE', 0, 'churn-predictor', 100);

--------------------------------------------------------------------------------
-- Step 5: Create Service Function to call the API
--------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION TELECOM_DEMO.CUSTOMER_RETENTION.PREDICT_CHURN(
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

--------------------------------------------------------------------------------
-- Step 6: Create wrapper stored procedure for easier use
--------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.GET_CHURN_PREDICTION(
    P_CUSTOMER_ID VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
AS
$$
DECLARE
    result VARIANT;
BEGIN
    SELECT TELECOM_DEMO.CUSTOMER_RETENTION.PREDICT_CHURN(
        c.CUSTOMER_ID,
        COALESCE(u.AVG_DATA_PCT, 50),
        COALESCE(u.DATA_TREND, 0),
        COALESCE(u.AVG_VOICE_PCT, 50),
        COALESCE(u.AVG_DAYS_INACTIVE, 1),
        COALESCE(n.AVG_SIGNAL, -70),
        COALESCE(n.DROPPED_CALLS, 0),
        COALESCE(n.COVERAGE_ISSUES, 0),
        COALESCE(cc.COMPLAINT_CNT, 0),
        COALESCE(cc.NEG_SENTIMENT_CNT, 0),
        COALESCE(cc.AVG_NPS, 7),
        DATEDIFF('month', c.CUSTOMER_SINCE, CURRENT_DATE()),
        COALESCE(s.MONTHLY_FEE, 50),
        COALESCE(u.PAYMENT_ISSUES, 0),
        c.CUSTOMER_SEGMENT,
        COALESCE(DATEDIFF('month', CURRENT_DATE(), s.CONTRACT_END_DATE), 12)
    ) INTO :result
    FROM TELECOM_DEMO.CUSTOMER_RETENTION.CUSTOMERS c
    LEFT JOIN (
        SELECT CUSTOMER_ID, MONTHLY_FEE, CONTRACT_END_DATE,
               ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY CONTRACT_START_DATE DESC) AS rn
        FROM TELECOM_DEMO.CUSTOMER_RETENTION.SUBSCRIPTIONS
        WHERE STATUS = 'Active'
    ) s ON c.CUSTOMER_ID = s.CUSTOMER_ID AND s.rn = 1
    LEFT JOIN (
        SELECT 
            CUSTOMER_ID,
            AVG(DATA_USAGE_PCT) AS AVG_DATA_PCT,
            (MAX(DATA_USED_GB) - MIN(DATA_USED_GB)) / NULLIF(MAX(DATA_USED_GB), 0) AS DATA_TREND,
            AVG(VOICE_USAGE_PCT) AS AVG_VOICE_PCT,
            AVG(DAYS_SINCE_LAST_USAGE) AS AVG_DAYS_INACTIVE,
            SUM(CASE WHEN PAYMENT_STATUS != 'Paid' THEN 1 ELSE 0 END) AS PAYMENT_ISSUES
        FROM TELECOM_DEMO.CUSTOMER_RETENTION.USAGE_METRICS
        WHERE USAGE_MONTH >= DATEADD('month', -3, CURRENT_DATE())
        GROUP BY CUSTOMER_ID
    ) u ON c.CUSTOMER_ID = u.CUSTOMER_ID
    LEFT JOIN (
        SELECT 
            CUSTOMER_ID,
            AVG(AVG_SIGNAL_STRENGTH_DBM) AS AVG_SIGNAL,
            SUM(DROPPED_CALLS) AS DROPPED_CALLS,
            SUM(CASE WHEN COVERAGE_ISSUES_REPORTED THEN 1 ELSE 0 END) AS COVERAGE_ISSUES
        FROM TELECOM_DEMO.CUSTOMER_RETENTION.NETWORK_STATS
        WHERE STAT_DATE >= DATEADD('day', -30, CURRENT_DATE())
        GROUP BY CUSTOMER_ID
    ) n ON c.CUSTOMER_ID = n.CUSTOMER_ID
    LEFT JOIN (
        SELECT 
            CUSTOMER_ID,
            COUNT(*) AS COMPLAINT_CNT,
            SUM(CASE WHEN CUSTOMER_SENTIMENT IN ('Negative', 'Very Negative') THEN 1 ELSE 0 END) AS NEG_SENTIMENT_CNT,
            AVG(NPS_SCORE) AS AVG_NPS
        FROM TELECOM_DEMO.CUSTOMER_RETENTION.CALL_CENTER_LOGS
        WHERE INTERACTION_DATE >= DATEADD('month', -6, CURRENT_TIMESTAMP())
        GROUP BY CUSTOMER_ID
    ) cc ON c.CUSTOMER_ID = cc.CUSTOMER_ID
    WHERE c.CUSTOMER_ID = :P_CUSTOMER_ID;
    
    RETURN result;
END;
$$;

-- Grant permissions
GRANT USAGE ON PROCEDURE TELECOM_DEMO.CUSTOMER_RETENTION.GET_CHURN_PREDICTION(VARCHAR) 
    TO ROLE ACCOUNTADMIN;

--------------------------------------------------------------------------------
-- Test the prediction
--------------------------------------------------------------------------------
-- CALL TELECOM_DEMO.CUSTOMER_RETENTION.GET_CHURN_PREDICTION('CUST-000001');
