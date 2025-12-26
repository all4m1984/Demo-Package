/*============================================================================
   Oil & Gas Upstream Operations Demo - Data Loading
   
   Purpose: Generates realistic synthetic data for all tables
   Duration: ~2-3 minutes
   Records: 120,000+ across all tables
   
   Execute this script after 01_setup_environment.sql
============================================================================*/

USE DATABASE OIL_GAS_UPSTREAM_DEMO;
USE SCHEMA OPERATIONS;
USE WAREHOUSE DEMO_WH;

-- ============================================================================
-- 1. Load Wells Master Data (500 wells)
-- ============================================================================
INSERT INTO WELLS
WITH field_data AS (
    SELECT field_name, operator, ROW_NUMBER() OVER (ORDER BY field_name) as rownum
    FROM (VALUES
        ('Permian Basin', 'Eagle Oil LLC'),
        ('Permian Basin', 'Pioneer Resources'),
        ('Bakken Field', 'Continental Resources'),
        ('Bakken Field', 'Whiting Petroleum'),
        ('Eagle Ford', 'EOG Resources'),
        ('Eagle Ford', 'Marathon Oil'),
        ('Niobrara', 'PDC Energy'),
        ('DJ Basin', 'Extraction Oil'),
        ('SCOOP/STACK', 'Devon Energy'),
        ('Marcellus', 'Range Resources')
    ) AS t(field_name, operator)
),
formations AS (
    SELECT formation, reservoir_name, ROW_NUMBER() OVER (ORDER BY formation) as rownum
    FROM (VALUES
        ('Wolfcamp', 'Wolfcamp A'),
        ('Bone Spring', 'Bone Spring A'),
        ('Three Forks', 'Middle Three Forks'),
        ('Bakken', 'Middle Bakken'),
        ('Eagle Ford', 'Eagle Ford Shale'),
        ('Niobrara', 'Niobrara B'),
        ('Woodford', 'Woodford Shale'),
        ('Marcellus', 'Marcellus Shale')
    ) AS t(formation, reservoir_name)
),
seq AS (
    SELECT SEQ4() as id FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT
    'WELL-' || LPAD(s.id::VARCHAR, 6, '0') as WELL_ID,
    fd.field_name || '-' || LPAD(s.id::VARCHAR, 4, '0') as WELL_NAME,
    fd.field_name,
    fd.operator,
    CASE (s.id % 10)
        WHEN 0 THEN 'Vertical'
        WHEN 1 THEN 'Deviated'
        WHEN 2 THEN 'Deviated'
        ELSE 'Horizontal'
    END as WELL_TYPE,
    CASE (s.id % 20)
        WHEN 0 THEN 'Shut-in'
        WHEN 1 THEN 'Inactive'
        ELSE 'Active'
    END as WELL_STATUS,
    DATEADD(day, -UNIFORM(730, 3650, RANDOM()), CURRENT_DATE()) as SPUD_DATE,
    DATEADD(day, UNIFORM(30, 120, RANDOM()), 
            DATEADD(day, -UNIFORM(730, 3650, RANDOM()), CURRENT_DATE())) as COMPLETION_DATE,
    UNIFORM(8000, 15000, RANDOM())::NUMBER(10,2) as TOTAL_DEPTH_FT,
    UNIFORM(10000, 22000, RANDOM())::NUMBER(10,2) as MEASURED_DEPTH_FT,
    CASE 
        WHEN (s.id % 10) < 7 THEN UNIFORM(5000, 12000, RANDOM())::NUMBER(10,2)
        ELSE NULL
    END as LATERAL_LENGTH_FT,
    31.5 + (UNIFORM(-200, 200, RANDOM()) / 100.0) as SURFACE_LATITUDE,
    -102.3 + (UNIFORM(-300, 300, RANDOM()) / 100.0) as SURFACE_LONGITUDE,
    form.formation,
    form.reservoir_name,
    UNIFORM(3000000, 8000000, RANDOM())::NUMBER(15,2) as DRILLING_COST_USD,
    UNIFORM(2000000, 6000000, RANDOM())::NUMBER(15,2) as COMPLETION_COST_USD,
    UNIFORM(200000, 1500000, RANDOM())::NUMBER(15,2) as ESTIMATED_RESERVES_BOE,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM seq s
CROSS JOIN field_data fd
CROSS JOIN formations form
WHERE s.id % 50 = fd.rownum - 1
  AND s.id % 8 = form.rownum - 1
LIMIT 500;

SELECT 'Loaded ' || COUNT(*) || ' wells' FROM WELLS;

-- ============================================================================
-- 2. Load Daily Production Data (90 days x 500 wells = 45,000 records)
-- ============================================================================
INSERT INTO DAILY_PRODUCTION
WITH dates AS (
    SELECT DATEADD(day, -SEQ4(), CURRENT_DATE()) as prod_date
    FROM TABLE(GENERATOR(ROWCOUNT => 90))
),
well_data AS (
    SELECT WELL_ID, WELL_STATUS, WELL_TYPE, 
           DATEDIFF(day, COMPLETION_DATE, CURRENT_DATE()) as WELL_AGE_DAYS
    FROM WELLS
)
SELECT
    'PROD-' || w.WELL_ID || '-' || TO_CHAR(d.prod_date, 'YYYYMMDD') as PRODUCTION_ID,
    w.WELL_ID,
    d.prod_date as PRODUCTION_DATE,
    CASE 
        WHEN w.WELL_STATUS = 'Active' THEN 
            GREATEST(0, UNIFORM(50, 400, RANDOM()) * 
            (1 - (w.WELL_AGE_DAYS / 3650.0) * 0.4) * -- Decline curve
            (0.9 + UNIFORM(0, 20, RANDOM()) / 100.0)) -- Daily variance
        ELSE 0
    END::NUMBER(10,2) as OIL_BBL,
    CASE 
        WHEN w.WELL_STATUS = 'Active' THEN 
            GREATEST(0, UNIFORM(200, 2000, RANDOM()) * 
            (1 - (w.WELL_AGE_DAYS / 3650.0) * 0.35) *
            (0.9 + UNIFORM(0, 20, RANDOM()) / 100.0))
        ELSE 0
    END::NUMBER(10,2) as GAS_MCF,
    CASE 
        WHEN w.WELL_STATUS = 'Active' THEN 
            UNIFORM(20, 200, RANDOM()) * 
            (w.WELL_AGE_DAYS / 1825.0) -- Water cut increases over time
        ELSE 0
    END::NUMBER(10,2) as WATER_BBL,
    NULL as BOE, -- Will be calculated
    UNIFORM(800, 1500, RANDOM())::NUMBER(8,2) as TUBING_PRESSURE_PSI,
    UNIFORM(1000, 2000, RANDOM())::NUMBER(8,2) as CASING_PRESSURE_PSI,
    UNIFORM(12, 48, RANDOM())::NUMBER(5,2) as CHOKE_SIZE_64THS,
    CASE WHEN w.WELL_STATUS = 'Active' THEN UNIFORM(20, 24, RANDOM())
         ELSE 0 END::NUMBER(5,2) as RUNTIME_HOURS,
    CASE WHEN w.WELL_STATUS = 'Active' THEN UNIFORM(0, 4, RANDOM())
         ELSE 24 END::NUMBER(5,2) as DOWNTIME_HOURS,
    CASE (HASH(w.WELL_ID) % 4)
        WHEN 0 THEN 'Gas lift'
        WHEN 1 THEN 'ESP'
        WHEN 2 THEN 'Rod pump'
        ELSE 'Natural flow'
    END as PRODUCTION_METHOD,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM dates d
CROSS JOIN well_data w;

-- Calculate BOE (Barrels of Oil Equivalent: Oil + Gas/6)
UPDATE DAILY_PRODUCTION
SET BOE = OIL_BBL + (GAS_MCF / 6.0);

SELECT 'Loaded ' || COUNT(*) || ' daily production records' FROM DAILY_PRODUCTION;

-- ============================================================================
-- 3. Load Well Operations (30 per well over time = 15,000 records)
-- ============================================================================
INSERT INTO WELL_OPERATIONS
WITH well_list AS (
    SELECT WELL_ID, COMPLETION_DATE FROM WELLS
),
operations_per_well AS (
    SELECT 
        w.WELL_ID,
        w.COMPLETION_DATE,
        SEQ4() as op_seq
    FROM well_list w,
    TABLE(GENERATOR(ROWCOUNT => 30))
)
SELECT
    'OP-' || WELL_ID || '-' || LPAD(op_seq::VARCHAR, 4, '0') as OPERATION_ID,
    WELL_ID,
    DATEADD(day, UNIFORM(1, 1000, RANDOM()), COMPLETION_DATE) as OPERATION_DATE,
    CASE (op_seq % 10)
        WHEN 0 THEN 'Workover'
        WHEN 1 THEN 'Workover'
        WHEN 2 THEN 'Stimulation'
        WHEN 3 THEN 'Stimulation'
        WHEN 4 THEN 'Maintenance'
        WHEN 5 THEN 'Maintenance'
        WHEN 6 THEN 'Maintenance'
        WHEN 7 THEN 'Maintenance'
        ELSE 'Inspection'
    END as OPERATION_TYPE,
    CASE (op_seq % 10)
        WHEN 0 THEN 'Pump replacement and tubing repair'
        WHEN 1 THEN 'Wellhead valve maintenance'
        WHEN 2 THEN 'Acid stimulation treatment'
        WHEN 3 THEN 'Hydraulic fracturing enhancement'
        WHEN 4 THEN 'Routine preventive maintenance'
        WHEN 5 THEN 'Flow line inspection and repair'
        WHEN 6 THEN 'Separator maintenance'
        WHEN 7 THEN 'Electrical system check'
        ELSE 'Safety inspection and testing'
    END as OPERATION_DESCRIPTION,
    CASE (op_seq % 10)
        WHEN 0 THEN UNIFORM(24, 72, RANDOM())
        WHEN 1 THEN UNIFORM(24, 72, RANDOM())
        WHEN 2 THEN UNIFORM(12, 48, RANDOM())
        WHEN 3 THEN UNIFORM(12, 48, RANDOM())
        ELSE UNIFORM(2, 16, RANDOM())
    END::NUMBER(8,2) as DURATION_HOURS,
    UNIFORM(5000, 50000, RANDOM())::NUMBER(12,2) as LABOR_COST_USD,
    UNIFORM(10000, 100000, RANDOM())::NUMBER(12,2) as MATERIAL_COST_USD,
    UNIFORM(5000, 80000, RANDOM())::NUMBER(12,2) as EQUIPMENT_COST_USD,
    NULL as TOTAL_COST_USD, -- Will calculate
    CASE (HASH(WELL_ID, op_seq) % 20)
        WHEN 0 THEN 'Halliburton'
        WHEN 1 THEN 'Schlumberger'
        WHEN 2 THEN 'Baker Hughes'
        WHEN 3 THEN 'Weatherford'
        ELSE 'Internal crew'
    END as VENDOR,
    CASE WHEN (op_seq % 20) > 0 THEN TRUE ELSE FALSE END as SUCCESS_FLAG,
    CASE 
        WHEN (op_seq % 10) IN (0,1,2,3) THEN UNIFORM(500, 5000, RANDOM())
        ELSE NULL
    END::NUMBER(10,2) as PRODUCTION_IMPACT_BOE,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM operations_per_well;

UPDATE WELL_OPERATIONS
SET TOTAL_COST_USD = LABOR_COST_USD + MATERIAL_COST_USD + EQUIPMENT_COST_USD;

SELECT 'Loaded ' || COUNT(*) || ' well operations' FROM WELL_OPERATIONS;

-- ============================================================================
-- 4. Load Equipment Assets (4 per well = 2,000 records)
-- ============================================================================
INSERT INTO EQUIPMENT_ASSETS
WITH well_list AS (
    SELECT WELL_ID, COMPLETION_DATE FROM WELLS
),
assets_per_well AS (
    SELECT 
        w.WELL_ID,
        w.COMPLETION_DATE,
        SEQ4() as asset_seq
    FROM well_list w,
    TABLE(GENERATOR(ROWCOUNT => 4))
)
SELECT
    'ASSET-' || WELL_ID || '-' || LPAD(asset_seq::VARCHAR, 2, '0') as ASSET_ID,
    CASE (asset_seq % 4)
        WHEN 0 THEN 'ESP Motor - ' || WELL_ID
        WHEN 1 THEN 'Separator Unit - ' || WELL_ID
        WHEN 2 THEN 'Wellhead Assembly - ' || WELL_ID
        ELSE 'Flow Meter - ' || WELL_ID
    END as ASSET_NAME,
    CASE (asset_seq % 4)
        WHEN 0 THEN 'Pump'
        WHEN 1 THEN 'Separator'
        WHEN 2 THEN 'Wellhead'
        ELSE 'Meter'
    END as ASSET_TYPE,
    WELL_ID,
    'Facility-' || SUBSTR(WELL_ID, 6, 3) as FACILITY_NAME,
    CASE (asset_seq % 4)
        WHEN 0 THEN 'Schlumberger'
        WHEN 1 THEN 'Cameron'
        WHEN 2 THEN 'GE Oil & Gas'
        ELSE 'Emerson'
    END as MANUFACTURER,
    'Model-' || UNIFORM(1000, 9999, RANDOM()) as MODEL,
    'SN-' || UNIFORM(100000, 999999, RANDOM()) as SERIAL_NUMBER,
    DATEADD(day, UNIFORM(0, 30, RANDOM()), COMPLETION_DATE) as INSTALL_DATE,
    CASE (asset_seq % 4)
        WHEN 0 THEN 5
        WHEN 1 THEN 15
        WHEN 2 THEN 20
        ELSE 10
    END::NUMBER(5,2) as DESIGN_LIFE_YEARS,
    CASE (asset_seq % 4)
        WHEN 0 THEN UNIFORM(80000, 150000, RANDOM())
        WHEN 1 THEN UNIFORM(200000, 400000, RANDOM())
        WHEN 2 THEN UNIFORM(50000, 100000, RANDOM())
        ELSE UNIFORM(20000, 50000, RANDOM())
    END::NUMBER(15,2) as REPLACEMENT_COST_USD,
    DATEADD(day, -UNIFORM(30, 180, RANDOM()), CURRENT_DATE()) as LAST_MAINTENANCE_DATE,
    DATEADD(day, UNIFORM(30, 180, RANDOM()), CURRENT_DATE()) as NEXT_MAINTENANCE_DATE,
    CASE (HASH(WELL_ID, asset_seq) % 4)
        WHEN 0 THEN 'Critical'
        WHEN 1 THEN 'High'
        WHEN 2 THEN 'Medium'
        ELSE 'Low'
    END as CRITICALITY,
    CASE (HASH(WELL_ID, asset_seq) % 20)
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Degraded'
        WHEN 2 THEN 'Degraded'
        WHEN 3 THEN 'Maintenance'
        ELSE 'Operational'
    END as STATUS,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM assets_per_well;

SELECT 'Loaded ' || COUNT(*) || ' equipment assets' FROM EQUIPMENT_ASSETS;

-- ============================================================================
-- 5. Load Equipment Failures (10 per asset over time = 20,000 records potential)
-- Sample 5,000 failures
-- ============================================================================
INSERT INTO EQUIPMENT_FAILURES
WITH assets AS (
    SELECT ASSET_ID, WELL_ID, INSTALL_DATE, CRITICALITY FROM EQUIPMENT_ASSETS
),
failures_sample AS (
    SELECT 
        a.ASSET_ID,
        a.WELL_ID,
        a.INSTALL_DATE,
        a.CRITICALITY,
        SEQ4() as fail_seq
    FROM assets a,
    TABLE(GENERATOR(ROWCOUNT => 10))
    WHERE UNIFORM(0, 100, RANDOM()) < 25 -- 25% of potential failures
    LIMIT 5000
)
SELECT
    'FAIL-' || ASSET_ID || '-' || LPAD(fail_seq::VARCHAR, 3, '0') as FAILURE_ID,
    ASSET_ID,
    WELL_ID,
    DATEADD(day, UNIFORM(1, 800, RANDOM()), INSTALL_DATE) as FAILURE_DATE,
    CASE (fail_seq % 5)
        WHEN 0 THEN 'SCADA Alarm'
        WHEN 1 THEN 'Visual Inspection'
        WHEN 2 THEN 'Production Anomaly'
        WHEN 3 THEN 'Vibration Sensor'
        ELSE 'Temperature Alert'
    END as DETECTION_METHOD,
    CASE (fail_seq % 12)
        WHEN 0 THEN 'Bearing failure'
        WHEN 1 THEN 'Seal leakage'
        WHEN 2 THEN 'Motor burnout'
        WHEN 3 THEN 'Valve malfunction'
        WHEN 4 THEN 'Corrosion damage'
        WHEN 5 THEN 'Electrical failure'
        WHEN 6 THEN 'Mechanical wear'
        WHEN 7 THEN 'Control system fault'
        WHEN 8 THEN 'Pressure relief valve trip'
        WHEN 9 THEN 'Flow restriction'
        WHEN 10 THEN 'Instrumentation error'
        ELSE 'Structural fatigue'
    END as FAILURE_MODE,
    CASE (fail_seq % 8)
        WHEN 0 THEN 'Equipment age and wear'
        WHEN 1 THEN 'Inadequate maintenance'
        WHEN 2 THEN 'Operating beyond design limits'
        WHEN 3 THEN 'Manufacturing defect'
        WHEN 4 THEN 'Corrosive environment'
        WHEN 5 THEN 'Installation error'
        WHEN 6 THEN 'External damage'
        ELSE 'Unknown - under investigation'
    END as FAILURE_CAUSE,
    CASE 
        WHEN CRITICALITY = 'Critical' THEN 
            CASE (fail_seq % 3)
                WHEN 0 THEN 'Critical'
                ELSE 'Major'
            END
        WHEN CRITICALITY = 'High' THEN
            CASE (fail_seq % 3)
                WHEN 0 THEN 'Major'
                ELSE 'Minor'
            END
        ELSE 'Minor'
    END as SEVERITY,
    CASE 
        WHEN CRITICALITY = 'Critical' THEN UNIFORM(24, 168, RANDOM())
        WHEN CRITICALITY = 'High' THEN UNIFORM(8, 72, RANDOM())
        ELSE UNIFORM(1, 24, RANDOM())
    END::NUMBER(8,2) as DOWNTIME_HOURS,
    UNIFORM(5000, 150000, RANDOM())::NUMBER(12,2) as REPAIR_COST_USD,
    UNIFORM(100, 5000, RANDOM())::NUMBER(10,2) as PRODUCTION_LOSS_BOE,
    DATEADD(hour, 
            UNIFORM(4, 200, RANDOM()),
            DATEADD(day, UNIFORM(1, 800, RANDOM()), INSTALL_DATE)) as RESOLVED_DATE,
    CASE (fail_seq % 8)
        WHEN 0 THEN 'Equipment age and wear - end of life'
        WHEN 1 THEN 'Inadequate preventive maintenance schedule'
        WHEN 2 THEN 'Operating conditions exceeded design parameters'
        WHEN 3 THEN 'Manufacturing quality control issue'
        WHEN 4 THEN 'H2S and CO2 corrosion'
        WHEN 5 THEN 'Improper installation torque'
        WHEN 6 THEN 'Third-party physical damage'
        ELSE 'Root cause analysis in progress'
    END as ROOT_CAUSE,
    CASE (fail_seq % 6)
        WHEN 0 THEN 'Replace with upgraded component'
        WHEN 1 THEN 'Increase maintenance frequency'
        WHEN 2 THEN 'Install additional monitoring'
        WHEN 3 THEN 'Implement operating limits'
        WHEN 4 THEN 'Improve corrosion protection'
        ELSE 'Review and update procedures'
    END as CORRECTIVE_ACTION,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM failures_sample;

SELECT 'Loaded ' || COUNT(*) || ' equipment failures' FROM EQUIPMENT_FAILURES;

-- ============================================================================
-- 6. Load Reservoir Data (50 unique reservoirs)
-- ============================================================================
INSERT INTO RESERVOIR_DATA
WITH reservoirs AS (
    SELECT DISTINCT 
        RESERVOIR_NAME,
        FORMATION,
        FIELD_NAME
    FROM WELLS
    LIMIT 50
)
SELECT
    'RES-' || LPAD(ROW_NUMBER() OVER (ORDER BY RESERVOIR_NAME)::VARCHAR, 4, '0') as RESERVOIR_ID,
    RESERVOIR_NAME,
    FIELD_NAME,
    FORMATION,
    DATEADD(year, -UNIFORM(5, 15, RANDOM()), CURRENT_DATE()) as DISCOVERY_DATE,
    CASE (HASH(RESERVOIR_NAME) % 3)
        WHEN 0 THEN 'Gas'
        WHEN 1 THEN 'Condensate'
        ELSE 'Oil'
    END as RESERVOIR_TYPE,
    UNIFORM(3500, 6000, RANDOM())::NUMBER(8,2) as INITIAL_PRESSURE_PSI,
    UNIFORM(2000, 4000, RANDOM())::NUMBER(8,2) as CURRENT_PRESSURE_PSI,
    NULL as PRESSURE_DEPLETION_PCT,
    UNIFORM(8, 18, RANDOM())::NUMBER(5,2) as POROSITY_PCT,
    UNIFORM(10, 500, RANDOM())::NUMBER(10,2) as PERMEABILITY_MD,
    UNIFORM(60, 85, RANDOM())::NUMBER(5,2) as OIL_SATURATION_PCT,
    UNIFORM(15, 40, RANDOM())::NUMBER(5,2) as WATER_SATURATION_PCT,
    UNIFORM(50, 250, RANDOM())::NUMBER(8,2) as NET_PAY_FT,
    UNIFORM(5000, 50000, RANDOM())::NUMBER(10,2) as AREA_ACRES,
    UNIFORM(10, 200, RANDOM())::NUMBER(12,2) as OOIP_MMSTB,
    NULL as RECOVERABLE_RESERVES_MMSTB,
    UNIFORM(25, 45, RANDOM())::NUMBER(5,2) as RECOVERY_FACTOR_PCT,
    NULL as CUMULATIVE_PRODUCTION_MMSTB,
    NULL as REMAINING_RESERVES_MMSTB,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM reservoirs;

-- Calculate derived fields
UPDATE RESERVOIR_DATA
SET PRESSURE_DEPLETION_PCT = ((INITIAL_PRESSURE_PSI - CURRENT_PRESSURE_PSI) / INITIAL_PRESSURE_PSI * 100)::NUMBER(5,2),
    RECOVERABLE_RESERVES_MMSTB = (OOIP_MMSTB * RECOVERY_FACTOR_PCT / 100.0)::NUMBER(12,2);

UPDATE RESERVOIR_DATA
SET CUMULATIVE_PRODUCTION_MMSTB = (RECOVERABLE_RESERVES_MMSTB * UNIFORM(20, 60, RANDOM()) / 100.0)::NUMBER(12,2);

UPDATE RESERVOIR_DATA
SET REMAINING_RESERVES_MMSTB = (RECOVERABLE_RESERVES_MMSTB - CUMULATIVE_PRODUCTION_MMSTB)::NUMBER(12,2);

SELECT 'Loaded ' || COUNT(*) || ' reservoirs' FROM RESERVOIR_DATA;

-- ============================================================================
-- 7. Load Reservoir Pressure Data (50 measurements per well = 25,000 records)
-- ============================================================================
INSERT INTO RESERVOIR_PRESSURE
WITH wells_res AS (
    SELECT 
        w.WELL_ID,
        w.COMPLETION_DATE,
        r.RESERVOIR_ID,
        r.INITIAL_PRESSURE_PSI,
        r.CURRENT_PRESSURE_PSI
    FROM WELLS w
    JOIN RESERVOIR_DATA r ON w.RESERVOIR_NAME = r.RESERVOIR_NAME
    WHERE UNIFORM(0, 100, RANDOM()) < 50 -- Sample 50% of wells
    LIMIT 500
),
measurements AS (
    SELECT 
        wr.*,
        SEQ4() as meas_seq
    FROM wells_res wr,
    TABLE(GENERATOR(ROWCOUNT => 50))
)
SELECT
    'PRES-' || WELL_ID || '-' || LPAD(meas_seq::VARCHAR, 4, '0') as MEASUREMENT_ID,
    RESERVOIR_ID,
    WELL_ID,
    DATEADD(day, meas_seq * 20, COMPLETION_DATE) as MEASUREMENT_DATE,
    GREATEST(500, 
        LEAST(INITIAL_PRESSURE_PSI,
            INITIAL_PRESSURE_PSI - 
            (INITIAL_PRESSURE_PSI - CURRENT_PRESSURE_PSI) * (meas_seq / 50.0) * 
            (0.95 + UNIFORM(0, 10, RANDOM()) / 100.0)))::NUMBER(8,2) as PRESSURE_PSI,
    UNIFORM(150, 250, RANDOM())::NUMBER(6,2) as TEMPERATURE_F,
    UNIFORM(8000, 12000, RANDOM())::NUMBER(10,2) as MEASUREMENT_DEPTH_FT,
    CASE (meas_seq % 4)
        WHEN 0 THEN 'Gauge'
        WHEN 1 THEN 'Test'
        ELSE 'Simulation'
    END as MEASUREMENT_METHOD,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM measurements;

SELECT 'Loaded ' || COUNT(*) || ' reservoir pressure measurements' FROM RESERVOIR_PRESSURE;

-- ============================================================================
-- 8. Load HSE Incidents (1,200 incidents)
-- ============================================================================
INSERT INTO HSE_INCIDENTS
WITH incidents AS (
    SELECT SEQ4() as inc_id FROM TABLE(GENERATOR(ROWCOUNT => 1200))
),
wells_sample AS (
    SELECT WELL_ID, ROW_NUMBER() OVER (ORDER BY WELL_ID) - 1 as well_row 
    FROM WELLS 
    ORDER BY RANDOM() 
    LIMIT 300
)
SELECT
    'HSE-' || LPAD(i.inc_id::VARCHAR, 6, '0') as INCIDENT_ID,
    DATEADD(day, -UNIFORM(1, 730, RANDOM()), CURRENT_DATE()) as INCIDENT_DATE,
    'Facility-' || LPAD(UNIFORM(1, 100, RANDOM())::VARCHAR, 3, '0') as FACILITY_NAME,
    w.WELL_ID,
    CASE (i.inc_id % 10)
        WHEN 0 THEN 'Safety'
        WHEN 1 THEN 'Safety'
        WHEN 2 THEN 'Safety'
        WHEN 3 THEN 'Environmental'
        WHEN 4 THEN 'Environmental'
        WHEN 5 THEN 'Environmental'
        ELSE 'Near-miss'
    END as INCIDENT_TYPE,
    CASE (i.inc_id % 15)
        WHEN 0 THEN 'Oil Spill'
        WHEN 1 THEN 'Gas Release'
        WHEN 2 THEN 'Slip/Trip/Fall'
        WHEN 3 THEN 'Hand Injury'
        WHEN 4 THEN 'Equipment Struck-by'
        WHEN 5 THEN 'Chemical Exposure'
        WHEN 6 THEN 'Fire'
        WHEN 7 THEN 'Vehicle Incident'
        WHEN 8 THEN 'Confined Space'
        WHEN 9 THEN 'Electrical Shock'
        WHEN 10 THEN 'Water Spill'
        WHEN 11 THEN 'Noise Exposure'
        WHEN 12 THEN 'Heat Stress'
        ELSE 'Near-miss Observation'
    END as INCIDENT_CATEGORY,
    CASE (i.inc_id % 30)
        WHEN 0 THEN 'Fatal'
        WHEN 1 THEN 'Serious'
        WHEN 2 THEN 'Serious'
        WHEN 3 THEN 'Minor'
        WHEN 4 THEN 'Minor'
        WHEN 5 THEN 'Minor'
        WHEN 6 THEN 'Minor'
        ELSE 'Near-miss'
    END as SEVERITY,
    'Incident description for HSE-' || LPAD(i.inc_id::VARCHAR, 6, '0') as DESCRIPTION,
    CASE (i.inc_id % 30)
        WHEN 0 THEN 1
        WHEN 1 THEN 1
        WHEN 2 THEN 1
        WHEN 3 THEN 0
        WHEN 4 THEN 0
        WHEN 5 THEN 0
        WHEN 6 THEN 0
        ELSE 0
    END as INJURIES,
    CASE (i.inc_id % 30)
        WHEN 0 THEN 1
        ELSE 0
    END as FATALITIES,
    CASE 
        WHEN (i.inc_id % 15) IN (0, 10) THEN UNIFORM(1, 50, RANDOM())::NUMBER(10,2)
        ELSE 0
    END as VOLUME_SPILLED_BBL,
    CASE (i.inc_id % 30)
        WHEN 0 THEN TRUE
        WHEN 1 THEN TRUE
        WHEN 2 THEN TRUE
        ELSE FALSE
    END as REGULATORY_REPORTABLE,
    CASE (i.inc_id % 30)
        WHEN 0 THEN UNIFORM(90, 180, RANDOM())
        WHEN 1 THEN UNIFORM(1, 30, RANDOM())
        WHEN 2 THEN UNIFORM(1, 30, RANDOM())
        ELSE 0
    END as DAYS_AWAY_FROM_WORK,
    UNIFORM(1000, 500000, RANDOM())::NUMBER(12,2) as ESTIMATED_COST_USD,
    'Root cause analysis completed' as ROOT_CAUSE,
    'Corrective actions implemented' as CORRECTIVE_ACTIONS,
    CASE (i.inc_id % 5)
        WHEN 0 THEN 'Open'
        WHEN 1 THEN 'Investigating'
        ELSE 'Closed'
    END as INVESTIGATION_STATUS,
    CASE 
        WHEN (i.inc_id % 5) > 1 THEN DATEADD(day, UNIFORM(30, 90, RANDOM()), 
                                             DATEADD(day, -UNIFORM(1, 730, RANDOM()), CURRENT_DATE()))
        ELSE NULL
    END as CLOSED_DATE,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM incidents i
LEFT JOIN wells_sample w ON (i.inc_id % 300) = w.well_row;

SELECT 'Loaded ' || COUNT(*) || ' HSE incidents' FROM HSE_INCIDENTS;

-- ============================================================================
-- 9. Load Drilling Projects (150 projects)
-- ============================================================================
INSERT INTO DRILLING_PROJECTS
WITH projects AS (
    SELECT 
        SEQ4() as proj_id,
        WELL_ID,
        FIELD_NAME
    FROM (SELECT WELL_ID, FIELD_NAME FROM WELLS ORDER BY RANDOM() LIMIT 150) w,
    TABLE(GENERATOR(ROWCOUNT => 1))
)
SELECT
    'PROJ-' || LPAD(proj_id::VARCHAR, 5, '0') as PROJECT_ID,
    FIELD_NAME || ' Development Phase ' || (proj_id % 5 + 1) as PROJECT_NAME,
    WELL_ID,
    FIELD_NAME,
    CASE (proj_id % 8)
        WHEN 0 THEN 'New drill'
        WHEN 1 THEN 'New drill'
        WHEN 2 THEN 'New drill'
        WHEN 3 THEN 'New drill'
        WHEN 4 THEN 'Workover'
        WHEN 5 THEN 'Workover'
        WHEN 6 THEN 'Facility'
        ELSE 'Pipeline'
    END as PROJECT_TYPE,
    CASE (proj_id % 10)
        WHEN 0 THEN 'Planned'
        WHEN 1 THEN 'Planned'
        WHEN 2 THEN 'In Progress'
        WHEN 3 THEN 'In Progress'
        WHEN 4 THEN 'Completed'
        WHEN 5 THEN 'Completed'
        WHEN 6 THEN 'Completed'
        WHEN 7 THEN 'Completed'
        WHEN 8 THEN 'Completed'
        ELSE 'Cancelled'
    END as PROJECT_STATUS,
    DATEADD(day, -UNIFORM(365, 730, RANDOM()), CURRENT_DATE()) as PLANNED_START_DATE,
    CASE 
        WHEN (proj_id % 10) > 1 THEN DATEADD(day, UNIFORM(-30, 30, RANDOM()), 
                                              DATEADD(day, -UNIFORM(365, 730, RANDOM()), CURRENT_DATE()))
        ELSE NULL
    END as ACTUAL_START_DATE,
    DATEADD(day, UNIFORM(90, 180, RANDOM()), 
            DATEADD(day, -UNIFORM(365, 730, RANDOM()), CURRENT_DATE())) as PLANNED_COMPLETION_DATE,
    CASE 
        WHEN (proj_id % 10) IN (4,5,6,7,8) THEN 
            DATEADD(day, UNIFORM(100, 200, RANDOM()), 
                    DATEADD(day, -UNIFORM(365, 730, RANDOM()), CURRENT_DATE()))
        ELSE NULL
    END as ACTUAL_COMPLETION_DATE,
    UNIFORM(5000000, 15000000, RANDOM())::NUMBER(15,2) as BUDGETED_COST_USD,
    CASE 
        WHEN (proj_id % 10) IN (4,5,6,7,8) THEN 
            UNIFORM(4500000, 17000000, RANDOM())::NUMBER(15,2)
        ELSE NULL
    END as ACTUAL_COST_USD,
    NULL as COST_VARIANCE_PCT,
    UNIFORM(200, 800, RANDOM())::NUMBER(10,2) as EXPECTED_PRODUCTION_BOEPD,
    UNIFORM(300000, 1200000, RANDOM())::NUMBER(15,2) as EXPECTED_EUR_BOE,
    UNIFORM(-2000000, 25000000, RANDOM())::NUMBER(15,2) as NPV_USD,
    UNIFORM(-5, 35, RANDOM())::NUMBER(5,2) as IRR_PCT,
    UNIFORM(18, 60, RANDOM())::NUMBER(5,2) as PAYBACK_MONTHS,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM projects;

UPDATE DRILLING_PROJECTS
SET COST_VARIANCE_PCT = CASE 
    WHEN ACTUAL_COST_USD IS NOT NULL AND BUDGETED_COST_USD > 0 
    THEN ((ACTUAL_COST_USD - BUDGETED_COST_USD) / BUDGETED_COST_USD * 100)::NUMBER(5,2)
    ELSE NULL
END;

SELECT 'Loaded ' || COUNT(*) || ' drilling projects' FROM DRILLING_PROJECTS;

-- ============================================================================
-- 10. Load Supply Chain Data (10,000 transactions)
-- ============================================================================
INSERT INTO SUPPLY_CHAIN
WITH transactions AS (
    SELECT SEQ4() as trans_id FROM TABLE(GENERATOR(ROWCOUNT => 10000))
),
wells_sample AS (
    SELECT WELL_ID, ROW_NUMBER() OVER (ORDER BY WELL_ID) - 1 as well_row FROM WELLS
),
projects_sample AS (
    SELECT PROJECT_ID, ROW_NUMBER() OVER (ORDER BY PROJECT_ID) - 1 as proj_row FROM DRILLING_PROJECTS
)
SELECT
    'SC-' || LPAD(t.trans_id::VARCHAR, 7, '0') as TRANSACTION_ID,
    DATEADD(day, -UNIFORM(1, 365, RANDOM()), CURRENT_DATE()) as TRANSACTION_DATE,
    CASE (t.trans_id % 20)
        WHEN 0 THEN 'Casing'
        WHEN 1 THEN 'Casing'
        WHEN 2 THEN 'Casing'
        WHEN 3 THEN 'Tubing'
        WHEN 4 THEN 'Tubing'
        WHEN 5 THEN 'Chemicals'
        WHEN 6 THEN 'Chemicals'
        WHEN 7 THEN 'Chemicals'
        WHEN 8 THEN 'Pump Parts'
        WHEN 9 THEN 'Pump Parts'
        WHEN 10 THEN 'Valves'
        WHEN 11 THEN 'Valves'
        WHEN 12 THEN 'Sensors'
        WHEN 13 THEN 'Sensors'
        WHEN 14 THEN 'Proppant'
        WHEN 15 THEN 'Drill Bits'
        WHEN 16 THEN 'Cement'
        ELSE 'General Supplies'
    END as MATERIAL_TYPE,
    'Material description for transaction ' || t.trans_id as MATERIAL_DESCRIPTION,
    CASE (t.trans_id % 12)
        WHEN 0 THEN 'Tenaris'
        WHEN 1 THEN 'Vallourec'
        WHEN 2 THEN 'National Oilwell Varco'
        WHEN 3 THEN 'Baker Hughes'
        WHEN 4 THEN 'Halliburton'
        WHEN 5 THEN 'Schlumberger'
        WHEN 6 THEN 'Weatherford'
        WHEN 7 THEN 'Cameron'
        WHEN 8 THEN 'FMC Technologies'
        WHEN 9 THEN 'GE Oil & Gas'
        ELSE 'Regional Supplier'
    END as VENDOR,
    UNIFORM(1, 1000, RANDOM())::NUMBER(10,2) as QUANTITY,
    CASE (t.trans_id % 20)
        WHEN 0 THEN 'Feet'
        WHEN 1 THEN 'Feet'
        WHEN 2 THEN 'Feet'
        WHEN 3 THEN 'Feet'
        WHEN 4 THEN 'Feet'
        WHEN 5 THEN 'Gallons'
        WHEN 6 THEN 'Gallons'
        WHEN 7 THEN 'Gallons'
        WHEN 16 THEN 'Gallons'
        WHEN 14 THEN 'Tons'
        ELSE 'Each'
    END as UNIT_OF_MEASURE,
    UNIFORM(10, 10000, RANDOM())::NUMBER(12,2) as UNIT_COST_USD,
    NULL as TOTAL_COST_USD,
    w.WELL_ID,
    CASE WHEN (t.trans_id % 5) = 0 THEN p.PROJECT_ID ELSE NULL END as PROJECT_ID,
    DATEADD(day, UNIFORM(7, 45, RANDOM()), 
            DATEADD(day, -UNIFORM(1, 365, RANDOM()), CURRENT_DATE())) as DELIVERY_DATE,
    UNIFORM(5, 60, RANDOM())::NUMBER(5) as LEAD_TIME_DAYS,
    CASE WHEN UNIFORM(0, 100, RANDOM()) < 85 THEN TRUE ELSE FALSE END as ON_TIME_DELIVERY,
    (3 + UNIFORM(0, 200, RANDOM()) / 100.0)::NUMBER(3,2) as QUALITY_RATING,
    UNIFORM(0, 5000, RANDOM())::NUMBER(10,2) as STOCK_LEVEL,
    UNIFORM(100, 1000, RANDOM())::NUMBER(10,2) as REORDER_POINT,
    CASE (t.trans_id % 4)
        WHEN 0 THEN 'Critical'
        WHEN 1 THEN 'High'
        WHEN 2 THEN 'Medium'
        ELSE 'Low'
    END as CRITICALITY,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM transactions t
LEFT JOIN wells_sample w ON (t.trans_id % 500) = w.well_row
LEFT JOIN projects_sample p ON (t.trans_id % 150) = p.proj_row;

UPDATE SUPPLY_CHAIN
SET TOTAL_COST_USD = QUANTITY * UNIT_COST_USD;

SELECT 'Loaded ' || COUNT(*) || ' supply chain transactions' FROM SUPPLY_CHAIN;

-- ============================================================================
-- 11. Load Emissions Data (18,000 records - daily per well for 90 days sample)
-- ============================================================================
INSERT INTO EMISSIONS_DATA
WITH dates AS (
    SELECT DATEADD(day, -SEQ4(), CURRENT_DATE()) as emission_date
    FROM TABLE(GENERATOR(ROWCOUNT => 90))
),
wells_sample AS (
    SELECT WELL_ID, FIELD_NAME FROM WELLS WHERE WELL_STATUS = 'Active' LIMIT 200
),
emissions_base AS (
    SELECT 
        d.emission_date,
        w.WELL_ID,
        w.FIELD_NAME,
        SEQ4() as emission_type_id
    FROM dates d
    CROSS JOIN wells_sample w,
    TABLE(GENERATOR(ROWCOUNT => 1))
)
SELECT
    'EMIS-' || WELL_ID || '-' || TO_CHAR(emission_date, 'YYYYMMDD') || '-' || emission_type_id as EMISSION_ID,
    emission_date as MEASUREMENT_DATE,
    'Facility-' || SUBSTR(WELL_ID, 6, 3) as FACILITY_NAME,
    WELL_ID,
    CASE (emission_type_id % 5)
        WHEN 0 THEN 'CO2'
        WHEN 1 THEN 'Methane'
        WHEN 2 THEN 'VOC'
        WHEN 3 THEN 'NOx'
        ELSE 'Flaring'
    END as EMISSION_TYPE,
    CASE (emission_type_id % 4)
        WHEN 0 THEN 'Combustion'
        WHEN 1 THEN 'Venting'
        WHEN 2 THEN 'Flaring'
        ELSE 'Fugitive'
    END as EMISSION_SOURCE,
    UNIFORM(0.5, 15, RANDOM())::NUMBER(12,4) as QUANTITY_TONNES,
    NULL as QUANTITY_CO2E_TONNES,
    CASE (emission_type_id % 3)
        WHEN 0 THEN 'Direct'
        WHEN 1 THEN 'Calculated'
        ELSE 'Estimated'
    END as MEASUREMENT_METHOD,
    UNIFORM(100, 500, RANDOM())::NUMBER(10,2) as PRODUCTION_BOE,
    NULL as EMISSION_INTENSITY,
    UNIFORM(10, 100, RANDOM())::NUMBER(12,4) as REGULATORY_LIMIT,
    'Compliant' as COMPLIANCE_STATUS,
    NULL as MITIGATION_ACTIONS,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM emissions_base
LIMIT 18000;

-- Calculate CO2 equivalent (GWP factors: CO2=1, Methane=25, VOC=3, NOx=10, Flaring=1)
UPDATE EMISSIONS_DATA
SET QUANTITY_CO2E_TONNES = CASE EMISSION_TYPE
    WHEN 'CO2' THEN QUANTITY_TONNES * 1
    WHEN 'Methane' THEN QUANTITY_TONNES * 25
    WHEN 'VOC' THEN QUANTITY_TONNES * 3
    WHEN 'NOx' THEN QUANTITY_TONNES * 10
    WHEN 'Flaring' THEN QUANTITY_TONNES * 1
    ELSE QUANTITY_TONNES
END;

UPDATE EMISSIONS_DATA
SET EMISSION_INTENSITY = CASE 
    WHEN PRODUCTION_BOE > 0 THEN (QUANTITY_CO2E_TONNES / PRODUCTION_BOE)
    ELSE 0
END;

UPDATE EMISSIONS_DATA
SET COMPLIANCE_STATUS = CASE 
    WHEN QUANTITY_CO2E_TONNES > REGULATORY_LIMIT * 1.1 THEN 'Violation'
    WHEN QUANTITY_CO2E_TONNES > REGULATORY_LIMIT * 0.9 THEN 'Warning'
    ELSE 'Compliant'
END;

SELECT 'Loaded ' || COUNT(*) || ' emissions records' FROM EMISSIONS_DATA;

-- ============================================================================
-- Final Summary
-- ============================================================================
SELECT '============================================' as SUMMARY;
SELECT 'DATA LOADING COMPLETE' as STATUS;
SELECT '============================================' as SUMMARY;
SELECT 'Wells: ' || COUNT(*) || ' records' as TABLE_SUMMARY FROM WELLS
UNION ALL
SELECT 'Daily Production: ' || COUNT(*) || ' records' FROM DAILY_PRODUCTION
UNION ALL
SELECT 'Well Operations: ' || COUNT(*) || ' records' FROM WELL_OPERATIONS
UNION ALL
SELECT 'Equipment Assets: ' || COUNT(*) || ' records' FROM EQUIPMENT_ASSETS
UNION ALL
SELECT 'Equipment Failures: ' || COUNT(*) || ' records' FROM EQUIPMENT_FAILURES
UNION ALL
SELECT 'Reservoir Data: ' || COUNT(*) || ' records' FROM RESERVOIR_DATA
UNION ALL
SELECT 'Reservoir Pressure: ' || COUNT(*) || ' records' FROM RESERVOIR_PRESSURE
UNION ALL
SELECT 'HSE Incidents: ' || COUNT(*) || ' records' FROM HSE_INCIDENTS
UNION ALL
SELECT 'Drilling Projects: ' || COUNT(*) || ' records' FROM DRILLING_PROJECTS
UNION ALL
SELECT 'Supply Chain: ' || COUNT(*) || ' records' FROM SUPPLY_CHAIN
UNION ALL
SELECT 'Emissions Data: ' || COUNT(*) || ' records' FROM EMISSIONS_DATA;

SELECT 'Total Records: ' || (
    (SELECT COUNT(*) FROM WELLS) +
    (SELECT COUNT(*) FROM DAILY_PRODUCTION) +
    (SELECT COUNT(*) FROM WELL_OPERATIONS) +
    (SELECT COUNT(*) FROM EQUIPMENT_ASSETS) +
    (SELECT COUNT(*) FROM EQUIPMENT_FAILURES) +
    (SELECT COUNT(*) FROM RESERVOIR_DATA) +
    (SELECT COUNT(*) FROM RESERVOIR_PRESSURE) +
    (SELECT COUNT(*) FROM HSE_INCIDENTS) +
    (SELECT COUNT(*) FROM DRILLING_PROJECTS) +
    (SELECT COUNT(*) FROM SUPPLY_CHAIN) +
    (SELECT COUNT(*) FROM EMISSIONS_DATA)
) as GRAND_TOTAL;

SELECT 'Ready for Snowflake Intelligence demo!' as NEXT_STEP;

