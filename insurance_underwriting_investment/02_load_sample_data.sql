-- ============================================================================
-- SNOWFLAKE INTELLIGENCE DEMO: INSURANCE UNDERWRITING & INVESTMENT MANAGEMENT
-- Script 2: Sample Data Loading (Southeast Asia Edition)
-- ============================================================================
-- Purpose: Generates realistic synthetic insurance data for Southeast Asia
-- Market: Singapore, Malaysia, Indonesia, Thailand, Philippines, Vietnam
-- Execution Time: 2-4 minutes (depends on warehouse size)
-- Records Generated: 100,000+
-- ============================================================================

USE DATABASE INSURANCE_DEMO;
USE SCHEMA UNDERWRITING_INV;
USE WAREHOUSE DEMO_WH;

-- ============================================================================
-- 1. PRODUCTS - Insurance product line definitions
-- ============================================================================

INSERT INTO PRODUCTS (PRODUCT_ID, PRODUCT_NAME, PRODUCT_TYPE, PRODUCT_CATEGORY, 
                      TARGET_LOSS_RATIO, TARGET_EXPENSE_RATIO, IS_ACTIVE, LAUNCH_DATE, DESCRIPTION)
VALUES
('PROD-001', 'Personal Auto Liability', 'Personal Auto', 'Casualty', 65.00, 25.00, TRUE, '2015-01-01', 'Personal automobile liability coverage'),
('PROD-002', 'Personal Auto Physical Damage', 'Personal Auto', 'Property', 68.00, 23.00, TRUE, '2015-01-01', 'Personal automobile physical damage coverage'),
('PROD-003', 'Commercial Auto', 'Commercial Auto', 'Casualty', 70.00, 26.00, TRUE, '2016-06-01', 'Commercial automobile coverage'),
('PROD-004', 'Homeowners', 'Homeowners', 'Property', 58.00, 28.00, TRUE, '2014-01-01', 'Residential property coverage'),
('PROD-005', 'Commercial Property', 'Commercial Property', 'Property', 55.00, 30.00, TRUE, '2016-01-01', 'Commercial property coverage'),
('PROD-006', 'General Liability', 'General Liability', 'Casualty', 72.00, 25.00, TRUE, '2015-01-01', 'General liability coverage for businesses'),
('PROD-007', 'Workers Compensation', 'Workers Comp', 'Casualty', 75.00, 20.00, TRUE, '2017-01-01', 'Workers compensation coverage'),
('PROD-008', 'Professional Liability', 'Professional Liability', 'Specialty', 68.00, 27.00, TRUE, '2018-01-01', 'Errors and omissions coverage'),
('PROD-009', 'Umbrella', 'Umbrella', 'Specialty', 45.00, 18.00, TRUE, '2015-01-01', 'Excess liability coverage'),
('PROD-010', 'Cyber Liability', 'Cyber', 'Specialty', 62.00, 32.00, FALSE, '2020-01-01', 'Cyber risk coverage (discontinued)');

SELECT 'Products loaded: ' || COUNT(*) || ' records' as STATUS FROM PRODUCTS;

-- ============================================================================
-- 2. UNDERWRITERS - Underwriter information
-- ============================================================================

