# Telecom Customer Retention Demo for Snowflake Intelligence

## Overview
This demo showcases Snowflake Intelligence's agentic capabilities for a cellular telecommunications customer retention use case. The agent combines:

- **Text-to-SQL** (Cortex Analyst) - Query customer data with natural language
- **Semantic Search** (Cortex Search) - Search call center logs and support tickets
- **Web Search** - Research competitor offers and market trends
- **ML Model API** (SPCS) - Real-time churn prediction
- **Email Tool** - Send promotional offers to customers

## Demo Scenario
Business users can:
1. Ask about customers with low usage/subscriptions
2. Investigate why their usage is declining
3. Check network quality and support interactions
4. Predict if they are likely to churn
5. Get recommended promotions
6. Send retention offers via email

## Directory Structure
```
telecom_retention_demo/
├── README.md                              # This file
├── sql/
│   ├── 01_setup_database.sql             # Create database, schema, tables
│   ├── 02_generate_synthetic_data.sql    # Generate demo data (uses CTEs and UNIFORM)
│   ├── 03_create_semantic_view.sql       # Create Cortex Analyst semantic view
│   ├── 04_create_cortex_search.sql       # Create search service for call center
│   ├── 05_deploy_spcs.sql                # Deploy ML model to SPCS (optional)
│   ├── 06_create_stored_procedures.sql   # Create custom agent tools
│   └── 07_create_agent.sql               # Create Snowflake Intelligence agent
├── ml_model/
│   ├── Dockerfile                        # Container image for SPCS
│   ├── requirements.txt                  # Python dependencies
│   ├── app.py                            # FastAPI application
│   ├── churn_predictor.py                # ML model implementation
│   ├── deploy_to_spcs.sh                 # Automated deployment script
│   └── SPCS_DEPLOYMENT_GUIDE.md          # Step-by-step SPCS deployment guide
└── agent_config/
    └── agent_spec.json                   # Full agent specification
```

## Quick Start

### Prerequisites
- Snowflake account with ACCOUNTADMIN or appropriate privileges
- Snowpark Container Services enabled (for ML model deployment)
- Docker installed locally (for building ML model image)

### Step 1: Setup Database and Tables
Run the SQL script in a Snowflake worksheet:
```sql
-- Run as ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;

-- Copy and execute contents of sql/01_setup_database.sql
```

### Step 2: Generate Synthetic Data
```sql
-- Copy and execute contents of sql/02_generate_synthetic_data.sql
```
This creates:
- 1,000 customers
- ~950 subscriptions (active + suspended)
- 12 months of usage data (~11,000 records)
- 90 days of network stats (~30,000 records)
- ~2,500 call center interactions
- 8 active promotions
- Churn predictions for all active customers

**Note:** The script uses:
- `UNIFORM(min, max, RANDOM())` for bounded random values (not raw `RANDOM()`)
- CTEs to avoid column alias reference issues in Snowflake

### Step 3: Create Semantic View for Cortex Analyst
```sql
-- Copy and execute contents of sql/03_create_semantic_view.sql
```

**Important:** The script uses `SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML()` with embedded YAML. The semantic model includes:
- **Facts**: Raw column values for aggregation (e.g., `BILL_AMT`, `DATA_GB`)
- **Metrics**: Aggregate expressions referencing facts (e.g., `AVG(USAGE_METRICS.BILL_AMT)`)
- **Dimensions**: Non-aggregated attributes for grouping/filtering
- **Relationships**: Foreign key connections between tables

### Step 4: Create Cortex Search Service
```sql
-- Copy and execute contents of sql/04_create_cortex_search.sql
```

### Step 5: Deploy ML Model to SPCS (Optional)

See `ml_model/SPCS_DEPLOYMENT_GUIDE.md` for detailed instructions.

**Prerequisites:**
1. Get your repository URL from Snowflake:
   ```sql
   SHOW IMAGE REPOSITORIES IN SCHEMA TELECOM_DEMO.SPCS;
   ```
2. Note the `repository_url` column (e.g., `myorg-myacct.registry.snowflakecomputing.com/...`)

**Quick deployment:**
```bash
cd ml_model

# Option 1: Edit and run the full deployment script
nano deploy_to_spcs.sh  # Set SNOWFLAKE_ORG, SNOWFLAKE_ACCOUNT, SNOWFLAKE_USER
chmod +x deploy_to_spcs.sh
./deploy_to_spcs.sh

# Option 2: Build locally, then use push script
docker build --platform linux/amd64 -t churn-predictor:latest .
nano push_image.sh  # Set REGISTRY_HOST and SNOWFLAKE_USER
chmod +x push_image.sh
./push_image.sh
```

