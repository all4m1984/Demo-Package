-- ============================================================================
-- SNOWFLAKE INTELLIGENCE DEMO: INSURANCE UNDERWRITING & INVESTMENT MANAGEMENT
-- Script 3: Intelligence Setup
-- ============================================================================
-- Purpose: Creates analytical views and prepares for Cortex Analyst
-- Execution Time: ~1 minute
-- Views Created: 6 (Underwriting: 4, Investment: 2)
-- ============================================================================

USE DATABASE INSURANCE_DEMO;
USE SCHEMA UNDERWRITING_INV;
USE WAREHOUSE DEMO_WH;

-- ============================================================================
-- 1. Underwriting Analytical Views
-- ============================================================================

-- ---------------------------------------------------------------------------
-- View 1: VW_UNDERWRITING_PERFORMANCE
-- Purpose: Product line performance metrics (loss ratio, combined ratio, etc.)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_UNDERWRITING_PERFORMANCE AS
WITH
premium_summary AS (
    SELECT 
        pol.POLICY_ID,
        pol.PRODUCT_ID,
        pol.UNDERWRITER_ID,
        pol.STATE,
        pol.REGION,
        pol.POLICY_STATUS,
        DATE_TRUNC('month', prem.ACCOUNTING_MONTH) as ACCOUNTING_MONTH,
        SUM(prem.WRITTEN_PREMIUM) as WRITTEN_PREMIUM,
        SUM(prem.EARNED_PREMIUM) as EARNED_PREMIUM,
        SUM(prem.COMMISSION_AMOUNT) as COMMISSION_AMOUNT
    FROM POLICIES pol
    JOIN PREMIUMS prem ON pol.POLICY_ID = prem.POLICY_ID
    GROUP BY 1,2,3,4,5,6,7
),
claims_summary AS (
    SELECT 
        pol.POLICY_ID,
        pol.PRODUCT_ID,
        DATE_TRUNC('month', clm.DATE_OF_LOSS) as LOSS_MONTH,
        COUNT(clm.CLAIM_ID) as CLAIM_COUNT,
        SUM(clm.CLAIM_AMOUNT) as INCURRED_LOSS,
        SUM(clm.PAID_AMOUNT) as PAID_LOSS,
        SUM(clm.RESERVE_AMOUNT) as RESERVE_AMOUNT
    FROM POLICIES pol
    JOIN CLAIMS clm ON pol.POLICY_ID = clm.POLICY_ID
    GROUP BY 1,2,3
)
SELECT
    ps.ACCOUNTING_MONTH,
    YEAR(ps.ACCOUNTING_MONTH) as ACCOUNTING_YEAR,
    QUARTER(ps.ACCOUNTING_MONTH) as ACCOUNTING_QUARTER,
    pr.PRODUCT_ID,
    pr.PRODUCT_NAME,
    pr.PRODUCT_TYPE,
    pr.PRODUCT_CATEGORY,
    pr.TARGET_LOSS_RATIO,
    pr.TARGET_EXPENSE_RATIO,
    ps.STATE,
    ps.REGION,
    ps.UNDERWRITER_ID,
    uw.FIRST_NAME || ' ' || uw.LAST_NAME as UNDERWRITER_NAME,
    uw.EXPERIENCE_LEVEL,
    COUNT(DISTINCT ps.POLICY_ID) as POLICY_COUNT,
    SUM(ps.WRITTEN_PREMIUM) as WRITTEN_PREMIUM,
    SUM(ps.EARNED_PREMIUM) as EARNED_PREMIUM,
    SUM(ps.COMMISSION_AMOUNT) as COMMISSION_EXPENSE,
    SUM(COALESCE(cs.INCURRED_LOSS, 0)) as INCURRED_LOSS,
    SUM(COALESCE(cs.PAID_LOSS, 0)) as PAID_LOSS,
    SUM(COALESCE(cs.RESERVE_AMOUNT, 0)) as RESERVE_AMOUNT,
    COALESCE(SUM(cs.CLAIM_COUNT), 0) as CLAIM_COUNT,
    -- Key Metrics
    CASE 
        WHEN SUM(ps.EARNED_PREMIUM) > 0 
        THEN ROUND(SUM(COALESCE(cs.INCURRED_LOSS, 0)) / SUM(ps.EARNED_PREMIUM) * 100, 2)
        ELSE 0 
    END as LOSS_RATIO,
    CASE 
        WHEN SUM(ps.WRITTEN_PREMIUM) > 0 
        THEN ROUND(SUM(ps.COMMISSION_AMOUNT) / SUM(ps.WRITTEN_PREMIUM) * 100, 2)
        ELSE 0 
    END as EXPENSE_RATIO,
    CASE 
        WHEN SUM(ps.EARNED_PREMIUM) > 0 AND SUM(ps.WRITTEN_PREMIUM) > 0
        THEN ROUND(
            (SUM(COALESCE(cs.INCURRED_LOSS, 0)) / SUM(ps.EARNED_PREMIUM) * 100) +
            (SUM(ps.COMMISSION_AMOUNT) / SUM(ps.WRITTEN_PREMIUM) * 100),
            2
        )
        ELSE 0 
    END as COMBINED_RATIO,
    CASE 
        WHEN COALESCE(SUM(cs.CLAIM_COUNT), 0) > 0 AND COUNT(DISTINCT ps.POLICY_ID) > 0
        THEN ROUND(COALESCE(SUM(cs.CLAIM_COUNT), 0)::FLOAT / COUNT(DISTINCT ps.POLICY_ID), 4)
        ELSE 0 
    END as CLAIM_FREQUENCY,
    CASE 
        WHEN COALESCE(SUM(cs.CLAIM_COUNT), 0) > 0 
        THEN ROUND(SUM(COALESCE(cs.INCURRED_LOSS, 0)) / SUM(cs.CLAIM_COUNT), 2)
        ELSE 0 
    END as CLAIM_SEVERITY