INSERT INTO UNDERWRITERS
WITH
regions AS (
    SELECT 'Singapore' as region UNION ALL SELECT 'Malaysia' UNION ALL 
    SELECT 'Indonesia' UNION ALL SELECT 'Thailand' UNION ALL 
    SELECT 'Philippines' UNION ALL SELECT 'Vietnam'
),
experience_levels AS (
    SELECT 'Junior' as level, 1 as min_years, 3 as max_years UNION ALL
    SELECT 'Mid', 4, 7 UNION ALL
    SELECT 'Senior', 8, 15 UNION ALL
    SELECT 'Principal', 16, 30
),
specializations AS (
    SELECT 'Personal Auto' as spec UNION ALL SELECT 'Commercial Lines' UNION ALL
    SELECT 'Property' UNION ALL SELECT 'Casualty' UNION ALL SELECT 'Specialty'
),
name_combos AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY r.region, e.level, s.spec) as id,
        r.region,
        e.level as experience_level,
        e.min_years + (ABS(RANDOM()) % (e.max_years - e.min_years + 1)) as years_exp,
        s.spec as specialization
    FROM regions r
    CROSS JOIN experience_levels e
    CROSS JOIN specializations s
),
underwriter_seq AS (
    SELECT SEQ4() + 1 as seq_num
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT
    'UW-' || LPAD(us.seq_num::VARCHAR, 5, '0') as UNDERWRITER_ID,
    CASE (us.seq_num % 30)
        WHEN 0 THEN 'Wei' WHEN 1 THEN 'Ahmad' WHEN 2 THEN 'Budi'
        WHEN 3 THEN 'Siti' WHEN 4 THEN 'Tan' WHEN 5 THEN 'Maria'
        WHEN 6 THEN 'Nguyen' WHEN 7 THEN 'Somchai' WHEN 8 THEN 'Rina'
        WHEN 9 THEN 'Kumar' WHEN 10 THEN 'Li' WHEN 11 THEN 'Dewi'
        WHEN 12 THEN 'Hassan' WHEN 13 THEN 'Putri' WHEN 14 THEN 'Arjun'
        WHEN 15 THEN 'Mei' WHEN 16 THEN 'Ravi' WHEN 17 THEN 'Anh'
        WHEN 18 THEN 'Nurul' WHEN 19 THEN 'Chen' WHEN 20 THEN 'Priya'
        WHEN 21 THEN 'Devi' WHEN 22 THEN 'Hasan' WHEN 23 THEN 'Ming'
        WHEN 24 THEN 'Pong' WHEN 25 THEN 'Ling' WHEN 26 THEN 'Farah'
        WHEN 27 THEN 'Rizal' WHEN 28 THEN 'Yuki' ELSE 'Zain'
    END as FIRST_NAME,
    CASE (us.seq_num % 30)
        WHEN 0 THEN 'Tan' WHEN 1 THEN 'Abdullah' WHEN 2 THEN 'Santoso'
        WHEN 3 THEN 'Wong' WHEN 4 THEN 'Lim' WHEN 5 THEN 'Santos'
        WHEN 6 THEN 'Tran' WHEN 7 THEN 'Patel' WHEN 8 THEN 'Lee'
        WHEN 9 THEN 'Chan' WHEN 10 THEN 'Ibrahim' WHEN 11 THEN 'Kumar'
        WHEN 12 THEN 'Nguyen' WHEN 13 THEN 'Singh' WHEN 14 THEN 'Sharma'
        WHEN 15 THEN 'Chen' WHEN 16 THEN 'Ismail' WHEN 17 THEN 'Wijaya'
        WHEN 18 THEN 'Ong' WHEN 19 THEN 'Rahman' WHEN 20 THEN 'Garcia'
        WHEN 21 THEN 'Yap' WHEN 22 THEN 'Chong' WHEN 23 THEN 'Koh'
        WHEN 24 THEN 'Suryanto' WHEN 25 THEN 'Pham' WHEN 26 THEN 'Reyes'
        WHEN 27 THEN 'Zubair' WHEN 28 THEN 'Ramos' ELSE 'Liu'
    END as LAST_NAME,
    nc.region,
    nc.experience_level,
    nc.years_exp,
    nc.specialization,
    DATEADD(day, -(nc.years_exp * 365 + (ABS(RANDOM()) % 365)), CURRENT_DATE()) as HIRE_DATE,
    CASE WHEN us.seq_num <= 480 THEN TRUE ELSE FALSE END as IS_ACTIVE,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM underwriter_seq us
LEFT JOIN name_combos nc ON nc.id = ((us.seq_num - 1) % (SELECT COUNT(*) FROM name_combos)) + 1;

SELECT 'Underwriters loaded: ' || COUNT(*) || ' records' as STATUS FROM UNDERWRITERS;

-- ============================================================================
-- 3. POLICYHOLDERS - Customer information
-- ============================================================================

INSERT INTO POLICYHOLDERS
WITH
countries AS (
    SELECT 'SG' as state, 0.15 as pct UNION ALL SELECT 'MY', 0.25 UNION ALL
    SELECT 'ID', 0.30 UNION ALL SELECT 'TH', 0.12 UNION ALL
    SELECT 'PH', 0.10 UNION ALL SELECT 'VN', 0.08
),
policyholder_seq AS (
    SELECT SEQ4() + 1 as seq_num
    FROM TABLE(GENERATOR(ROWCOUNT => 10000))
)
SELECT
    'PH-' || LPAD(ps.seq_num::VARCHAR, 6, '0') as POLICYHOLDER_ID,
    CASE (ps.seq_num % 30)
        WHEN 0 THEN 'Wei' WHEN 1 THEN 'Ahmad' WHEN 2 THEN 'Budi'
        WHEN 3 THEN 'Siti' WHEN 4 THEN 'Tan' WHEN 5 THEN 'Maria'
        WHEN 6 THEN 'Nguyen' WHEN 7 THEN 'Somchai' WHEN 8 THEN 'Rina'
        WHEN 9 THEN 'Kumar' WHEN 10 THEN 'Li' WHEN 11 THEN 'Dewi'
        WHEN 12 THEN 'Hassan' WHEN 13 THEN 'Putri' WHEN 14 THEN 'Arjun'
        WHEN 15 THEN 'Mei' WHEN 16 THEN 'Ravi' WHEN 17 THEN 'Anh'
        WHEN 18 THEN 'Nurul' WHEN 19 THEN 'Chen' WHEN 20 THEN 'Priya'
        WHEN 21 THEN 'Devi' WHEN 22 THEN 'Hasan' WHEN 23 THEN 'Ming'
        WHEN 24 THEN 'Pong' WHEN 25 THEN 'Ling' WHEN 26 THEN 'Farah'
        WHEN 27 THEN 'Rizal' WHEN 28 THEN 'Yuki' ELSE 'Zain'
    END as FIRST_NAME,
    CASE (ps.seq_num % 30)
        WHEN 0 THEN 'Tan' WHEN 1 THEN 'Abdullah' WHEN 2 THEN 'Santoso'
        WHEN 3 THEN 'Wong' WHEN 4 THEN 'Lim' WHEN 5 THEN 'Santos'
        WHEN 6 THEN 'Tran' WHEN 7 THEN 'Patel' WHEN 8 THEN 'Lee'
        WHEN 9 THEN 'Chan' WHEN 10 THEN 'Ibrahim' WHEN 11 THEN 'Kumar'
        WHEN 12 THEN 'Nguyen' WHEN 13 THEN 'Singh' WHEN 14 THEN 'Sharma'
        WHEN 15 THEN 'Chen' WHEN 16 THEN 'Ismail' WHEN 17 THEN 'Wijaya'
        WHEN 18 THEN 'Ong' WHEN 19 THEN 'Rahman' WHEN 20 THEN 'Garcia'
        WHEN 21 THEN 'Yap' WHEN 22 THEN 'Chong' WHEN 23 THEN 'Koh'
        WHEN 24 THEN 'Suryanto' WHEN 25 THEN 'Pham' WHEN 26 THEN 'Reyes'
        WHEN 27 THEN 'Zubair' WHEN 28 THEN 'Ramos' ELSE 'Liu'
    END as LAST_NAME,
    DATEADD(year, -(25 + (ABS(RANDOM()) % 40)), CURRENT_DATE()) as DATE_OF_BIRTH,
    CASE WHEN (ABS(RANDOM()) % 2) = 0 THEN 'Male' ELSE 'Female' END as GENDER,
    (SELECT state FROM countries ORDER BY RANDOM() LIMIT 1) as STATE,
    CASE (ABS(RANDOM()) % 6)
        WHEN 0 THEN LPAD((100000 + (ABS(RANDOM()) % 900000))::VARCHAR, 6, '0')  -- SG format
        WHEN 1 THEN LPAD((10000 + (ABS(RANDOM()) % 90000))::VARCHAR, 5, '0')    -- MY format
        WHEN 2 THEN LPAD((10000 + (ABS(RANDOM()) % 90000))::VARCHAR, 5, '0')    -- ID format
        WHEN 3 THEN LPAD((10000 + (ABS(RANDOM()) % 90000))::VARCHAR, 5, '0')    -- TH format
        WHEN 4 THEN LPAD((1000 + (ABS(RANDOM()) % 9000))::VARCHAR, 4, '0')      -- PH format
        ELSE LPAD((100000 + (ABS(RANDOM()) % 900000))::VARCHAR, 6, '0')         -- VN format
    END as ZIP_CODE,
    550 + (ABS(RANDOM()) % 251) as CREDIT_SCORE,  -- 550-800
    30 + (ABS(RANDOM()) % 61) as RISK_SCORE,  -- 30-90
    CASE 
        WHEN (ABS(RANDOM()) % 100) < 30 THEN 'Preferred'
        WHEN (ABS(RANDOM()) % 100) < 75 THEN 'Standard'
        ELSE 'Non-Standard'
    END as CUSTOMER_SEGMENT,
    CASE (ABS(RANDOM()) % 4)
        WHEN 0 THEN 'Agent' WHEN 1 THEN 'Direct'
        WHEN 2 THEN 'Broker' ELSE 'Online'
    END as ACQUISITION_CHANNEL,
    DATEADD(day, -(365 + (ABS(RANDOM()) % 2190)), CURRENT_DATE()) as CUSTOMER_SINCE_DATE,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM policyholder_seq ps;

SELECT 'Policyholders loaded: ' || COUNT(*) || ' records' as STATUS FROM POLICYHOLDERS;
-- ============================================================================
-- 4. POLICIES - Policy details
-- ============================================================================

INSERT INTO POLICIES (
    POLICY_ID, POLICY_NUMBER, POLICYHOLDER_ID, PRODUCT_ID, UNDERWRITER_ID,
    POLICY_STATUS, EFFECTIVE_DATE, EXPIRATION_DATE, ANNUAL_PREMIUM, COVERAGE_LIMIT,
    DEDUCTIBLE, STATE, REGION, ISSUE_DATE, CANCELLATION_DATE
)
WITH
active_products AS (
    SELECT PRODUCT_ID, PRODUCT_TYPE, PRODUCT_CATEGORY,
           ROW_NUMBER() OVER (ORDER BY PRODUCT_ID) as prod_row
    FROM PRODUCTS WHERE IS_ACTIVE = TRUE
),
policy_seq AS (
    SELECT SEQ4() + 1 as seq_num
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))
),
policyholders_sample AS (
    SELECT POLICYHOLDER_ID, STATE, RISK_SCORE,
           ROW_NUMBER() OVER (ORDER BY POLICYHOLDER_ID) as ph_row
    FROM POLICYHOLDERS
),
underwriters_sample AS (
    SELECT UNDERWRITER_ID, REGION,
           ROW_NUMBER() OVER (ORDER BY UNDERWRITER_ID) as uw_row
    FROM UNDERWRITERS
    WHERE IS_ACTIVE = TRUE
)
SELECT
    'POL-' || LPAD(ps.seq_num::VARCHAR, 7, '0') as POLICY_ID,
    'P' || LPAD(ps.seq_num::VARCHAR, 10, '0') as POLICY_NUMBER,
    ph.POLICYHOLDER_ID,
    ap.PRODUCT_ID,
    uw.UNDERWRITER_ID,
    CASE 
        WHEN ps.seq_num % 20 = 0 THEN 'Expired'
        WHEN ps.seq_num % 30 = 0 THEN 'Cancelled'
        ELSE 'Active'
    END as POLICY_STATUS,
    DATEADD(day, -((ABS(RANDOM()) % 1095)), CURRENT_DATE()) as EFFECTIVE_DATE,
    DATEADD(day, 365, DATEADD(day, -((ABS(RANDOM()) % 1095)), CURRENT_DATE())) as EXPIRATION_DATE,
    CASE ap.PRODUCT_TYPE
        WHEN 'Personal Auto' THEN 1200 + (ABS(RANDOM()) % 1801) + (ph.RISK_SCORE * 10)
        WHEN 'Commercial Auto' THEN 3000 + (ABS(RANDOM()) % 7001) + (ph.RISK_SCORE * 20)
        WHEN 'Homeowners' THEN 1500 + (ABS(RANDOM()) % 2501) + (ph.RISK_SCORE * 15)
        WHEN 'Commercial Property' THEN 5000 + (ABS(RANDOM()) % 15001) + (ph.RISK_SCORE * 30)
        WHEN 'General Liability' THEN 2500 + (ABS(RANDOM()) % 7501)
        WHEN 'Workers Comp' THEN 4000 + (ABS(RANDOM()) % 11001)
        WHEN 'Professional Liability' THEN 3500 + (ABS(RANDOM()) % 8501)
        ELSE 800 + (ABS(RANDOM()) % 1201)
    END as ANNUAL_PREMIUM,
    CASE ap.PRODUCT_TYPE
        WHEN 'Personal Auto' THEN 250000 + (ABS(RANDOM()) % 250001)
        WHEN 'Commercial Auto' THEN 1000000 + (ABS(RANDOM()) % 4000001)
        WHEN 'Homeowners' THEN 300000 + (ABS(RANDOM()) % 700001)
        WHEN 'Commercial Property' THEN 1000000 + (ABS(RANDOM()) % 9000001)
        WHEN 'General Liability' THEN 1000000 + (ABS(RANDOM()) % 4000001)
        WHEN 'Workers Comp' THEN 500000 + (ABS(RANDOM()) % 4500001)
        WHEN 'Professional Liability' THEN 1000000 + (ABS(RANDOM()) % 4000001)
        ELSE 1000000 + (ABS(RANDOM()) % 9000001)
    END as COVERAGE_LIMIT,
    CASE ap.PRODUCT_CATEGORY
        WHEN 'Property' THEN 500 + (ABS(RANDOM()) % 4501)  -- 500-5000
        WHEN 'Casualty' THEN 1000 + (ABS(RANDOM()) % 9001)  -- 1000-10000
        ELSE 2500 + (ABS(RANDOM()) % 7501)  -- 2500-10000
    END as DEDUCTIBLE,
    ph.STATE,
    CASE 
        WHEN ph.STATE = 'SG' THEN 'Singapore'
        WHEN ph.STATE = 'MY' THEN 'Malaysia'
        WHEN ph.STATE = 'ID' THEN 'Indonesia'
        WHEN ph.STATE = 'TH' THEN 'Thailand'
        WHEN ph.STATE = 'PH' THEN 'Philippines'
        WHEN ph.STATE = 'VN' THEN 'Vietnam'
        ELSE 'Singapore'
    END as REGION,
    DATEADD(day, -3, DATEADD(day, -((ABS(RANDOM()) % 1095)), CURRENT_DATE())) as ISSUE_DATE,
    CASE 
        WHEN ps.seq_num % 30 = 0 THEN DATEADD(day, (ABS(RANDOM()) % 365), DATEADD(day, -((ABS(RANDOM()) % 1095)), CURRENT_DATE()))
        ELSE NULL
    END as CANCELLATION_DATE
