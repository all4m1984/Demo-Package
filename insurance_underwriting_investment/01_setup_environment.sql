-- ============================================================================
-- SNOWFLAKE INTELLIGENCE DEMO: INSURANCE UNDERWRITING & INVESTMENT MANAGEMENT
-- Script 1: Environment Setup (Southeast Asia Edition)
-- ============================================================================
-- Purpose: Creates database, schema, and tables for insurance demo
-- Market: Singapore, Malaysia, Indonesia, Thailand, Philippines, Vietnam
-- Execution Time: ~2 minutes
-- Tables Created: 10 (Underwriting: 7, Investment: 3)
-- ============================================================================

-- Set context
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 1. Database and Warehouse Setup
-- ============================================================================

-- Create demo database
CREATE DATABASE IF NOT EXISTS INSURANCE_DEMO
    COMMENT = 'Snowflake Intelligence Demo - Insurance Underwriting & Investment Management';

USE DATABASE INSURANCE_DEMO;

-- Create schema
CREATE SCHEMA IF NOT EXISTS UNDERWRITING_INV
    COMMENT = 'Insurance underwriting and investment management data';

USE SCHEMA UNDERWRITING_INV;

-- Create or use warehouse
CREATE WAREHOUSE IF NOT EXISTS DEMO_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for demo purposes';

USE WAREHOUSE DEMO_WH;

SELECT 'Environment setup complete' as STATUS;

