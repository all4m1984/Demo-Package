/*============================================================================
   FMCG Trade Promotion & Demand Intelligence Demo - Environment Setup
   
   Purpose: Creates database, schema, tables, and warehouse for FMCG demo
   Duration: ~2 minutes
   
   This script sets up the foundation for demonstrating Snowflake Intelligence
   capabilities in FMCG trade promotion optimization, demand forecasting,
   and on-shelf availability analysis.
============================================================================*/

-- ============================================================================
-- 1. Create Database and Schema
-- ============================================================================

CREATE OR REPLACE DATABASE FMCG_TRADE_DEMO;
USE DATABASE FMCG_TRADE_DEMO;

CREATE OR REPLACE SCHEMA ANALYTICS;
USE SCHEMA ANALYTICS;

SELECT 'Database and schema created successfully' as STATUS;

-- ============================================================================
-- 2. Create Warehouse
-- ============================================================================

CREATE OR REPLACE WAREHOUSE FMCG_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = FALSE
    COMMENT = 'Warehouse for FMCG Trade Promotion and Demand Intelligence Demo';

USE WAREHOUSE FMCG_WH;

SELECT 'Warehouse created successfully' as STATUS;

-- ============================================================================
-- 3. Create Core Tables
-- ============================================================================

-- Products Master Table
CREATE OR REPLACE TABLE PRODUCTS (
    SKU_ID VARCHAR(50) PRIMARY KEY,
    SKU_NAME VARCHAR(200),
    BRAND VARCHAR(100),
    CATEGORY VARCHAR(100),
    SUB_CATEGORY VARCHAR(100),
    PACK_SIZE VARCHAR(50),
    UNIT_COST NUMBER(10,2),
    REGULAR_PRICE NUMBER(10,2),
    PRODUCT_LAUNCH_DATE DATE,
    IS_ACTIVE BOOLEAN,
    SUPPLIER_ID VARCHAR(50)
);

-- Stores Master Table
CREATE OR REPLACE TABLE STORES (
    STORE_ID VARCHAR(50) PRIMARY KEY,
    STORE_NAME VARCHAR(200),
    STORE_FORMAT VARCHAR(50), -- Hypermarket, Supermarket, Convenience, Online
    REGION VARCHAR(50),
    CITY VARCHAR(100),
    STATE VARCHAR(50),
    STORE_SIZE_SQFT NUMBER(10,0),
    OPEN_DATE DATE,
    IS_ACTIVE BOOLEAN
);

-- Daily Sales Table
CREATE OR REPLACE TABLE DAILY_SALES (
    SALE_ID VARCHAR(50) PRIMARY KEY,
    STORE_ID VARCHAR(50),
    SKU_ID VARCHAR(50),
    SALE_DATE DATE,
    UNITS_SOLD NUMBER(10,2),
    REVENUE NUMBER(12,2),
    COST NUMBER(12,2),
    DISCOUNT_AMOUNT NUMBER(10,2),
    IS_PROMOTED BOOLEAN,
    PROMOTION_ID VARCHAR(50),
    FOREIGN KEY (STORE_ID) REFERENCES STORES(STORE_ID),
    FOREIGN KEY (SKU_ID) REFERENCES PRODUCTS(SKU_ID)
);

-- Trade Promotions Master Table
CREATE OR REPLACE TABLE TRADE_PROMOTIONS (
    PROMOTION_ID VARCHAR(50) PRIMARY KEY,
    PROMOTION_NAME VARCHAR(200),
    PROMOTION_TYPE VARCHAR(50), -- Discount, Display, Feature, Combo, BOGO
    PROMOTION_MECHANIC VARCHAR(100),
    DISCOUNT_PERCENTAGE NUMBER(5,2),
    START_DATE DATE,
    END_DATE DATE,
    BUDGET NUMBER(12,2),
    TARGET_CATEGORY VARCHAR(100)
);

