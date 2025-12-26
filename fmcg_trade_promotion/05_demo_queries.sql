/*============================================================================
   FMCG Trade Promotion & Demand Intelligence Demo - Sample Queries
   
   Purpose: Sample SQL queries to validate data and demonstrate insights
   Duration: Optional - for validation and traditional BI comparison
   
   Note: These queries demonstrate what Cortex Analyst can answer in natural
   language. Use Cortex Analyst for the actual demo!
============================================================================*/

USE DATABASE FMCG_TRADE_DEMO;
USE SCHEMA ANALYTICS;
USE WAREHOUSE FMCG_WH;

-- ============================================================================
-- PART 1: TRADE PROMOTION OPTIMIZATION QUERIES
-- ============================================================================

-- Query 1: Top 10 Promotions by ROI
SELECT 
    PROMOTION_NAME,
    PROMOTION_TYPE,
    CATEGORY,
    BRAND,
    COUNT(DISTINCT STORE_ID) as store_count,
    SUM(TOTAL_PROMOTED_REVENUE) as total_revenue,
    SUM(INCREMENTAL_REVENUE) as incremental_revenue,
    AVG(PROMOTION_ROI_PCT) as avg_roi_pct,
    AVG(PROMOTION_LIFT_PCT) as avg_lift_pct
FROM VW_PROMOTION_PERFORMANCE
WHERE PROMOTION_ROI_PCT IS NOT NULL
GROUP BY PROMOTION_NAME, PROMOTION_TYPE, CATEGORY, BRAND
ORDER BY avg_roi_pct DESC
LIMIT 10;

-- Query 2: Promotion Effectiveness by Type
SELECT 
    PROMOTION_TYPE,
    COUNT(DISTINCT PROMOTION_NAME) as promo_count,
    COUNT(DISTINCT SKU_ID) as sku_count,
    SUM(TOTAL_PROMOTED_REVENUE) as total_revenue,
    SUM(INCREMENTAL_REVENUE) as incremental_revenue,
    AVG(PROMOTION_ROI_PCT) as avg_roi_pct,
    AVG(PROMOTION_LIFT_PCT) as avg_lift_pct,
    SUM(GROSS_PROFIT) as total_profit
FROM VW_PROMOTION_PERFORMANCE
GROUP BY PROMOTION_TYPE
ORDER BY avg_roi_pct DESC;

-- Query 3: Category Responsiveness to Promotions
SELECT 
    CATEGORY,
    COUNT(DISTINCT PROMOTION_ID) as promo_count,
    AVG(PROMOTION_LIFT_PCT) as avg_lift_pct,
    SUM(INCREMENTAL_REVENUE) / NULLIF(SUM(PROMOTION_COST), 0) as efficiency_ratio,
    SUM(TOTAL_PROMOTED_REVENUE) as total_revenue
FROM VW_PROMOTION_PERFORMANCE
GROUP BY CATEGORY
ORDER BY avg_lift_pct DESC;

-- Query 4: Regional Promotion Performance
SELECT 
    REGION,
    PROMOTION_TYPE,
    COUNT(DISTINCT PROMOTION_ID) as promo_count,
    AVG(PROMOTION_ROI_PCT) as avg_roi_pct,
    SUM(INCREMENTAL_REVENUE) as incremental_revenue,
    AVG(COMPLIANCE_SCORE) as avg_compliance
FROM VW_PROMOTION_PERFORMANCE
GROUP BY REGION, PROMOTION_TYPE
ORDER BY REGION, avg_roi_pct DESC;

-- Query 5: Promoted vs Baseline Sales Comparison
SELECT 
    p.CATEGORY,
    p.SUB_CATEGORY,
    SUM(CASE WHEN ds.IS_PROMOTED THEN ds.REVENUE ELSE 0 END) as promoted_revenue,
    SUM(CASE WHEN NOT ds.IS_PROMOTED THEN ds.REVENUE ELSE 0 END) as baseline_revenue,
    SUM(ds.REVENUE) as total_revenue,
    (SUM(CASE WHEN ds.IS_PROMOTED THEN ds.REVENUE ELSE 0 END) / 
     NULLIF(SUM(ds.REVENUE), 0)) * 100 as promotional_mix_pct
FROM DAILY_SALES ds
JOIN PRODUCTS p ON ds.SKU_ID = p.SKU_ID
WHERE ds.SALE_DATE >= DATEADD(month, -3, CURRENT_DATE())
GROUP BY p.CATEGORY, p.SUB_CATEGORY
ORDER BY promotional_mix_pct DESC;

-- ============================================================================
-- PART 2: DEMAND FORECASTING QUERIES
-- ============================================================================

-- Query 6: Forecast Accuracy by Category
SELECT 
    CATEGORY,
    COUNT(*) as forecast_count,
    AVG(ABSOLUTE_PERCENTAGE_ERROR) as avg_mape,
    SUM(FORECASTED_UNITS) as total_forecasted,
    SUM(ACTUAL_UNITS) as total_actual,
    SUM(FORECAST_ERROR) as total_error,
    SUM(CASE WHEN FORECAST_BIAS = 'Under-Forecast' THEN 1 ELSE 0 END) as under_forecast_count,
    SUM(CASE WHEN FORECAST_BIAS = 'Over-Forecast' THEN 1 ELSE 0 END) as over_forecast_count