FROM premium_summary ps
JOIN PRODUCTS pr ON ps.PRODUCT_ID = pr.PRODUCT_ID
JOIN UNDERWRITERS uw ON ps.UNDERWRITER_ID = uw.UNDERWRITER_ID
LEFT JOIN claims_summary cs 
    ON ps.POLICY_ID = cs.POLICY_ID 
    AND ps.ACCOUNTING_MONTH = cs.LOSS_MONTH
GROUP BY 1,2,3,4,5,6,7,8,9,10,11,12,13,14;

-- ---------------------------------------------------------------------------
-- View 2: VW_CLAIMS_ANALYSIS
-- Purpose: Detailed claims analysis
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_CLAIMS_ANALYSIS AS
SELECT
    clm.CLAIM_ID,
    clm.CLAIM_NUMBER,
    clm.CLAIM_STATUS,
    clm.CLAIM_TYPE,
    clm.SEVERITY_CATEGORY,
    clm.DATE_OF_LOSS,
    clm.DATE_REPORTED,
    clm.DATE_CLOSED,
    DATEDIFF(day, clm.DATE_REPORTED, COALESCE(clm.DATE_CLOSED, CURRENT_DATE())) as DAYS_TO_CLOSE,
    YEAR(clm.DATE_OF_LOSS) as LOSS_YEAR,
    QUARTER(clm.DATE_OF_LOSS) as LOSS_QUARTER,
    MONTH(clm.DATE_OF_LOSS) as LOSS_MONTH,
    pol.POLICY_ID,
    pol.POLICY_NUMBER,
    pol.ANNUAL_PREMIUM,
    pol.COVERAGE_LIMIT,
    pol.DEDUCTIBLE,
    pol.STATE,
    pol.REGION,
    pr.PRODUCT_ID,
    pr.PRODUCT_NAME,
    pr.PRODUCT_TYPE,
    pr.PRODUCT_CATEGORY,
    ph.POLICYHOLDER_ID,
    ph.FIRST_NAME || ' ' || ph.LAST_NAME as POLICYHOLDER_NAME,
    ph.CUSTOMER_SEGMENT,
    ph.RISK_SCORE,
    uw.UNDERWRITER_ID,
    uw.FIRST_NAME || ' ' || uw.LAST_NAME as UNDERWRITER_NAME,
    clm.CLAIM_AMOUNT,
    clm.PAID_AMOUNT,
    clm.RESERVE_AMOUNT,
    clm.SALVAGE_AMOUNT,
    clm.REINSURANCE_RECOVERY,
    clm.CLAIM_AMOUNT - COALESCE(clm.SALVAGE_AMOUNT, 0) - COALESCE(clm.REINSURANCE_RECOVERY, 0) as NET_CLAIM_AMOUNT,
    CASE 
        WHEN pol.ANNUAL_PREMIUM > 0 
        THEN ROUND(clm.CLAIM_AMOUNT / pol.ANNUAL_PREMIUM * 100, 2)
        ELSE 0 
    END as CLAIM_TO_PREMIUM_RATIO
