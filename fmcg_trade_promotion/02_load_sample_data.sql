/*============================================================================
   FMCG Trade Promotion & Demand Intelligence Demo - Sample Data Loading
   
   Purpose: Generates and loads realistic synthetic FMCG data
   Duration: ~5 minutes
   
   This script creates comprehensive sample data for:
   - 500 SKUs across multiple categories
   - 250 Stores across different formats and regions
   - 180 days of sales history
   - 100 Trade Promotions with events
   - Inventory and demand forecast data
============================================================================*/

USE DATABASE FMCG_TRADE_DEMO;
USE SCHEMA ANALYTICS;
USE WAREHOUSE FMCG_WH;

-- ============================================================================
-- 1. Load Products Data (500 SKUs)
-- ============================================================================

INSERT INTO PRODUCTS
WITH 
brands AS (
    SELECT 'BrandA' as brand, 1 as brand_id UNION ALL
    SELECT 'BrandB', 2 UNION ALL
    SELECT 'BrandC', 3 UNION ALL
    SELECT 'BrandD', 4 UNION ALL
    SELECT 'BrandE', 5 UNION ALL
    SELECT 'BrandF', 6 UNION ALL
    SELECT 'BrandG', 7 UNION ALL
    SELECT 'BrandH', 8 UNION ALL
    SELECT 'BrandI', 9 UNION ALL
    SELECT 'BrandJ', 10
),
categories AS (
    SELECT 'Beverages' as category, 'Soft Drinks' as sub_category, '15-25' as price_range UNION ALL
    SELECT 'Beverages', 'Juices', '20-35' UNION ALL
    SELECT 'Beverages', 'Water', '5-15' UNION ALL
    SELECT 'Snacks', 'Chips', '10-20' UNION ALL
    SELECT 'Snacks', 'Cookies', '12-25' UNION ALL
    SELECT 'Dairy', 'Milk', '15-30' UNION ALL
    SELECT 'Dairy', 'Yogurt', '10-20' UNION ALL
    SELECT 'Dairy', 'Cheese', '20-40' UNION ALL
    SELECT 'Personal Care', 'Shampoo', '25-50' UNION ALL
    SELECT 'Personal Care', 'Soap', '10-20' UNION ALL
    SELECT 'Household', 'Detergent', '30-60' UNION ALL
    SELECT 'Household', 'Cleaners', '15-30'
),
numbers AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) as n
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT
    'SKU-' || LPAD(n::VARCHAR, 6, '0') as SKU_ID,
    c.category || ' - ' || b.brand || ' - ' || c.sub_category || ' ' || n as SKU_NAME,
    b.brand as BRAND,
    c.category as CATEGORY,
    c.sub_category as SUB_CATEGORY,
    CASE 
        WHEN UNIFORM(1, 4, RANDOM()) = 1 THEN '250g'
        WHEN UNIFORM(1, 4, RANDOM()) = 2 THEN '500g'
        WHEN UNIFORM(1, 4, RANDOM()) = 3 THEN '1L'
        ELSE '1.5L'
    END as PACK_SIZE,
    ROUND(CAST(SPLIT_PART(c.price_range, '-', 1) AS NUMBER) * 0.6 + (ABS(RANDOM()) % 5), 2) as UNIT_COST,
    ROUND(CAST(SPLIT_PART(c.price_range, '-', 1) AS NUMBER) + 
          (ABS(RANDOM()) % (CAST(SPLIT_PART(c.price_range, '-', 2) AS NUMBER) - CAST(SPLIT_PART(c.price_range, '-', 1) AS NUMBER) + 1)), 2) as REGULAR_PRICE,
    DATEADD(day, -UNIFORM(30, 1800, RANDOM()), CURRENT_DATE()) as PRODUCT_LAUNCH_DATE,
    TRUE as IS_ACTIVE,
    'SUPPLIER-' || LPAD(UNIFORM(1, 50, RANDOM())::VARCHAR, 3, '0') as SUPPLIER_ID
FROM numbers n
CROSS JOIN brands b
CROSS JOIN categories c
WHERE n <= 500
LIMIT 500;

SELECT 'Products loaded: ' || COUNT(*) || ' SKUs' as STATUS FROM PRODUCTS;

-- ============================================================================
-- 2. Load Stores Data (250 Stores)
-- ============================================================================