FROM VW_FORECAST_ACCURACY
WHERE ACTUAL_UNITS IS NOT NULL
GROUP BY CATEGORY
ORDER BY avg_mape;

-- Query 7: Top Products with Highest Forecast Error
SELECT 
    SKU_NAME,
    BRAND,
    CATEGORY,
    REGION,
    COUNT(*) as forecast_count,
    AVG(ABSOLUTE_PERCENTAGE_ERROR) as avg_mape,
    SUM(ABS(FORECAST_ERROR)) as total_abs_error,
    FORECAST_BIAS
FROM VW_FORECAST_ACCURACY
WHERE ACTUAL_UNITS IS NOT NULL
GROUP BY SKU_NAME, BRAND, CATEGORY, REGION, FORECAST_BIAS
ORDER BY avg_mape DESC
LIMIT 20;

-- Query 8: Forecast Accuracy Trend Over Time
SELECT 
    DATE_TRUNC('WEEK', FORECAST_DATE) as forecast_week,
    COUNT(*) as forecast_count,
    AVG(ABSOLUTE_PERCENTAGE_ERROR) as avg_mape,
    AVG(CONFIDENCE_LEVEL) as avg_confidence,
    SUM(CASE WHEN WITHIN_CONFIDENCE_INTERVAL THEN 1 ELSE 0 END) / 
        NULLIF(COUNT(*), 0) * 100 as confidence_hit_rate_pct
FROM VW_FORECAST_ACCURACY
WHERE ACTUAL_UNITS IS NOT NULL
    AND FORECAST_DATE >= DATEADD(month, -1, CURRENT_DATE())
GROUP BY DATE_TRUNC('WEEK', FORECAST_DATE)
ORDER BY forecast_week;

-- Query 9: Upcoming Week Demand Forecast
SELECT 
    p.CATEGORY,
    p.BRAND,
    df.FORECAST_DATE,
    SUM(df.FORECASTED_UNITS) as total_forecasted_units,
    AVG(df.CONFIDENCE_LEVEL) as avg_confidence,
    SUM(df.FORECAST_LOWER_BOUND) as total_lower_bound,
    SUM(df.FORECAST_UPPER_BOUND) as total_upper_bound
FROM DEMAND_FORECAST df
JOIN PRODUCTS p ON df.SKU_ID = p.SKU_ID
WHERE df.FORECAST_DATE BETWEEN CURRENT_DATE() AND DATEADD(day, 7, CURRENT_DATE())
GROUP BY p.CATEGORY, p.BRAND, df.FORECAST_DATE
ORDER BY df.FORECAST_DATE, total_forecasted_units DESC;

-- ============================================================================
-- PART 3: ON-SHELF AVAILABILITY QUERIES
-- ============================================================================

-- Query 10: Stores with Worst OSA Performance
SELECT 
    STORE_NAME,
    STORE_FORMAT,
    REGION,
    CITY,
    COUNT(DISTINCT SKU_ID) as sku_count,
    AVG(OSA_PERCENTAGE) as avg_osa_pct,
    SUM(OOS_DAYS) as total_oos_days,
    SUM(ESTIMATED_LOST_REVENUE) as total_lost_revenue,
    SUM(ESTIMATED_LOST_UNITS) as total_lost_units
FROM VW_OSA_METRICS
GROUP BY STORE_NAME, STORE_FORMAT, REGION, CITY
ORDER BY avg_osa_pct ASC
LIMIT 10;

-- Query 11: Category OSA Performance
SELECT 
    CATEGORY,
    SUB_CATEGORY,
    COUNT(DISTINCT STORE_ID) as store_count,
    COUNT(DISTINCT SKU_ID) as sku_count,
    AVG(OSA_PERCENTAGE) as avg_osa_pct,
    SUM(OOS_DAYS) as total_oos_days,
    SUM(ESTIMATED_LOST_REVENUE) as total_lost_revenue
FROM VW_OSA_METRICS
GROUP BY CATEGORY, SUB_CATEGORY
ORDER BY total_lost_revenue DESC;

-- Query 12: High-Risk Out-of-Stock Items
SELECT 
    SKU_NAME,
    BRAND,
    CATEGORY,
    STORE_NAME,
    REGION,
    OOS_RISK_LEVEL,
    OSA_PERCENTAGE,
    OOS_DAYS,
    ESTIMATED_LOST_REVENUE,
    AVG_INVENTORY,
    DAYS_OF_SUPPLY
FROM VW_OSA_METRICS
WHERE OOS_RISK_LEVEL IN ('Critical', 'High')
ORDER BY ESTIMATED_LOST_REVENUE DESC
LIMIT 20;