-- Promotion Events (Execution at store level)
CREATE OR REPLACE TABLE PROMOTION_EVENTS (
    EVENT_ID VARCHAR(50) PRIMARY KEY,
    PROMOTION_ID VARCHAR(50),
    STORE_ID VARCHAR(50),
    SKU_ID VARCHAR(50),
    START_DATE DATE,
    END_DATE DATE,
    ACTUAL_DISCOUNT_PERCENTAGE NUMBER(5,2),
    PROMOTION_COST NUMBER(10,2),
    COMPLIANCE_SCORE NUMBER(3,0), -- 0-100
    FOREIGN KEY (PROMOTION_ID) REFERENCES TRADE_PROMOTIONS(PROMOTION_ID),
    FOREIGN KEY (STORE_ID) REFERENCES STORES(STORE_ID),
    FOREIGN KEY (SKU_ID) REFERENCES PRODUCTS(SKU_ID)
);

-- Inventory Levels Table
CREATE OR REPLACE TABLE INVENTORY_LEVELS (
    INVENTORY_ID VARCHAR(50) PRIMARY KEY,
    STORE_ID VARCHAR(50),
    SKU_ID VARCHAR(50),
    INVENTORY_DATE DATE,
    BEGINNING_INVENTORY NUMBER(10,2),
    RECEIPTS NUMBER(10,2),
    SALES NUMBER(10,2),
    ENDING_INVENTORY NUMBER(10,2),
    OUT_OF_STOCK_FLAG BOOLEAN,
    DAYS_OUT_OF_STOCK NUMBER(3,0),
    FOREIGN KEY (STORE_ID) REFERENCES STORES(STORE_ID),
    FOREIGN KEY (SKU_ID) REFERENCES PRODUCTS(SKU_ID)
);

-- Demand Forecast Table
CREATE OR REPLACE TABLE DEMAND_FORECAST (
    FORECAST_ID VARCHAR(50) PRIMARY KEY,
    STORE_ID VARCHAR(50),
    SKU_ID VARCHAR(50),
    FORECAST_DATE DATE,
    FORECAST_CREATED_DATE DATE,
    FORECASTED_UNITS NUMBER(10,2),
    FORECAST_LOWER_BOUND NUMBER(10,2),
    FORECAST_UPPER_BOUND NUMBER(10,2),
    CONFIDENCE_LEVEL NUMBER(3,0), -- 0-100
    ACTUAL_UNITS NUMBER(10,2),
    FOREIGN KEY (STORE_ID) REFERENCES STORES(STORE_ID),
    FOREIGN KEY (SKU_ID) REFERENCES PRODUCTS(SKU_ID)
);

-- Supply Chain Lead Times Table
CREATE OR REPLACE TABLE SUPPLY_CHAIN_LEAD_TIMES (
    LEAD_TIME_ID VARCHAR(50) PRIMARY KEY,
    SUPPLIER_ID VARCHAR(50),
    SKU_ID VARCHAR(50),
    REGION VARCHAR(50),
    AVERAGE_LEAD_TIME_DAYS NUMBER(5,1),
    MIN_ORDER_QUANTITY NUMBER(10,0),
    LAST_UPDATED_DATE DATE,
    FOREIGN KEY (SKU_ID) REFERENCES PRODUCTS(SKU_ID)
);

SELECT 'Core tables created successfully' as STATUS;

-- ============================================================================
-- 4. Create Indexes for Performance
-- ============================================================================

-- Indexes on DAILY_SALES for common queries
ALTER TABLE DAILY_SALES ADD SEARCH OPTIMIZATION;

-- Indexes on INVENTORY_LEVELS
ALTER TABLE INVENTORY_LEVELS ADD SEARCH OPTIMIZATION;

-- Indexes on DEMAND_FORECAST
ALTER TABLE DEMAND_FORECAST ADD SEARCH OPTIMIZATION;

SELECT 'Indexes created successfully' as STATUS;

-- ============================================================================
-- 5. Summary
-- ============================================================================

SELECT 
    'Environment setup complete!' as MESSAGE,
    'Database: FMCG_TRADE_DEMO' as DATABASE_NAME,
    'Schema: ANALYTICS' as SCHEMA_NAME,
    'Warehouse: FMCG_WH' as WAREHOUSE_NAME,
    'Tables: 8 core tables created' as TABLES_STATUS;

SELECT 
    TABLE_NAME,
    ROW_COUNT,
    BYTES / 1024 / 1024 as SIZE_MB
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'ANALYTICS'
    AND TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

/*============================================================================
   Next Step: Execute 02_load_sample_data.sql
============================================================================*/