**Note for Mac/zsh users:** Use the provided scripts instead of typing docker commands directly. The `:latest` tag can cause zsh shell interpretation issues.

Then run the SPCS deployment SQL:
```sql
-- Copy and execute contents of sql/05_deploy_spcs.sql
```

**Alternative (without SPCS):** The demo includes a rule-based churn prediction stored procedure that works without SPCS deployment.

### Step 6: Create Stored Procedures (Custom Tools)

**IMPORTANT:** Before running this script, edit `sql/06_create_stored_procedures.sql` and replace:
- `<YOUR_EMAIL>` with your actual email address (appears in 2 places)

```sql
-- Copy and execute contents of sql/06_create_stored_procedures.sql
```

### Step 7: Create the Snowflake Intelligence Agent

**Option A: Snowflake UI (Recommended)**
1. Navigate to Snowflake Intelligence > Agents
2. Click "Create Agent"
3. Configure the agent using the specification in `agent_config/agent_spec.json`

**Option B: SQL**
```sql
-- Copy and execute contents of sql/07_create_agent.sql
```

## Demo Walkthrough

### Sample Questions to Ask the Agent

#### 1. Identify At-Risk Customers
```
"Who are our customers with high churn risk?"
"Show me customers with declining data usage in the last 3 months"
"Which Premium customers are at risk of churning?"
```

#### 2. Investigate Customer Issues
```
"What issues has customer CUST-000001 reported?"
"Show me customers who complained about network problems"
"Find all escalated support tickets from unhappy customers"
```

#### 3. Analyze Network Experience
```
"Which customers are experiencing poor signal quality?"
"Show me customers with more than 3 dropped calls"
"Find customers in areas with known coverage issues"
```

#### 4. Get Churn Predictions
```
"Calculate the churn risk for CUST-000050"
"What are the main factors contributing to churn for our high-risk customers?"
"Predict if CUST-000100 will churn"
```

#### 5. Find Retention Offers
```
"What promotions can we offer to retain CUST-000025?"
"Show me available retention offers for high-risk customers"
"What's the best promotion for a Premium customer with network issues?"
```

#### 6. Take Action
```
"Send the loyalty discount promotion to CUST-000001"
"Compare our retention offers with what competitors are offering"
"What should we do to retain our top 10 at-risk customers?"
```

#### 7. Complete Customer Analysis Workflow
```
"Give me a complete retention analysis for customer CUST-000001"
```
This should:
1. Pull customer profile and usage data
2. Show churn prediction and risk factors
3. Search for support interactions
4. Check network quality
5. Recommend promotions
6. Offer to send an email

## Agent Capabilities Summary

| Capability | Tool | Description |
|------------|------|-------------|
| Text-to-SQL | `query_customer_retention` | Natural language queries on customer data |
| Semantic Search | `search_call_center` | Search support interactions and complaints |
| Web Search | `search_web` | Research competitors and market trends |
| ML Prediction | `predict_churn` | Real-time churn probability calculation |
| Recommendations | `get_promotions` | Personalized promotion suggestions |
| Email Action | `send_email` | Send retention offers to customers |

## Data Model

### Tables
- **CUSTOMERS**: Demographics, segment, tenure, lifetime value
- **SUBSCRIPTIONS**: Plan details, pricing, contract dates
- **USAGE_METRICS**: Monthly data/voice/SMS usage, billing
- **NETWORK_STATS**: Signal quality, speeds, dropped calls
- **CALL_CENTER_LOGS**: Support interactions and sentiment
- **PROMOTIONS**: Available retention offers
- **CHURN_PREDICTIONS**: ML model predictions
- **EMAIL_LOG**: Sent communications tracking

### Customer Segments
- **Premium**: High-value customers, unlimited plans, $75+ monthly
- **Standard**: Mid-tier, moderate usage, $45-75 monthly
- **Budget**: Price-sensitive, basic plans, $25-45 monthly

### Churn Risk Categories
- **High**: >60% probability - Immediate action required
- **Medium**: 30-60% probability - Proactive outreach recommended
- **Low**: <30% probability - Monitor and nurture

## Semantic Model Structure

The semantic view `CUSTOMER_RETENTION_ANALYTICS` uses Snowflake's semantic view architecture:

### Facts vs Metrics
- **Facts**: Non-aggregated column expressions (e.g., `BILL_AMT`, `DATA_GB`)
- **Metrics**: Aggregate expressions that reference facts (e.g., `SUM(USAGE_METRICS.BILL_AMT)`)