FROM policy_seq ps
LEFT JOIN active_products ap ON ap.prod_row = ((ps.seq_num - 1) % (SELECT COUNT(*) FROM PRODUCTS WHERE IS_ACTIVE = TRUE)) + 1
LEFT JOIN policyholders_sample ph ON ph.ph_row = ((ps.seq_num - 1) % (SELECT COUNT(*) FROM POLICYHOLDERS)) + 1
LEFT JOIN underwriters_sample uw ON uw.uw_row = ((ps.seq_num - 1) % (SELECT COUNT(*) FROM UNDERWRITERS WHERE IS_ACTIVE = TRUE)) + 1;

SELECT 'Policies loaded: ' || COUNT(*) || ' records' as STATUS FROM POLICIES;

-- ============================================================================
-- 5. PREMIUMS - Premium transactions
-- ============================================================================

INSERT INTO PREMIUMS (
    PREMIUM_ID, POLICY_ID, TRANSACTION_DATE, TRANSACTION_TYPE,
    WRITTEN_PREMIUM, EARNED_PREMIUM, UNEARNED_PREMIUM,
    COMMISSION_AMOUNT, COMMISSION_RATE, ACCOUNTING_MONTH
)
WITH
policies_data AS (
    SELECT 
        POLICY_ID,
        EFFECTIVE_DATE,
        EXPIRATION_DATE,
        ANNUAL_PREMIUM,
        POLICY_STATUS
    FROM POLICIES
),
months_series AS (
    SELECT 
        DATEADD(month, -SEQ4(), DATE_TRUNC('month', CURRENT_DATE())) as month_date
    FROM TABLE(GENERATOR(ROWCOUNT => 36))
    WHERE SEQ4() < 36
),
policy_months AS (
    SELECT 
        pd.POLICY_ID,
        ms.month_date,
        pd.ANNUAL_PREMIUM,
        pd.EFFECTIVE_DATE,
        pd.POLICY_STATUS,
        ROW_NUMBER() OVER (PARTITION BY pd.POLICY_ID ORDER BY ms.month_date) as month_num
    FROM policies_data pd
    CROSS JOIN months_series ms
    WHERE ms.month_date >= DATE_TRUNC('month', pd.EFFECTIVE_DATE)
        AND ms.month_date <= DATE_TRUNC('month', CURRENT_DATE())
)
SELECT
    'PREM-' || pm.POLICY_ID || '-' || TO_CHAR(pm.month_date, 'YYYYMM') as PREMIUM_ID,
    pm.POLICY_ID,
    pm.month_date as TRANSACTION_DATE,
    CASE 
        WHEN pm.month_num = 1 THEN 'New Business'
        WHEN pm.month_num % 12 = 1 AND pm.month_num > 1 THEN 'Renewal'
        WHEN (ABS(RANDOM()) % 50) = 0 THEN 'Endorsement'
        ELSE 'Standard'
    END as TRANSACTION_TYPE,
    CASE 
        WHEN pm.month_num = 1 THEN pm.ANNUAL_PREMIUM
        WHEN pm.month_num % 12 = 1 AND pm.month_num > 1 THEN pm.ANNUAL_PREMIUM * 1.03  -- 3% renewal increase
        WHEN (ABS(RANDOM()) % 50) = 0 THEN (ABS(RANDOM()) % 501)  -- Endorsement
        ELSE 0
    END as WRITTEN_PREMIUM,
    ROUND(pm.ANNUAL_PREMIUM / 12.0, 2) as EARNED_PREMIUM,
    ROUND(pm.ANNUAL_PREMIUM * (1 - (pm.month_num % 12) / 12.0), 2) as UNEARNED_PREMIUM,
    ROUND((pm.ANNUAL_PREMIUM / 12.0) * 0.12, 2) as COMMISSION_AMOUNT,  -- 12% commission
    12.00 as COMMISSION_RATE,
    pm.month_date as ACCOUNTING_MONTH