-- Query 13: OSA by Store Format
SELECT 
    STORE_FORMAT,
    REGION,
    COUNT(DISTINCT STORE_ID) as store_count,
    AVG(OSA_PERCENTAGE) as avg_osa_pct,
    SUM(OOS_DAYS) as total_oos_days,
    SUM(ESTIMATED_LOST_REVENUE) as total_lost_revenue,
    SUM(ESTIMATED_LOST_REVENUE) / NULLIF(COUNT(DISTINCT STORE_ID), 0) as lost_revenue_per_store
FROM VW_OSA_METRICS
GROUP BY STORE_FORMAT, REGION
ORDER BY lost_revenue_per_store DESC;

-- Query 14: Products with Best Inventory Management
SELECT 
    SKU_NAME,
    BRAND,
    CATEGORY,
    COUNT(DISTINCT STORE_ID) as store_count,
    AVG(OSA_PERCENTAGE) as avg_osa_pct,
    AVG(DAYS_OF_SUPPLY) as avg_days_of_supply,
    SUM(OOS_DAYS) as total_oos_days
FROM VW_OSA_METRICS
WHERE OSA_PERCENTAGE >= 95
GROUP BY SKU_NAME, BRAND, CATEGORY
ORDER BY avg_osa_pct DESC, avg_days_of_supply
LIMIT 20;

-- ============================================================================
-- PART 4: INTEGRATED INSIGHTS (Cross-Functional Analysis)
-- ============================================================================

-- Query 15: Promotion Impact on OSA
SELECT 
    pp.CATEGORY,
    pp.PROMOTION_TYPE,
    AVG(osa.OSA_PERCENTAGE) as avg_osa_during_promo,
    SUM(osa.OOS_DAYS) as total_oos_days,
    SUM(pp.INCREMENTAL_REVENUE) as incremental_revenue,
    SUM(osa.ESTIMATED_LOST_REVENUE) as lost_revenue_from_oos
FROM VW_PROMOTION_PERFORMANCE pp
JOIN VW_OSA_METRICS osa 
    ON pp.SKU_ID = osa.SKU_ID
    AND pp.STORE_ID = osa.STORE_ID
GROUP BY pp.CATEGORY, pp.PROMOTION_TYPE
ORDER BY lost_revenue_from_oos DESC;

-- Query 16: Forecast Accuracy for Top Promoted Categories
SELECT 
    fa.CATEGORY,
    COUNT(DISTINCT fa.SKU_ID) as sku_count,
    AVG(fa.ABSOLUTE_PERCENTAGE_ERROR) as avg_mape,
    SUM(pp.INCREMENTAL_REVENUE) as total_promo_incremental_revenue,
    AVG(pp.PROMOTION_LIFT_PCT) as avg_promo_lift_pct
FROM VW_FORECAST_ACCURACY fa
JOIN VW_PROMOTION_PERFORMANCE pp 
    ON fa.SKU_ID = pp.SKU_ID
    AND fa.CATEGORY = pp.CATEGORY
WHERE fa.ACTUAL_UNITS IS NOT NULL
GROUP BY fa.CATEGORY
ORDER BY total_promo_incremental_revenue DESC;

-- Query 17: Store Performance Dashboard
SELECT 
    s.STORE_NAME,
    s.STORE_FORMAT,
    s.REGION,
    COUNT(DISTINCT ds.SKU_ID) as sku_count,
    SUM(ds.REVENUE) as total_revenue,
    SUM(ds.REVENUE - ds.COST) as gross_profit,
    AVG(osa.OSA_PERCENTAGE) as avg_osa_pct,
    AVG(pp.PROMOTION_ROI_PCT) as avg_promo_roi
FROM STORES s
JOIN DAILY_SALES ds ON s.STORE_ID = ds.STORE_ID
LEFT JOIN VW_OSA_METRICS osa ON s.STORE_ID = osa.STORE_ID
LEFT JOIN VW_PROMOTION_PERFORMANCE pp ON s.STORE_ID = pp.STORE_ID
WHERE ds.SALE_DATE >= DATEADD(month, -1, CURRENT_DATE())
GROUP BY s.STORE_NAME, s.STORE_FORMAT, s.REGION
ORDER BY total_revenue DESC
LIMIT 20;

-- ============================================================================
-- SUMMARY
-- ============================================================================

SELECT 
    'Demo queries executed successfully!' as MESSAGE,
    'Use these as reference for Cortex Analyst natural language queries' as NOTE;

/*============================================================================
   CORTEX ANALYST EQUIVALENT QUESTIONS:
   
   Instead of running these SQL queries, ask Cortex Analyst:
   
   Trade Promotion:
   - "Which promotions had the best ROI last quarter?"
   - "Show me promotion lift by promotion type"
   - "Which categories respond best to discounts?"
   
   Demand Forecasting:
   - "What is the forecast accuracy by category?"
   - "Which products have the highest forecast error?"
   - "Show me next week's demand forecast for beverages"
   
   On-Shelf Availability:
   - "Which stores have the worst OSA performance?"
   - "What is the estimated lost revenue from stockouts?"
   - "Show me high-risk out-of-stock items"
   
   Integrated:
   - "How do promotions impact on-shelf availability?"
   - "What is the forecast accuracy for promoted categories?"
============================================================================*/

