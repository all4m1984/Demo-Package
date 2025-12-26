/*============================================================================
   Oil & Gas Upstream Operations Demo - Sample Queries
   
   Purpose: Demonstrates analytical capabilities with sample queries
   Duration: Use during demo to show SQL-based analytics
   
   These queries address the 10 critical executive questions
============================================================================*/

USE DATABASE OIL_GAS_UPSTREAM_DEMO;
USE SCHEMA OPERATIONS;
USE WAREHOUSE DEMO_WH;

-- ============================================================================
-- Q1: Production Optimization - Top and Bottom Performers
-- ============================================================================
-- Question: What are our top and bottom performing wells by production efficiency?

-- Top 10 performers (last 90 days)
SELECT 
    w.WELL_NAME,
    w.FIELD_NAME,
    w.WELL_TYPE,
    COUNT(DISTINCT dp.PRODUCTION_DATE) as PRODUCING_DAYS,
    SUM(dp.BOE) as TOTAL_BOE,
    AVG(dp.BOE) as AVG_DAILY_BOE,
    SUM(dp.OIL_BBL) as TOTAL_OIL_BBL,
    AVG(dp.TUBING_PRESSURE_PSI) as AVG_TUBING_PRESSURE,
    dp.PRODUCTION_METHOD,
    CASE 
        WHEN AVG(dp.BOE) > 400 THEN 'Excellent'
        WHEN AVG(dp.BOE) > 250 THEN 'Good'
        WHEN AVG(dp.BOE) > 150 THEN 'Average'
        ELSE 'Below Average'
    END as PERFORMANCE_RATING
FROM WELLS w
JOIN DAILY_PRODUCTION dp ON w.WELL_ID = dp.WELL_ID
WHERE w.WELL_STATUS = 'Active'
  AND dp.PRODUCTION_DATE >= DATEADD(day, -90, CURRENT_DATE())
GROUP BY w.WELL_NAME, w.FIELD_NAME, w.WELL_TYPE, dp.PRODUCTION_METHOD
ORDER BY AVG_DAILY_BOE DESC
LIMIT 10;

-- Bottom 10 performers (identify optimization candidates)
SELECT 
    w.WELL_NAME,
    w.FIELD_NAME,
    AVG(dp.BOE) as AVG_DAILY_BOE,
    AVG(dp.TUBING_PRESSURE_PSI) as AVG_TUBING_PRESSURE,
    SUM(dp.DOWNTIME_HOURS) as TOTAL_DOWNTIME,
    COUNT(DISTINCT wo.OPERATION_ID) as WORKOVER_COUNT,
    'Low pressure / High downtime' as LIKELY_ISSUE
FROM WELLS w
JOIN DAILY_PRODUCTION dp ON w.WELL_ID = dp.WELL_ID
LEFT JOIN WELL_OPERATIONS wo ON w.WELL_ID = wo.WELL_ID
WHERE w.WELL_STATUS = 'Active'
  AND dp.PRODUCTION_DATE >= DATEADD(day, -90, CURRENT_DATE())
GROUP BY w.WELL_NAME, w.FIELD_NAME
HAVING AVG(dp.BOE) > 0
ORDER BY AVG_DAILY_BOE ASC
LIMIT 10;

-- ============================================================================
-- Q2: Cost Management - Highest Operating Cost per BOE
-- ============================================================================
-- Question: Which wells have the highest operating cost per barrel?

SELECT 
    w.WELL_NAME,
    w.FIELD_NAME,
    w.WELL_TYPE,
    SUM(dp.BOE) as TOTAL_PRODUCTION_BOE,
    SUM(wo.TOTAL_COST_USD) as TOTAL_OPEX_USD,
    ROUND(SUM(wo.TOTAL_COST_USD) / NULLIF(SUM(dp.BOE), 0), 2) as OPEX_PER_BOE,
    COUNT(DISTINCT wo.OPERATION_ID) as OPERATION_COUNT,
    SUM(CASE WHEN wo.OPERATION_TYPE = 'Workover' THEN wo.TOTAL_COST_USD ELSE 0 END) as WORKOVER_COSTS,
    CASE 
        WHEN SUM(wo.TOTAL_COST_USD) / NULLIF(SUM(dp.BOE), 0) > 40 THEN 'High Cost - Review'
        WHEN SUM(wo.TOTAL_COST_USD) / NULLIF(SUM(dp.BOE), 0) > 25 THEN 'Above Average'
        WHEN SUM(wo.TOTAL_COST_USD) / NULLIF(SUM(dp.BOE), 0) > 15 THEN 'Average'
        ELSE 'Efficient'
    END as COST_RATING
