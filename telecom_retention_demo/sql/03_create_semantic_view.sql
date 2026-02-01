--------------------------------------------------------------------------------
-- TELECOM CUSTOMER RETENTION DEMO - SEMANTIC VIEW
-- Creates semantic view for customer retention analytics using YAML
--------------------------------------------------------------------------------

USE DATABASE TELECOM_DEMO;
USE SCHEMA CUSTOMER_RETENTION;
USE ROLE ACCOUNTADMIN;

--------------------------------------------------------------------------------
-- Create Semantic View from YAML specification
-- Using SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML stored procedure
--------------------------------------------------------------------------------
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'TELECOM_DEMO.CUSTOMER_RETENTION',
    $$
name: CUSTOMER_RETENTION_ANALYTICS
description: Comprehensive semantic model for telecom customer retention analytics. Enables natural language queries about customer usage, subscriptions, network quality, support interactions, and churn risk.

tables:
  - name: CUSTOMERS
    description: Core customer demographic and profile information
    base_table:
      database: TELECOM_DEMO
      schema: CUSTOMER_RETENTION
      table: CUSTOMERS
    primary_key:
      columns:
        - CUSTOMER_ID
    dimensions:
      - name: CUSTOMER_ID
        description: Unique identifier for each customer
        expr: CUSTOMER_ID
        data_type: VARCHAR
      - name: CUSTOMER_NAME
        description: Full name of the customer
        expr: CONCAT(FIRST_NAME, ' ', LAST_NAME)
        data_type: VARCHAR
      - name: EMAIL
        description: Customer email address
        expr: EMAIL
        data_type: VARCHAR
      - name: CITY
        description: City of customer residence
        expr: CITY
        data_type: VARCHAR
      - name: STATE
        description: State of customer residence
        expr: STATE
        data_type: VARCHAR
      - name: CUSTOMER_SEGMENT
        description: Customer tier - Premium, Standard, or Budget
        expr: CUSTOMER_SEGMENT
        data_type: VARCHAR
      - name: PREFERRED_CONTACT_METHOD
        description: Preferred communication channel
        expr: PREFERRED_CONTACT_METHOD
        data_type: VARCHAR
      - name: OPT_IN_MARKETING
        description: Marketing opt-in status
        expr: OPT_IN_MARKETING
        data_type: BOOLEAN
      - name: CUSTOMER_SINCE
        description: Date customer first subscribed
        expr: CUSTOMER_SINCE
        data_type: DATE
    facts:
      - name: CREDIT_SCORE_VAL
        description: Customer credit score value
        expr: CREDIT_SCORE
        data_type: NUMBER
      - name: LTV_VAL
        description: Customer lifetime value
        expr: LIFETIME_VALUE
        data_type: NUMBER
    metrics:
      - name: TOTAL_CUSTOMERS
        description: Count of total customers
        expr: COUNT(DISTINCT CUSTOMER_ID)
      - name: AVG_CREDIT_SCORE
        description: Average credit score
        expr: AVG(CUSTOMERS.CREDIT_SCORE_VAL)
      - name: AVG_LIFETIME_VALUE
        description: Average lifetime value per customer
        expr: AVG(CUSTOMERS.LTV_VAL)

  - name: SUBSCRIPTIONS
    description: Customer subscription and plan details
    base_table:
      database: TELECOM_DEMO
      schema: CUSTOMER_RETENTION
      table: SUBSCRIPTIONS
    primary_key:
      columns:
        - SUBSCRIPTION_ID
    dimensions:
      - name: SUBSCRIPTION_ID
        description: Unique subscription identifier
        expr: SUBSCRIPTION_ID
        data_type: VARCHAR
      - name: CUSTOMER_ID
        description: Reference to customer
        expr: CUSTOMER_ID
        data_type: VARCHAR
      - name: PLAN_NAME
        description: Name of subscription plan
        expr: PLAN_NAME
        data_type: VARCHAR
      - name: PLAN_TYPE
        description: Plan category - Postpaid or Prepaid
        expr: PLAN_TYPE
        data_type: VARCHAR
      - name: STATUS
        description: Subscription status - Active, Suspended, Cancelled
        expr: STATUS
        data_type: VARCHAR
      - name: CONTRACT_START_DATE
        description: Contract start date
        expr: CONTRACT_START_DATE
        data_type: DATE
      - name: CONTRACT_END_DATE
        description: Contract end date
        expr: CONTRACT_END_DATE
        data_type: DATE
    facts:
      - name: MONTHLY_FEE_VAL
        description: Monthly subscription fee
        expr: MONTHLY_FEE
        data_type: NUMBER
    metrics:
      - name: TOTAL_SUBSCRIPTIONS
        description: Count of subscriptions
        expr: COUNT(DISTINCT SUBSCRIPTION_ID)
      - name: ACTIVE_SUBSCRIPTIONS
        description: Count of active subscriptions
        expr: COUNT(DISTINCT CASE WHEN STATUS = 'Active' THEN SUBSCRIPTION_ID END)
      - name: AVG_MONTHLY_FEE
        description: Average monthly fee
        expr: AVG(SUBSCRIPTIONS.MONTHLY_FEE_VAL)
      - name: TOTAL_MONTHLY_REVENUE
        description: Total monthly revenue
        expr: SUM(SUBSCRIPTIONS.MONTHLY_FEE_VAL)

  - name: USAGE_METRICS
    description: Monthly usage data including data, voice, and SMS
    base_table:
      database: TELECOM_DEMO
      schema: CUSTOMER_RETENTION
      table: USAGE_METRICS
    primary_key:
      columns:
        - USAGE_ID
    dimensions:
      - name: USAGE_ID
        description: Unique usage record identifier
        expr: USAGE_ID
        data_type: VARCHAR
      - name: CUSTOMER_ID
        description: Reference to customer
        expr: CUSTOMER_ID
        data_type: VARCHAR
      - name: SUBSCRIPTION_ID
        description: Reference to subscription
        expr: SUBSCRIPTION_ID
        data_type: VARCHAR
      - name: USAGE_MONTH
        description: Month of usage record
        expr: USAGE_MONTH
        data_type: DATE
      - name: PAYMENT_STATUS
        description: Bill payment status
        expr: PAYMENT_STATUS
        data_type: VARCHAR
    facts:
      - name: DATA_GB
        description: Data used in GB
        expr: DATA_USED_GB
        data_type: NUMBER
      - name: DATA_PCT
        description: Data usage percentage
        expr: DATA_USAGE_PCT
        data_type: NUMBER
      - name: VOICE_MIN
        description: Voice minutes used
        expr: VOICE_MINUTES_USED
        data_type: NUMBER
      - name: BILL_AMT
        description: Total bill amount
        expr: TOTAL_BILL_AMOUNT
        data_type: NUMBER
      - name: DAYS_INACTIVE
        description: Days since last usage
        expr: DAYS_SINCE_LAST_USAGE
        data_type: NUMBER
    metrics:
      - name: TOTAL_DATA_USED_GB
        description: Total data consumed in GB
        expr: SUM(USAGE_METRICS.DATA_GB)
      - name: AVG_DATA_USED_GB
        description: Average data consumption per customer
        expr: AVG(USAGE_METRICS.DATA_GB)
      - name: AVG_DATA_USAGE_PCT
        description: Average percentage of data limit used
        expr: AVG(USAGE_METRICS.DATA_PCT)
      - name: TOTAL_VOICE_MINUTES
        description: Total voice minutes used
        expr: SUM(USAGE_METRICS.VOICE_MIN)
      - name: SUM_BILL_AMOUNT
        description: Total billing amount
        expr: SUM(USAGE_METRICS.BILL_AMT)
      - name: AVG_BILL_AMOUNT
        description: Average bill per customer
        expr: AVG(USAGE_METRICS.BILL_AMT)
      - name: AVG_DAYS_SINCE_LAST_USAGE
        description: Average days since last usage
        expr: AVG(USAGE_METRICS.DAYS_INACTIVE)

  - name: NETWORK_STATS
    description: Network quality and performance metrics
    base_table:
      database: TELECOM_DEMO
      schema: CUSTOMER_RETENTION
      table: NETWORK_STATS
    primary_key:
      columns:
        - STAT_ID
    dimensions:
      - name: STAT_ID
        description: Unique network stat identifier
        expr: STAT_ID
        data_type: VARCHAR
      - name: CUSTOMER_ID
        description: Reference to customer
        expr: CUSTOMER_ID
        data_type: VARCHAR
      - name: STAT_DATE
        description: Date of network statistics
        expr: STAT_DATE
        data_type: DATE
      - name: SIGNAL_QUALITY
        description: Signal quality - Excellent, Good, Fair, Poor
        expr: SIGNAL_QUALITY
        data_type: VARCHAR
      - name: NETWORK_TYPE
        description: Network technology - 5G, 4G, 3G
        expr: NETWORK_TYPE
        data_type: VARCHAR
      - name: COVERAGE_ISSUES_REPORTED
        description: Coverage issues reported flag
        expr: COVERAGE_ISSUES_REPORTED
        data_type: BOOLEAN
    facts:
      - name: SIGNAL_DBM
        description: Signal strength in dBm
        expr: AVG_SIGNAL_STRENGTH_DBM
        data_type: NUMBER
      - name: DOWNLOAD_MBPS
        description: Download speed in Mbps
        expr: AVG_DOWNLOAD_SPEED_MBPS
        data_type: NUMBER
      - name: LATENCY_VAL
        description: Latency in ms
        expr: LATENCY_MS
        data_type: NUMBER
      - name: DROPPED_CALLS_VAL
        description: Number of dropped calls
        expr: DROPPED_CALLS
        data_type: NUMBER
      - name: FAILED_CONN_VAL
        description: Number of failed connections
        expr: FAILED_CONNECTIONS
        data_type: NUMBER
    metrics:
      - name: AVG_SIGNAL_STRENGTH
        description: Average signal strength in dBm
        expr: AVG(NETWORK_STATS.SIGNAL_DBM)
      - name: AVG_DOWNLOAD_SPEED
        description: Average download speed in Mbps
        expr: AVG(NETWORK_STATS.DOWNLOAD_MBPS)
      - name: AVG_LATENCY
        description: Average network latency in ms
        expr: AVG(NETWORK_STATS.LATENCY_VAL)
      - name: TOTAL_DROPPED_CALLS
        description: Total dropped calls
        expr: SUM(NETWORK_STATS.DROPPED_CALLS_VAL)
      - name: TOTAL_FAILED_CONNECTIONS
        description: Total failed connections
        expr: SUM(NETWORK_STATS.FAILED_CONN_VAL)
      - name: CUSTOMERS_WITH_POOR_SIGNAL
        description: Customers with poor signal
        expr: COUNT(DISTINCT CASE WHEN SIGNAL_QUALITY = 'Poor' THEN CUSTOMER_ID END)

  - name: CHURN_PREDICTIONS
    description: ML model predictions for customer churn risk
    base_table:
      database: TELECOM_DEMO
      schema: CUSTOMER_RETENTION
      table: CHURN_PREDICTIONS
    primary_key:
      columns:
        - PREDICTION_ID
    dimensions:
      - name: PREDICTION_ID
        description: Unique prediction identifier
        expr: PREDICTION_ID
        data_type: VARCHAR
      - name: CUSTOMER_ID
        description: Reference to customer
        expr: CUSTOMER_ID
        data_type: VARCHAR
      - name: PREDICTION_DATE
        description: Date of prediction
        expr: PREDICTION_DATE
        data_type: DATE
      - name: CHURN_RISK_CATEGORY
        description: Risk level - High, Medium, Low
        expr: CHURN_RISK_CATEGORY
        data_type: VARCHAR
      - name: MODEL_VERSION
        description: ML model version
        expr: MODEL_VERSION
        data_type: VARCHAR
    facts:
      - name: CHURN_PROB_VAL
        description: Churn probability value
        expr: CHURN_PROBABILITY
        data_type: NUMBER
      - name: DAYS_TO_CHURN_VAL
        description: Days until likely churn
        expr: DAYS_UNTIL_LIKELY_CHURN
        data_type: NUMBER
    metrics:
      - name: AVG_CHURN_PROBABILITY
        description: Average churn probability score
        expr: AVG(CHURN_PREDICTIONS.CHURN_PROB_VAL)
      - name: HIGH_RISK_CUSTOMERS
        description: Count of high-risk customers
        expr: COUNT(DISTINCT CASE WHEN CHURN_RISK_CATEGORY = 'High' THEN CUSTOMER_ID END)
      - name: MEDIUM_RISK_CUSTOMERS
        description: Count of medium-risk customers
        expr: COUNT(DISTINCT CASE WHEN CHURN_RISK_CATEGORY = 'Medium' THEN CUSTOMER_ID END)
      - name: AVG_DAYS_UNTIL_CHURN
        description: Average days until likely churn
        expr: AVG(CHURN_PREDICTIONS.DAYS_TO_CHURN_VAL)

  - name: PROMOTIONS
    description: Available promotional offers for retention
    base_table:
      database: TELECOM_DEMO
      schema: CUSTOMER_RETENTION
      table: PROMOTIONS
    primary_key:
      columns:
        - PROMOTION_ID
    dimensions:
      - name: PROMOTION_ID
        description: Unique promotion identifier
        expr: PROMOTION_ID
        data_type: VARCHAR
      - name: PROMOTION_NAME
        description: Name of promotion
        expr: PROMOTION_NAME
        data_type: VARCHAR
      - name: PROMOTION_TYPE
        description: Type - Discount, Upgrade, Loyalty, Winback, Device
        expr: PROMOTION_TYPE
        data_type: VARCHAR
      - name: DESCRIPTION
        description: Promotion description
        expr: DESCRIPTION
        data_type: VARCHAR
      - name: IS_ACTIVE
        description: Whether promotion is active
        expr: IS_ACTIVE
        data_type: BOOLEAN
      - name: VALID_FROM
        description: Promotion start date
        expr: VALID_FROM
        data_type: DATE
      - name: VALID_UNTIL
        description: Promotion end date
        expr: VALID_UNTIL
        data_type: DATE
    facts:
      - name: SUCCESS_RATE_VAL
        description: Promotion success rate
        expr: SUCCESS_RATE
        data_type: NUMBER
    metrics:
      - name: TOTAL_PROMOTIONS
        description: Count of promotions
        expr: COUNT(DISTINCT PROMOTION_ID)
      - name: AVG_SUCCESS_RATE
        description: Average success rate
        expr: AVG(PROMOTIONS.SUCCESS_RATE_VAL)