FROM CLAIMS clm
JOIN POLICIES pol ON clm.POLICY_ID = pol.POLICY_ID
JOIN PRODUCTS pr ON pol.PRODUCT_ID = pr.PRODUCT_ID
JOIN POLICYHOLDERS ph ON pol.POLICYHOLDER_ID = ph.POLICYHOLDER_ID
JOIN UNDERWRITERS uw ON pol.UNDERWRITER_ID = uw.UNDERWRITER_ID;

-- ---------------------------------------------------------------------------
-- View 3: VW_RESERVE_ADEQUACY
-- Purpose: Reserve adequacy and development analysis
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_RESERVE_ADEQUACY AS
WITH
latest_reserves AS (
    SELECT 
        CLAIM_ID,
        RESERVE_DATE,
        CASE_RESERVE,
        IBNR_RESERVE,
        TOTAL_RESERVE,
        CONFIDENCE_LEVEL,
        ROW_NUMBER() OVER (PARTITION BY CLAIM_ID ORDER BY RESERVE_DATE DESC) as rn
    FROM RESERVES
)
SELECT
    clm.CLAIM_ID,
    clm.CLAIM_NUMBER,
    clm.CLAIM_STATUS,
    clm.CLAIM_TYPE,
    clm.DATE_OF_LOSS,
    YEAR(clm.DATE_OF_LOSS) as ACCIDENT_YEAR,
    clm.DATE_REPORTED,
    pol.POLICY_ID,
    pr.PRODUCT_ID,
    pr.PRODUCT_NAME,
    pr.PRODUCT_TYPE,
    pol.STATE,
    pol.REGION,
    clm.CLAIM_AMOUNT as ULTIMATE_LOSS,
    clm.PAID_AMOUNT,
    clm.RESERVE_AMOUNT as CURRENT_RESERVE,
    lr.CASE_RESERVE,
    lr.IBNR_RESERVE,
    lr.TOTAL_RESERVE as ACTUARIAL_RESERVE,
    lr.CONFIDENCE_LEVEL,
    lr.RESERVE_DATE as LAST_RESERVE_DATE,
    clm.PAID_AMOUNT + clm.RESERVE_AMOUNT as ESTIMATED_ULTIMATE,
    CASE 
        WHEN clm.CLAIM_AMOUNT > 0 
        THEN ROUND((clm.PAID_AMOUNT + clm.RESERVE_AMOUNT - clm.CLAIM_AMOUNT) / clm.CLAIM_AMOUNT * 100, 2)
        ELSE 0 
    END as RESERVE_ADEQUACY_PCT,
    CASE 
        WHEN clm.CLAIM_AMOUNT > 0 AND (clm.PAID_AMOUNT + clm.RESERVE_AMOUNT) < clm.CLAIM_AMOUNT 
        THEN 'Understated'
        WHEN clm.CLAIM_AMOUNT > 0 AND (clm.PAID_AMOUNT + clm.RESERVE_AMOUNT) > clm.CLAIM_AMOUNT * 1.1 
        THEN 'Overstated'
        ELSE 'Adequate'
    END as RESERVE_ADEQUACY_STATUS
