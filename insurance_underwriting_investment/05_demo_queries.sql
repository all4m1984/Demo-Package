-- ============================================================================
-- SNOWFLAKE INTELLIGENCE DEMO: INSURANCE UNDERWRITING & INVESTMENT MANAGEMENT
-- Script 5: Demo Queries
-- ============================================================================
-- Purpose: Sample analytical queries for demonstrating insurance insights
-- Usage: Run these queries as fallback if Cortex Analyst is not available
-- ============================================================================

USE DATABASE INSURANCE_DEMO;
USE SCHEMA UNDERWRITING_INV;
USE WAREHOUSE DEMO_WH;

-- ============================================================================
-- SECTION 1: UNDERWRITING PERFORMANCE ANALYSIS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Query 1.1: Combined Ratio by Product Line (Last 12 Months)
-- Business Question: What is the combined ratio by product line?
-- Target: Combined ratio < 100% indicates underwriting profit
-- ---------------------------------------------------------------------------
SELECT 
    PRODUCT_TYPE,
    PRODUCT_NAME,
    ROUND(AVG(COMBINED_RATIO), 2) as AVG_COMBINED_RATIO,
    ROUND(AVG(LOSS_RATIO), 2) as AVG_LOSS_RATIO,
    ROUND(AVG(EXPENSE_RATIO), 2) as AVG_EXPENSE_RATIO,
    SUM(EARNED_PREMIUM) as TOTAL_EARNED_PREMIUM,
    SUM(INCURRED_LOSS) as TOTAL_INCURRED_LOSS,
    SUM(POLICY_COUNT) as TOTAL_POLICIES
FROM VW_UNDERWRITING_PERFORMANCE
WHERE ACCOUNTING_MONTH >= DATEADD(month, -12, CURRENT_DATE())
GROUP BY 1, 2
ORDER BY AVG_COMBINED_RATIO DESC;

-- ---------------------------------------------------------------------------
-- Query 1.2: Products with High Loss Ratios
-- Business Question: Which product lines have loss ratios above 65%?
-- Impact: Identify products requiring rate increases or underwriting changes
-- ---------------------------------------------------------------------------
SELECT 
    PRODUCT_TYPE,
    PRODUCT_CATEGORY,
    TARGET_LOSS_RATIO,
    ROUND(AVG(LOSS_RATIO), 2) as ACTUAL_LOSS_RATIO,
    ROUND(AVG(LOSS_RATIO) - TARGET_LOSS_RATIO, 2) as VARIANCE,
    SUM(EARNED_PREMIUM) as TOTAL_EARNED_PREMIUM,
    SUM(INCURRED_LOSS) as TOTAL_INCURRED_LOSS
FROM VW_UNDERWRITING_PERFORMANCE
WHERE ACCOUNTING_YEAR = YEAR(CURRENT_DATE())
GROUP BY 1, 2, 3
HAVING AVG(LOSS_RATIO) > 65
ORDER BY ACTUAL_LOSS_RATIO DESC;

-- ---------------------------------------------------------------------------
-- Query 1.3: Top 10 Underwriters by Performance
-- Business Question: Who are our best-performing underwriters?
-- Impact: Identify top performers for best practices and rewards
-- ---------------------------------------------------------------------------
SELECT 
    UNDERWRITER_NAME,
    EXPERIENCE_LEVEL,
    REGION,
    ROUND(AVG(COMBINED_RATIO), 2) as AVG_COMBINED_RATIO,
    ROUND(AVG(LOSS_RATIO), 2) as AVG_LOSS_RATIO,
    SUM(EARNED_PREMIUM) as TOTAL_EARNED_PREMIUM,
    SUM(POLICY_COUNT) as TOTAL_POLICIES,
    SUM(CLAIM_COUNT) as TOTAL_CLAIMS
FROM VW_UNDERWRITING_PERFORMANCE
WHERE ACCOUNTING_YEAR = YEAR(CURRENT_DATE())
GROUP BY 1, 2, 3
ORDER BY AVG_COMBINED_RATIO ASC
LIMIT 10;

-- ---------------------------------------------------------------------------
-- Query 1.4: Loss Ratio Trend by Quarter
-- Business Question: How is our loss ratio trending over time?
-- Impact: Identify deteriorating or improving trends early
-- ---------------------------------------------------------------------------
SELECT 
    ACCOUNTING_YEAR,
    ACCOUNTING_QUARTER,
    PRODUCT_TYPE,
    ROUND(AVG(LOSS_RATIO), 2) as AVG_LOSS_RATIO,
    SUM(EARNED_PREMIUM) as TOTAL_EARNED_PREMIUM,
    SUM(INCURRED_LOSS) as TOTAL_INCURRED_LOSS
