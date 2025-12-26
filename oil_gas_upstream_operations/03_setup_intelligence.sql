/*============================================================================
   Oil & Gas Upstream Operations Demo - Snowflake Intelligence Setup
   
   Purpose: Configure Cortex Analyst and semantic model
   Duration: ~1-2 minutes
   
   Execute this script after loading data
============================================================================*/

USE DATABASE OIL_GAS_UPSTREAM_DEMO;
USE SCHEMA OPERATIONS;
USE WAREHOUSE DEMO_WH;

-- ============================================================================
-- Create stage for semantic model
-- ============================================================================

-- Create internal stage for storing the semantic model YAML file
CREATE STAGE IF NOT EXISTS CORTEX_STAGE
    COMMENT = 'Stage for Cortex Analyst semantic model and configurations';

-- Display the stage path for file upload
SELECT 'Stage created: @OIL_GAS_UPSTREAM_DEMO.OPERATIONS.CORTEX_STAGE' as STAGE_INFO;
SELECT 'Upload semantic_model.yaml using Snowsight UI to upload the file to this stage' as INSTRUCTION;


-- ============================================================================
-- Create aggregated views for better performance with Cortex Analyst
-- ============================================================================

-- Monthly production summary by well
CREATE OR REPLACE VIEW VW_MONTHLY_PRODUCTION AS
SELECT 
    w.WELL_ID,
    w.WELL_NAME,
    w.FIELD_NAME,
    w.OPERATOR,
    w.WELL_TYPE,
    w.RESERVOIR_NAME,
    DATE_TRUNC('MONTH', dp.PRODUCTION_DATE) as PRODUCTION_MONTH,
    SUM(dp.OIL_BBL) as TOTAL_OIL_BBL,
    SUM(dp.GAS_MCF) as TOTAL_GAS_MCF,
    SUM(dp.WATER_BBL) as TOTAL_WATER_BBL,
    SUM(dp.BOE) as TOTAL_BOE,
    AVG(dp.OIL_BBL) as AVG_DAILY_OIL,
    AVG(dp.BOE) as AVG_DAILY_BOE,
    AVG(dp.TUBING_PRESSURE_PSI) as AVG_TUBING_PRESSURE,
    SUM(dp.RUNTIME_HOURS) as TOTAL_RUNTIME_HOURS,
    SUM(dp.DOWNTIME_HOURS) as TOTAL_DOWNTIME_HOURS,
    COUNT(DISTINCT dp.PRODUCTION_DATE) as PRODUCING_DAYS
FROM WELLS w
JOIN DAILY_PRODUCTION dp ON w.WELL_ID = dp.WELL_ID
GROUP BY 1,2,3,4,5,6,7;

-- Well economics view
CREATE OR REPLACE VIEW VW_WELL_ECONOMICS AS
SELECT 
    w.WELL_ID,
    w.WELL_NAME,
    w.FIELD_NAME,
    w.OPERATOR,
    w.DRILLING_COST_USD,
    w.COMPLETION_COST_USD,
    w.COMPLETION_DATE,
    (w.DRILLING_COST_USD + w.COMPLETION_COST_USD) as TOTAL_CAPEX_USD,
    w.ESTIMATED_RESERVES_BOE,
    SUM(dp.BOE) as CUMULATIVE_PRODUCTION_BOE,
    SUM(wo.TOTAL_COST_USD) as TOTAL_OPEX_USD,
    CASE 
        WHEN SUM(dp.BOE) > 0 THEN SUM(wo.TOTAL_COST_USD) / SUM(dp.BOE)
        ELSE NULL 
    END as OPEX_PER_BOE,
    CASE 
        WHEN SUM(dp.BOE) > 0 THEN 
            (w.DRILLING_COST_USD + w.COMPLETION_COST_USD + SUM(wo.TOTAL_COST_USD)) / SUM(dp.BOE)
        ELSE NULL 
    END as TOTAL_COST_PER_BOE,
    DATEDIFF(day, w.COMPLETION_DATE, CURRENT_DATE()) as DAYS_ON_PRODUCTION,
    CASE 
        WHEN w.ESTIMATED_RESERVES_BOE > 0 THEN 
            (SUM(dp.BOE) / w.ESTIMATED_RESERVES_BOE * 100)
        ELSE NULL
    END as RESERVE_RECOVERY_PCT