### Key Tables in Semantic Model
| Table | Facts | Metrics | Key Dimensions |
|-------|-------|---------|----------------|
| CUSTOMERS | CREDIT_SCORE_VAL, LTV_VAL | TOTAL_CUSTOMERS, AVG_LIFETIME_VALUE | CUSTOMER_SEGMENT, CITY, STATE |
| SUBSCRIPTIONS | MONTHLY_FEE_VAL | TOTAL_SUBSCRIPTIONS, AVG_MONTHLY_FEE | PLAN_NAME, STATUS |
| USAGE_METRICS | DATA_GB, BILL_AMT, VOICE_MIN | AVG_DATA_USED_GB, SUM_BILL_AMOUNT | USAGE_MONTH, PAYMENT_STATUS |
| NETWORK_STATS | SIGNAL_DBM, DOWNLOAD_MBPS | AVG_SIGNAL_STRENGTH, TOTAL_DROPPED_CALLS | SIGNAL_QUALITY, NETWORK_TYPE |
| CHURN_PREDICTIONS | CHURN_PROB_VAL, DAYS_TO_CHURN_VAL | AVG_CHURN_PROBABILITY, HIGH_RISK_CUSTOMERS | CHURN_RISK_CATEGORY |
| PROMOTIONS | SUCCESS_RATE_VAL | TOTAL_PROMOTIONS, AVG_SUCCESS_RATE | PROMOTION_TYPE, IS_ACTIVE |

## Troubleshooting

### Common Issues

1. **"Number out of representable range" during data generation**
   - This is fixed in the current script
   - Uses `UNIFORM(min, max, RANDOM())` instead of raw `RANDOM()`
   - Uses CTEs to avoid column alias reference issues

2. **"Invalid expression in VALUES clause"**
   - Functions like `PARSE_JSON()` cannot be used in VALUES clause
   - Solution: Use `SELECT ... UNION ALL` instead

3. **"Invalid metric definition" error**
   - Metrics cannot directly reference base table columns that share names with other metrics
   - Solution: Define facts for raw values, then reference facts in metrics with `TABLE_NAME.FACT_NAME`

4. **"Semantic view not found"**
   - Ensure `SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML()` completed successfully
   - Check grants on the semantic view
   - Run `SHOW SEMANTIC VIEWS IN SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION;`

5. **"Search service not ready"**
   - Cortex Search services take time to index
   - Check `DESCRIBE CORTEX SEARCH SERVICE CALL_CENTER_SEARCH;` for status
   - Wait for status to show "ACTIVE"

6. **"SPCS service not responding"**
   - Check compute pool status: `DESCRIBE COMPUTE POOL TELECOM_CHURN_POOL;`
   - Verify Docker image was pushed successfully
   - Check service logs: `SELECT SYSTEM$GET_SERVICE_LOGS('CHURN_PREDICTION_SERVICE', 0, 'churn-api');`

7. **"Stored procedure not found"**
   - Ensure procedures were created in correct schema
   - Check grants on procedures
   - Verify the procedure signatures match agent spec

## Customization

### Adding More Customers
Modify `02_generate_synthetic_data.sql`:
```sql
-- Change ROWCOUNT => 1000 to your desired number
FROM TABLE(GENERATOR(ROWCOUNT => 5000));
```

### Adding New Promotions
Use SELECT with UNION ALL (not VALUES with PARSE_JSON):
```sql
INSERT INTO PROMOTIONS (...)
SELECT 'PROMO-009', 'Custom Offer', 'Loyalty',
       'Your custom promotion description',
       ...,
       PARSE_JSON('["Premium", "Standard"]'),
       ...;
```

### Modifying Churn Model
- For rule-based: Edit `CALCULATE_CHURN_RISK` procedure
- For ML-based: Retrain the model in `ml_model/churn_predictor.py`

## Configuration Checklist

Before deploying, ensure you've updated these placeholders:

| File | Placeholder | Description |
|------|-------------|-------------|
| `sql/06_create_stored_procedures.sql` | `<YOUR_EMAIL>` | Email recipient for notifications |
| `ml_model/push_image.sh` | `<YOUR_ORG>-<YOUR_ACCOUNT>` | Snowflake registry host |
| `ml_model/push_image.sh` | `<YOUR_USERNAME>` | Snowflake username |
| `ml_model/deploy_to_spcs.sh` | `SNOWFLAKE_ORG` | Your Snowflake org name |
| `ml_model/deploy_to_spcs.sh` | `SNOWFLAKE_ACCOUNT` | Your Snowflake account name |
| `ml_model/deploy_to_spcs.sh` | `SNOWFLAKE_USER` | Your Snowflake username |

## Support
For issues with this demo, contact your Snowflake representative or file an issue in the demo repository.