FROM VW_UNDERWRITING_PERFORMANCE
WHERE ACCOUNTING_YEAR >= YEAR(CURRENT_DATE()) - 2
GROUP BY 1, 2, 3
ORDER BY 1 DESC, 2 DESC, 3;

-- ---------------------------------------------------------------------------
-- Query 1.5: Regional Performance Comparison
-- Business Question: How do different regions perform?
-- Impact: Identify geographic areas of strength and weakness
-- ---------------------------------------------------------------------------
SELECT 
    REGION,
    ROUND(AVG(COMBINED_RATIO), 2) as AVG_COMBINED_RATIO,
    ROUND(AVG(LOSS_RATIO), 2) as AVG_LOSS_RATIO,
    SUM(EARNED_PREMIUM) as TOTAL_EARNED_PREMIUM,
    SUM(POLICY_COUNT) as TOTAL_POLICIES,
    ROUND(AVG(CLAIM_FREQUENCY), 4) as AVG_CLAIM_FREQUENCY,
    ROUND(AVG(CLAIM_SEVERITY), 2) as AVG_CLAIM_SEVERITY
FROM VW_UNDERWRITING_PERFORMANCE
WHERE ACCOUNTING_YEAR = YEAR(CURRENT_DATE())
GROUP BY 1
ORDER BY AVG_COMBINED_RATIO;

-- ============================================================================
-- SECTION 2: CLAIMS ANALYSIS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Query 2.1: Claims Frequency and Severity by Product
-- Business Question: What drives our loss ratios - frequency or severity?
-- Impact: Understand root causes to take targeted action
-- ---------------------------------------------------------------------------
SELECT 
    PRODUCT_TYPE,
    COUNT(CLAIM_ID) as CLAIM_COUNT,
    ROUND(AVG(CLAIM_AMOUNT), 2) as AVG_CLAIM_AMOUNT,
    SUM(CLAIM_AMOUNT) as TOTAL_INCURRED,
    ROUND(AVG(DAYS_TO_CLOSE), 1) as AVG_DAYS_TO_CLOSE,
    ROUND(COUNT(CLAIM_ID)::FLOAT / 
          (SELECT COUNT(DISTINCT POLICY_ID) FROM VW_CLAIMS_ANALYSIS), 4) as OVERALL_FREQUENCY
FROM VW_CLAIMS_ANALYSIS
WHERE LOSS_YEAR = YEAR(CURRENT_DATE())
GROUP BY 1
ORDER BY TOTAL_INCURRED DESC;

-- ---------------------------------------------------------------------------
-- Query 2.2: High Severity Claims
-- Business Question: What are our largest claims?
-- Impact: Focus on high-value claims management and subrogation
-- ---------------------------------------------------------------------------
SELECT 
    CLAIM_NUMBER,
    CLAIM_STATUS,
    CLAIM_TYPE,
    SEVERITY_CATEGORY,
    PRODUCT_TYPE,
    STATE,
    DATE_OF_LOSS,
    CLAIM_AMOUNT,
    PAID_AMOUNT,
    RESERVE_AMOUNT,
    REINSURANCE_RECOVERY,
    NET_CLAIM_AMOUNT,
    DAYS_TO_CLOSE
FROM VW_CLAIMS_ANALYSIS
WHERE LOSS_YEAR >= YEAR(CURRENT_DATE()) - 1
    AND SEVERITY_CATEGORY IN ('High', 'Catastrophic')
ORDER BY CLAIM_AMOUNT DESC
LIMIT 20;

-- ---------------------------------------------------------------------------
-- Query 2.3: Claims by Type and Product
-- Business Question: What types of claims are most common?
-- Impact: Identify risk concentrations and mitigation opportunities
-- ---------------------------------------------------------------------------
SELECT 
    PRODUCT_TYPE,
    CLAIM_TYPE,
    COUNT(CLAIM_ID) as CLAIM_COUNT,
    ROUND(AVG(CLAIM_AMOUNT), 2) as AVG_CLAIM_AMOUNT,
    SUM(CLAIM_AMOUNT) as TOTAL_INCURRED,
    ROUND(COUNT(CLAIM_ID)::FLOAT / 
          SUM(COUNT(CLAIM_ID)) OVER (PARTITION BY PRODUCT_TYPE) * 100, 2) as PCT_OF_PRODUCT_CLAIMS