FROM WELLS w
JOIN DAILY_PRODUCTION dp ON w.WELL_ID = dp.WELL_ID
LEFT JOIN WELL_OPERATIONS wo ON w.WELL_ID = wo.WELL_ID
WHERE w.WELL_STATUS = 'Active'
GROUP BY w.WELL_NAME, w.FIELD_NAME, w.WELL_TYPE
HAVING SUM(dp.BOE) > 1000
ORDER BY OPEX_PER_BOE DESC
LIMIT 20;

-- Cost breakdown by operation type
SELECT 
    wo.OPERATION_TYPE,
    COUNT(*) as OPERATION_COUNT,
    SUM(wo.TOTAL_COST_USD) as TOTAL_COST_USD,
    AVG(wo.TOTAL_COST_USD) as AVG_COST_PER_OPERATION,
    SUM(wo.DURATION_HOURS) as TOTAL_DURATION_HOURS,
    SUM(wo.PRODUCTION_IMPACT_BOE) as TOTAL_PRODUCTION_UPLIFT_BOE
FROM WELL_OPERATIONS wo
WHERE wo.OPERATION_DATE >= DATEADD(month, -12, CURRENT_DATE())
GROUP BY wo.OPERATION_TYPE
ORDER BY TOTAL_COST_USD DESC;

-- ============================================================================
-- Q3: Equipment Reliability - Failure Rates and Risk
-- ============================================================================
-- Question: What is our equipment failure rate and which assets pose highest risk?

SELECT 
    ea.ASSET_TYPE,
    ea.CRITICALITY,
    COUNT(DISTINCT ea.ASSET_ID) as ASSET_COUNT,
    COUNT(ef.FAILURE_ID) as TOTAL_FAILURES,
    ROUND(COUNT(ef.FAILURE_ID)::FLOAT / NULLIF(COUNT(DISTINCT ea.ASSET_ID), 0), 2) as FAILURES_PER_ASSET,
    SUM(ef.DOWNTIME_HOURS) as TOTAL_DOWNTIME_HOURS,
    SUM(ef.REPAIR_COST_USD) as TOTAL_REPAIR_COST_USD,
    SUM(ef.PRODUCTION_LOSS_BOE) as TOTAL_PRODUCTION_LOSS_BOE,
    ROUND(SUM(ef.PRODUCTION_LOSS_BOE) * 70, 0) as ESTIMATED_REVENUE_LOSS_USD -- Assuming $70/BOE
FROM EQUIPMENT_ASSETS ea
LEFT JOIN EQUIPMENT_FAILURES ef ON ea.ASSET_ID = ef.ASSET_ID
GROUP BY ea.ASSET_TYPE, ea.CRITICALITY
ORDER BY FAILURES_PER_ASSET DESC, ea.CRITICALITY;

-- High-risk assets requiring immediate attention
SELECT 
    ea.ASSET_ID,
    ea.ASSET_NAME,
    ea.ASSET_TYPE,
    w.WELL_NAME,
    ea.CRITICALITY,
    ea.STATUS,
    DATEDIFF(day, ea.INSTALL_DATE, CURRENT_DATE()) as AGE_DAYS,
    ea.DESIGN_LIFE_YEARS * 365 as DESIGN_LIFE_DAYS,
    ROUND((DATEDIFF(day, ea.INSTALL_DATE, CURRENT_DATE()) / (ea.DESIGN_LIFE_YEARS * 365.0) * 100), 1) as LIFE_CONSUMED_PCT,
    COUNT(ef.FAILURE_ID) as FAILURE_COUNT_LAST_YEAR,
    SUM(ef.DOWNTIME_HOURS) as DOWNTIME_HOURS,
    DATEDIFF(day, ea.LAST_MAINTENANCE_DATE, CURRENT_DATE()) as DAYS_SINCE_MAINTENANCE,
    CASE 
        WHEN ea.STATUS = 'Failed' THEN 'Immediate Action Required'
        WHEN ea.STATUS = 'Degraded' AND ea.CRITICALITY = 'Critical' THEN 'Urgent'
        WHEN COUNT(ef.FAILURE_ID) > 3 THEN 'High Risk'
        WHEN DATEDIFF(day, ea.INSTALL_DATE, CURRENT_DATE()) > ea.DESIGN_LIFE_YEARS * 365 THEN 'End of Life'
        ELSE 'Monitor'
    END as RECOMMENDATION