FROM policy_months pm
WHERE (ABS(RANDOM()) % 10) < 9;  -- Sample 90% of possible records

SELECT 'Premiums loaded: ' || COUNT(*) || ' records' as STATUS FROM PREMIUMS;
-- ============================================================================
-- 6. CLAIMS - Claims data
-- ============================================================================

INSERT INTO CLAIMS (
    CLAIM_ID, CLAIM_NUMBER, POLICY_ID, CLAIM_STATUS, CLAIM_TYPE,
    DATE_OF_LOSS, DATE_REPORTED, DATE_CLOSED, CLAIM_AMOUNT,
    PAID_AMOUNT, RESERVE_AMOUNT, SALVAGE_AMOUNT, REINSURANCE_RECOVERY,
    SEVERITY_CATEGORY, AT_FAULT, ADJUSTER_ID, CREATED_DATE
)
WITH
policies_sample AS (
    SELECT 
        p.POLICY_ID,
        p.PRODUCT_ID,
        p.EFFECTIVE_DATE,
        p.EXPIRATION_DATE,
        p.ANNUAL_PREMIUM,
        p.COVERAGE_LIMIT,
        pr.PRODUCT_TYPE,
        pr.TARGET_LOSS_RATIO
    FROM POLICIES p
    JOIN PRODUCTS pr ON p.PRODUCT_ID = pr.PRODUCT_ID
    WHERE p.POLICY_STATUS = 'Active'
),
claims_seq AS (
    SELECT SEQ4() + 1 as seq_num
    FROM TABLE(GENERATOR(ROWCOUNT => 15000))
),
policies_with_row AS (
    SELECT *, ROW_NUMBER() OVER (ORDER BY POLICY_ID) as pol_row
    FROM policies_sample
)
SELECT
    'CLM-' || LPAD(cs.seq_num::VARCHAR, 7, '0') as CLAIM_ID,
    'C' || LPAD(cs.seq_num::VARCHAR, 10, '0') as CLAIM_NUMBER,
    pwr.POLICY_ID,
    CASE 
        WHEN (ABS(RANDOM()) % 10) < 7 THEN 'Closed'
        WHEN (ABS(RANDOM()) % 10) < 9 THEN 'Open'
        ELSE 'Reopened'
    END as CLAIM_STATUS,
    CASE pwr.PRODUCT_TYPE
        WHEN 'Personal Auto' THEN 
            CASE (ABS(RANDOM()) % 5)
                WHEN 0 THEN 'Collision' WHEN 1 THEN 'Comprehensive'
                WHEN 2 THEN 'Bodily Injury' WHEN 3 THEN 'Property Damage'
                ELSE 'Uninsured Motorist'
            END
        WHEN 'Commercial Auto' THEN 
            CASE (ABS(RANDOM()) % 4)
                WHEN 0 THEN 'Collision' WHEN 1 THEN 'Liability'
                WHEN 2 THEN 'Cargo Loss' ELSE 'Physical Damage'
            END
        WHEN 'Homeowners' THEN 
            CASE (ABS(RANDOM()) % 5)
                WHEN 0 THEN 'Fire' WHEN 1 THEN 'Theft'
                WHEN 2 THEN 'Water Damage' WHEN 3 THEN 'Wind/Hail'
                ELSE 'Liability'
            END
        WHEN 'Commercial Property' THEN 
            CASE (ABS(RANDOM()) % 4)
                WHEN 0 THEN 'Fire' WHEN 1 THEN 'Theft'
                WHEN 2 THEN 'Business Interruption' ELSE 'Equipment Breakdown'
            END
        WHEN 'General Liability' THEN 
            CASE (ABS(RANDOM()) % 3)
                WHEN 0 THEN 'Bodily Injury' WHEN 1 THEN 'Property Damage'
                ELSE 'Personal Injury'
            END
        WHEN 'Workers Comp' THEN 
            CASE (ABS(RANDOM()) % 4)
                WHEN 0 THEN 'Medical Only' WHEN 1 THEN 'Lost Time'
                WHEN 2 THEN 'Permanent Disability' ELSE 'Death'
            END
        WHEN 'Professional Liability' THEN 
            CASE (ABS(RANDOM()) % 3)
                WHEN 0 THEN 'Negligence' WHEN 1 THEN 'Errors and Omissions'
                ELSE 'Breach of Duty'
            END
        ELSE 'Other'
    END as CLAIM_TYPE,
    DATEADD(day, 
            (ABS(RANDOM()) % GREATEST(1, DATEDIFF(day, pwr.EFFECTIVE_DATE, LEAST(pwr.EXPIRATION_DATE, CURRENT_DATE())))), 
            pwr.EFFECTIVE_DATE) as DATE_OF_LOSS,
    DATEADD(day, 
            1 + (ABS(RANDOM()) % 30), 
            DATEADD(day, 
                    (ABS(RANDOM()) % GREATEST(1, DATEDIFF(day, pwr.EFFECTIVE_DATE, LEAST(pwr.EXPIRATION_DATE, CURRENT_DATE())))), 
                    pwr.EFFECTIVE_DATE)) as DATE_REPORTED,
    CASE 
        WHEN (ABS(RANDOM()) % 10) < 7 THEN 
            DATEADD(day, 
                    30 + (ABS(RANDOM()) % 180), 
                    DATEADD(day, 
                            (ABS(RANDOM()) % GREATEST(1, DATEDIFF(day, pwr.EFFECTIVE_DATE, LEAST(pwr.EXPIRATION_DATE, CURRENT_DATE())))), 
                            pwr.EFFECTIVE_DATE))
        ELSE NULL
    END as DATE_CLOSED,
    ROUND(
        (pwr.ANNUAL_PREMIUM * pwr.TARGET_LOSS_RATIO / 100.0) * 
        CASE (ABS(RANDOM()) % 10)
            WHEN 0 THEN 0.1  -- Small claim
            WHEN 1 THEN 0.2
            WHEN 2 THEN 0.3
            WHEN 3 THEN 0.5
            WHEN 4 THEN 0.8
            WHEN 5 THEN 1.0
            WHEN 6 THEN 1.5
            WHEN 7 THEN 2.5
            WHEN 8 THEN 5.0  -- Large claim
            ELSE 10.0  -- Very large claim
        END,
        2
    ) as CLAIM_AMOUNT,
    NULL as PAID_AMOUNT,  -- Will be calculated after
    NULL as RESERVE_AMOUNT,  -- Will be calculated after
    CASE WHEN (ABS(RANDOM()) % 20) = 0 THEN ROUND((ABS(RANDOM()) % 5001), 2) ELSE 0 END as SALVAGE_AMOUNT,
    CASE WHEN (ABS(RANDOM()) % 30) = 0 THEN ROUND((ABS(RANDOM()) % 10001), 2) ELSE 0 END as REINSURANCE_RECOVERY,
    CASE 
        WHEN cs.seq_num % 100 < 70 THEN 'Low'
        WHEN cs.seq_num % 100 < 90 THEN 'Medium'
        WHEN cs.seq_num % 100 < 98 THEN 'High'
        ELSE 'Catastrophic'
    END as SEVERITY_CATEGORY,
    CASE WHEN (ABS(RANDOM()) % 3) = 0 THEN FALSE ELSE TRUE END as AT_FAULT,
    'ADJ-' || LPAD((1 + (ABS(RANDOM()) % 100))::VARCHAR, 5, '0') as ADJUSTER_ID,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM claims_seq cs
