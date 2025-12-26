/*============================================================================
   FMCG Trade Promotion & Demand Intelligence Demo - Semantic Model Upload Helper
   
   Purpose: Provides instructions and commands to upload the semantic_model.yaml
   Duration: <1 minute
   
   Execute this script after 03_setup_intelligence.sql
============================================================================*/

USE DATABASE FMCG_TRADE_DEMO;
USE SCHEMA ANALYTICS;
USE WAREHOUSE FMCG_WH;

-- ============================================================================
-- 1. Verify Stage Exists
-- ============================================================================
CREATE STAGE IF NOT EXISTS CORTEX_STAGE;

SELECT 'Stage CORTEX_STAGE ready for semantic model upload.' as STATUS;

-- ============================================================================
-- 2. Upload the semantic_model.yaml file to the stage
--    You have several options to upload the file. Choose one:
-- ============================================================================

-- OPTION A: Using Snowsight UI (Recommended for Demos)
-- ----------------------------------------------------
-- 1. In Snowsight, navigate to:
--    Data -> Databases -> FMCG_TRADE_DEMO -> ANALYTICS -> Stages
-- 2. Click on the 'CORTEX_STAGE' stage.
-- 3. Click the '+ Files' button.
-- 4. Select the 'semantic_model.yaml' file from your local machine (this folder).
-- 5. Click 'Upload'.
-- 6. Verify the file appears in the list.

SELECT 'To upload via Snowsight UI: Navigate to Data > Databases > FMCG_TRADE_DEMO > ANALYTICS > Stages > CORTEX_STAGE and upload semantic_model.yaml' as UI_INSTRUCTIONS;

-- OPTION B: Using SnowSQL (Command Line)
-- --------------------------------------
-- Open your terminal or command prompt and run the following command.
-- Make sure you are in the directory where semantic_model.yaml is located.

-- Example SnowSQL command:
-- PUT file://semantic_model.yaml @FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

SELECT 'To upload via SnowSQL: PUT file://semantic_model.yaml @FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;' as SNOWSQL_INSTRUCTIONS;

-- ============================================================================
-- 3. Verify the file is in the stage
-- ============================================================================
LIST @CORTEX_STAGE;

-- Expected output: You should see 'semantic_model.yaml' listed.

-- ============================================================================
-- 4. Next Steps: Use Cortex Analyst
-- ============================================================================
SELECT 'Semantic model upload instructions provided. Proceed to Cortex Analyst in Snowsight.' as NEXT_STEP_STATUS;
SELECT 'In Cortex Analyst, when prompted for the semantic model, use the path:' as CORTEX_PATH_INFO;
SELECT '@FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE/semantic_model.yaml' as CORTEX_MODEL_PATH;
SELECT 'Then start asking natural language questions about your FMCG data!' as FINAL_INSTRUCTION;

/*============================================================================
   Sample Questions to Ask Cortex Analyst:
   
   Trade Promotion Optimization:
   - Which promotions had the best ROI last quarter?
   - Show me promotion lift by promotion type
   - What is the incremental revenue from promotions in the Beverages category?
   
   Demand Forecasting:
   - What is the demand forecast for top products next week?
   - Show me forecast accuracy by category
   - Which products have the highest forecast error?
   
   On-Shelf Availability:
   - Which stores have the highest out-of-stock rates?
   - What is the estimated lost revenue from stockouts?
   - Show me OSA percentage by product category
============================================================================*/