FROM EQUIPMENT_ASSETS ea
LEFT JOIN WELLS w ON ea.WELL_ID = w.WELL_ID
LEFT JOIN EQUIPMENT_FAILURES ef ON ea.ASSET_ID = ef.ASSET_ID 
    AND ef.FAILURE_DATE >= DATEADD(year, -1, CURRENT_DATE())
WHERE ea.CRITICALITY IN ('Critical', 'High')
GROUP BY ea.ASSET_ID, ea.ASSET_NAME, ea.ASSET_TYPE, w.WELL_NAME, ea.CRITICALITY, 
         ea.STATUS, ea.INSTALL_DATE, ea.DESIGN_LIFE_YEARS, ea.LAST_MAINTENANCE_DATE
HAVING 
    ea.STATUS IN ('Failed', 'Degraded') 
    OR COUNT(ef.FAILURE_ID) > 2
    OR DATEDIFF(day, ea.INSTALL_DATE, CURRENT_DATE()) > ea.DESIGN_LIFE_YEARS * 365
ORDER BY 
    CASE 
        WHEN ea.STATUS = 'Failed' THEN 1
        WHEN ea.STATUS = 'Degraded' AND ea.CRITICALITY = 'Critical' THEN 2
        WHEN COUNT(ef.FAILURE_ID) > 3 THEN 3
        ELSE 4
    END,
    LIFE_CONSUMED_PCT DESC
LIMIT 25;

-- ============================================================================
-- Q4: Reservoir Performance - Pressure Trends
-- ============================================================================
-- Question: How are reservoir pressure and production rates trending?

SELECT 
    r.FIELD_NAME,
    r.RESERVOIR_NAME,
    r.RESERVOIR_TYPE,
    r.INITIAL_PRESSURE_PSI,
    r.CURRENT_PRESSURE_PSI,
    r.PRESSURE_DEPLETION_PCT,
    r.REMAINING_RESERVES_MMSTB,
    r.RECOVERY_FACTOR_PCT,
    COUNT(DISTINCT w.WELL_ID) as ACTIVE_WELLS,
    AVG(dp.BOE) as AVG_DAILY_PRODUCTION_BOE,
    CASE 
        WHEN r.PRESSURE_DEPLETION_PCT > 60 THEN 'Critical - Consider pressure maintenance'
        WHEN r.PRESSURE_DEPLETION_PCT > 40 THEN 'Monitor closely'
        WHEN r.PRESSURE_DEPLETION_PCT > 20 THEN 'Normal depletion'
        ELSE 'Early life'
    END as PRESSURE_STATUS
FROM RESERVOIR_DATA r
LEFT JOIN WELLS w ON r.RESERVOIR_NAME = w.RESERVOIR_NAME AND w.WELL_STATUS = 'Active'
LEFT JOIN DAILY_PRODUCTION dp ON w.WELL_ID = dp.WELL_ID 
    AND dp.PRODUCTION_DATE >= DATEADD(day, -30, CURRENT_DATE())
GROUP BY r.FIELD_NAME, r.RESERVOIR_NAME, r.RESERVOIR_TYPE, r.INITIAL_PRESSURE_PSI,
         r.CURRENT_PRESSURE_PSI, r.PRESSURE_DEPLETION_PCT, r.REMAINING_RESERVES_MMSTB,
         r.RECOVERY_FACTOR_PCT
ORDER BY r.PRESSURE_DEPLETION_PCT DESC;