LEFT JOIN policies_with_row pwr ON pwr.pol_row = ((cs.seq_num - 1) % (SELECT COUNT(*) FROM policies_sample)) + 1;

-- Update PAID_AMOUNT and RESERVE_AMOUNT based on CLAIM_STATUS
UPDATE CLAIMS
SET 
    PAID_AMOUNT = CASE 
        WHEN CLAIM_STATUS = 'Closed' THEN CLAIM_AMOUNT
        WHEN CLAIM_STATUS = 'Open' THEN ROUND(CLAIM_AMOUNT * (0.3 + (ABS(RANDOM()) % 41) / 100.0), 2)  -- 30-70% paid
        ELSE ROUND(CLAIM_AMOUNT * (0.5 + (ABS(RANDOM()) % 31) / 100.0), 2)  -- 50-80% paid
    END,
    RESERVE_AMOUNT = CASE 
        WHEN CLAIM_STATUS = 'Closed' THEN 0
        WHEN CLAIM_STATUS = 'Open' THEN ROUND(CLAIM_AMOUNT * (0.3 + (ABS(RANDOM()) % 41) / 100.0), 2)
        ELSE ROUND(CLAIM_AMOUNT * (0.2 + (ABS(RANDOM()) % 31) / 100.0), 2)
    END;

SELECT 'Claims loaded: ' || COUNT(*) || ' records' as STATUS FROM CLAIMS;

-- ============================================================================
-- 7. RESERVES - Loss reserves
-- ============================================================================

INSERT INTO RESERVES (
    RESERVE_ID, CLAIM_ID, RESERVE_DATE, CASE_RESERVE, IBNR_RESERVE,
    TOTAL_RESERVE, RESERVE_TYPE, ACTUARY_ID, CONFIDENCE_LEVEL, CREATED_DATE
)
WITH
open_claims AS (
    SELECT 
        CLAIM_ID,
        DATE_REPORTED,
        CLAIM_AMOUNT,
        RESERVE_AMOUNT
    FROM CLAIMS
    WHERE CLAIM_STATUS IN ('Open', 'Reopened')
),
reserve_dates AS (
    SELECT 
        oc.CLAIM_ID,
        oc.DATE_REPORTED,
        oc.CLAIM_AMOUNT,
        oc.RESERVE_AMOUNT,
        DATEADD(month, rs.seq_num * 3, oc.DATE_REPORTED) as reserve_date,
        rs.seq_num as reserve_seq
    FROM open_claims oc
    CROSS JOIN (
        SELECT SEQ4() as seq_num
        FROM TABLE(GENERATOR(ROWCOUNT => 5))
        WHERE SEQ4() < 5
    ) rs
    WHERE DATEADD(month, rs.seq_num * 3, oc.DATE_REPORTED) <= CURRENT_DATE()
)
SELECT
    'RSV-' || rd.CLAIM_ID || '-' || rd.reserve_seq as RESERVE_ID,
    rd.CLAIM_ID,
    rd.reserve_date as RESERVE_DATE,
    ROUND(rd.RESERVE_AMOUNT * (0.7 + (ABS(RANDOM()) % 31) / 100.0), 2) as CASE_RESERVE,
    ROUND(rd.RESERVE_AMOUNT * (0.2 + (ABS(RANDOM()) % 21) / 100.0), 2) as IBNR_RESERVE,
    rd.RESERVE_AMOUNT as TOTAL_RESERVE,
    CASE 
        WHEN rd.reserve_seq = 0 THEN 'Initial'
        WHEN rd.reserve_seq >= 4 THEN 'Final'
        ELSE 'Subsequent'
    END as RESERVE_TYPE,
    'ACT-' || LPAD((1 + (ABS(RANDOM()) % 20))::VARCHAR, 5, '0') as ACTUARY_ID,
    CASE 
        WHEN rd.reserve_seq <= 1 THEN 75.00
        WHEN rd.reserve_seq <= 3 THEN 85.00
        ELSE 90.00
    END as CONFIDENCE_LEVEL,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM reserve_dates rd;

