/*============================================================================
   FMCG Trade Promotion & Demand Intelligence Demo - Intelligence Setup
   
   Purpose: Creates analytical views and prepares Cortex Analyst setup
   Duration: ~1 minute
   
   This script creates pre-aggregated views optimized for:
   - Trade promotion performance analysis
   - Demand forecast accuracy metrics
   - On-shelf availability tracking
============================================================================*/

USE DATABASE FMCG_TRADE_DEMO;
USE SCHEMA ANALYTICS;
USE WAREHOUSE FMCG_WH;

-- ============================================================================
-- 1. Create Promotion Performance View
-- ============================================================================

CREATE OR REPLACE VIEW VW_PROMOTION_PERFORMANCE AS
WITH
baseline_sales AS (
    SELECT 
        ds.SKU_ID,
        ds.STORE_ID,
        AVG(ds.UNITS_SOLD) as avg_baseline_units,
        AVG(ds.REVENUE) as avg_baseline_revenue
    FROM DAILY_SALES ds
    WHERE ds.IS_PROMOTED = FALSE
        AND ds.SALE_DATE >= DATEADD(day, -180, CURRENT_DATE())
    GROUP BY ds.SKU_ID, ds.STORE_ID
),
promoted_sales AS (
    SELECT 
        ds.PROMOTION_ID,
        ds.SKU_ID,
        ds.STORE_ID,
        SUM(ds.UNITS_SOLD) as total_promoted_units,
        SUM(ds.REVENUE) as total_promoted_revenue,
        SUM(ds.COST) as total_cost,
        SUM(ds.DISCOUNT_AMOUNT) as total_discount,
        COUNT(DISTINCT ds.SALE_DATE) as promotion_days
    FROM DAILY_SALES ds
    WHERE ds.IS_PROMOTED = TRUE
    GROUP BY ds.PROMOTION_ID, ds.SKU_ID, ds.STORE_ID
)
SELECT
    tp.PROMOTION_ID,
    tp.PROMOTION_NAME,
    tp.PROMOTION_TYPE,
    tp.PROMOTION_MECHANIC,
    tp.START_DATE,
    tp.END_DATE,
    tp.BUDGET,
    tp.TARGET_CATEGORY,
    p.SKU_ID,
    p.BRAND,
    p.CATEGORY,
    p.SUB_CATEGORY,
    s.STORE_ID,
    s.STORE_NAME,
    s.STORE_FORMAT,
    s.REGION,
    pe.PROMOTION_COST,
    pe.COMPLIANCE_SCORE,
    ps.promotion_days,
    ps.total_promoted_units,
    ps.total_promoted_revenue,
    ps.total_cost,
    ps.total_discount,
    COALESCE(bs.avg_baseline_units * ps.promotion_days, 0) as expected_baseline_units,
    COALESCE(bs.avg_baseline_revenue * ps.promotion_days, 0) as expected_baseline_revenue,
    ps.total_promoted_units - COALESCE(bs.avg_baseline_units * ps.promotion_days, 0) as incremental_units,
    ps.total_promoted_revenue - COALESCE(bs.avg_baseline_revenue * ps.promotion_days, 0) as incremental_revenue,
    (ps.total_promoted_revenue - ps.total_cost - ps.total_discount) as gross_profit,
    CASE 
        WHEN pe.PROMOTION_COST > 0 THEN
            ((ps.total_promoted_revenue - ps.total_cost - ps.total_discount - pe.PROMOTION_COST) / pe.PROMOTION_COST) * 100
        ELSE NULL
    END as promotion_roi_pct,
    CASE 
        WHEN COALESCE(bs.avg_baseline_units * ps.promotion_days, 0) > 0 THEN
            ((ps.total_promoted_units - COALESCE(bs.avg_baseline_units * ps.promotion_days, 0)) / 
             (bs.avg_baseline_units * ps.promotion_days)) * 100
        ELSE NULL
    END as promotion_lift_pct
FROM TRADE_PROMOTIONS tp
JOIN PROMOTION_EVENTS pe ON tp.PROMOTION_ID = pe.PROMOTION_ID
JOIN PRODUCTS p ON pe.SKU_ID = p.SKU_ID
JOIN STORES s ON pe.STORE_ID = s.STORE_ID
LEFT JOIN promoted_sales ps 
    ON ps.PROMOTION_ID = tp.PROMOTION_ID
    AND ps.SKU_ID = pe.SKU_ID
    AND ps.STORE_ID = pe.STORE_ID
LEFT JOIN baseline_sales bs 
    ON bs.SKU_ID = pe.SKU_ID
    AND bs.STORE_ID = pe.STORE_ID;

SELECT 'VW_PROMOTION_PERFORMANCE created' as STATUS;

-- ============================================================================
-- 2. Create Forecast Accuracy View
-- ============================================================================

