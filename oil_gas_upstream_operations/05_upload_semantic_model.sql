/*============================================================================
   Oil & Gas Upstream Operations Demo - Upload Semantic Model
   
   Purpose: Upload semantic_model.yaml to Snowflake stage for Cortex Analyst
   Duration: ~1 minute
   
   Execute this script after running 03_setup_intelligence.sql
   
   IMPORTANT: You need to upload the semantic_model.yaml file using one of
   the methods below BEFORE you can use Cortex Analyst.
============================================================================*/

USE DATABASE OIL_GAS_UPSTREAM_DEMO;
USE SCHEMA OPERATIONS;

-- ============================================================================
-- Step 1: Verify the stage exists
-- ============================================================================
SHOW STAGES LIKE 'CORTEX_STAGE';

-- ============================================================================
-- Step 2: Upload the semantic_model.yaml file
-- ============================================================================

/*
   Choose ONE of the following methods to upload:
   
   METHOD 1: Using SnowSQL (Command Line)
   ========================================
   From your terminal where semantic_model.yaml is located:
   
   snowsql -c your_connection -q "PUT file://semantic_model.yaml @OIL_GAS_UPSTREAM_DEMO.OPERATIONS.CORTEX_STAGE AUTO_COMPRESS=FALSE;"
   
   Or in SnowSQL interactive mode:
   
   USE DATABASE OIL_GAS_UPSTREAM_DEMO;
   USE SCHEMA OPERATIONS;
   PUT file://semantic_model.yaml @CORTEX_STAGE AUTO_COMPRESS=FALSE;
   
   
   METHOD 2: Using Snowsight UI (Easiest)
   ========================================
   1. Log into Snowsight
   2. Navigate: Data > Databases > OIL_GAS_UPSTREAM_DEMO > OPERATIONS > Stages
   3. Click on "CORTEX_STAGE"
   4. Click the "+ Files" button
   5. Select semantic_model.yaml from your computer
   6. Click "Upload"
   
   
   METHOD 3: Using Python (Snowpark)
   ===================================
   from snowflake.snowpark import Session
   
   session = Session.builder.configs(connection_parameters).create()
   session.file.put("semantic_model.yaml", "@CORTEX_STAGE", auto_compress=False)
   
   
   METHOD 4: Using Python (Snowflake Connector)
   ==============================================
   import snowflake.connector
   
   conn = snowflake.connector.connect(...)
   cursor = conn.cursor()
   cursor.execute("USE DATABASE OIL_GAS_UPSTREAM_DEMO")
   cursor.execute("USE SCHEMA OPERATIONS")
   cursor.execute("PUT file://semantic_model.yaml @CORTEX_STAGE AUTO_COMPRESS=FALSE")
*/

-- ============================================================================
-- Step 3: Verify the file was uploaded successfully
-- ============================================================================

LIST @CORTEX_STAGE;

-- You should see: semantic_model.yaml (or semantic_model.yaml.gz if compressed)

-- ============================================================================
-- Step 4: View the file contents to verify (optional)
-- ============================================================================

-- Preview the semantic model file
SELECT $1 FROM @CORTEX_STAGE/semantic_model.yaml (FILE_FORMAT => (TYPE = 'CSV' FIELD_DELIMITER = NONE)) LIMIT 50;

-- ============================================================================
-- Step 5: Grant access to the stage (if needed for other roles)
-- ============================================================================

-- Grant usage to other roles if needed
-- GRANT READ ON STAGE CORTEX_STAGE TO ROLE YOUR_ROLE;

-- ============================================================================
-- Next Steps: Using Cortex Analyst
-- ============================================================================

SELECT '============================================' as INFO;
SELECT 'Semantic model uploaded successfully!' as STATUS;
SELECT '============================================' as INFO;
SELECT '' as BLANK;
SELECT 'To use with Cortex Analyst:' as INSTRUCTION;
SELECT '' as BLANK;
SELECT '1. Open Snowsight UI' as STEP_1;
SELECT '2. Navigate to: Projects > Cortex Analyst (or look in left sidebar)' as STEP_2;
SELECT '3. Create a new Analyst session or select existing one' as STEP_3;
SELECT '4. When prompted for semantic model, enter:' as STEP_4;
SELECT '   @OIL_GAS_UPSTREAM_DEMO.OPERATIONS.CORTEX_STAGE/semantic_model.yaml' as MODEL_PATH;
SELECT '' as BLANK;
SELECT '5. Start asking questions in natural language!' as STEP_5;
SELECT '' as BLANK;
SELECT 'Example questions:' as EXAMPLES;
SELECT '  - "What are my top 10 wells by production?"' as Q1;
SELECT '  - "Which wells have the highest operating costs?"' as Q2;
SELECT '  - "Show me equipment failures in the last 6 months"' as Q3;
SELECT '  - "What is my carbon emissions intensity by field?"' as Q4;
SELECT '============================================' as INFO;

-- ============================================================================
-- Troubleshooting
-- ============================================================================

/*
   ISSUE: File not found after upload
   SOLUTION: Check if file was compressed (.gz extension)
   
   ISSUE: Cortex Analyst cannot find the model
   SOLUTION: Use full path: @OIL_GAS_UPSTREAM_DEMO.OPERATIONS.CORTEX_STAGE/semantic_model.yaml
   
   ISSUE: Permission denied
   SOLUTION: Ensure you have USAGE on stage and READ on files
   
   ISSUE: Semantic model validation errors
   SOLUTION: Check the YAML syntax in semantic_model.yaml
   
   For more help, run:
   SHOW STAGES LIKE 'CORTEX_STAGE';
   LIST @CORTEX_STAGE;
   DESC STAGE CORTEX_STAGE;
*/