SELECT 'Reserves loaded: ' || COUNT(*) || ' records' as STATUS FROM RESERVES;

-- ============================================================================
-- 8. INVESTMENTS - Portfolio holdings
-- ============================================================================

INSERT INTO INVESTMENTS (
    INVESTMENT_ID, SECURITY_ID, SECURITY_NAME, ASSET_CLASS, SECURITY_TYPE,
    SECTOR, RATING, QUANTITY, PURCHASE_DATE, PURCHASE_PRICE,
    COST_BASIS, CURRENT_PRICE, MARKET_VALUE, UNREALIZED_GAIN_LOSS,
    COUPON_RATE, YIELD_TO_MATURITY, DURATION, MATURITY_DATE,
    CURRENCY, PORTFOLIO_NAME, CREATED_DATE
)
WITH
asset_classes AS (
    SELECT 'Corporate Bonds' as asset_class, 'Bond' as sec_type, 0.45 as target_alloc UNION ALL
    SELECT 'Municipal Bonds', 'Bond', 0.15 UNION ALL
    SELECT 'Government Bonds', 'Bond', 0.20 UNION ALL
    SELECT 'Mortgage-Backed Securities', 'MBS', 0.08 UNION ALL
    SELECT 'Common Stock', 'Stock', 0.07 UNION ALL
    SELECT 'Preferred Stock', 'Stock', 0.03 UNION ALL
    SELECT 'Real Estate', 'REIT', 0.02
),
sectors AS (
    SELECT 'Financials' as sector UNION ALL SELECT 'Technology' UNION ALL
    SELECT 'Healthcare' UNION ALL SELECT 'Consumer' UNION ALL
    SELECT 'Industrials' UNION ALL SELECT 'Utilities' UNION ALL
    SELECT 'Energy' UNION ALL SELECT 'Materials'
),
ratings AS (
    SELECT 'AAA' as rating, 0.20 as pct UNION ALL SELECT 'AA+', 0.15 UNION ALL
    SELECT 'AA', 0.15 UNION ALL SELECT 'AA-', 0.15 UNION ALL
    SELECT 'A+', 0.12 UNION ALL SELECT 'A', 0.12 UNION ALL
    SELECT 'A-', 0.08 UNION ALL SELECT 'BBB+', 0.03
),
investment_seq AS (
    SELECT SEQ4() + 1 as seq_num
    FROM TABLE(GENERATOR(ROWCOUNT => 500))
)
SELECT
    'INV-' || LPAD(inv_seq.seq_num::VARCHAR, 6, '0') as INVESTMENT_ID,
    'SEC-' || LPAD(inv_seq.seq_num::VARCHAR, 8, '0') as SECURITY_ID,
    CASE ac.asset_class
        WHEN 'Corporate Bonds' THEN 
            (SELECT sector FROM sectors ORDER BY RANDOM() LIMIT 1) || ' Corp ' || 
            (2 + (ABS(RANDOM()) % 8)) || '.' || (ABS(RANDOM()) % 1000) || '% ' || 
            (2025 + (ABS(RANDOM()) % 11))
        WHEN 'Municipal Bonds' THEN 
            'Muni Bond ' || (ABS(RANDOM()) % 50) || ' ' || (2 + (ABS(RANDOM()) % 6)) || '% ' || (2025 + (ABS(RANDOM()) % 16))
        WHEN 'Government Bonds' THEN 
            'US Treasury ' || (1 + (ABS(RANDOM()) % 5)) || '% ' || (2025 + (ABS(RANDOM()) % 11))
        WHEN 'Mortgage-Backed Securities' THEN 
            'MBS Pool ' || LPAD((ABS(RANDOM()) % 10000)::VARCHAR, 6, '0')
        WHEN 'Common Stock' THEN 
            (SELECT sector FROM sectors ORDER BY RANDOM() LIMIT 1) || ' Company ' || (ABS(RANDOM()) % 1000)
        WHEN 'Preferred Stock' THEN 
            (SELECT sector FROM sectors ORDER BY RANDOM() LIMIT 1) || ' Preferred ' || (ABS(RANDOM() % 100))
        ELSE 'Real Estate Investment Trust ' || (ABS(RANDOM()) % 50)
    END as SECURITY_NAME,
    ac.asset_class as ASSET_CLASS,
    ac.sec_type as SECURITY_TYPE,
    (SELECT sector FROM sectors ORDER BY RANDOM() LIMIT 1) as SECTOR,
    CASE 
        WHEN ac.sec_type IN ('Bond', 'MBS') THEN (SELECT rating FROM ratings ORDER BY RANDOM() LIMIT 1)
        ELSE NULL
    END as RATING,
    CASE 
        WHEN ac.sec_type IN ('Bond', 'MBS') THEN 1000 + (ABS(RANDOM()) % 9001)  -- Bonds: 1,000-10,000 units
        ELSE 100 + (ABS(RANDOM()) % 9901)  -- Stocks: 100-10,000 shares
    END as QUANTITY,
    DATEADD(day, -(365 + (ABS(RANDOM()) % 1825)), CURRENT_DATE()) as PURCHASE_DATE,
    CASE 
        WHEN ac.sec_type IN ('Bond', 'MBS') THEN 95 + (ABS(RANDOM()) % 11)  -- Bonds: $95-105 per $100 face
        ELSE 20 + (ABS(RANDOM()) % 281)  -- Stocks: $20-300 per share
    END as PURCHASE_PRICE,
    NULL as COST_BASIS,  -- Will calculate
    CASE 
        WHEN ac.sec_type IN ('Bond', 'MBS') THEN 96 + (ABS(RANDOM()) % 9)  -- Current: $96-104
        ELSE 25 + (ABS(RANDOM()) % 276)  -- Stocks: $25-300
    END as CURRENT_PRICE,
    NULL as MARKET_VALUE,  -- Will calculate
    NULL as UNREALIZED_GAIN_LOSS,  -- Will calculate
    CASE 
        WHEN ac.sec_type IN ('Bond', 'MBS') THEN 2.50 + (ABS(RANDOM()) % 551) / 100.0  -- 2.5%-8.0%
        ELSE NULL
    END as COUPON_RATE,
    CASE 
        WHEN ac.sec_type IN ('Bond', 'MBS') THEN 2.80 + (ABS(RANDOM()) % 531) / 100.0  -- 2.8%-8.1%
        WHEN ac.sec_type = 'Stock' THEN 1.00 + (ABS(RANDOM()) % 401) / 100.0  -- 1.0%-5.0% dividend yield
        ELSE NULL
    END as YIELD_TO_MATURITY,
    CASE 
        WHEN ac.sec_type IN ('Bond', 'MBS') THEN 2.0 + (ABS(RANDOM()) % 1201) / 100.0  -- 2.0-14.0 years
        ELSE NULL
    END as DURATION,
    CASE 
        WHEN ac.sec_type IN ('Bond', 'MBS') THEN 
            DATEADD(year, 3 + (ABS(RANDOM()) % 23), CURRENT_DATE())  -- 3-25 years
        ELSE NULL
    END as MATURITY_DATE,
    'USD' as CURRENCY,
    CASE 
        WHEN (ABS(RANDOM()) % 10) < 6 THEN 'General'
        ELSE 'Liability-Matched'
    END as PORTFOLIO_NAME,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM investment_seq inv_seq