FROM WELLS w
LEFT JOIN DAILY_PRODUCTION dp ON w.WELL_ID = dp.WELL_ID
LEFT JOIN WELL_OPERATIONS wo ON w.WELL_ID = wo.WELL_ID
GROUP BY 1,2,3,4,5,6,7,9;

-- Field level summary
CREATE OR REPLACE VIEW VW_FIELD_SUMMARY AS
SELECT 
    w.FIELD_NAME,
    w.OPERATOR,
    COUNT(DISTINCT w.WELL_ID) as WELL_COUNT,
    COUNT(DISTINCT CASE WHEN w.WELL_STATUS = 'Active' THEN w.WELL_ID END) as ACTIVE_WELLS,
    SUM(w.DRILLING_COST_USD + w.COMPLETION_COST_USD) as TOTAL_CAPEX_USD,
    SUM(dp.BOE) as CUMULATIVE_PRODUCTION_BOE,
    AVG(dp.BOE) as AVG_DAILY_BOE,
    SUM(wo.TOTAL_COST_USD) as TOTAL_OPEX_USD,
    COUNT(DISTINCT ef.FAILURE_ID) as TOTAL_FAILURES,
    SUM(ef.DOWNTIME_HOURS) as TOTAL_DOWNTIME_HOURS,
    COUNT(DISTINCT hse.INCIDENT_ID) as HSE_INCIDENT_COUNT,
    SUM(ed.QUANTITY_CO2E_TONNES) as TOTAL_EMISSIONS_CO2E
FROM WELLS w
LEFT JOIN DAILY_PRODUCTION dp ON w.WELL_ID = dp.WELL_ID
LEFT JOIN WELL_OPERATIONS wo ON w.WELL_ID = wo.WELL_ID
LEFT JOIN EQUIPMENT_ASSETS ea ON w.WELL_ID = ea.WELL_ID
LEFT JOIN EQUIPMENT_FAILURES ef ON ea.ASSET_ID = ef.ASSET_ID
LEFT JOIN HSE_INCIDENTS hse ON w.WELL_ID = hse.WELL_ID
LEFT JOIN EMISSIONS_DATA ed ON w.WELL_ID = ed.WELL_ID
GROUP BY 1,2;

-- HSE metrics view
CREATE OR REPLACE VIEW VW_HSE_METRICS AS
SELECT 
    DATE_TRUNC('MONTH', INCIDENT_DATE) as INCIDENT_MONTH,
    FACILITY_NAME,
    INCIDENT_TYPE,
    INCIDENT_CATEGORY,
    SEVERITY,
    COUNT(*) as INCIDENT_COUNT,
    SUM(INJURIES) as TOTAL_INJURIES,
    SUM(FATALITIES) as TOTAL_FATALITIES,
    SUM(VOLUME_SPILLED_BBL) as TOTAL_SPILLED_BBL,
    SUM(ESTIMATED_COST_USD) as TOTAL_INCIDENT_COST_USD,
    SUM(DAYS_AWAY_FROM_WORK) as TOTAL_DAYS_AWAY
FROM HSE_INCIDENTS
GROUP BY 1,2,3,4,5;

-- Emissions by facility and type
CREATE OR REPLACE VIEW VW_EMISSIONS_SUMMARY AS
SELECT 
    DATE_TRUNC('MONTH', MEASUREMENT_DATE) as EMISSION_MONTH,
    FACILITY_NAME,
    EMISSION_TYPE,
    EMISSION_SOURCE,
    SUM(QUANTITY_TONNES) as TOTAL_QUANTITY_TONNES,
    SUM(QUANTITY_CO2E_TONNES) as TOTAL_CO2E_TONNES,
    SUM(PRODUCTION_BOE) as TOTAL_PRODUCTION_BOE,
    CASE 
        WHEN SUM(PRODUCTION_BOE) > 0 THEN SUM(QUANTITY_CO2E_TONNES) / SUM(PRODUCTION_BOE)
        ELSE 0
    END as EMISSION_INTENSITY,
    COUNT(CASE WHEN COMPLIANCE_STATUS = 'Violation' THEN 1 END) as VIOLATION_COUNT
FROM EMISSIONS_DATA
GROUP BY 1,2,3,4;