-- Pressure trend over time (last 6 months)
SELECT 
    DATE_TRUNC('MONTH', rp.MEASUREMENT_DATE) as MONTH,
    r.RESERVOIR_NAME,
    r.FIELD_NAME,
    AVG(rp.PRESSURE_PSI) as AVG_PRESSURE_PSI,
    MIN(rp.PRESSURE_PSI) as MIN_PRESSURE_PSI,
    MAX(rp.PRESSURE_PSI) as MAX_PRESSURE_PSI,
    COUNT(DISTINCT rp.WELL_ID) as WELLS_MEASURED
FROM RESERVOIR_PRESSURE rp
JOIN RESERVOIR_DATA r ON rp.RESERVOIR_ID = r.RESERVOIR_ID
WHERE rp.MEASUREMENT_DATE >= DATEADD(month, -6, CURRENT_DATE())
GROUP BY DATE_TRUNC('MONTH', rp.MEASUREMENT_DATE), r.RESERVOIR_NAME, r.FIELD_NAME
ORDER BY r.RESERVOIR_NAME, MONTH;

-- ============================================================================
-- Q5: HSE Compliance - Safety Incidents and Regulatory Risk
-- ============================================================================
-- Question: What are our safety incidents and compliance rates?

-- HSE Summary Dashboard
SELECT 
    CASE 
        WHEN INCIDENT_DATE >= DATEADD(month, -1, CURRENT_DATE()) THEN 'Last Month'
        WHEN INCIDENT_DATE >= DATEADD(month, -3, CURRENT_DATE()) THEN 'Last Quarter'
        WHEN INCIDENT_DATE >= DATEADD(month, -6, CURRENT_DATE()) THEN 'Last 6 Months'
        ELSE 'Older'
    END as TIME_PERIOD,
    INCIDENT_TYPE,
    SEVERITY,
    COUNT(*) as INCIDENT_COUNT,
    SUM(INJURIES) as TOTAL_INJURIES,
    SUM(FATALITIES) as TOTAL_FATALITIES,
    SUM(VOLUME_SPILLED_BBL) as TOTAL_SPILLED_BBL,
    SUM(ESTIMATED_COST_USD) as TOTAL_COST_USD,
    COUNT(CASE WHEN REGULATORY_REPORTABLE THEN 1 END) as REPORTABLE_INCIDENTS
FROM HSE_INCIDENTS
WHERE INCIDENT_DATE >= DATEADD(month, -6, CURRENT_DATE())
GROUP BY TIME_PERIOD, INCIDENT_TYPE, SEVERITY
ORDER BY TIME_PERIOD, INCIDENT_TYPE, SEVERITY;

-- Incident trends by month
SELECT 
    DATE_TRUNC('MONTH', INCIDENT_DATE) as INCIDENT_MONTH,
    COUNT(*) as TOTAL_INCIDENTS,
    COUNT(CASE WHEN SEVERITY = 'Fatal' THEN 1 END) as FATAL,
    COUNT(CASE WHEN SEVERITY = 'Serious' THEN 1 END) as SERIOUS,
    COUNT(CASE WHEN SEVERITY = 'Minor' THEN 1 END) as MINOR,
    COUNT(CASE WHEN SEVERITY = 'Near-miss' THEN 1 END) as NEAR_MISS,
    SUM(DAYS_AWAY_FROM_WORK) as TOTAL_DAYS_AWAY,
    -- Calculate TRIR (Total Recordable Incident Rate per 200,000 hours)
    -- Assuming 500 employees working 2000 hours/year
    ROUND((COUNT(CASE WHEN SEVERITY IN ('Fatal', 'Serious', 'Minor') THEN 1 END)::FLOAT / 
           (500 * 2000 / 12)) * 200000, 2) as TRIR
FROM HSE_INCIDENTS
WHERE INCIDENT_DATE >= DATEADD(month, -12, CURRENT_DATE())
GROUP BY DATE_TRUNC('MONTH', INCIDENT_DATE)
ORDER BY INCIDENT_MONTH DESC;

-- High-risk facilities
SELECT 
    FACILITY_NAME,
    COUNT(*) as INCIDENT_COUNT,
    COUNT(CASE WHEN SEVERITY IN ('Fatal', 'Serious') THEN 1 END) as SERIOUS_INCIDENTS,
    SUM(ESTIMATED_COST_USD) as TOTAL_INCIDENT_COST,
    COUNT(CASE WHEN REGULATORY_REPORTABLE THEN 1 END) as REPORTABLE_COUNT,
    'Enhanced safety measures required' as RECOMMENDATION