CREATE OR REPLACE VIEW VW_FORECAST_ACCURACY AS
WITH
forecast_actuals AS (
    SELECT 
        df.FORECAST_ID,
        df.STORE_ID,
        df.SKU_ID,
        df.FORECAST_DATE,
        df.FORECAST_CREATED_DATE,
        df.FORECASTED_UNITS,
        df.FORECAST_LOWER_BOUND,
        df.FORECAST_UPPER_BOUND,
        df.CONFIDENCE_LEVEL,
        COALESCE(ds.UNITS_SOLD, df.ACTUAL_UNITS) as actual_units
    FROM DEMAND_FORECAST df
    LEFT JOIN DAILY_SALES ds 
        ON df.STORE_ID = ds.STORE_ID
        AND df.SKU_ID = ds.SKU_ID
        AND df.FORECAST_DATE = ds.SALE_DATE
    WHERE df.FORECAST_DATE <= CURRENT_DATE()
)
SELECT
    fa.FORECAST_ID,
    fa.STORE_ID,
    s.STORE_NAME,
    s.STORE_FORMAT,
    s.REGION,
    fa.SKU_ID,
    p.SKU_NAME,
    p.BRAND,
    p.CATEGORY,
    p.SUB_CATEGORY,
    fa.FORECAST_DATE,
    fa.FORECAST_CREATED_DATE,
    fa.FORECASTED_UNITS,
    fa.FORECAST_LOWER_BOUND,
    fa.FORECAST_UPPER_BOUND,
    fa.CONFIDENCE_LEVEL,
    fa.actual_units as ACTUAL_UNITS,
    fa.actual_units - fa.FORECASTED_UNITS as forecast_error,
    ABS(fa.actual_units - fa.FORECASTED_UNITS) as absolute_error,
    CASE 
        WHEN fa.actual_units > 0 THEN
            (ABS(fa.actual_units - fa.FORECASTED_UNITS) / fa.actual_units) * 100
        ELSE NULL
    END as absolute_percentage_error,
    CASE 
        WHEN fa.actual_units BETWEEN fa.FORECAST_LOWER_BOUND AND fa.FORECAST_UPPER_BOUND THEN TRUE
        ELSE FALSE
    END as within_confidence_interval,
    CASE 
        WHEN fa.actual_units > fa.FORECASTED_UNITS THEN 'Under-Forecast'
        WHEN fa.actual_units < fa.FORECASTED_UNITS THEN 'Over-Forecast'
        ELSE 'Accurate'
    END as forecast_bias
FROM forecast_actuals fa
JOIN PRODUCTS p ON fa.SKU_ID = p.SKU_ID
JOIN STORES s ON fa.STORE_ID = s.STORE_ID
WHERE fa.actual_units IS NOT NULL;

SELECT 'VW_FORECAST_ACCURACY created' as STATUS;

-- ============================================================================
-- 3. Create On-Shelf Availability (OSA) Metrics View
-- ============================================================================

CREATE OR REPLACE VIEW VW_OSA_METRICS AS
WITH
inventory_summary AS (
    SELECT 
        il.STORE_ID,
        il.SKU_ID,
        COUNT(DISTINCT il.INVENTORY_DATE) as total_days,
        SUM(CASE WHEN il.OUT_OF_STOCK_FLAG = TRUE THEN 1 ELSE 0 END) as oos_days,
        SUM(il.DAYS_OUT_OF_STOCK) as total_oos_days,
        AVG(il.ENDING_INVENTORY) as avg_inventory,
        MIN(il.ENDING_INVENTORY) as min_inventory,
        MAX(il.ENDING_INVENTORY) as max_inventory
    FROM INVENTORY_LEVELS il
    WHERE il.INVENTORY_DATE >= DATEADD(day, -90, CURRENT_DATE())
    GROUP BY il.STORE_ID, il.SKU_ID
),
sales_impact AS (
    SELECT 
        ds.STORE_ID,
        ds.SKU_ID,
        AVG(ds.UNITS_SOLD) as avg_daily_sales,
        AVG(ds.REVENUE) as avg_daily_revenue
    FROM DAILY_SALES ds
    WHERE ds.SALE_DATE >= DATEADD(day, -90, CURRENT_DATE())
        AND ds.IS_PROMOTED = FALSE
    GROUP BY ds.STORE_ID, ds.SKU_ID
)
SELECT
    s.STORE_ID,
    s.STORE_NAME,
    s.STORE_FORMAT,
    s.REGION,
    s.CITY,
    p.SKU_ID,
    p.SKU_NAME,
    p.BRAND,
    p.CATEGORY,
    p.SUB_CATEGORY,
    p.REGULAR_PRICE,
    isum.total_days,
    isum.oos_days,
    isum.total_oos_days,
    CASE 
        WHEN isum.total_days > 0 THEN
            ((isum.total_days - isum.oos_days) / isum.total_days) * 100
        ELSE 0
    END as osa_percentage,
    isum.avg_inventory,
    isum.min_inventory,
    isum.max_inventory,
    si.avg_daily_sales,
    si.avg_daily_revenue,
    isum.oos_days * si.avg_daily_sales as estimated_lost_units,
    isum.oos_days * si.avg_daily_revenue as estimated_lost_revenue,
    CASE 
        WHEN isum.avg_inventory > 0 AND si.avg_daily_sales > 0 THEN
            isum.avg_inventory / si.avg_daily_sales
        ELSE NULL
    END as days_of_supply,
    CASE 
        WHEN isum.oos_days > 10 THEN 'Critical'
        WHEN isum.oos_days > 5 THEN 'High'
        WHEN isum.oos_days > 2 THEN 'Medium'
        ELSE 'Low'
    END as oos_risk_level