relationships:
  - name: CUSTOMER_TO_SUBSCRIPTION
    left_table: SUBSCRIPTIONS
    right_table: CUSTOMERS
    relationship_columns:
      - left_column: CUSTOMER_ID
        right_column: CUSTOMER_ID
    relationship_type: many_to_one

  - name: CUSTOMER_TO_USAGE
    left_table: USAGE_METRICS
    right_table: CUSTOMERS
    relationship_columns:
      - left_column: CUSTOMER_ID
        right_column: CUSTOMER_ID
    relationship_type: many_to_one

  - name: CUSTOMER_TO_NETWORK
    left_table: NETWORK_STATS
    right_table: CUSTOMERS
    relationship_columns:
      - left_column: CUSTOMER_ID
        right_column: CUSTOMER_ID
    relationship_type: many_to_one

  - name: CUSTOMER_TO_CHURN
    left_table: CHURN_PREDICTIONS
    right_table: CUSTOMERS
    relationship_columns:
      - left_column: CUSTOMER_ID
        right_column: CUSTOMER_ID
    relationship_type: many_to_one

  - name: SUBSCRIPTION_TO_USAGE
    left_table: USAGE_METRICS
    right_table: SUBSCRIPTIONS
    relationship_columns:
      - left_column: SUBSCRIPTION_ID
        right_column: SUBSCRIPTION_ID
    relationship_type: many_to_one
    $$
);

--------------------------------------------------------------------------------
-- Grant permissions on semantic view
--------------------------------------------------------------------------------
GRANT USAGE ON DATABASE TELECOM_DEMO TO ROLE ACCOUNTADMIN;
GRANT USAGE ON SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION TO ROLE ACCOUNTADMIN;

--------------------------------------------------------------------------------
-- Verify semantic view creation
--------------------------------------------------------------------------------
SHOW SEMANTIC VIEWS IN SCHEMA TELECOM_DEMO.CUSTOMER_RETENTION;

-- Describe the semantic view
DESCRIBE SEMANTIC VIEW TELECOM_DEMO.CUSTOMER_RETENTION.CUSTOMER_RETENTION_ANALYTICS;