FROM VW_CLAIMS_ANALYSIS
WHERE LOSS_YEAR = YEAR(CURRENT_DATE())
GROUP BY 1, 2
ORDER BY 1, CLAIM_COUNT DESC;

-- ---------------------------------------------------------------------------
-- Query 2.4: Open Claims Summary
-- Business Question: What is our current open claims exposure?
-- Impact: Monitor outstanding liabilities and reserve adequacy
-- ---------------------------------------------------------------------------
SELECT 
    PRODUCT_TYPE,
    CLAIM_STATUS,
    COUNT(CLAIM_ID) as OPEN_CLAIM_COUNT,
    SUM(CLAIM_AMOUNT) as TOTAL_INCURRED,
    SUM(PAID_AMOUNT) as TOTAL_PAID,
    SUM(RESERVE_AMOUNT) as TOTAL_RESERVES,
    ROUND(AVG(DATEDIFF(day, DATE_REPORTED, CURRENT_DATE())), 1) as AVG_DAYS_OPEN
FROM VW_CLAIMS_ANALYSIS
WHERE CLAIM_STATUS IN ('Open', 'Reopened')
GROUP BY 1, 2
ORDER BY TOTAL_RESERVES DESC;

-- ============================================================================
-- SECTION 3: RESERVE ADEQUACY ANALYSIS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Query 3.1: Reserve Adequacy by Accident Year
-- Business Question: Are our reserves adequate for each accident year?
-- Impact: Ensure financial stability and accurate earnings
-- ---------------------------------------------------------------------------
SELECT 
    ACCIDENT_YEAR,
    RESERVE_ADEQUACY_STATUS,
    COUNT(CLAIM_ID) as CLAIM_COUNT,
    SUM(ULTIMATE_LOSS) as ULTIMATE_LOSS,
    SUM(PAID_AMOUNT) as PAID_TO_DATE,
    SUM(CURRENT_RESERVE) as CURRENT_RESERVES,
    SUM(ESTIMATED_ULTIMATE) as ESTIMATED_ULTIMATE,
    ROUND(AVG(RESERVE_ADEQUACY_PCT), 2) as AVG_ADEQUACY_PCT,
    ROUND(AVG(CONFIDENCE_LEVEL), 2) as AVG_CONFIDENCE
FROM VW_RESERVE_ADEQUACY
GROUP BY 1, 2
ORDER BY 1 DESC, 2;

-- ---------------------------------------------------------------------------
-- Query 3.2: Products with Understated Reserves
-- Business Question: Which products have inadequate reserves?
-- Impact: Take corrective action to avoid adverse development
-- ---------------------------------------------------------------------------
SELECT 
    PRODUCT_TYPE,
    COUNT(CLAIM_ID) as CLAIM_COUNT,
    SUM(ULTIMATE_LOSS) as ULTIMATE_LOSS,
    SUM(ESTIMATED_ULTIMATE) as ESTIMATED_ULTIMATE,
    SUM(ULTIMATE_LOSS - ESTIMATED_ULTIMATE) as RESERVE_DEFICIENCY
FROM VW_RESERVE_ADEQUACY
WHERE RESERVE_ADEQUACY_STATUS = 'Understated'
GROUP BY 1
ORDER BY RESERVE_DEFICIENCY DESC;

-- ---------------------------------------------------------------------------
-- Query 3.3: IBNR Reserve Analysis
-- Business Question: What is our IBNR exposure by product?
-- Impact: Monitor incurred but not reported claim reserves
-- ---------------------------------------------------------------------------
SELECT 
    PRODUCT_TYPE,
    ACCIDENT_YEAR,
    SUM(CASE_RESERVE) as TOTAL_CASE_RESERVE,
    SUM(IBNR_RESERVE) as TOTAL_IBNR_RESERVE,
    SUM(ACTUARIAL_RESERVE) as TOTAL_ACTUARIAL_RESERVE,
    ROUND(SUM(IBNR_RESERVE)::FLOAT / NULLIF(SUM(ACTUARIAL_RESERVE), 0) * 100, 2) as IBNR_PCT
FROM VW_RESERVE_ADEQUACY
GROUP BY 1, 2
ORDER BY 1, 2 DESC;