FROM STORES s
JOIN inventory_summary isum ON s.STORE_ID = isum.STORE_ID
JOIN PRODUCTS p ON isum.SKU_ID = p.SKU_ID
LEFT JOIN sales_impact si 
    ON si.STORE_ID = isum.STORE_ID
    AND si.SKU_ID = isum.SKU_ID;

SELECT 'VW_OSA_METRICS created' as STATUS;

-- ============================================================================
-- 4. Create Product Category Performance View
-- ============================================================================

CREATE OR REPLACE VIEW VW_CATEGORY_PERFORMANCE AS
SELECT
    p.CATEGORY,
    p.SUB_CATEGORY,
    p.BRAND,
    s.REGION,
    s.STORE_FORMAT,
    DATE_TRUNC('MONTH', ds.SALE_DATE) as SALES_MONTH,
    COUNT(DISTINCT p.SKU_ID) as sku_count,
    COUNT(DISTINCT s.STORE_ID) as store_count,
    SUM(ds.UNITS_SOLD) as total_units_sold,
    SUM(ds.REVENUE) as total_revenue,
    SUM(ds.COST) as total_cost,
    SUM(ds.DISCOUNT_AMOUNT) as total_discount,
    SUM(ds.REVENUE - ds.COST) as gross_profit,
    CASE 
        WHEN SUM(ds.REVENUE) > 0 THEN
            (SUM(ds.REVENUE - ds.COST) / SUM(ds.REVENUE)) * 100
        ELSE 0
    END as gross_margin_pct,
    AVG(ds.REVENUE / NULLIF(ds.UNITS_SOLD, 0)) as avg_unit_price,
    SUM(CASE WHEN ds.IS_PROMOTED THEN ds.REVENUE ELSE 0 END) as promoted_revenue,
    SUM(CASE WHEN NOT ds.IS_PROMOTED THEN ds.REVENUE ELSE 0 END) as baseline_revenue,
    CASE 
        WHEN SUM(ds.REVENUE) > 0 THEN
            (SUM(CASE WHEN ds.IS_PROMOTED THEN ds.REVENUE ELSE 0 END) / SUM(ds.REVENUE)) * 100
        ELSE 0
    END as promotional_revenue_pct
FROM DAILY_SALES ds
JOIN PRODUCTS p ON ds.SKU_ID = p.SKU_ID
JOIN STORES s ON ds.STORE_ID = s.STORE_ID
WHERE ds.SALE_DATE >= DATEADD(month, -6, CURRENT_DATE())
GROUP BY 
    p.CATEGORY,
    p.SUB_CATEGORY,
    p.BRAND,
    s.REGION,
    s.STORE_FORMAT,
    DATE_TRUNC('MONTH', ds.SALE_DATE);

SELECT 'VW_CATEGORY_PERFORMANCE created' as STATUS;

-- ============================================================================
-- 5. Create Stage for Semantic Model
-- ============================================================================

CREATE STAGE IF NOT EXISTS CORTEX_STAGE;

SELECT 'Stage CORTEX_STAGE created' as STATUS;

-- ============================================================================
-- 6. Summary
-- ============================================================================

SELECT 
    'Intelligence setup complete!' as MESSAGE,
    'Created 4 analytical views' as VIEWS_STATUS,
    'Created CORTEX_STAGE for semantic model upload' as STAGE_STATUS;

SELECT 
    TABLE_NAME as VIEW_NAME,
    TABLE_TYPE,
    ROW_COUNT as ESTIMATED_ROWS
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'ANALYTICS'
    AND TABLE_TYPE = 'VIEW'
ORDER BY TABLE_NAME;

/*============================================================================
   Next Steps:
   1. Execute 04_upload_semantic_model.sql for upload instructions
   2. Upload semantic_model.yaml to CORTEX_STAGE
   3. Connect Cortex Analyst to the semantic model
   4. Start asking natural language questions!
============================================================================*/

