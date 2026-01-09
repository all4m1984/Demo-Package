-- ============================================================================
-- SNOWFLAKE INTELLIGENCE DEMO: INSURANCE UNDERWRITING & INVESTMENT MANAGEMENT
-- Script 4: Upload Semantic Model
-- ============================================================================
-- Purpose: Helper script to upload semantic_model.yaml to Snowflake stage
-- Execution Time: ~1 minute
-- ============================================================================

USE DATABASE INSURANCE_DEMO;
USE SCHEMA UNDERWRITING_INV;
USE WAREHOUSE DEMO_WH;

-- ============================================================================
-- Instructions for Uploading Semantic Model
-- ============================================================================

/*
STEP 1: Upload the semantic_model.yaml file to the CORTEX_STAGE

Option A: Using SnowSQL (Command Line)
---------------------------------------
snowsql -c <your_connection_name>
USE DATABASE INSURANCE_DEMO;
USE SCHEMA UNDERWRITING_INV;
PUT file:///path/to/semantic_model.yaml @CORTEX_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

Example (Mac/Linux):
PUT file:///Users/yourname/Downloads/insurance_underwriting_investment/semantic_model.yaml @CORTEX_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

Example (Windows):
PUT file://C:\Users\yourname\Downloads\insurance_underwriting_investment\semantic_model.yaml @CORTEX_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;


Option B: Using Snowsight UI
-----------------------------
1. Navigate to Data > Databases > INSURANCE_DEMO > UNDERWRITING_INV > Stages
2. Click on CORTEX_STAGE
3. Click "+ Files" button in top right
4. Select semantic_model.yaml from your local machine
5. Click "Upload"


Option C: Using Python (Snowflake Connector)
---------------------------------------------
import snowflake.connector

conn = snowflake.connector.connect(
    user='YOUR_USER',
    password='YOUR_PASSWORD',
    account='YOUR_ACCOUNT',
    warehouse='DEMO_WH',
    database='INSURANCE_DEMO',
    schema='UNDERWRITING_INV'
)

cursor = conn.cursor()
cursor.execute("PUT file:///path/to/semantic_model.yaml @CORTEX_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE")
cursor.close()
conn.close()

*/

-- ============================================================================
-- STEP 2: Verify the upload
-- ============================================================================

-- List files in the stage
LIST @CORTEX_STAGE;

-- Expected output: You should see semantic_model.yaml in the stage

-- ============================================================================
-- STEP 3: Set up Cortex Analyst
-- ============================================================================

/*
After uploading the semantic model, you can use Cortex Analyst in Snowsight:

1. Navigate to Projects > Cortex Analyst (or search for "Analyst" in Snowsight)
2. Click "+ New Analyst App" or select existing app
3. Configure the app:
   - Name: Insurance Underwriting & Investment Demo
   - Database: INSURANCE_DEMO
   - Schema: UNDERWRITING_INV
   - Stage: CORTEX_STAGE
   - Semantic Model File: semantic_model.yaml
4. Click "Create" or "Save"
5. Start asking questions in natural language!

Sample Questions to Try:
- "What is the combined ratio by product line for the last 12 months?"
- "Which product lines have loss ratios above 65%?"
- "Who are the top 10 underwriters by combined ratio?"
- "What is our current asset allocation?"
- "What is our portfolio yield compared to last quarter?"
- "Show me claims frequency and severity by product type"
- "What is our reserve adequacy by accident year?"
- "How much investment income are we generating monthly?"
*/

-- ============================================================================
-- STEP 4: Alternative - Query using SQL (if Cortex Analyst UI not available)
-- ============================================================================

-- You can also use Cortex Analyst programmatically via SQL:
/*
SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'What is the combined ratio by product line?',
    {'semantic_model': '@CORTEX_STAGE/semantic_model.yaml'}
) as RESPONSE;
*/

-- ============================================================================
-- Verification Queries
-- ============================================================================

-- Verify data is ready for analysis
SELECT 'Underwriting Performance Records' as METRIC, COUNT(*) as COUNT FROM VW_UNDERWRITING_PERFORMANCE
UNION ALL
SELECT 'Claims Records', COUNT(*) FROM VW_CLAIMS_ANALYSIS
UNION ALL
SELECT 'Reserve Records', COUNT(*) FROM VW_RESERVE_ADEQUACY
UNION ALL
SELECT 'Policy Records', COUNT(*) FROM VW_POLICY_SUMMARY
UNION ALL
SELECT 'Investment Holdings', COUNT(*) FROM VW_INVESTMENT_PORTFOLIO
UNION ALL
SELECT 'Investment Transactions', COUNT(*) FROM VW_INVESTMENT_PERFORMANCE;

SELECT '✓ Semantic model ready for upload!' as STATUS,
       '✓ Follow instructions above to upload to CORTEX_STAGE' as NEXT_STEP;

-- ============================================================================
-- Troubleshooting
-- ============================================================================

/*
Common Issues:

1. "Stage does not exist"
   Solution: Re-run script 03_setup_intelligence.sql to create the stage

2. "Permission denied"
   Solution: Ensure you have USAGE privilege on the stage:
   GRANT USAGE ON STAGE CORTEX_STAGE TO ROLE <your_role>;

3. "File not found"
   Solution: Verify the file path is correct and the file exists

4. "Cortex Analyst not available"
   Solution: Contact your Snowflake account team to enable Cortex Analyst

5. "Semantic model validation failed"
   Solution: Verify semantic_model.yaml syntax is correct
   Check for proper indentation and YAML structure

For more help:
- Check Snowflake documentation: https://docs.snowflake.com/en/user-guide/cortex-analyst
- Contact your Snowflake account team
*/

-- ============================================================================
-- NEXT STEP: Start using Cortex Analyst or run demo queries
-- See: 05_demo_queries.sql for sample analytical queries
-- ============================================================================