LEFT JOIN asset_classes ac ON ac.asset_class = (
    SELECT asset_class FROM asset_classes ORDER BY RANDOM() LIMIT 1
);

-- Calculate derived fields
UPDATE INVESTMENTS
SET 
    COST_BASIS = ROUND(QUANTITY * PURCHASE_PRICE, 2),
    MARKET_VALUE = ROUND(QUANTITY * CURRENT_PRICE, 2);

UPDATE INVESTMENTS
SET UNREALIZED_GAIN_LOSS = MARKET_VALUE - COST_BASIS;

SELECT 'Investments loaded: ' || COUNT(*) || ' records' as STATUS FROM INVESTMENTS;

-- ============================================================================
-- 9. INVESTMENT_TRANSACTIONS - Buy/sell/income transactions
-- ============================================================================

INSERT INTO INVESTMENT_TRANSACTIONS (
    TRANSACTION_ID, INVESTMENT_ID, TRANSACTION_DATE, TRANSACTION_TYPE,
    QUANTITY, PRICE, AMOUNT, REALIZED_GAIN_LOSS,
    INCOME_TYPE, ACCOUNTING_MONTH, BROKER, CREATED_DATE
)
WITH
investments_data AS (
    SELECT 
        INVESTMENT_ID,
        SECURITY_ID,
        SECURITY_TYPE,
        PURCHASE_DATE,
        QUANTITY,
        PURCHASE_PRICE,
        CURRENT_PRICE,
        COUPON_RATE,
        YIELD_TO_MATURITY
    FROM INVESTMENTS
),
months_series AS (
    SELECT 
        DATEADD(month, -SEQ4(), DATE_TRUNC('month', CURRENT_DATE())) as month_date
    FROM TABLE(GENERATOR(ROWCOUNT => 36))
    WHERE SEQ4() < 36
),
investment_months AS (
    SELECT 
        inv.INVESTMENT_ID,
        ms.month_date,
        inv.SECURITY_TYPE,
        inv.QUANTITY,
        inv.PURCHASE_PRICE,
        inv.CURRENT_PRICE,
        inv.COUPON_RATE,
        inv.YIELD_TO_MATURITY,
        ROW_NUMBER() OVER (PARTITION BY inv.INVESTMENT_ID ORDER BY ms.month_date) as month_seq
    FROM investments_data inv
    CROSS JOIN months_series ms
    WHERE ms.month_date >= DATE_TRUNC('month', inv.PURCHASE_DATE)
)
SELECT
    'TXN-' || im.INVESTMENT_ID || '-' || TO_CHAR(im.month_date, 'YYYYMM') || '-' || 
        CASE 
            WHEN im.month_seq = 1 THEN 'P'
            WHEN (ABS(RANDOM()) % 100) = 0 THEN 'S'
            WHEN im.SECURITY_TYPE IN ('Bond', 'MBS') THEN 'I'
            ELSE 'D'
        END as TRANSACTION_ID,
    im.INVESTMENT_ID,
    im.month_date as TRANSACTION_DATE,
    CASE 
        WHEN im.month_seq = 1 THEN 'Purchase'
        WHEN (ABS(RANDOM()) % 100) = 0 THEN 'Sale'
        WHEN im.SECURITY_TYPE IN ('Bond', 'MBS') THEN 'Interest'
        ELSE 'Dividend'
    END as TRANSACTION_TYPE,
    CASE 
        WHEN im.month_seq = 1 THEN im.QUANTITY
        WHEN (ABS(RANDOM()) % 100) = 0 THEN im.QUANTITY * (0.2 + (ABS(RANDOM()) % 61) / 100.0)  -- Sell 20-80%
        ELSE NULL
    END as QUANTITY,
    CASE 
        WHEN im.month_seq = 1 THEN im.PURCHASE_PRICE
        WHEN (ABS(RANDOM()) % 100) = 0 THEN im.CURRENT_PRICE
        ELSE NULL
    END as PRICE,
    CASE 
        WHEN im.month_seq = 1 THEN ROUND(im.QUANTITY * im.PURCHASE_PRICE, 2)
        WHEN (ABS(RANDOM()) % 100) = 0 THEN 
            ROUND(im.QUANTITY * (0.2 + (ABS(RANDOM()) % 61) / 100.0) * im.CURRENT_PRICE, 2)
        WHEN im.SECURITY_TYPE IN ('Bond', 'MBS') THEN 
            ROUND(im.QUANTITY * im.PURCHASE_PRICE * (COALESCE(im.COUPON_RATE, 3.5) / 100.0) / 12.0, 2)
        ELSE 
            ROUND(im.QUANTITY * im.PURCHASE_PRICE * (COALESCE(im.YIELD_TO_MATURITY, 2.5) / 100.0) / 12.0, 2)
    END as AMOUNT,
    CASE 
        WHEN (ABS(RANDOM()) % 100) = 0 THEN 
            ROUND(im.QUANTITY * (0.2 + (ABS(RANDOM()) % 61) / 100.0) * (im.CURRENT_PRICE - im.PURCHASE_PRICE), 2)
        ELSE NULL
    END as REALIZED_GAIN_LOSS,
    CASE 
        WHEN im.month_seq > 1 AND im.SECURITY_TYPE IN ('Bond', 'MBS') THEN 'Interest'
        WHEN im.month_seq > 1 THEN 'Dividend'
        ELSE NULL
    END as INCOME_TYPE,
    im.month_date as ACCOUNTING_MONTH,
    CASE (ABS(RANDOM()) % 8)
        WHEN 0 THEN 'DBS Bank' WHEN 1 THEN 'UOB Kay Hian'
        WHEN 2 THEN 'Maybank Investment' WHEN 3 THEN 'CGS-CIMB Securities'
        WHEN 4 THEN 'Mandiri Sekuritas' WHEN 5 THEN 'SCB Securities'
        WHEN 6 THEN 'BPI Securities' ELSE 'VNDIRECT Securities'
    END as BROKER,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM investment_months im
