--------------------------------------------------------------------------------
-- TELECOM CUSTOMER RETENTION DEMO - CREATE AGENT
-- Creates the Snowflake Intelligence Agent with all tools
--------------------------------------------------------------------------------

USE ROLE ACCOUNTADMIN;
USE DATABASE TELECOM_DEMO;
USE SCHEMA CUSTOMER_RETENTION;

--------------------------------------------------------------------------------
-- Step 1: Verify all prerequisites are in place
--------------------------------------------------------------------------------

-- Check semantic view exists
SHOW SEMANTIC VIEWS LIKE 'CUSTOMER_RETENTION_ANALYTICS' IN SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION;

-- Check cortex search service exists
SHOW CORTEX SEARCH SERVICES LIKE 'CALL_CENTER_SEARCH' IN SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION;

-- Check stored procedures exist
SHOW PROCEDURES LIKE 'CALCULATE_CHURN_RISK' IN SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION;
SHOW PROCEDURES LIKE 'GET_RECOMMENDED_PROMOTIONS' IN SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION;
SHOW PROCEDURES LIKE 'SEND_RETENTION_EMAIL' IN SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION;

--------------------------------------------------------------------------------
-- Step 2: Create staging area for agent config
--------------------------------------------------------------------------------
CREATE STAGE IF NOT EXISTS TELECOM_DEMO.CUSTOMER_RETENTION.AGENT_CONFIG_STAGE
    DIRECTORY = (ENABLE = TRUE);

-- Upload agent_spec.json to stage:
-- PUT file:///path/to/agent_spec.json @TELECOM_DEMO.CUSTOMER_RETENTION.AGENT_CONFIG_STAGE

--------------------------------------------------------------------------------
-- Step 3: Create the Agent (REST API Method)
--------------------------------------------------------------------------------
-- The agent is created using the REST API via the create_or_alter_agent.py script
-- or through Snowflake Intelligence UI

/*
Using the CLI/Python script:

uv run python scripts/create_or_alter_agent.py create \
  --agent-name TELECOM_RETENTION_AGENT \
  --config-file agent_config/agent_spec.json \
  --database TELECOM_DEMO \
  --schema CUSTOMER_RETENTION \
  --role ACCOUNTADMIN \
  --connection snowhouse
*/

--------------------------------------------------------------------------------
-- Step 4: Alternative - Create Agent via SQL (simplified version)
--------------------------------------------------------------------------------
-- Note: Full agent spec requires REST API, but here's a simplified SQL version

CREATE OR REPLACE AGENT TELECOM_DEMO.CUSTOMER_RETENTION.TELECOM_RETENTION_AGENT
    COMMENT = 'Customer retention agent for telecom with text-to-SQL, semantic search, ML predictions, and email tools';

-- After creating the agent shell, use the Admin UI or REST API to configure tools

--------------------------------------------------------------------------------
-- Step 5: Verify Agent
--------------------------------------------------------------------------------
SHOW AGENTS LIKE 'TELECOM_RETENTION_AGENT' IN SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION;
DESCRIBE AGENT TELECOM_DEMO.CUSTOMER_RETENTION.TELECOM_RETENTION_AGENT;

--------------------------------------------------------------------------------
-- Step 6: Grant Access
--------------------------------------------------------------------------------
-- Grant usage to other roles as needed
-- GRANT USAGE ON AGENT TELECOM_DEMO.CUSTOMER_RETENTION.TELECOM_RETENTION_AGENT TO ROLE <role_name>;

--------------------------------------------------------------------------------
-- Step 7: Test the Agent
--------------------------------------------------------------------------------
/*
Test queries to try in Snowflake Intelligence:

1. "Who are our high-risk customers who might churn?"

2. "Show me customers with low data usage in the last 3 months"

3. "What issues has customer CUST-000001 reported to our call center?"

4. "Calculate the churn risk for CUST-000050"

5. "What promotions can we offer to retain customer CUST-000100?"

6. "Find customers experiencing network issues who have called support"

7. "Send the loyalty discount promotion to customer CUST-000025"

8. "Compare our retention offers with what competitors are offering"

9. "Show me customers in the Premium segment with declining usage"

10. "Summarize the retention situation for customer CUST-000001"
*/