INSERT INTO STORES
WITH
formats AS (
    SELECT 'Hypermarket' as format, 1 as format_id, 80000 as avg_sqft UNION ALL
    SELECT 'Supermarket', 2, 40000 UNION ALL
    SELECT 'Convenience', 3, 2000 UNION ALL
    SELECT 'Online', 4, 0
),
regions AS (
    SELECT 'North' as region, 'New York' as city, 'NY' as state UNION ALL
    SELECT 'North', 'Boston', 'MA' UNION ALL
    SELECT 'South', 'Miami', 'FL' UNION ALL
    SELECT 'South', 'Atlanta', 'GA' UNION ALL
    SELECT 'East', 'Philadelphia', 'PA' UNION ALL
    SELECT 'East', 'Baltimore', 'MD' UNION ALL
    SELECT 'West', 'Los Angeles', 'CA' UNION ALL
    SELECT 'West', 'Seattle', 'WA' UNION ALL
    SELECT 'Central', 'Chicago', 'IL' UNION ALL
    SELECT 'Central', 'Dallas', 'TX'
),
numbers AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) as n
    FROM TABLE(GENERATOR(ROWCOUNT => 250))
)
SELECT
    'STORE-' || LPAD(n::VARCHAR, 5, '0') as STORE_ID,
    r.city || ' - ' || f.format || ' ' || n as STORE_NAME,
    f.format as STORE_FORMAT,
    r.region as REGION,
    r.city as CITY,
    r.state as STATE,
    CASE 
        WHEN f.format = 'Online' THEN 0
        ELSE f.avg_sqft + UNIFORM(-10000, 10000, RANDOM())
    END as STORE_SIZE_SQFT,
    DATEADD(day, -UNIFORM(365, 3650, RANDOM()), CURRENT_DATE()) as OPEN_DATE,
    TRUE as IS_ACTIVE
FROM numbers n
CROSS JOIN formats f
CROSS JOIN regions r
WHERE n <= 250
LIMIT 250;

SELECT 'Stores loaded: ' || COUNT(*) || ' stores' as STATUS FROM STORES;

-- ============================================================================
-- 3. Load Trade Promotions (100 Promotions)
-- ============================================================================

INSERT INTO TRADE_PROMOTIONS
WITH
promo_types AS (
    SELECT 'Discount' as type, 1 as type_id UNION ALL
    SELECT 'Display', 2 UNION ALL
    SELECT 'Feature', 3 UNION ALL
    SELECT 'Combo', 4 UNION ALL
    SELECT 'BOGO', 5
),
categories AS (
    SELECT 'Beverages' as category UNION ALL
    SELECT 'Snacks' UNION ALL
    SELECT 'Dairy' UNION ALL
    SELECT 'Personal Care' UNION ALL
    SELECT 'Household'
),
numbers AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) as n
    FROM TABLE(GENERATOR(ROWCOUNT => 100))
)
SELECT
    'PROMO-' || LPAD(n::VARCHAR, 5, '0') as PROMOTION_ID,
    pt.type || ' - ' || c.category || ' Promotion ' || n as PROMOTION_NAME,
    pt.type as PROMOTION_TYPE,
    CASE 
        WHEN pt.type = 'Discount' THEN 'Price Reduction'
        WHEN pt.type = 'Display' THEN 'End Cap Display'
        WHEN pt.type = 'Feature' THEN 'Weekly Flyer Feature'
        WHEN pt.type = 'Combo' THEN 'Multi-Buy Discount'
        ELSE 'Buy One Get One'
    END as PROMOTION_MECHANIC,
    CASE 
        WHEN pt.type = 'Discount' THEN UNIFORM(10, 30, RANDOM())
        WHEN pt.type = 'BOGO' THEN 50
        ELSE UNIFORM(15, 25, RANDOM())
    END as DISCOUNT_PERCENTAGE,
    DATEADD(day, -UNIFORM(1, 180, RANDOM()), CURRENT_DATE()) as START_DATE,
    DATEADD(day, UNIFORM(7, 30, RANDOM()), DATEADD(day, -UNIFORM(1, 180, RANDOM()), CURRENT_DATE())) as END_DATE,
    ROUND(UNIFORM(5000, 50000, RANDOM()), 2) as BUDGET,
    c.category as TARGET_CATEGORY