FROM HSE_INCIDENTS
WHERE INCIDENT_DATE >= DATEADD(month, -12, CURRENT_DATE())
GROUP BY FACILITY_NAME
HAVING COUNT(*) > 5
ORDER BY SERIOUS_INCIDENTS DESC, INCIDENT_COUNT DESC;

-- ============================================================================
-- Q6: Capital Efficiency - ROI of Drilling Investments
-- ============================================================================
-- Question: What is the ROI of recent drilling investments?

SELECT 
    dp.PROJECT_NAME,
    dp.FIELD_NAME,
    dp.PROJECT_TYPE,
    dp.PROJECT_STATUS,
    dp.BUDGETED_COST_USD,
    dp.ACTUAL_COST_USD,
    dp.COST_VARIANCE_PCT,
    dp.EXPECTED_PRODUCTION_BOEPD,
    dp.EXPECTED_EUR_BOE,
    dp.NPV_USD,
    dp.IRR_PCT,
    dp.PAYBACK_MONTHS,
    CASE 
        WHEN dp.NPV_USD > 15000000 AND dp.IRR_PCT > 25 THEN 'Tier 1 - Prioritize'
        WHEN dp.NPV_USD > 10000000 AND dp.IRR_PCT > 20 THEN 'Tier 2 - Strong'
        WHEN dp.NPV_USD > 5000000 AND dp.IRR_PCT > 15 THEN 'Tier 3 - Good'
        WHEN dp.NPV_USD > 0 AND dp.IRR_PCT > 10 THEN 'Tier 4 - Acceptable'
        ELSE 'Below Hurdle - Reconsider'
    END as PRIORITY_TIER,
    ROUND(dp.NPV_USD / NULLIF(dp.BUDGETED_COST_USD, 0), 2) as NPV_TO_CAPEX_RATIO
FROM DRILLING_PROJECTS dp
WHERE dp.PROJECT_STATUS IN ('Planned', 'In Progress', 'Completed')
  AND dp.PROJECT_TYPE = 'New drill'
ORDER BY dp.NPV_USD DESC, dp.IRR_PCT DESC
LIMIT 20;

-- Portfolio summary by field
SELECT 
    FIELD_NAME,
    COUNT(*) as PROJECT_COUNT,
    SUM(BUDGETED_COST_USD) as TOTAL_BUDGETED_CAPEX,
    SUM(ACTUAL_COST_USD) as TOTAL_ACTUAL_CAPEX,
    AVG(COST_VARIANCE_PCT) as AVG_COST_VARIANCE_PCT,
    SUM(EXPECTED_PRODUCTION_BOEPD) as TOTAL_EXPECTED_PRODUCTION,
    SUM(NPV_USD) as TOTAL_NPV_USD,
    AVG(IRR_PCT) as AVG_IRR_PCT,
    AVG(PAYBACK_MONTHS) as AVG_PAYBACK_MONTHS
FROM DRILLING_PROJECTS
WHERE PROJECT_STATUS IN ('Planned', 'In Progress', 'Completed')
GROUP BY FIELD_NAME
ORDER BY TOTAL_NPV_USD DESC;

-- ============================================================================
-- Q7: Production Forecasting - 12-Month Forecast
-- ============================================================================
-- Question: What is our 12-month production forecast?