-- ============================================================================
-- SECTION 4: INVESTMENT PORTFOLIO ANALYSIS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Query 4.1: Current Asset Allocation
-- Business Question: What is our current asset allocation vs. targets?
-- Impact: Ensure portfolio alignment with investment policy
-- ---------------------------------------------------------------------------
SELECT 
    ASSET_CLASS,
    COUNT(INVESTMENT_ID) as HOLDINGS_COUNT,
    SUM(COST_BASIS) as TOTAL_COST_BASIS,
    SUM(MARKET_VALUE) as TOTAL_MARKET_VALUE,
    SUM(UNREALIZED_GAIN_LOSS) as TOTAL_UNREALIZED_GL,
    ROUND(SUM(MARKET_VALUE) / 
          (SELECT SUM(MARKET_VALUE) FROM VW_INVESTMENT_PORTFOLIO) * 100, 2) as ALLOCATION_PCT,
    ROUND(AVG(YIELD_TO_MATURITY), 2) as AVG_YIELD,
    ROUND(AVG(DURATION), 2) as AVG_DURATION
FROM VW_INVESTMENT_PORTFOLIO
GROUP BY 1
ORDER BY TOTAL_MARKET_VALUE DESC;

-- ---------------------------------------------------------------------------
-- Query 4.2: Portfolio Performance by Asset Class
-- Business Question: Which asset classes are performing best?
-- Impact: Tactical allocation decisions and performance attribution
-- ---------------------------------------------------------------------------
SELECT 
    ASSET_CLASS,
    SUM(COST_BASIS) as TOTAL_COST_BASIS,
    SUM(MARKET_VALUE) as TOTAL_MARKET_VALUE,
    SUM(UNREALIZED_GAIN_LOSS) as UNREALIZED_GL,
    ROUND(SUM(UNREALIZED_GAIN_LOSS) / NULLIF(SUM(COST_BASIS), 0) * 100, 2) as UNREALIZED_RETURN_PCT,
    SUM(REALIZED_GAIN_LOSS) as REALIZED_GL,
    SUM(TOTAL_INCOME) as TOTAL_INCOME,
    SUM(UNREALIZED_GAIN_LOSS + REALIZED_GAIN_LOSS + TOTAL_INCOME) as TOTAL_RETURN
FROM VW_INVESTMENT_PORTFOLIO
GROUP BY 1
ORDER BY TOTAL_RETURN DESC;

-- ---------------------------------------------------------------------------
-- Query 4.3: Investment Income Trend
-- Business Question: How much investment income are we generating monthly?
-- Impact: Forecast cash flows and offset underwriting losses
-- ---------------------------------------------------------------------------
SELECT 
    TO_CHAR(ACCOUNTING_MONTH, 'YYYY-MM') as MONTH,
    SUM(TOTAL_INTEREST_INCOME) as INTEREST_INCOME,
    SUM(TOTAL_DIVIDEND_INCOME) as DIVIDEND_INCOME,
    SUM(TOTAL_INVESTMENT_INCOME) as TOTAL_INVESTMENT_INCOME,
    SUM(TOTAL_REALIZED_GAINS) as REALIZED_GAINS,
    ROUND(AVG(ANNUALIZED_YIELD_PCT), 2) as AVG_PORTFOLIO_YIELD
FROM VW_INVESTMENT_PERFORMANCE
WHERE ACCOUNTING_YEAR >= YEAR(CURRENT_DATE()) - 1
GROUP BY 1
ORDER BY 1 DESC;

-- ---------------------------------------------------------------------------
-- Query 4.4: Portfolio Yield by Asset Class (Quarterly)
-- Business Question: What is our portfolio yield compared to last quarter?
-- Impact: Monitor yield trends and compare to benchmarks
-- ---------------------------------------------------------------------------
SELECT 
    ACCOUNTING_YEAR,
    ACCOUNTING_QUARTER,
    ASSET_CLASS,
    ROUND(AVG(ANNUALIZED_YIELD_PCT), 2) as AVG_YIELD,
    SUM(PORTFOLIO_VALUE) as AVG_PORTFOLIO_VALUE
FROM VW_INVESTMENT_PERFORMANCE
WHERE ACCOUNTING_YEAR >= YEAR(CURRENT_DATE()) - 1
GROUP BY 1, 2, 3
ORDER BY 1 DESC, 2 DESC, 3;

-- ---------------------------------------------------------------------------
-- Query 4.5: Fixed Income Holdings by Rating
-- Business Question: What is our credit quality distribution?
-- Impact: Monitor credit risk concentration
-- ---------------------------------------------------------------------------
SELECT 
    RATING_CATEGORY,
    RATING,
    COUNT(INVESTMENT_ID) as HOLDINGS_COUNT,
    SUM(MARKET_VALUE) as TOTAL_MARKET_VALUE,
    ROUND(SUM(MARKET_VALUE) / 
          (SELECT SUM(MARKET_VALUE) FROM VW_INVESTMENT_PORTFOLIO WHERE SECURITY_TYPE IN ('Bond', 'MBS')) * 100, 2) as PCT_OF_FIXED_INCOME,
    ROUND(AVG(YIELD_TO_MATURITY), 2) as AVG_YIELD,
    ROUND(AVG(DURATION), 2) as AVG_DURATION,
    ROUND(AVG(YEARS_TO_MATURITY), 2) as AVG_YEARS_TO_MATURITY