FROM numbers n
CROSS JOIN promo_types pt
CROSS JOIN categories c
WHERE n <= 100
LIMIT 100;

SELECT 'Promotions loaded: ' || COUNT(*) || ' promotions' as STATUS FROM TRADE_PROMOTIONS;

-- ============================================================================
-- 4. Load Promotion Events (5000+ Events)
-- ============================================================================

INSERT INTO PROMOTION_EVENTS
WITH
promotions_sample AS (
    SELECT PROMOTION_ID, START_DATE, END_DATE, DISCOUNT_PERCENTAGE, TARGET_CATEGORY, BUDGET,
           ROW_NUMBER() OVER (ORDER BY PROMOTION_ID) as promo_row
    FROM TRADE_PROMOTIONS
),
promo_count AS (
    SELECT COUNT(*) as total FROM promotions_sample
),
stores_sample AS (
    SELECT STORE_ID, ROW_NUMBER() OVER (ORDER BY STORE_ID) as store_row
    FROM STORES
    WHERE STORE_FORMAT != 'Online'  -- Online stores don't have physical promotion displays
    LIMIT 200
),
store_count AS (
    SELECT COUNT(*) as total FROM stores_sample
),
products_sample AS (
    SELECT SKU_ID, CATEGORY, REGULAR_PRICE,
           ROW_NUMBER() OVER (PARTITION BY CATEGORY ORDER BY SKU_ID) as prod_row
    FROM PRODUCTS
    WHERE IS_ACTIVE = TRUE
),
event_numbers AS (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) as event_num
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))
)
SELECT
    'EVENT-' || LPAD(e.event_num::VARCHAR, 7, '0') as EVENT_ID,
    p.PROMOTION_ID,
    s.STORE_ID,
    pr.SKU_ID,
    p.START_DATE as START_DATE,
    p.END_DATE as END_DATE,
    p.DISCOUNT_PERCENTAGE + ((ABS(RANDOM()) % 5) - 2) as ACTUAL_DISCOUNT_PERCENTAGE,
    ROUND((pr.REGULAR_PRICE * p.DISCOUNT_PERCENTAGE / 100) * (50 + (ABS(RANDOM()) % 151)), 2) as PROMOTION_COST,
    70 + (ABS(RANDOM()) % 31) as COMPLIANCE_SCORE
FROM event_numbers e
CROSS JOIN promo_count pc
CROSS JOIN store_count sc
LEFT JOIN promotions_sample p ON p.promo_row = (MOD(e.event_num, pc.total) + 1)
LEFT JOIN stores_sample s ON s.store_row = (MOD(e.event_num, sc.total) + 1)
LEFT JOIN products_sample pr ON pr.CATEGORY = p.TARGET_CATEGORY 
    AND pr.prod_row = (MOD(e.event_num, 10) + 1)
WHERE e.event_num <= 5000;

SELECT 'Promotion events loaded: ' || COUNT(*) || ' events' as STATUS FROM PROMOTION_EVENTS;

-- ============================================================================
-- 5. Load Daily Sales Data (180 days, ~8M records)
-- ============================================================================