-- Equipment health score
CREATE OR REPLACE VIEW VW_EQUIPMENT_HEALTH AS
SELECT 
    ea.ASSET_ID,
    ea.ASSET_NAME,
    ea.ASSET_TYPE,
    ea.WELL_ID,
    ea.CRITICALITY,
    ea.STATUS,
    ea.INSTALL_DATE,
    ea.DESIGN_LIFE_YEARS,
    ea.LAST_MAINTENANCE_DATE,
    DATEDIFF(day, ea.INSTALL_DATE, CURRENT_DATE()) as AGE_DAYS,
    ea.DESIGN_LIFE_YEARS * 365 as DESIGN_LIFE_DAYS,
    CASE 
        WHEN ea.DESIGN_LIFE_YEARS * 365 > 0 THEN 
            (DATEDIFF(day, ea.INSTALL_DATE, CURRENT_DATE()) / (ea.DESIGN_LIFE_YEARS * 365.0) * 100)
        ELSE 0
    END as LIFE_CONSUMED_PCT,
    COUNT(ef.FAILURE_ID) as FAILURE_COUNT,
    SUM(ef.DOWNTIME_HOURS) as TOTAL_DOWNTIME_HOURS,
    SUM(ef.REPAIR_COST_USD) as TOTAL_REPAIR_COST_USD,
    DATEDIFF(day, ea.LAST_MAINTENANCE_DATE, CURRENT_DATE()) as DAYS_SINCE_MAINTENANCE,
    CASE 
        WHEN COUNT(ef.FAILURE_ID) = 0 THEN 100
        WHEN COUNT(ef.FAILURE_ID) BETWEEN 1 AND 2 THEN 80
        WHEN COUNT(ef.FAILURE_ID) BETWEEN 3 AND 5 THEN 60
        WHEN COUNT(ef.FAILURE_ID) BETWEEN 6 AND 10 THEN 40
        ELSE 20
    END as HEALTH_SCORE
FROM EQUIPMENT_ASSETS ea
LEFT JOIN EQUIPMENT_FAILURES ef ON ea.ASSET_ID = ef.ASSET_ID
GROUP BY 1,2,3,4,5,6,7,8,9;

-- Project portfolio view
CREATE OR REPLACE VIEW VW_PROJECT_PORTFOLIO AS
SELECT 
    PROJECT_ID,
    PROJECT_NAME,
    FIELD_NAME,
    PROJECT_TYPE,
    PROJECT_STATUS,
    BUDGETED_COST_USD,
    ACTUAL_COST_USD,
    COST_VARIANCE_PCT,
    EXPECTED_PRODUCTION_BOEPD,
    NPV_USD,
    IRR_PCT,
    PAYBACK_MONTHS,
    CASE 
        WHEN NPV_USD > 0 AND IRR_PCT > 15 THEN 'Excellent'
        WHEN NPV_USD > 0 AND IRR_PCT > 10 THEN 'Good'
        WHEN NPV_USD > 0 THEN 'Acceptable'
        ELSE 'Poor'
    END as ECONOMICS_RATING,
    DATEDIFF(day, PLANNED_START_DATE, COALESCE(ACTUAL_START_DATE, CURRENT_DATE())) as START_VARIANCE_DAYS,
    DATEDIFF(day, PLANNED_COMPLETION_DATE, COALESCE(ACTUAL_COMPLETION_DATE, CURRENT_DATE())) as COMPLETION_VARIANCE_DAYS
FROM DRILLING_PROJECTS;

-- Supply chain performance
CREATE OR REPLACE VIEW VW_VENDOR_PERFORMANCE AS
SELECT 
    VENDOR,
    MATERIAL_TYPE,
    COUNT(*) as TRANSACTION_COUNT,
    SUM(TOTAL_COST_USD) as TOTAL_SPEND_USD,
    AVG(LEAD_TIME_DAYS) as AVG_LEAD_TIME_DAYS,
    SUM(CASE WHEN ON_TIME_DELIVERY THEN 1 ELSE 0 END)::FLOAT / COUNT(*) * 100 as ON_TIME_DELIVERY_PCT,
    AVG(QUALITY_RATING) as AVG_QUALITY_RATING,
    COUNT(CASE WHEN CRITICALITY = 'Critical' THEN 1 END) as CRITICAL_ITEMS_COUNT
FROM SUPPLY_CHAIN
GROUP BY 1,2;