FROM VW_INVESTMENT_PORTFOLIO
WHERE SECURITY_TYPE IN ('Bond', 'MBS')
    AND RATING IS NOT NULL
GROUP BY 1, 2
ORDER BY 
    CASE RATING_CATEGORY
        WHEN 'High Grade' THEN 1
        WHEN 'Upper Medium Grade' THEN 2
        WHEN 'Lower Medium Grade' THEN 3
        ELSE 4
    END,
    2;

-- ---------------------------------------------------------------------------
-- Query 4.6: Duration Analysis
-- Business Question: What is our duration gap between assets and liabilities?
-- Impact: Measure interest rate risk exposure
-- ---------------------------------------------------------------------------
SELECT 
    ASSET_CLASS,
    SECURITY_TYPE,
    COUNT(INVESTMENT_ID) as HOLDINGS,
    ROUND(AVG(DURATION), 2) as AVG_DURATION,
    ROUND(AVG(YEARS_TO_MATURITY), 2) as AVG_MATURITY,
    SUM(MARKET_VALUE) as TOTAL_MARKET_VALUE
FROM VW_INVESTMENT_PORTFOLIO
WHERE SECURITY_TYPE IN ('Bond', 'MBS')
GROUP BY 1, 2
ORDER BY AVG_DURATION DESC;

-- ============================================================================
-- SECTION 5: INTEGRATED ANALYSIS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Query 5.1: Overall Profitability (Underwriting + Investment)
-- Business Question: What is our overall profitability including investment income?
-- Impact: Comprehensive view of insurer profitability
-- ---------------------------------------------------------------------------
WITH 
underwriting AS (
    SELECT 
        ACCOUNTING_YEAR,
        ACCOUNTING_QUARTER,
        SUM(EARNED_PREMIUM) as TOTAL_EARNED_PREMIUM,
        SUM(INCURRED_LOSS) as TOTAL_INCURRED_LOSS,
        SUM(COMMISSION_EXPENSE) as TOTAL_COMMISSION
    FROM VW_UNDERWRITING_PERFORMANCE
    GROUP BY 1, 2
),
investment AS (
    SELECT 
        ACCOUNTING_YEAR,
        ACCOUNTING_QUARTER,
        SUM(TOTAL_INVESTMENT_INCOME) as TOTAL_INV_INCOME,
        SUM(TOTAL_REALIZED_GAINS) as TOTAL_REALIZED_GAINS
    FROM VW_INVESTMENT_PERFORMANCE
    GROUP BY 1, 2
)
SELECT 
    u.ACCOUNTING_YEAR,
    u.ACCOUNTING_QUARTER,
    u.TOTAL_EARNED_PREMIUM,
    u.TOTAL_INCURRED_LOSS,
    u.TOTAL_COMMISSION,
    u.TOTAL_EARNED_PREMIUM - u.TOTAL_INCURRED_LOSS - u.TOTAL_COMMISSION as UNDERWRITING_PROFIT,
    COALESCE(i.TOTAL_INV_INCOME, 0) as INVESTMENT_INCOME,
    COALESCE(i.TOTAL_REALIZED_GAINS, 0) as REALIZED_GAINS,
    (u.TOTAL_EARNED_PREMIUM - u.TOTAL_INCURRED_LOSS - u.TOTAL_COMMISSION) + 
        COALESCE(i.TOTAL_INV_INCOME, 0) + COALESCE(i.TOTAL_REALIZED_GAINS, 0) as TOTAL_PROFIT
FROM underwriting u
LEFT JOIN investment i ON u.ACCOUNTING_YEAR = i.ACCOUNTING_YEAR AND u.ACCOUNTING_QUARTER = i.ACCOUNTING_QUARTER
ORDER BY 1 DESC, 2 DESC;

-- ============================================================================
-- End of Demo Queries
-- ============================================================================

SELECT '✓ Demo queries completed!' as STATUS,
       '✓ These queries demonstrate key insurance insights' as NOTE,
       '✓ For natural language queries, use Cortex Analyst' as NEXT_STEP;