-- Current production rate and trend
WITH monthly_production AS (
    SELECT 
        DATE_TRUNC('MONTH', PRODUCTION_DATE) as PROD_MONTH,
        SUM(BOE) as TOTAL_BOE,
        AVG(BOE) as AVG_DAILY_BOE,
        COUNT(DISTINCT WELL_ID) as ACTIVE_WELL_COUNT
    FROM DAILY_PRODUCTION
    WHERE PRODUCTION_DATE >= DATEADD(month, -6, CURRENT_DATE())
    GROUP BY DATE_TRUNC('MONTH', PRODUCTION_DATE)
),
decline_rate AS (
    SELECT 
        AVG((LAG(AVG_DAILY_BOE) OVER (ORDER BY PROD_MONTH) - AVG_DAILY_BOE) / 
            NULLIF(LAG(AVG_DAILY_BOE) OVER (ORDER BY PROD_MONTH), 0) * 100) as AVG_MONTHLY_DECLINE_PCT
    FROM monthly_production
)
SELECT 
    mp.PROD_MONTH,
    mp.TOTAL_BOE,
    mp.AVG_DAILY_BOE,
    mp.ACTIVE_WELL_COUNT,
    ROUND(mp.AVG_DAILY_BOE * 365 / 12, 0) as MONTHLY_BOE_EQUIVALENT,
    ROUND(dr.AVG_MONTHLY_DECLINE_PCT, 2) as MONTHLY_DECLINE_PCT,
    -- Simple forecast using decline rate
    ROUND(mp.AVG_DAILY_BOE * POWER((1 - dr.AVG_MONTHLY_DECLINE_PCT/100), 
          DATEDIFF(month, mp.PROD_MONTH, DATEADD(month, 12, CURRENT_DATE()))), 0) as FORECASTED_DAILY_BOE
FROM monthly_production mp
CROSS JOIN decline_rate dr
ORDER BY mp.PROD_MONTH DESC;

-- ============================================================================
-- Q8: Supply Chain - Vendor Performance Issues
-- ============================================================================
-- Question: What are critical material shortages and vendor performance issues?