FROM CLAIMS clm
JOIN POLICIES pol ON clm.POLICY_ID = pol.POLICY_ID
JOIN PRODUCTS pr ON pol.PRODUCT_ID = pr.PRODUCT_ID
LEFT JOIN latest_reserves lr ON clm.CLAIM_ID = lr.CLAIM_ID AND lr.rn = 1
WHERE clm.CLAIM_STATUS IN ('Open', 'Reopened');

-- ---------------------------------------------------------------------------
-- View 4: VW_POLICY_SUMMARY
-- Purpose: Policy-level summary for analysis
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_POLICY_SUMMARY AS
SELECT
    pol.POLICY_ID,
    pol.POLICY_NUMBER,
    pol.POLICY_STATUS,
    pol.EFFECTIVE_DATE,
    pol.EXPIRATION_DATE,
    pol.ISSUE_DATE,
    YEAR(pol.EFFECTIVE_DATE) as POLICY_YEAR,
    DATEDIFF(day, pol.EFFECTIVE_DATE, COALESCE(pol.EXPIRATION_DATE, CURRENT_DATE())) as POLICY_TERM_DAYS,
    pr.PRODUCT_ID,
    pr.PRODUCT_NAME,
    pr.PRODUCT_TYPE,
    pr.PRODUCT_CATEGORY,
    ph.POLICYHOLDER_ID,
    ph.FIRST_NAME || ' ' || ph.LAST_NAME as POLICYHOLDER_NAME,
    ph.STATE as POLICYHOLDER_STATE,
    ph.CREDIT_SCORE,
    ph.RISK_SCORE,
    ph.CUSTOMER_SEGMENT,
    ph.ACQUISITION_CHANNEL,
    uw.UNDERWRITER_ID,
    uw.FIRST_NAME || ' ' || uw.LAST_NAME as UNDERWRITER_NAME,
    uw.REGION as UNDERWRITER_REGION,
    uw.EXPERIENCE_LEVEL,
    pol.ANNUAL_PREMIUM,
    pol.COVERAGE_LIMIT,
    pol.DEDUCTIBLE,
    pol.STATE,
    pol.REGION,
    (SELECT COUNT(*) FROM CLAIMS WHERE POLICY_ID = pol.POLICY_ID) as CLAIM_COUNT,
    (SELECT COALESCE(SUM(CLAIM_AMOUNT), 0) FROM CLAIMS WHERE POLICY_ID = pol.POLICY_ID) as TOTAL_CLAIMS,
    CASE 
        WHEN pol.ANNUAL_PREMIUM > 0 
        THEN ROUND(
            (SELECT COALESCE(SUM(CLAIM_AMOUNT), 0) FROM CLAIMS WHERE POLICY_ID = pol.POLICY_ID) / 
            pol.ANNUAL_PREMIUM * 100, 
            2
        )
        ELSE 0 
    END as POLICY_LOSS_RATIO
FROM POLICIES pol
JOIN PRODUCTS pr ON pol.PRODUCT_ID = pr.PRODUCT_ID
JOIN POLICYHOLDERS ph ON pol.POLICYHOLDER_ID = ph.POLICYHOLDER_ID
JOIN UNDERWRITERS uw ON pol.UNDERWRITER_ID = uw.UNDERWRITER_ID;

-- ============================================================================
-- 2. Investment Analytical Views
-- ============================================================================