-- ============================================================================
-- 2. Underwriting Tables
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Table 1: PRODUCTS - Insurance product line definitions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE PRODUCTS (
    PRODUCT_ID VARCHAR(20) PRIMARY KEY,
    PRODUCT_NAME VARCHAR(100) NOT NULL,
    PRODUCT_TYPE VARCHAR(50) NOT NULL,  -- Personal Auto, Commercial Auto, etc.
    PRODUCT_CATEGORY VARCHAR(30) NOT NULL,  -- Property, Casualty, Specialty
    TARGET_LOSS_RATIO NUMBER(5,2),  -- Target loss ratio % (e.g., 65.00)
    TARGET_EXPENSE_RATIO NUMBER(5,2),  -- Target expense ratio %
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    LAUNCH_DATE DATE,
    DESCRIPTION VARCHAR(500),
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------------
-- Table 2: POLICYHOLDERS - Customer information
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE POLICYHOLDERS (
    POLICYHOLDER_ID VARCHAR(20) PRIMARY KEY,
    FIRST_NAME VARCHAR(50),
    LAST_NAME VARCHAR(50),
    DATE_OF_BIRTH DATE,
    GENDER VARCHAR(10),
    STATE VARCHAR(2),
    ZIP_CODE VARCHAR(10),
    CREDIT_SCORE NUMBER(3,0),  -- 300-850
    RISK_SCORE NUMBER(3,0),  -- 1-100 (higher = higher risk)
    CUSTOMER_SEGMENT VARCHAR(30),  -- Preferred, Standard, Non-Standard
    ACQUISITION_CHANNEL VARCHAR(30),  -- Agent, Direct, Broker
    CUSTOMER_SINCE_DATE DATE,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------------
-- Table 3: UNDERWRITERS - Underwriter information
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE UNDERWRITERS (
    UNDERWRITER_ID VARCHAR(20) PRIMARY KEY,
    FIRST_NAME VARCHAR(50),
    LAST_NAME VARCHAR(50),
    REGION VARCHAR(30),  -- Northeast, Southeast, Midwest, West
    EXPERIENCE_LEVEL VARCHAR(20),  -- Junior, Mid, Senior, Principal
    YEARS_EXPERIENCE NUMBER(2,0),
    SPECIALIZATION VARCHAR(50),  -- Product line specialization
    HIRE_DATE DATE,
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------------
-- Table 4: POLICIES - Policy details
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE POLICIES (
    POLICY_ID VARCHAR(30) PRIMARY KEY,
    POLICY_NUMBER VARCHAR(30) UNIQUE NOT NULL,
    POLICYHOLDER_ID VARCHAR(20) NOT NULL,
    PRODUCT_ID VARCHAR(20) NOT NULL,
    UNDERWRITER_ID VARCHAR(20) NOT NULL,
    POLICY_STATUS VARCHAR(20),  -- Active, Expired, Cancelled
    EFFECTIVE_DATE DATE NOT NULL,
    EXPIRATION_DATE DATE NOT NULL,
    ANNUAL_PREMIUM NUMBER(10,2),  -- Annual premium amount
    COVERAGE_LIMIT NUMBER(12,2),  -- Policy limit
    DEDUCTIBLE NUMBER(8,2),
    STATE VARCHAR(2),
    REGION VARCHAR(30),
    ISSUE_DATE DATE,
    CANCELLATION_DATE DATE,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (POLICYHOLDER_ID) REFERENCES POLICYHOLDERS(POLICYHOLDER_ID),
    FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCTS(PRODUCT_ID),
    FOREIGN KEY (UNDERWRITER_ID) REFERENCES UNDERWRITERS(UNDERWRITER_ID)
);

-- ---------------------------------------------------------------------------
-- Table 5: PREMIUMS - Premium transactions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE PREMIUMS (
    PREMIUM_ID VARCHAR(30) PRIMARY KEY,
    POLICY_ID VARCHAR(30) NOT NULL,
    TRANSACTION_DATE DATE NOT NULL,
    TRANSACTION_TYPE VARCHAR(30),  -- New Business, Renewal, Endorsement, Cancellation
    WRITTEN_PREMIUM NUMBER(10,2),  -- Premium written in this transaction
    EARNED_PREMIUM NUMBER(10,2),  -- Premium earned (recognized) in this period
    UNEARNED_PREMIUM NUMBER(10,2),  -- Premium not yet earned
    COMMISSION_AMOUNT NUMBER(10,2),  -- Commission paid
    COMMISSION_RATE NUMBER(5,2),  -- Commission rate %
    ACCOUNTING_MONTH DATE,  -- Month for accounting purposes (YYYY-MM-01)
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (POLICY_ID) REFERENCES POLICIES(POLICY_ID)
);

-- ---------------------------------------------------------------------------
-- Table 6: CLAIMS - Claims data
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE CLAIMS (
    CLAIM_ID VARCHAR(30) PRIMARY KEY,
    CLAIM_NUMBER VARCHAR(30) UNIQUE NOT NULL,
    POLICY_ID VARCHAR(30) NOT NULL,
    CLAIM_STATUS VARCHAR(20),  -- Open, Closed, Reopened
    CLAIM_TYPE VARCHAR(50),  -- Collision, Theft, Fire, Liability, etc.
    DATE_OF_LOSS DATE NOT NULL,
    DATE_REPORTED DATE NOT NULL,
    DATE_CLOSED DATE,
    CLAIM_AMOUNT NUMBER(12,2),  -- Total incurred amount (paid + reserves)
    PAID_AMOUNT NUMBER(12,2),  -- Amount paid to date
    RESERVE_AMOUNT NUMBER(12,2),  -- Current reserve (case + IBNR)
    SALVAGE_AMOUNT NUMBER(10,2),  -- Salvage/subrogation recovery
    REINSURANCE_RECOVERY NUMBER(10,2),  -- Amount recovered from reinsurance
    SEVERITY_CATEGORY VARCHAR(20),  -- Low, Medium, High, Catastrophic
    AT_FAULT BOOLEAN,  -- Was policyholder at fault?
    ADJUSTER_ID VARCHAR(20),
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (POLICY_ID) REFERENCES POLICIES(POLICY_ID)
);

-- ---------------------------------------------------------------------------
-- Table 7: RESERVES - Loss reserves by claim
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE RESERVES (
    RESERVE_ID VARCHAR(30) PRIMARY KEY,
    CLAIM_ID VARCHAR(30) NOT NULL,
    RESERVE_DATE DATE NOT NULL,
    CASE_RESERVE NUMBER(12,2),  -- Reserve for known claims
    IBNR_RESERVE NUMBER(12,2),  -- Incurred But Not Reported reserve
    TOTAL_RESERVE NUMBER(12,2),  -- Case + IBNR
    RESERVE_TYPE VARCHAR(30),  -- Initial, Subsequent, Final
    ACTUARY_ID VARCHAR(20),
    CONFIDENCE_LEVEL NUMBER(5,2),  -- Confidence level % (e.g., 75, 90)
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (CLAIM_ID) REFERENCES CLAIMS(CLAIM_ID)
);

-- ============================================================================
-- 3. Investment Tables
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Table 8: INVESTMENTS - Portfolio holdings
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE INVESTMENTS (
    INVESTMENT_ID VARCHAR(30) PRIMARY KEY,
    SECURITY_ID VARCHAR(30) NOT NULL,
    SECURITY_NAME VARCHAR(200),
    ASSET_CLASS VARCHAR(50),  -- Corporate Bonds, Municipal Bonds, Equities, etc.
    SECURITY_TYPE VARCHAR(50),  -- Bond, Stock, REIT, MBS, etc.
    SECTOR VARCHAR(50),  -- Financials, Technology, Utilities, etc.
    RATING VARCHAR(10),  -- S&P rating (AAA, AA+, etc.) for bonds
    QUANTITY NUMBER(18,4),
    PURCHASE_DATE DATE,
    PURCHASE_PRICE NUMBER(18,4),
    COST_BASIS NUMBER(18,2),  -- Total cost basis
    CURRENT_PRICE NUMBER(18,4),
    MARKET_VALUE NUMBER(18,2),  -- Current market value
    UNREALIZED_GAIN_LOSS NUMBER(18,2),  -- Market value - Cost basis
    COUPON_RATE NUMBER(8,4),  -- For bonds (e.g., 4.2500 = 4.25%)
    YIELD_TO_MATURITY NUMBER(8,4),  -- Current yield %
    DURATION NUMBER(8,4),  -- Macaulay duration in years
    MATURITY_DATE DATE,  -- For bonds
    CURRENCY VARCHAR(3) DEFAULT 'USD',
    PORTFOLIO_NAME VARCHAR(50),  -- General, Liability-Matched, etc.
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- ---------------------------------------------------------------------------
-- Table 9: INVESTMENT_TRANSACTIONS - Buy/sell/income transactions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE INVESTMENT_TRANSACTIONS (
    TRANSACTION_ID VARCHAR(30) PRIMARY KEY,
    INVESTMENT_ID VARCHAR(30) NOT NULL,
    TRANSACTION_DATE DATE NOT NULL,
    TRANSACTION_TYPE VARCHAR(30),  -- Purchase, Sale, Interest, Dividend, Maturity
    QUANTITY NUMBER(18,4),  -- For purchases/sales
    PRICE NUMBER(18,4),  -- Transaction price per unit
    AMOUNT NUMBER(18,2),  -- Total transaction amount
    REALIZED_GAIN_LOSS NUMBER(18,2),  -- For sales
    INCOME_TYPE VARCHAR(30),  -- Interest, Dividend, Capital Gain
    ACCOUNTING_MONTH DATE,  -- Month for accounting (YYYY-MM-01)
    BROKER VARCHAR(100),
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (INVESTMENT_ID) REFERENCES INVESTMENTS(INVESTMENT_ID)
);

-- ---------------------------------------------------------------------------
-- Table 10: REINSURANCE - Reinsurance treaties and recoveries
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TABLE REINSURANCE (
    TREATY_ID VARCHAR(30) PRIMARY KEY,
    TREATY_NAME VARCHAR(100),
    TREATY_TYPE VARCHAR(30),  -- Quota Share, Excess of Loss, Catastrophe
    REINSURER_NAME VARCHAR(100),
    REINSURER_RATING VARCHAR(10),  -- AM Best rating
    PRODUCT_ID VARCHAR(20),  -- Product covered
    EFFECTIVE_DATE DATE,
    EXPIRATION_DATE DATE,
    RETENTION_LIMIT NUMBER(18,2),  -- Amount retained before reinsurance applies
    COVERAGE_LIMIT NUMBER(18,2),  -- Maximum reinsurance coverage
    CEDED_PREMIUM NUMBER(18,2),  -- Premium paid to reinsurer
    CEDING_COMMISSION NUMBER(18,2),  -- Commission received from reinsurer
    RECOVERIES_TO_DATE NUMBER(18,2),  -- Total recoveries received
    IS_ACTIVE BOOLEAN DEFAULT TRUE,
    CREATED_DATE TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCTS(PRODUCT_ID)
);

-- ============================================================================
-- 4. Verification
-- ============================================================================

-- Show all created tables
SHOW TABLES;

-- Verify table structures
SELECT 
    'Tables created successfully. Ready for data loading.' as STATUS,
    COUNT(*) as TABLE_COUNT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'UNDERWRITING_INV'
    AND TABLE_TYPE = 'BASE TABLE';

SELECT '✓ Environment setup complete!' as MESSAGE;

-- ============================================================================
-- NEXT STEP: Run 02_load_sample_data.sql to populate tables with realistic data
-- ============================================================================