INSERT INTO DAILY_SALES
WITH
date_series AS (
    SELECT DATEADD(day, -SEQ4(), CURRENT_DATE()) as sale_date
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
    WHERE SEQ4() < 180
),
stores_list AS (
    SELECT STORE_ID, STORE_FORMAT,
           ROW_NUMBER() OVER (ORDER BY STORE_ID) as store_num
    FROM STORES
),
products_list AS (
    SELECT SKU_ID, CATEGORY, REGULAR_PRICE, UNIT_COST,
           ROW_NUMBER() OVER (ORDER BY SKU_ID) as prod_num
    FROM PRODUCTS
    WHERE IS_ACTIVE = TRUE
),
promotion_lookup AS (
    SELECT 
        pe.STORE_ID,
        pe.SKU_ID,
        pe.PROMOTION_ID,
        pe.START_DATE,
        pe.END_DATE,
        pe.ACTUAL_DISCOUNT_PERCENTAGE
    FROM PROMOTION_EVENTS pe
),
store_product_pairs AS (
    SELECT 
        s.STORE_ID,
        s.STORE_FORMAT,
        s.store_num,
        p.SKU_ID,
        p.CATEGORY,
        p.REGULAR_PRICE,
        p.UNIT_COST,
        p.prod_num
    FROM stores_list s
    CROSS JOIN products_list p
    WHERE 
        (s.STORE_FORMAT = 'Hypermarket' AND p.prod_num <= 300) OR
        (s.STORE_FORMAT = 'Supermarket' AND p.prod_num <= 200) OR
        (s.STORE_FORMAT = 'Convenience' AND p.prod_num <= 100) OR
        (s.STORE_FORMAT = 'Online' AND p.prod_num <= 400)
)
SELECT
    'SALE-' || d.sale_date || '-' || sp.STORE_ID || '-' || sp.SKU_ID as SALE_ID,
    sp.STORE_ID,
    sp.SKU_ID,
    d.sale_date as SALE_DATE,
    -- Units sold with promotion lift
    CASE 
        WHEN pl.PROMOTION_ID IS NOT NULL THEN
            GREATEST(0, ROUND((5 + (ABS(RANDOM()) % 46)) * (1 + pl.ACTUAL_DISCOUNT_PERCENTAGE / 50), 2))
        ELSE
            GREATEST(0, ROUND(5 + (ABS(RANDOM()) % 26), 2))
    END as UNITS_SOLD,
    -- Revenue calculation
    CASE 
        WHEN pl.PROMOTION_ID IS NOT NULL THEN
            GREATEST(0, ROUND(
                (5 + (ABS(RANDOM()) % 46)) * (1 + pl.ACTUAL_DISCOUNT_PERCENTAGE / 50) * 
                (sp.REGULAR_PRICE * (1 - pl.ACTUAL_DISCOUNT_PERCENTAGE / 100)), 
            2))
        ELSE
            GREATEST(0, ROUND((5 + (ABS(RANDOM()) % 26)) * sp.REGULAR_PRICE, 2))
    END as REVENUE,
    -- Cost calculation
    CASE 
        WHEN pl.PROMOTION_ID IS NOT NULL THEN
            GREATEST(0, ROUND(
                (5 + (ABS(RANDOM()) % 46)) * (1 + pl.ACTUAL_DISCOUNT_PERCENTAGE / 50) * sp.UNIT_COST, 
            2))
        ELSE
            GREATEST(0, ROUND((5 + (ABS(RANDOM()) % 26)) * sp.UNIT_COST, 2))
    END as COST,
    -- Discount amount
    CASE 
        WHEN pl.PROMOTION_ID IS NOT NULL THEN
            GREATEST(0, ROUND(
                (5 + (ABS(RANDOM()) % 46)) * (1 + pl.ACTUAL_DISCOUNT_PERCENTAGE / 50) * 
                sp.REGULAR_PRICE * pl.ACTUAL_DISCOUNT_PERCENTAGE / 100, 
            2))
        ELSE 0
    END as DISCOUNT_AMOUNT,
    CASE WHEN pl.PROMOTION_ID IS NOT NULL THEN TRUE ELSE FALSE END as IS_PROMOTED,
    pl.PROMOTION_ID
FROM date_series d
CROSS JOIN store_product_pairs sp
LEFT JOIN promotion_lookup pl
    ON pl.STORE_ID = sp.STORE_ID
    AND pl.SKU_ID = sp.SKU_ID
    AND d.sale_date BETWEEN pl.START_DATE AND pl.END_DATE
WHERE (ABS(RANDOM()) % 100) < CASE 
    WHEN pl.PROMOTION_ID IS NOT NULL THEN 95  -- High probability of sales during promotion
    ELSE 70  -- Lower probability for baseline sales
END;

SELECT 'Daily sales loaded: ' || COUNT(*) || ' records' as STATUS FROM DAILY_SALES;

-- ============================================================================
-- 6. Load Inventory Levels Data (180 days)
-- ============================================================================

