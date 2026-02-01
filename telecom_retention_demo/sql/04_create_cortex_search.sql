--------------------------------------------------------------------------------
-- TELECOM CUSTOMER RETENTION DEMO - CORTEX SEARCH SERVICE
-- Creates search service for call center logs and support tickets
--------------------------------------------------------------------------------

USE DATABASE TELECOM_DEMO;
USE SCHEMA CUSTOMER_RETENTION;
USE ROLE ACCOUNTADMIN;

--------------------------------------------------------------------------------
-- Create a view that combines call center logs with customer context
-- This enriches the search results with customer information
--------------------------------------------------------------------------------
CREATE OR REPLACE VIEW CALL_CENTER_SEARCH_VIEW AS
SELECT
    cl.INTERACTION_ID,
    cl.CUSTOMER_ID,
    c.FIRST_NAME || ' ' || c.LAST_NAME AS CUSTOMER_NAME,
    c.CUSTOMER_SEGMENT,
    c.CITY || ', ' || c.STATE AS CUSTOMER_LOCATION,
    cl.INTERACTION_DATE,
    cl.CHANNEL,
    cl.AGENT_NAME,
    cl.CATEGORY,
    cl.SUBCATEGORY,
    cl.ISSUE_DESCRIPTION,
    cl.RESOLUTION_DESCRIPTION,
    cl.RESOLUTION_STATUS,
    cl.CUSTOMER_SENTIMENT,
    cl.NPS_SCORE,
    cl.FIRST_CONTACT_RESOLUTION,
    cl.ESCALATED,
    cl.RETENTION_OFFER_MADE,
    cl.RETENTION_OFFER_ACCEPTED,
    -- Combine text fields for better search
    cl.TRANSCRIPT_SUMMARY,
    -- Create a comprehensive searchable text field
    'Customer: ' || c.FIRST_NAME || ' ' || c.LAST_NAME || 
    ' | Segment: ' || c.CUSTOMER_SEGMENT ||
    ' | Category: ' || cl.CATEGORY || ' - ' || cl.SUBCATEGORY ||
    ' | Channel: ' || cl.CHANNEL ||
    ' | Sentiment: ' || cl.CUSTOMER_SENTIMENT ||
    ' | Issue: ' || cl.ISSUE_DESCRIPTION ||
    ' | Resolution: ' || COALESCE(cl.RESOLUTION_DESCRIPTION, 'Pending') ||
    ' | Status: ' || cl.RESOLUTION_STATUS AS FULL_SEARCH_TEXT
FROM CALL_CENTER_LOGS cl
JOIN CUSTOMERS c ON cl.CUSTOMER_ID = c.CUSTOMER_ID;

--------------------------------------------------------------------------------
-- Create Cortex Search Service on the call center logs
--------------------------------------------------------------------------------
CREATE OR REPLACE CORTEX SEARCH SERVICE TELECOM_DEMO.CUSTOMER_RETENTION.CALL_CENTER_SEARCH
    ON FULL_SEARCH_TEXT
    ATTRIBUTES 
        CUSTOMER_ID,
        CUSTOMER_NAME,
        CUSTOMER_SEGMENT,
        CUSTOMER_LOCATION,
        CATEGORY,
        SUBCATEGORY,
        CHANNEL,
        AGENT_NAME,
        CUSTOMER_SENTIMENT,
        NPS_SCORE,
        RESOLUTION_STATUS,
        ESCALATED,
        RETENTION_OFFER_MADE
    WAREHOUSE = TELECOM_DEMO_WH
    TARGET_LAG = '1 day'
AS (
    SELECT 
        INTERACTION_ID,
        CUSTOMER_ID,
        CUSTOMER_NAME,
        CUSTOMER_SEGMENT,
        CUSTOMER_LOCATION,
        INTERACTION_DATE,
        CHANNEL,
        AGENT_NAME,
        CATEGORY,
        SUBCATEGORY,
        ISSUE_DESCRIPTION,
        RESOLUTION_DESCRIPTION,
        RESOLUTION_STATUS,
        CUSTOMER_SENTIMENT,
        NPS_SCORE,
        FIRST_CONTACT_RESOLUTION,
        ESCALATED,
        RETENTION_OFFER_MADE,
        RETENTION_OFFER_ACCEPTED,
        TRANSCRIPT_SUMMARY,
        FULL_SEARCH_TEXT
    FROM CALL_CENTER_SEARCH_VIEW
);

--------------------------------------------------------------------------------
-- Grant permissions
--------------------------------------------------------------------------------
GRANT USAGE ON CORTEX SEARCH SERVICE TELECOM_DEMO.CUSTOMER_RETENTION.CALL_CENTER_SEARCH 
    TO ROLE ACCOUNTADMIN;

--------------------------------------------------------------------------------
-- Verify the search service
--------------------------------------------------------------------------------
SHOW CORTEX SEARCH SERVICES IN SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION;

DESCRIBE CORTEX SEARCH SERVICE TELECOM_DEMO.CUSTOMER_RETENTION.CALL_CENTER_SEARCH;

--------------------------------------------------------------------------------
-- Test the search service
--------------------------------------------------------------------------------
-- Example: Search for customers with network issues
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'TELECOM_DEMO.CUSTOMER_RETENTION.CALL_CENTER_SEARCH',
    '{
        "query": "network issues poor signal dropped calls",
        "columns": ["CUSTOMER_ID", "CUSTOMER_NAME", "CATEGORY", "ISSUE_DESCRIPTION", "CUSTOMER_SENTIMENT"],
        "limit": 10
    }'
);

-- Example: Search for cancellation-related interactions
SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
    'TELECOM_DEMO.CUSTOMER_RETENTION.CALL_CENTER_SEARCH',
    '{
        "query": "customer wants to cancel unhappy dissatisfied competitor offer",
        "columns": ["CUSTOMER_ID", "CUSTOMER_NAME", "CATEGORY", "ISSUE_DESCRIPTION", "RESOLUTION_STATUS"],
        "limit": 10
    }'
);