-- Reservoir performance tracking
CREATE OR REPLACE VIEW VW_RESERVOIR_PERFORMANCE AS
SELECT 
    r.RESERVOIR_ID,
    r.RESERVOIR_NAME,
    r.FIELD_NAME,
    r.RESERVOIR_TYPE,
    r.INITIAL_PRESSURE_PSI,
    r.CURRENT_PRESSURE_PSI,
    r.PRESSURE_DEPLETION_PCT,
    r.OOIP_MMSTB,
    r.RECOVERABLE_RESERVES_MMSTB,
    r.CUMULATIVE_PRODUCTION_MMSTB,
    r.REMAINING_RESERVES_MMSTB,
    r.RECOVERY_FACTOR_PCT,
    COUNT(DISTINCT w.WELL_ID) as WELL_COUNT,
    AVG(dp.BOE) as AVG_DAILY_PRODUCTION_BOE,
    SUM(dp.BOE) as CURRENT_CUMULATIVE_BOE
FROM RESERVOIR_DATA r
LEFT JOIN WELLS w ON r.RESERVOIR_NAME = w.RESERVOIR_NAME
LEFT JOIN DAILY_PRODUCTION dp ON w.WELL_ID = dp.WELL_ID
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12;

-- ============================================================================
-- Create sample queries for testing Cortex Analyst
-- ============================================================================

CREATE OR REPLACE TABLE CORTEX_SAMPLE_QUERIES (
    QUERY_ID VARCHAR(50),
    QUESTION VARCHAR(1000),
    CATEGORY VARCHAR(100),
    EXPECTED_TABLES VARCHAR(500),
    NOTES VARCHAR(1000)
);

INSERT INTO CORTEX_SAMPLE_QUERIES VALUES
('Q1', 'What are the top 10 wells by production efficiency in the last 30 days?', 
 'Production Optimization', 'VW_WELL_PERFORMANCE, DAILY_PRODUCTION', 
 'Shows best performing wells by BOE per day'),
 
('Q2', 'Which wells have the highest operating cost per BOE?', 
 'Cost Management', 'VW_WELL_ECONOMICS', 
 'Identifies high-cost wells for optimization'),
 
('Q3', 'Show me equipment with the highest failure rates and associated downtime', 
 'Equipment Reliability', 'VW_EQUIPMENT_HEALTH, EQUIPMENT_FAILURES', 
 'Critical for maintenance planning'),
 
('Q4', 'What is the current reservoir pressure trend across all fields?', 
 'Reservoir Performance', 'RESERVOIR_PRESSURE, RESERVOIR_DATA', 
 'Monitors reservoir depletion'),
 
('Q5', 'What are our safety incidents in the last 6 months by severity?', 
 'HSE Compliance', 'VW_HSE_METRICS, HSE_INCIDENTS', 
 'Tracks safety performance'),
 
('Q6', 'Which drilling projects have the best economics and why?', 
 'Capital Efficiency', 'VW_PROJECT_PORTFOLIO, DRILLING_PROJECTS', 
 'Guides capital allocation'),
 
('Q7', 'What is our 12-month production forecast based on current decline curves?', 
 'Production Forecasting', 'DAILY_PRODUCTION, WELLS', 
 'Requires time series analysis'),
 
('Q8', 'Which vendors have the worst on-time delivery performance?', 
 'Supply Chain', 'VW_VENDOR_PERFORMANCE, SUPPLY_CHAIN', 
 'Supply chain optimization'),
 
('Q9', 'What are our carbon emissions by field and how do they trend?', 
 'Emissions & ESG', 'VW_EMISSIONS_SUMMARY, EMISSIONS_DATA', 
 'ESG reporting and compliance'),
 
('Q10', 'Which undeveloped locations offer the best NPV and IRR?', 
 'Field Development', 'VW_PROJECT_PORTFOLIO, DRILLING_PROJECTS', 
 'Prioritizes development opportunities');

-- ============================================================================
-- Grant permissions for Cortex Analyst
-- ============================================================================

GRANT SELECT ON ALL VIEWS IN SCHEMA OIL_GAS_UPSTREAM_DEMO.OPERATIONS TO ROLE PUBLIC;

-- ============================================================================
-- Create metadata for better Cortex understanding
-- ============================================================================

CREATE OR REPLACE TABLE DATA_DICTIONARY (
    TABLE_NAME VARCHAR(100),
    COLUMN_NAME VARCHAR(100),
    BUSINESS_NAME VARCHAR(200),
    DESCRIPTION VARCHAR(1000),
    DATA_TYPE VARCHAR(50),
    SAMPLE_VALUES VARCHAR(500),
    BUSINESS_RULES VARCHAR(1000)
);