INSERT INTO INVENTORY_LEVELS
WITH
date_series AS (
    SELECT DATEADD(day, -SEQ4(), CURRENT_DATE()) as inv_date
    FROM TABLE(GENERATOR(ROWCOUNT => 180))
    WHERE SEQ4() < 180
),
store_sku_combos AS (
    SELECT 
        s.STORE_ID,
        s.STORE_FORMAT,
        p.SKU_ID
    FROM STORES s
    CROSS JOIN (
        SELECT SKU_ID,
               ROW_NUMBER() OVER (ORDER BY SKU_ID) as prod_num
        FROM PRODUCTS
        WHERE IS_ACTIVE = TRUE
    ) p
    WHERE 
        (s.STORE_FORMAT = 'Hypermarket' AND p.prod_num <= 250) OR
        (s.STORE_FORMAT = 'Supermarket' AND p.prod_num <= 150) OR
        (s.STORE_FORMAT = 'Convenience' AND p.prod_num <= 80) OR
        (s.STORE_FORMAT = 'Online' AND p.prod_num <= 400)
),
sales_agg AS (
    SELECT 
        STORE_ID,
        SKU_ID,
        SALE_DATE,
        SUM(UNITS_SOLD) as daily_sales
    FROM DAILY_SALES
    GROUP BY STORE_ID, SKU_ID, SALE_DATE
),
inventory_calc AS (
    SELECT
        d.inv_date,
        sc.STORE_ID,
        sc.SKU_ID,
        GREATEST(0, ROUND(20 + (ABS(RANDOM()) % 181), 2)) as beg_inv,
        GREATEST(0, ROUND(ABS(RANDOM()) % 101, 2)) as receipts,
        COALESCE(sa.daily_sales, 0) as sales,
        (ABS(RANDOM()) % 100) as random_filter
    FROM date_series d
    CROSS JOIN store_sku_combos sc
    LEFT JOIN sales_agg sa
        ON sa.STORE_ID = sc.STORE_ID
        AND sa.SKU_ID = sc.SKU_ID
        AND sa.SALE_DATE = d.inv_date
)
SELECT
    'INV-' || inv_date || '-' || STORE_ID || '-' || SKU_ID as INVENTORY_ID,
    STORE_ID,
    SKU_ID,
    inv_date as INVENTORY_DATE,
    beg_inv as BEGINNING_INVENTORY,
    receipts as RECEIPTS,
    sales as SALES,
    GREATEST(0, ROUND(beg_inv + receipts - sales, 2)) as ENDING_INVENTORY,
    CASE 
        WHEN (beg_inv + receipts - sales) <= 0 THEN TRUE
        ELSE FALSE
    END as OUT_OF_STOCK_FLAG,
    CASE 
        WHEN (beg_inv + receipts - sales) <= 0 THEN (ABS(RANDOM()) % 4)
        ELSE 0
    END as DAYS_OUT_OF_STOCK
FROM inventory_calc
WHERE random_filter < 30;  -- Sample 30% of possible combinations

SELECT 'Inventory levels loaded: ' || COUNT(*) || ' records' as STATUS FROM INVENTORY_LEVELS;

-- ============================================================================
-- 7. Load Demand Forecast Data (30 days forward)
-- ============================================================================

INSERT INTO DEMAND_FORECAST
WITH
future_dates AS (
    SELECT DATEADD(day, SEQ4(), CURRENT_DATE()) as forecast_date
    FROM TABLE(GENERATOR(ROWCOUNT => 30))
    WHERE SEQ4() < 30
),
store_sku_sample AS (
    SELECT 
        s.STORE_ID,
        p.SKU_ID
    FROM STORES s
    CROSS JOIN (
        SELECT SKU_ID,
               ROW_NUMBER() OVER (ORDER BY SKU_ID) as prod_num
        FROM PRODUCTS
        WHERE IS_ACTIVE = TRUE
    ) p
    WHERE s.STORE_FORMAT != 'Online'
        AND p.prod_num <= 100
    LIMIT 5000
),
historical_avg AS (
    SELECT 
        STORE_ID,
        SKU_ID,
        AVG(UNITS_SOLD) as avg_units
    FROM DAILY_SALES
    WHERE SALE_DATE >= DATEADD(day, -90, CURRENT_DATE())
        AND IS_PROMOTED = FALSE
    GROUP BY STORE_ID, SKU_ID
)
SELECT
    'FCST-' || fd.forecast_date || '-' || sss.STORE_ID || '-' || sss.SKU_ID as FORECAST_ID,
    sss.STORE_ID,
    sss.SKU_ID,
    fd.forecast_date as FORECAST_DATE,
    CURRENT_DATE() as FORECAST_CREATED_DATE,
    GREATEST(0, ROUND(COALESCE(ha.avg_units, 15) * (0.8 + (ABS(RANDOM()) % 41) / 100.0), 2)) as FORECASTED_UNITS,
    GREATEST(0, ROUND(COALESCE(ha.avg_units, 15) * (0.6 + (ABS(RANDOM()) % 31) / 100.0), 2)) as FORECAST_LOWER_BOUND,
    GREATEST(0, ROUND(COALESCE(ha.avg_units, 15) * (1.1 + (ABS(RANDOM()) % 31) / 100.0), 2)) as FORECAST_UPPER_BOUND,
    75 + (ABS(RANDOM()) % 21) as CONFIDENCE_LEVEL,
    NULL as ACTUAL_UNITS  -- Will be filled as actual sales occur