-- ---------------------------------------------------------------------------
-- View 5: VW_INVESTMENT_PORTFOLIO
-- Purpose: Portfolio holdings and performance analysis
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_INVESTMENT_PORTFOLIO AS
SELECT
    inv.INVESTMENT_ID,
    inv.SECURITY_ID,
    inv.SECURITY_NAME,
    inv.ASSET_CLASS,
    inv.SECURITY_TYPE,
    inv.SECTOR,
    inv.RATING,
    inv.PORTFOLIO_NAME,
    inv.PURCHASE_DATE,
    DATEDIFF(day, inv.PURCHASE_DATE, CURRENT_DATE()) as HOLDING_PERIOD_DAYS,
    inv.QUANTITY,
    inv.PURCHASE_PRICE,
    inv.COST_BASIS,
    inv.CURRENT_PRICE,
    inv.MARKET_VALUE,
    inv.UNREALIZED_GAIN_LOSS,
    CASE 
        WHEN inv.COST_BASIS > 0 
        THEN ROUND(inv.UNREALIZED_GAIN_LOSS / inv.COST_BASIS * 100, 2)
        ELSE 0 
    END as UNREALIZED_RETURN_PCT,
    inv.COUPON_RATE,
    inv.YIELD_TO_MATURITY,
    inv.DURATION,
    inv.MATURITY_DATE,
    CASE 
        WHEN inv.MATURITY_DATE IS NOT NULL 
        THEN DATEDIFF(day, CURRENT_DATE(), inv.MATURITY_DATE) / 365.25
        ELSE NULL 
    END as YEARS_TO_MATURITY,
    CASE 
        WHEN inv.SECURITY_TYPE IN ('Bond', 'MBS') THEN
            CASE 
                WHEN inv.RATING IN ('AAA', 'AA+', 'AA', 'AA-') THEN 'High Grade'
                WHEN inv.RATING IN ('A+', 'A', 'A-') THEN 'Upper Medium Grade'
                WHEN inv.RATING IN ('BBB+', 'BBB', 'BBB-') THEN 'Lower Medium Grade'
                ELSE 'Non-Investment Grade'
            END
        ELSE NULL 
    END as RATING_CATEGORY,
    -- Calculate total realized gain/loss from sales
    (SELECT COALESCE(SUM(REALIZED_GAIN_LOSS), 0) 
     FROM INVESTMENT_TRANSACTIONS 
     WHERE INVESTMENT_ID = inv.INVESTMENT_ID AND TRANSACTION_TYPE = 'Sale') as REALIZED_GAIN_LOSS,
    -- Calculate total investment income
    (SELECT COALESCE(SUM(AMOUNT), 0) 
     FROM INVESTMENT_TRANSACTIONS 
     WHERE INVESTMENT_ID = inv.INVESTMENT_ID 
       AND TRANSACTION_TYPE IN ('Interest', 'Dividend')) as TOTAL_INCOME,
    inv.COST_BASIS + inv.UNREALIZED_GAIN_LOSS as TOTAL_VALUE
FROM INVESTMENTS inv;