INSERT INTO DATA_DICTIONARY VALUES
('WELLS', 'WELL_ID', 'Well Identifier', 'Unique identifier for each well', 'VARCHAR', 'WELL-000001', 'Primary key'),
('WELLS', 'BOE', 'Barrels of Oil Equivalent', 'Standard unit combining oil and gas production', 'NUMBER', '100-5000', 'Oil BBL + (Gas MCF / 6)'),
('DAILY_PRODUCTION', 'OIL_BBL', 'Oil Production', 'Daily oil production in barrels', 'NUMBER', '0-1000', 'Declines over time'),
('WELL_OPERATIONS', 'OPEX_PER_BOE', 'Operating Cost per BOE', 'Operating expense per barrel of oil equivalent', 'NUMBER', '5-50', 'Lower is better'),
('EQUIPMENT_FAILURES', 'MTBF', 'Mean Time Between Failures', 'Average time between equipment failures', 'NUMBER', '100-500 days', 'Higher is better'),
('HSE_INCIDENTS', 'TRIR', 'Total Recordable Incident Rate', 'Safety incidents per 200,000 work hours', 'NUMBER', '0-5', 'Lower is better'),
('EMISSIONS_DATA', 'EMISSION_INTENSITY', 'Emissions Intensity', 'Tonnes CO2e per BOE produced', 'NUMBER', '0.01-0.5', 'Lower is better'),
('DRILLING_PROJECTS', 'NPV_USD', 'Net Present Value', 'Present value of future cash flows', 'NUMBER', '-5M to 50M', 'Higher is better'),
('DRILLING_PROJECTS', 'IRR_PCT', 'Internal Rate of Return', 'Annual return percentage', 'NUMBER', '-10 to 40', 'Target >15%'),
('RESERVOIR_DATA', 'RECOVERY_FACTOR_PCT', 'Recovery Factor', 'Percentage of OOIP that can be recovered', 'NUMBER', '20-50%', 'Depends on reservoir type');

-- ============================================================================
-- Summary
-- ============================================================================

SELECT 'Snowflake Intelligence setup completed!' as STATUS;
SELECT 'Aggregated views created: 9' as INFO;
SELECT 'Sample queries loaded: 10' as INFO;
SELECT 'Data dictionary entries: 10' as INFO;
SELECT '' as BLANK;
SELECT '============================================' as SEPARATOR;
SELECT 'NEXT STEP: Upload Semantic Model' as NEXT_STEP;
SELECT '============================================' as SEPARATOR;

-- Instructions for uploading semantic model
SELECT 'Upload the semantic_model.yaml file to enable Cortex Analyst:' as INSTRUCTION_1;
SELECT '' as BLANK;
SELECT 'Option 1 - Using SnowSQL:' as OPTION_1;
SELECT 'PUT file:///path/to/semantic_model.yaml @CORTEX_STAGE AUTO_COMPRESS=FALSE;' as COMMAND_1;
SELECT '' as BLANK;
SELECT 'Option 2 - Using Snowsight UI:' as OPTION_2;
SELECT '1. Go to Data > Databases > OIL_GAS_UPSTREAM_DEMO > OPERATIONS > Stages' as STEP_1;
SELECT '2. Click on CORTEX_STAGE' as STEP_2;
SELECT '3. Click "+ Files" button and upload semantic_model.yaml' as STEP_3;
SELECT '' as BLANK;
SELECT 'Option 3 - Using Python:' as OPTION_3;
SELECT 'session.file.put("semantic_model.yaml", "@CORTEX_STAGE", auto_compress=False)' as COMMAND_3;
SELECT '' as BLANK;
SELECT '============================================' as SEPARATOR;
SELECT 'After uploading, verify the file:' as VERIFICATION;
SELECT 'LIST @CORTEX_STAGE;' as VERIFY_COMMAND;
SELECT '' as BLANK;
SELECT '============================================' as SEPARATOR;
SELECT 'Using Cortex Analyst:' as USAGE;
SELECT '1. Open Snowsight and navigate to Projects > Cortex Analyst' as USAGE_1;
SELECT '2. Create new Analyst or select existing one' as USAGE_2;
SELECT '3. Reference the semantic model: @CORTEX_STAGE/semantic_model.yaml' as USAGE_3;
SELECT '4. Start asking questions in natural language!' as USAGE_4;
SELECT '' as BLANK;
SELECT 'Try asking: "What are my top performing wells?" or "Show safety incidents this year"' as EXAMPLE;


-- Display sample queries for reference
SELECT 
    QUERY_ID,
    QUESTION,
    CATEGORY
FROM CORTEX_SAMPLE_QUERIES
ORDER BY QUERY_ID;

