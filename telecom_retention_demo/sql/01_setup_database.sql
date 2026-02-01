--------------------------------------------------------------------------------
-- TELECOM CUSTOMER RETENTION DEMO - DATABASE SETUP
-- Run this script with ACCOUNTADMIN or a role with CREATE DATABASE privilege
--------------------------------------------------------------------------------

USE ROLE ACCOUNTADMIN;

-- Create database and schema
CREATE DATABASE IF NOT EXISTS TELECOM_DEMO;
CREATE SCHEMA IF NOT EXISTS TELECOM_DEMO.CUSTOMER_RETENTION;

-- Create warehouse for demo if needed
CREATE WAREHOUSE IF NOT EXISTS TELECOM_DEMO_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

USE DATABASE TELECOM_DEMO;
USE SCHEMA CUSTOMER_RETENTION;
USE WAREHOUSE TELECOM_DEMO_WH;

--------------------------------------------------------------------------------
-- TABLE: CUSTOMERS - Core customer information
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE CUSTOMERS (
    CUSTOMER_ID VARCHAR(20) PRIMARY KEY,
    FIRST_NAME VARCHAR(50),
    LAST_NAME VARCHAR(50),
    EMAIL VARCHAR(100),
    PHONE_NUMBER VARCHAR(20),
    DATE_OF_BIRTH DATE,
    GENDER VARCHAR(10),
    ADDRESS VARCHAR(200),
    CITY VARCHAR(50),
    STATE VARCHAR(50),
    ZIP_CODE VARCHAR(10),
    COUNTRY VARCHAR(50) DEFAULT 'USA',
    CUSTOMER_SINCE DATE,
    CUSTOMER_SEGMENT VARCHAR(20), -- 'Premium', 'Standard', 'Budget'
    CREDIT_SCORE INT,
    LIFETIME_VALUE DECIMAL(12,2),
    PREFERRED_CONTACT_METHOD VARCHAR(20), -- 'Email', 'SMS', 'Phone'
    OPT_IN_MARKETING BOOLEAN DEFAULT TRUE,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

--------------------------------------------------------------------------------
-- TABLE: SUBSCRIPTIONS - Customer plan details
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE SUBSCRIPTIONS (
    SUBSCRIPTION_ID VARCHAR(20) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    PLAN_NAME VARCHAR(50), -- 'Unlimited Plus', 'Family Share', 'Basic', 'Pay As You Go'
    PLAN_TYPE VARCHAR(20), -- 'Postpaid', 'Prepaid'
    MONTHLY_FEE DECIMAL(10,2),
    DATA_LIMIT_GB INT, -- -1 for unlimited
    VOICE_MINUTES_LIMIT INT, -- -1 for unlimited
    SMS_LIMIT INT, -- -1 for unlimited
    CONTRACT_START_DATE DATE,
    CONTRACT_END_DATE DATE,
    CONTRACT_LENGTH_MONTHS INT,
    EARLY_TERMINATION_FEE DECIMAL(10,2),
    DEVICE_FINANCING BOOLEAN DEFAULT FALSE,
    DEVICE_MONTHLY_PAYMENT DECIMAL(10,2),
    INTERNATIONAL_ROAMING BOOLEAN DEFAULT FALSE,
    HOTSPOT_ENABLED BOOLEAN DEFAULT FALSE,
    STATUS VARCHAR(20) DEFAULT 'Active', -- 'Active', 'Suspended', 'Cancelled'
    CANCELLATION_DATE DATE,
    CANCELLATION_REASON VARCHAR(100),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    UPDATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

--------------------------------------------------------------------------------
-- TABLE: USAGE_METRICS - Monthly usage data
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE USAGE_METRICS (
    USAGE_ID VARCHAR(30) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    SUBSCRIPTION_ID VARCHAR(20) REFERENCES SUBSCRIPTIONS(SUBSCRIPTION_ID),
    USAGE_MONTH DATE, -- First day of month
    DATA_USED_GB DECIMAL(10,3),
    DATA_LIMIT_GB INT,
    DATA_USAGE_PCT DECIMAL(5,2),
    VOICE_MINUTES_USED INT,
    VOICE_MINUTES_LIMIT INT,
    VOICE_USAGE_PCT DECIMAL(5,2),
    SMS_SENT INT,
    SMS_LIMIT INT,
    SMS_USAGE_PCT DECIMAL(5,2),
    INTERNATIONAL_DATA_GB DECIMAL(10,3),
    INTERNATIONAL_VOICE_MINUTES INT,
    OVERAGE_CHARGES DECIMAL(10,2),
    TOTAL_BILL_AMOUNT DECIMAL(10,2),
    PAYMENT_STATUS VARCHAR(20), -- 'Paid', 'Pending', 'Overdue', 'Partial'
    DAYS_SINCE_LAST_USAGE INT,
    APP_SESSIONS INT,
    APP_TIME_MINUTES INT,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

--------------------------------------------------------------------------------
-- TABLE: NETWORK_STATS - Network quality metrics per customer
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE NETWORK_STATS (
    STAT_ID VARCHAR(30) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    STAT_DATE DATE,
    PRIMARY_CELL_TOWER VARCHAR(50),
    AVG_SIGNAL_STRENGTH_DBM INT, -- Typically -50 to -110, higher is better
    SIGNAL_QUALITY VARCHAR(20), -- 'Excellent', 'Good', 'Fair', 'Poor'
    AVG_DOWNLOAD_SPEED_MBPS DECIMAL(10,2),
    AVG_UPLOAD_SPEED_MBPS DECIMAL(10,2),
    LATENCY_MS INT,
    PACKET_LOSS_PCT DECIMAL(5,2),
    DROPPED_CALLS INT,
    FAILED_CONNECTIONS INT,
    NETWORK_TYPE VARCHAR(10), -- '5G', '4G', '3G'
    COVERAGE_ISSUES_REPORTED BOOLEAN DEFAULT FALSE,
    DATA_THROTTLED BOOLEAN DEFAULT FALSE,
    ROAMING_PCT DECIMAL(5,2),
    INDOOR_USAGE_PCT DECIMAL(5,2),
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

--------------------------------------------------------------------------------
-- TABLE: CALL_CENTER_LOGS - Support interactions (for Cortex Search)
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE CALL_CENTER_LOGS (
    INTERACTION_ID VARCHAR(30) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    INTERACTION_DATE TIMESTAMP_NTZ,
    CHANNEL VARCHAR(20), -- 'Phone', 'Chat', 'Email', 'Store', 'App'
    AGENT_ID VARCHAR(20),
    AGENT_NAME VARCHAR(50),
    CATEGORY VARCHAR(50), -- 'Billing', 'Technical', 'Plan Change', 'Cancellation', 'General'
    SUBCATEGORY VARCHAR(50),
    ISSUE_DESCRIPTION TEXT,
    RESOLUTION_DESCRIPTION TEXT,
    RESOLUTION_STATUS VARCHAR(20), -- 'Resolved', 'Escalated', 'Pending', 'Unresolved'
    CUSTOMER_SENTIMENT VARCHAR(20), -- 'Positive', 'Neutral', 'Negative', 'Very Negative'
    NPS_SCORE INT, -- 0-10
    CALL_DURATION_MINUTES INT,
    WAIT_TIME_MINUTES INT,
    FIRST_CONTACT_RESOLUTION BOOLEAN,
    ESCALATED BOOLEAN DEFAULT FALSE,
    ESCALATION_REASON VARCHAR(100),
    COMPENSATION_OFFERED DECIMAL(10,2),
    RETENTION_OFFER_MADE BOOLEAN DEFAULT FALSE,
    RETENTION_OFFER_ACCEPTED BOOLEAN,
    TRANSCRIPT_SUMMARY TEXT, -- Searchable summary
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

--------------------------------------------------------------------------------
-- TABLE: PROMOTIONS - Available offers for retention
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE PROMOTIONS (
    PROMOTION_ID VARCHAR(20) PRIMARY KEY,
    PROMOTION_NAME VARCHAR(100),
    PROMOTION_TYPE VARCHAR(30), -- 'Discount', 'Upgrade', 'Loyalty', 'Winback', 'Device'
    DESCRIPTION TEXT,
    DISCOUNT_PCT DECIMAL(5,2),
    DISCOUNT_AMOUNT DECIMAL(10,2),
    BONUS_DATA_GB INT,
    BONUS_MINUTES INT,
    FREE_MONTHS INT,
    DEVICE_DISCOUNT_PCT DECIMAL(5,2),
    VALID_FROM DATE,
    VALID_UNTIL DATE,
    MIN_TENURE_MONTHS INT, -- Minimum customer tenure required
    MAX_CHURN_SCORE DECIMAL(5,2), -- Target churn score threshold
    TARGET_SEGMENTS VARIANT, -- Array of segments this applies to
    ELIGIBILITY_CRITERIA TEXT,
    TERMS_AND_CONDITIONS TEXT,
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    SUCCESS_RATE DECIMAL(5,2), -- Historical success rate
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

--------------------------------------------------------------------------------
-- TABLE: CHURN_PREDICTIONS - ML model outputs (updated by SPCS)
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE CHURN_PREDICTIONS (
    PREDICTION_ID VARCHAR(30) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    PREDICTION_DATE DATE,
    CHURN_PROBABILITY DECIMAL(5,4), -- 0.0000 to 1.0000
    CHURN_RISK_CATEGORY VARCHAR(20), -- 'High', 'Medium', 'Low'
    TOP_CHURN_FACTORS VARIANT, -- Array of contributing factors
    RECOMMENDED_ACTIONS VARIANT, -- Array of recommended interventions
    MODEL_VERSION VARCHAR(20),
    CONFIDENCE_SCORE DECIMAL(5,4),
    DAYS_UNTIL_LIKELY_CHURN INT,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

--------------------------------------------------------------------------------
-- TABLE: EMAIL_LOG - Track sent emails for compliance
--------------------------------------------------------------------------------
CREATE OR REPLACE TABLE EMAIL_LOG (
    EMAIL_LOG_ID VARCHAR(30) PRIMARY KEY,
    CUSTOMER_ID VARCHAR(20) REFERENCES CUSTOMERS(CUSTOMER_ID),
    EMAIL_ADDRESS VARCHAR(100),
    PROMOTION_ID VARCHAR(20) REFERENCES PROMOTIONS(PROMOTION_ID),
    EMAIL_TYPE VARCHAR(30), -- 'Retention', 'Promotion', 'Winback'
    SUBJECT_LINE VARCHAR(200),
    EMAIL_BODY TEXT,
    SENT_AT TIMESTAMP_NTZ,
    SENT_BY VARCHAR(50),
    DELIVERY_STATUS VARCHAR(20), -- 'Sent', 'Delivered', 'Bounced', 'Failed'
    OPENED_AT TIMESTAMP_NTZ,
    CLICKED_AT TIMESTAMP_NTZ,
    UNSUBSCRIBED BOOLEAN DEFAULT FALSE,
    CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

COMMIT;

SELECT 'Database setup complete!' AS STATUS;