SELECT 
    sc.VENDOR,
    sc.MATERIAL_TYPE,
    COUNT(*) as TRANSACTION_COUNT,
    SUM(sc.TOTAL_COST_USD) as TOTAL_SPEND_USD,
    AVG(sc.LEAD_TIME_DAYS) as AVG_LEAD_TIME,
    ROUND(SUM(CASE WHEN sc.ON_TIME_DELIVERY THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100, 1) as ON_TIME_DELIVERY_PCT,
    AVG(sc.QUALITY_RATING) as AVG_QUALITY_RATING,
    COUNT(CASE WHEN sc.CRITICALITY = 'Critical' THEN 1 END) as CRITICAL_ITEMS,
    CASE 
        WHEN AVG(sc.QUALITY_RATING) < 3.5 OR 
             SUM(CASE WHEN sc.ON_TIME_DELIVERY THEN 1 ELSE 0 END)::FLOAT / COUNT(*) < 0.80 
        THEN 'Performance Issues - Review Contract'
        WHEN SUM(CASE WHEN sc.ON_TIME_DELIVERY THEN 1 ELSE 0 END)::FLOAT / COUNT(*) < 0.90 
        THEN 'Below Target - Monitor'
        ELSE 'Acceptable Performance'
    END as VENDOR_STATUS
FROM SUPPLY_CHAIN sc
WHERE sc.TRANSACTION_DATE >= DATEADD(month, -6, CURRENT_DATE())
GROUP BY sc.VENDOR, sc.MATERIAL_TYPE
HAVING COUNT(*) >= 10
ORDER BY ON_TIME_DELIVERY_PCT ASC, AVG_QUALITY_RATING ASC
LIMIT 20;

-- Critical materials below reorder point
SELECT 
    sc.MATERIAL_TYPE,
    sc.VENDOR,
    AVG(sc.STOCK_LEVEL) as CURRENT_STOCK,
    AVG(sc.REORDER_POINT) as REORDER_POINT,
    AVG(sc.LEAD_TIME_DAYS) as AVG_LEAD_TIME_DAYS,
    COUNT(DISTINCT sc.WELL_ID) as WELLS_REQUIRING_MATERIAL,
    'Order immediately' as ACTION
FROM SUPPLY_CHAIN sc
WHERE sc.CRITICALITY IN ('Critical', 'High')
  AND sc.STOCK_LEVEL < sc.REORDER_POINT
GROUP BY sc.MATERIAL_TYPE, sc.VENDOR
ORDER BY sc.MATERIAL_TYPE;

-- ============================================================================
-- Q9: Emissions & ESG - Carbon Emissions and Progress
-- ============================================================================
-- Question: What are our emissions and progress toward ESG targets?

SELECT 
    DATE_TRUNC('MONTH', ed.MEASUREMENT_DATE) as EMISSION_MONTH,
    ed.EMISSION_TYPE,
    SUM(ed.QUANTITY_CO2E_TONNES) as TOTAL_CO2E_TONNES,
    SUM(ed.PRODUCTION_BOE) as TOTAL_PRODUCTION_BOE,
    ROUND(SUM(ed.QUANTITY_CO2E_TONNES) / NULLIF(SUM(ed.PRODUCTION_BOE), 0), 4) as EMISSION_INTENSITY,
    COUNT(CASE WHEN ed.COMPLIANCE_STATUS = 'Violation' THEN 1 END) as VIOLATIONS,
    -- Assuming target is 0.15 tonnes CO2e per BOE
    CASE 
        WHEN SUM(ed.QUANTITY_CO2E_TONNES) / NULLIF(SUM(ed.PRODUCTION_BOE), 0) > 0.20 THEN 'Above Target - Action Required'
        WHEN SUM(ed.QUANTITY_CO2E_TONNES) / NULLIF(SUM(ed.PRODUCTION_BOE), 0) > 0.15 THEN 'Near Target - Monitor'
        ELSE 'Meeting Target'
    END as TARGET_STATUS
FROM EMISSIONS_DATA ed
WHERE ed.MEASUREMENT_DATE >= DATEADD(month, -12, CURRENT_DATE())
GROUP BY DATE_TRUNC('MONTH', ed.MEASUREMENT_DATE), ed.EMISSION_TYPE
ORDER BY EMISSION_MONTH DESC, TOTAL_CO2E_TONNES DESC;

-- Emissions by field and source
SELECT 
    w.FIELD_NAME,
    ed.EMISSION_SOURCE,
    SUM(ed.QUANTITY_CO2E_TONNES) as TOTAL_CO2E_TONNES,
    SUM(ed.PRODUCTION_BOE) as TOTAL_PRODUCTION_BOE,
    ROUND(SUM(ed.QUANTITY_CO2E_TONNES) / NULLIF(SUM(ed.PRODUCTION_BOE), 0), 4) as EMISSION_INTENSITY,
    ROUND(SUM(ed.QUANTITY_CO2E_TONNES) / 
          (SELECT SUM(QUANTITY_CO2E_TONNES) FROM EMISSIONS_DATA 
           WHERE MEASUREMENT_DATE >= DATEADD(month, -12, CURRENT_DATE())) * 100, 1) as PCT_OF_TOTAL
FROM EMISSIONS_DATA ed
JOIN WELLS w ON ed.WELL_ID = w.WELL_ID
WHERE ed.MEASUREMENT_DATE >= DATEADD(month, -12, CURRENT_DATE())
GROUP BY w.FIELD_NAME, ed.EMISSION_SOURCE
ORDER BY TOTAL_CO2E_TONNES DESC;

-- ============================================================================
-- Q10: Field Development - Best Economics for Next Drilling Campaign
-- ============================================================================
-- Question: Which undeveloped locations offer the best economics?

SELECT 
    dp.PROJECT_ID,
    dp.PROJECT_NAME,
    dp.FIELD_NAME,
    dp.BUDGETED_COST_USD,
    dp.EXPECTED_PRODUCTION_BOEPD,
    dp.EXPECTED_EUR_BOE,
    dp.NPV_USD,
    dp.IRR_PCT,
    dp.PAYBACK_MONTHS,
    -- Calculate metrics
    ROUND(dp.NPV_USD / NULLIF(dp.BUDGETED_COST_USD, 0), 2) as NPV_INDEX,
    ROUND(dp.BUDGETED_COST_USD / NULLIF(dp.EXPECTED_EUR_BOE, 0), 2) as CAPEX_PER_BOE,
    ROUND(dp.EXPECTED_EUR_BOE / NULLIF(dp.BUDGETED_COST_USD, 0) * 1000000, 0) as BOE_PER_MILLION_USD,
    -- Scoring system (weighted)
    ROUND(
        (dp.NPV_USD / 1000000) * 0.4 +  -- NPV weight 40%
        (dp.IRR_PCT) * 0.3 +              -- IRR weight 30%
        ((60 - dp.PAYBACK_MONTHS) / 60 * 100) * 0.2 + -- Payback weight 20%
        ((dp.EXPECTED_EUR_BOE / 1000000) * 10) * 0.1  -- EUR weight 10%
    , 2) as COMPOSITE_SCORE
FROM DRILLING_PROJECTS dp
WHERE dp.PROJECT_STATUS = 'Planned'
  AND dp.PROJECT_TYPE = 'New drill'
  AND dp.NPV_USD > 0
ORDER BY COMPOSITE_SCORE DESC
LIMIT 15;

-- Field development summary
SELECT 
    FIELD_NAME,
    COUNT(*) as PLANNED_PROJECTS,
    SUM(BUDGETED_COST_USD) as TOTAL_CAPEX_REQUIRED,
    SUM(EXPECTED_PRODUCTION_BOEPD) as TOTAL_EXPECTED_PRODUCTION,
    SUM(NPV_USD) as TOTAL_NPV,
    AVG(IRR_PCT) as AVG_IRR,
    AVG(PAYBACK_MONTHS) as AVG_PAYBACK_MONTHS,
    CASE 
        WHEN AVG(IRR_PCT) > 20 AND SUM(NPV_USD) > 50000000 THEN 'High Priority'
        WHEN AVG(IRR_PCT) > 15 AND SUM(NPV_USD) > 20000000 THEN 'Medium Priority'
        ELSE 'Low Priority'
    END as DEVELOPMENT_PRIORITY
FROM DRILLING_PROJECTS
WHERE PROJECT_STATUS = 'Planned'
  AND PROJECT_TYPE = 'New drill'
GROUP BY FIELD_NAME
ORDER BY TOTAL_NPV DESC;

-- ============================================================================
-- Summary Dashboard - Executive KPIs
-- ============================================================================

SELECT '============ EXECUTIVE DASHBOARD ============' as SECTION;

-- Production KPIs
SELECT 
    'Production' as METRIC_CATEGORY,
    'Current Daily Production' as METRIC,
    ROUND(SUM(dp.BOE) / COUNT(DISTINCT dp.PRODUCTION_DATE), 0) as VALUE,
    'BOE/day' as UNIT
FROM DAILY_PRODUCTION dp
WHERE dp.PRODUCTION_DATE >= DATEADD(day, -30, CURRENT_DATE())
UNION ALL
SELECT 
    'Production',
    'Active Wells',
    COUNT(DISTINCT WELL_ID),
    'wells'
FROM WELLS
WHERE WELL_STATUS = 'Active'
UNION ALL
-- Cost KPIs
SELECT 
    'Costs',
    'Average OPEX per BOE',
    ROUND(SUM(wo.TOTAL_COST_USD) / NULLIF(SUM(dp.BOE), 0), 2),
    'USD/BOE'
FROM WELL_OPERATIONS wo
JOIN DAILY_PRODUCTION dp ON wo.WELL_ID = dp.WELL_ID
WHERE wo.OPERATION_DATE >= DATEADD(month, -12, CURRENT_DATE())
UNION ALL
-- Reliability KPIs
SELECT 
    'Reliability',
    'Equipment Failures (YTD)',
    COUNT(*),
    'incidents'
FROM EQUIPMENT_FAILURES
WHERE FAILURE_DATE >= DATE_TRUNC('YEAR', CURRENT_DATE())
UNION ALL
-- Safety KPIs
SELECT 
    'HSE',
    'Recordable Incidents (YTD)',
    COUNT(*),
    'incidents'
FROM HSE_INCIDENTS
WHERE INCIDENT_DATE >= DATE_TRUNC('YEAR', CURRENT_DATE())
  AND SEVERITY IN ('Fatal', 'Serious', 'Minor')
UNION ALL
-- ESG KPIs
SELECT 
    'ESG',
    'Carbon Intensity',
    ROUND(SUM(ed.QUANTITY_CO2E_TONNES) / NULLIF(SUM(ed.PRODUCTION_BOE), 0), 4),
    'tCO2e/BOE'
FROM EMISSIONS_DATA ed
WHERE ed.MEASUREMENT_DATE >= DATEADD(month, -12, CURRENT_DATE());

SELECT '============================================' as SECTION;