WHERE (ABS(RANDOM()) % 10) < 7;  -- Sample 70% of records

SELECT 'Investment transactions loaded: ' || COUNT(*) || ' records' as STATUS FROM INVESTMENT_TRANSACTIONS;

-- ============================================================================
-- 10. REINSURANCE - Reinsurance treaties
-- ============================================================================

INSERT INTO REINSURANCE (
    TREATY_ID, TREATY_NAME, TREATY_TYPE, REINSURER_NAME, REINSURER_RATING,
    PRODUCT_ID, EFFECTIVE_DATE, EXPIRATION_DATE, RETENTION_LIMIT,
    COVERAGE_LIMIT, CEDED_PREMIUM, CEDING_COMMISSION, RECOVERIES_TO_DATE, IS_ACTIVE, CREATED_DATE
)
WITH
products_list AS (
    SELECT PRODUCT_ID, PRODUCT_NAME, PRODUCT_TYPE
    FROM PRODUCTS
    WHERE IS_ACTIVE = TRUE
),
reinsurers AS (
    SELECT 'Munich Re' as reinsurer, 'A++' as rating UNION ALL
    SELECT 'Swiss Re', 'A++' UNION ALL
    SELECT 'Hannover Re', 'A+' UNION ALL
    SELECT 'SCOR', 'A+' UNION ALL
    SELECT 'Asia Capital Reinsurance', 'A' UNION ALL
    SELECT 'Singapore Reinsurance', 'A' UNION ALL
    SELECT 'Malaysian Re', 'A-' UNION ALL
    SELECT 'Thai Re', 'BBB+'
),
treaty_types AS (
    SELECT 'Quota Share' as treaty_type UNION ALL
    SELECT 'Excess of Loss' UNION ALL
    SELECT 'Catastrophe'
),
treaty_seq AS (
    SELECT SEQ4() + 1 as seq_num
    FROM TABLE(GENERATOR(ROWCOUNT => 50))
)
SELECT
    'TREATY-' || LPAD(ts.seq_num::VARCHAR, 5, '0') as TREATY_ID,
    pl.PRODUCT_TYPE || ' ' || tt.treaty_type || ' Treaty ' || ts.seq_num as TREATY_NAME,
    tt.treaty_type as TREATY_TYPE,
    r.reinsurer as REINSURER_NAME,
    r.rating as REINSURER_RATING,
    pl.PRODUCT_ID,
    DATEADD(year, -(1 + (ABS(RANDOM()) % 3)), DATE_TRUNC('year', CURRENT_DATE())) as EFFECTIVE_DATE,
    DATEADD(year, 1, DATEADD(year, -(1 + (ABS(RANDOM()) % 3)), DATE_TRUNC('year', CURRENT_DATE()))) as EXPIRATION_DATE,
    CASE tt.treaty_type
        WHEN 'Quota Share' THEN 100000 + (ABS(RANDOM()) % 400001)  -- $100K-$500K retention
        WHEN 'Excess of Loss' THEN 500000 + (ABS(RANDOM()) % 4500001)  -- $500K-$5M retention
        ELSE 5000000 + (ABS(RANDOM()) % 20000001)  -- $5M-$25M cat retention
    END as RETENTION_LIMIT,
    CASE tt.treaty_type
        WHEN 'Quota Share' THEN 5000000 + (ABS(RANDOM()) % 20000001)  -- $5M-$25M coverage
        WHEN 'Excess of Loss' THEN 10000000 + (ABS(RANDOM()) % 90000001)  -- $10M-$100M coverage
        ELSE 50000000 + (ABS(RANDOM()) % 450000001)  -- $50M-$500M cat coverage
    END as COVERAGE_LIMIT,
    500000 + (ABS(RANDOM()) % 4500001) as CEDED_PREMIUM,  -- $500K-$5M
    CASE tt.treaty_type
        WHEN 'Quota Share' THEN 50000 + (ABS(RANDOM()) % 450001)  -- Commission on quota share
        ELSE 0
    END as CEDING_COMMISSION,
    CASE 
        WHEN (ABS(RANDOM()) % 3) = 0 THEN 100000 + (ABS(RANDOM()) % 900001)
        ELSE 0
    END as RECOVERIES_TO_DATE,
    TRUE as IS_ACTIVE,
    CURRENT_TIMESTAMP() as CREATED_DATE
FROM treaty_seq ts
LEFT JOIN products_list pl ON pl.PRODUCT_ID = (
    SELECT PRODUCT_ID FROM products_list ORDER BY RANDOM() LIMIT 1
)
LEFT JOIN reinsurers r ON r.reinsurer = (
    SELECT reinsurer FROM reinsurers ORDER BY RANDOM() LIMIT 1
)
LEFT JOIN treaty_types tt ON tt.treaty_type = (
    SELECT treaty_type FROM treaty_types ORDER BY RANDOM() LIMIT 1
);

SELECT 'Reinsurance treaties loaded: ' || COUNT(*) || ' records' as STATUS FROM REINSURANCE;

-- ============================================================================
-- 11. Data Loading Summary
-- ============================================================================

SELECT 'Data loading complete!' as MESSAGE;

SELECT 
    'PRODUCTS' as TABLE_NAME, COUNT(*) as RECORD_COUNT FROM PRODUCTS
UNION ALL
SELECT 'UNDERWRITERS', COUNT(*) FROM UNDERWRITERS
UNION ALL
SELECT 'POLICYHOLDERS', COUNT(*) FROM POLICYHOLDERS
UNION ALL
SELECT 'POLICIES', COUNT(*) FROM POLICIES
UNION ALL
SELECT 'PREMIUMS', COUNT(*) FROM PREMIUMS
UNION ALL
SELECT 'CLAIMS', COUNT(*) FROM CLAIMS
UNION ALL
SELECT 'RESERVES', COUNT(*) FROM RESERVES
UNION ALL
SELECT 'INVESTMENTS', COUNT(*) FROM INVESTMENTS
UNION ALL
SELECT 'INVESTMENT_TRANSACTIONS', COUNT(*) FROM INVESTMENT_TRANSACTIONS
UNION ALL
SELECT 'REINSURANCE', COUNT(*) FROM REINSURANCE
ORDER BY TABLE_NAME;

SELECT '✓ Sample data loaded successfully!' as STATUS,
       '✓ 100,000+ records across 10 tables' as DETAILS;

-- ============================================================================
-- NEXT STEP: Run 03_setup_intelligence.sql to create analytical views
-- ============================================================================