-- ---------------------------------------------------------------------------
-- View 6: VW_INVESTMENT_PERFORMANCE
-- Purpose: Investment performance metrics by period
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_INVESTMENT_PERFORMANCE AS
WITH
monthly_transactions AS (
    SELECT 
        inv.INVESTMENT_ID,
        inv.ASSET_CLASS,
        inv.SECURITY_TYPE,
        inv.SECTOR,
        inv.PORTFOLIO_NAME,
        DATE_TRUNC('month', txn.ACCOUNTING_MONTH) as ACCOUNTING_MONTH,
        SUM(CASE WHEN txn.TRANSACTION_TYPE = 'Purchase' THEN txn.AMOUNT ELSE 0 END) as PURCHASES,
        SUM(CASE WHEN txn.TRANSACTION_TYPE = 'Sale' THEN txn.AMOUNT ELSE 0 END) as SALES,
        SUM(CASE WHEN txn.TRANSACTION_TYPE = 'Interest' THEN txn.AMOUNT ELSE 0 END) as INTEREST_INCOME,
        SUM(CASE WHEN txn.TRANSACTION_TYPE = 'Dividend' THEN txn.AMOUNT ELSE 0 END) as DIVIDEND_INCOME,
        SUM(CASE WHEN txn.TRANSACTION_TYPE = 'Sale' THEN COALESCE(txn.REALIZED_GAIN_LOSS, 0) ELSE 0 END) as REALIZED_GAINS
    FROM INVESTMENTS inv
    JOIN INVESTMENT_TRANSACTIONS txn ON inv.INVESTMENT_ID = txn.INVESTMENT_ID
    GROUP BY 1,2,3,4,5,6
)
SELECT
    mt.ACCOUNTING_MONTH,
    YEAR(mt.ACCOUNTING_MONTH) as ACCOUNTING_YEAR,
    QUARTER(mt.ACCOUNTING_MONTH) as ACCOUNTING_QUARTER,
    mt.ASSET_CLASS,
    mt.SECURITY_TYPE,
    mt.SECTOR,
    mt.PORTFOLIO_NAME,
    COUNT(DISTINCT mt.INVESTMENT_ID) as HOLDINGS_COUNT,
    SUM(mt.PURCHASES) as TOTAL_PURCHASES,
    SUM(mt.SALES) as TOTAL_SALES,
    SUM(mt.INTEREST_INCOME) as TOTAL_INTEREST_INCOME,
    SUM(mt.DIVIDEND_INCOME) as TOTAL_DIVIDEND_INCOME,
    SUM(mt.INTEREST_INCOME) + SUM(mt.DIVIDEND_INCOME) as TOTAL_INVESTMENT_INCOME,
    SUM(mt.REALIZED_GAINS) as TOTAL_REALIZED_GAINS,
    -- Calculate portfolio value at month end (simplified)
    (SELECT SUM(MARKET_VALUE) 
     FROM INVESTMENTS 
     WHERE ASSET_CLASS = mt.ASSET_CLASS 
       AND PURCHASE_DATE <= mt.ACCOUNTING_MONTH) as PORTFOLIO_VALUE,
    -- Yield calculation (annualized)
    CASE 
        WHEN (SELECT SUM(COST_BASIS) 
              FROM INVESTMENTS 
              WHERE ASSET_CLASS = mt.ASSET_CLASS 
                AND PURCHASE_DATE <= mt.ACCOUNTING_MONTH) > 0
        THEN ROUND(
            ((SUM(mt.INTEREST_INCOME) + SUM(mt.DIVIDEND_INCOME)) * 12) / 
            (SELECT SUM(COST_BASIS) 
             FROM INVESTMENTS 
             WHERE ASSET_CLASS = mt.ASSET_CLASS 
               AND PURCHASE_DATE <= mt.ACCOUNTING_MONTH) * 100,
            2
        )
        ELSE 0 
    END as ANNUALIZED_YIELD_PCT
FROM monthly_transactions mt
GROUP BY 1,2,3,4,5,6,7;

-- ============================================================================
-- 3. Create Stage for Semantic Model
-- ============================================================================

CREATE STAGE IF NOT EXISTS CORTEX_STAGE
    COMMENT = 'Stage for Cortex Analyst semantic model files';

SELECT 'Stage created successfully' as STATUS;

-- ============================================================================
-- 4. Verification
-- ============================================================================

-- Show all created views
SHOW VIEWS;

-- Verify view data
SELECT 'VW_UNDERWRITING_PERFORMANCE' as VIEW_NAME, COUNT(*) as RECORD_COUNT 
FROM VW_UNDERWRITING_PERFORMANCE
UNION ALL
SELECT 'VW_CLAIMS_ANALYSIS', COUNT(*) FROM VW_CLAIMS_ANALYSIS
UNION ALL
SELECT 'VW_RESERVE_ADEQUACY', COUNT(*) FROM VW_RESERVE_ADEQUACY
UNION ALL
SELECT 'VW_POLICY_SUMMARY', COUNT(*) FROM VW_POLICY_SUMMARY
UNION ALL
SELECT 'VW_INVESTMENT_PORTFOLIO', COUNT(*) FROM VW_INVESTMENT_PORTFOLIO
UNION ALL
SELECT 'VW_INVESTMENT_PERFORMANCE', COUNT(*) FROM VW_INVESTMENT_PERFORMANCE
ORDER BY VIEW_NAME;

SELECT '✓ Intelligence setup complete!' as STATUS,
       '✓ 6 analytical views created' as DETAILS,
       '✓ CORTEX_STAGE ready for semantic model' as NEXT_STEP;

-- ============================================================================
-- NEXT STEP: Upload semantic_model.yaml using 04_upload_semantic_model.sql
-- ============================================================================