FROM future_dates fd
CROSS JOIN store_sku_sample sss
LEFT JOIN historical_avg ha
    ON ha.STORE_ID = sss.STORE_ID
    AND ha.SKU_ID = sss.SKU_ID;

SELECT 'Demand forecasts loaded: ' || COUNT(*) || ' forecasts' as STATUS FROM DEMAND_FORECAST;

-- ============================================================================
-- 8. Load Supply Chain Lead Times
-- ============================================================================

INSERT INTO SUPPLY_CHAIN_LEAD_TIMES
WITH
supplier_product_pairs AS (
    SELECT 
        p.SUPPLIER_ID,
        p.SKU_ID,
        ROW_NUMBER() OVER (PARTITION BY p.SUPPLIER_ID ORDER BY p.SKU_ID) as prod_row
    FROM PRODUCTS p
    WHERE p.IS_ACTIVE = TRUE
),
supplier_top_products AS (
    SELECT 
        SUPPLIER_ID,
        SKU_ID
    FROM supplier_product_pairs
    WHERE prod_row <= 5
),
regions AS (
    SELECT DISTINCT REGION
    FROM STORES
)
SELECT
    'LEAD-' || stp.SUPPLIER_ID || '-' || r.REGION || '-' || stp.SKU_ID as LEAD_TIME_ID,
    stp.SUPPLIER_ID,
    stp.SKU_ID,
    r.REGION,
    ROUND((3 + (ABS(RANDOM()) % 19)) + (ABS(RANDOM()) % 11) / 10.0, 1) as AVERAGE_LEAD_TIME_DAYS,
    50 + (ABS(RANDOM()) % 451) as MIN_ORDER_QUANTITY,
    CURRENT_DATE() as LAST_UPDATED_DATE
FROM supplier_top_products stp
CROSS JOIN regions r;

SELECT 'Supply chain lead times loaded: ' || COUNT(*) || ' records' as STATUS FROM SUPPLY_CHAIN_LEAD_TIMES;

-- ============================================================================
-- 9. Data Loading Summary
-- ============================================================================

SELECT 'Data loading complete!' as MESSAGE;

SELECT 
    'PRODUCTS' as TABLE_NAME, 
    COUNT(*) as RECORD_COUNT,
    '500 SKUs across multiple categories' as DESCRIPTION
FROM PRODUCTS
UNION ALL
SELECT 
    'STORES', 
    COUNT(*),
    '250 stores across different formats and regions'
FROM STORES
UNION ALL
SELECT 
    'TRADE_PROMOTIONS', 
    COUNT(*),
    '100 trade promotions with various mechanics'
FROM TRADE_PROMOTIONS
UNION ALL
SELECT 
    'PROMOTION_EVENTS', 
    COUNT(*),
    'Promotion executions at store level'
FROM PROMOTION_EVENTS
UNION ALL
SELECT 
    'DAILY_SALES', 
    COUNT(*),
    '180 days of daily sales data'
FROM DAILY_SALES
UNION ALL
SELECT 
    'INVENTORY_LEVELS', 
    COUNT(*),
    'Daily inventory tracking with out-of-stock flags'
FROM INVENTORY_LEVELS
UNION ALL
SELECT 
    'DEMAND_FORECAST', 
    COUNT(*),
    '30 days forward-looking demand forecasts'
FROM DEMAND_FORECAST
UNION ALL
SELECT 
    'SUPPLY_CHAIN_LEAD_TIMES', 
    COUNT(*),
    'Supplier lead times by region and SKU'
FROM SUPPLY_CHAIN_LEAD_TIMES;

/*============================================================================
   Next Step: Execute 03_setup_intelligence.sql
============================================================================*/

