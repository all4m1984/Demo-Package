# Insurance Underwriting & Investment Management Demo
## Southeast Asia Edition

## Overview

This demo package showcases Snowflake Intelligence (Cortex Analyst) capabilities for the **Insurance Industry in Southeast Asia**, focusing on two critical operational areas:

1. **Underwriting & Product Lines** - Risk assessment, pricing, profitability analysis
2. **Investment Management** - Portfolio performance, asset allocation, yield optimization

The demo enables executives and analysts to ask complex business questions in natural language and receive instant, accurate insights from realistic insurance data across **Southeast Asian markets** (Singapore, Malaysia, Indonesia, Thailand, Philippines, Vietnam).

---

## 🎯 Business Focus Areas

### Underwriting & Product Lines
- **Loss Ratio Analysis** - Track loss ratios by product line, region, and time
- **Product Profitability** - Identify profitable vs. unprofitable products
- **Combined Ratio Management** - Monitor overall underwriting performance
- **Premium Adequacy** - Ensure pricing covers expected losses
- **Claims Trends** - Analyze frequency, severity, and emerging patterns
- **Reserve Adequacy** - Monitor loss reserve development
- **Underwriter Performance** - Track performance by underwriter
- **Risk Selection** - Evaluate underwriting quality

### Investment Management
- **Portfolio Performance** - Track investment returns by asset class
- **Asset Allocation** - Monitor strategic vs. actual allocation
- **Investment Yield** - Analyze yield trends and compare to benchmarks
- **Duration Matching** - Ensure assets match liability duration (ALM)
- **Investment Income** - Track interest, dividends, and realized gains
- **Market Value Changes** - Monitor unrealized gains/losses
- **Risk Metrics** - Evaluate portfolio risk concentration
- **Regulatory Compliance** - Ensure compliance with investment regulations

---

## 📊 Data Model

### Underwriting Tables (7 tables)

1. **PRODUCTS** - Insurance product line definitions
   - Product ID, Name, Type (Auto, Property, Liability, etc.)
   - Target loss ratio, pricing factors

2. **POLICYHOLDERS** - Customer information
   - Policyholder demographics, risk scores
   - Customer segments, acquisition channel

3. **POLICIES** - Policy details
   - Policy number, product, premium, limits, deductibles
   - Effective/expiration dates, status

4. **UNDERWRITERS** - Underwriter information
   - Underwriter ID, name, region, experience level
   - Performance metrics

5. **CLAIMS** - Claims data
   - Claim number, policy, amount, status (Open/Closed)
   - Claim type, date of loss, settlement date

6. **PREMIUMS** - Premium transactions
   - Written premium, earned premium, unearned premium
   - Transaction dates, adjustments

7. **RESERVES** - Loss reserves
   - Case reserves, IBNR (Incurred But Not Reported)
   - Reserve adequacy indicators

### Investment Tables (3 tables)

8. **INVESTMENTS** - Portfolio holdings
   - Security ID, type, asset class, sector
   - Cost basis, market value, yield
   - Duration, maturity date

9. **INVESTMENT_TRANSACTIONS** - Buy/sell/income
   - Transaction type (Purchase, Sale, Interest, Dividend)
   - Amount, date, realized gain/loss

10. **REINSURANCE** - Reinsurance treaties
    - Treaty details, ceded premium, recoveries
    - Retention limits, coverage types

---

## 🔥 Top 10 Critical Executive Questions

### Underwriting Questions

1. **"What is our combined ratio by product line for the last 12 months?"**
   - *Impact:* Core profitability metric; combined ratio > 100% = underwriting loss
   - *Insight:* Identify unprofitable products requiring rate action

2. **"Which product lines have loss ratios above 65%?"**
   - *Impact:* Target threshold for profitability (varies by product)
   - *Insight:* Prioritize rate increases or underwriting tightening

3. **"Show me claims frequency and severity trends by product over the last 3 years"**
   - *Impact:* Understand root causes of loss ratio deterioration
   - *Insight:* Differentiate frequency vs. severity problems

4. **"Which underwriters have the best combined ratios?"**
   - *Impact:* Identify top performers for best practices sharing
   - *Insight:* Target coaching for underperformers

5. **"What is our reserve adequacy by accident year?"**
   - *Impact:* Inadequate reserves = earnings volatility and regulatory issues
   - *Insight:* Adjust reserving methodology if needed

### Investment Questions

6. **"What is our current asset allocation vs. strategic targets?"**
   - *Impact:* Off-target allocation = unintended risk exposure
   - *Insight:* Rebalance portfolio to meet investment policy

7. **"What is our portfolio yield compared to last quarter and industry benchmarks?"**
   - *Impact:* Investment income is 20-40% of insurer revenue
   - *Insight:* Optimize yield while managing risk

8. **"Show me investment performance by asset class for YTD"**
   - *Impact:* Identify outperforming and underperforming assets
   - *Insight:* Tactical allocation adjustments

9. **"What is our duration gap between assets and liabilities?"**
   - *Impact:* Duration mismatch = interest rate risk
   - *Insight:* Adjust asset duration to match liability duration

10. **"How much investment income are we generating monthly?"**
    - *Impact:* Investment income offsets underwriting losses
    - *Insight:* Forecast cash flows and liquidity

---

## 📈 Sample Data Statistics

- **100,000+ total records** across 10 tables
- **5,000 Active Policies** across 8 product lines
- **15,000 Claims** (mix of open and closed)
- **20,000 Premium Transactions** spanning 3 years
- **500 Investment Holdings** across multiple asset classes
- **10,000 Investment Transactions** (buys, sells, income)
- **500 Underwriters** across 6 Southeast Asian markets
- **Markets Covered:** Singapore, Malaysia, Indonesia, Thailand, Philippines, Vietnam
- **Data Period:** 2022-01-01 to current date

### Product Lines Covered
- Personal Auto
- Commercial Auto
- Homeowners
- Commercial Property
- General Liability
- Workers Compensation
- Professional Liability
- Umbrella/Excess

### Asset Classes Covered
- Corporate Bonds (Investment Grade)
- Municipal Bonds
- Government Bonds (Treasury, Agency)
- Mortgage-Backed Securities (MBS)
- Equities (Common Stock, Preferred Stock)
- Real Estate (REITs, Direct Holdings)

---

## 🚀 Quick Start

### Prerequisites
- Snowflake account with Cortex Analyst access
- ACCOUNTADMIN or equivalent role
- Medium or Large warehouse (recommended)

### Setup Time: ~7-9 minutes

1. **Setup Environment** (2 min) - `01_setup_environment.sql`
   - Creates database `INSURANCE_DEMO`
   - Creates schema `UNDERWRITING_INV`
   - Creates 10 tables

2. **Load Sample Data** (2-4 min) - `02_load_sample_data.sql`
   - Generates 100,000+ realistic synthetic records
   - Establishes proper relationships
   - Ensures data quality and referential integrity
   - **Note**: Time varies by warehouse size (Medium recommended)

3. **Setup Intelligence** (1 min) - `03_setup_intelligence.sql`
   - Creates analytical views for Cortex Analyst
   - Sets up semantic model stage

4. **Upload Semantic Model** (1 min) - `04_upload_semantic_model.sql`
   - Upload `semantic_model.yaml` to Snowflake stage
   - Configure Cortex Analyst

### Demo Time: 5-8 minutes

---

## 📁 Package Contents

```
insurance_underwriting_investment/
├── README.md                       # This file
├── QUICK_START.md                  # Fast setup guide
├── DEMO_GUIDE.md                   # 5-8 minute demo script
├── 01_setup_environment.sql        # Database & table creation
├── 02_load_sample_data.sql         # Synthetic data generation
├── 03_setup_intelligence.sql       # Cortex Analyst setup
├── 04_upload_semantic_model.sql    # Semantic model upload helper
├── 05_demo_queries.sql             # Sample analytical queries
└── semantic_model.yaml             # Cortex Analyst configuration
```

---

## 💡 Key Demo Talking Points

### Value Proposition

**BEFORE Snowflake Intelligence:**
- Actuaries spend days building loss ratio reports
- Investment analysts manually aggregate portfolio data
- Executives wait for scheduled reports
- Ad-hoc questions require new SQL development
- Only technical users can access insights

**AFTER Snowflake Intelligence:**
- Any user asks questions in natural language
- Instant answers with accurate SQL generation
- Real-time decision making
- Self-service analytics for all roles
- Actuaries focus on complex modeling, not reporting

### Business Impact

**Underwriting Impact:**
- 💰 **5-10% improvement in combined ratio** = millions in profitability
- ⚡ **Faster rate adequacy decisions** = competitive advantage
- 🎯 **Better risk selection** = lower loss ratios
- 📊 **Real-time performance tracking** = proactive management

**Investment Impact:**
- 💰 **20-50 bps yield improvement** = significant income increase
- ⚡ **Faster rebalancing decisions** = better risk management
- 🎯 **Optimized asset allocation** = higher returns
- 📊 **Real-time compliance monitoring** = reduced regulatory risk

---

## 🎬 Demo Flow (8 minutes)

**Minutes 1-2: Context Setting**
- Show data model (10 tables, 100K+ records)
- Explain insurance industry challenges
- Introduce Cortex Analyst capabilities

**Minutes 3-4: Underwriting & Product Lines**
- "What is our combined ratio by product line?"
- "Which products have loss ratios above 65%?"
- "Show me top 5 underwriters by performance"

**Minutes 5-6: Investment Management**
- "What is our current asset allocation?"
- "What is our portfolio yield vs. last quarter?"
- "Show me investment income by month for this year"

**Minutes 7-8: Advanced Insights**
- "What is our duration gap between assets and liabilities?"
- "Which claims are driving our high loss ratio in auto?"
- "How do our reserve levels compare to expected losses?"

---

## 🔧 Technical Details

### Warehouse Sizing
- **Setup:** Medium (faster) or Small (cheaper)
- **Demo:** Small warehouse is sufficient
- **Cost:** < $1 for complete setup + demo cycle

### Data Generation Approach
- **Realistic Patterns:** Loss ratios vary by product line (50-85%)
- **Seasonality:** Claims and premiums have realistic patterns
- **Relationships:** All foreign keys properly maintained
- **Data Quality:** No orphan records, proper date sequencing

### Performance
- All analytical queries run in < 5 seconds
- Views pre-aggregate data for optimal performance
- Cortex Analyst generates efficient SQL

---

## 📚 Industry Context

### Key Insurance Metrics

**Combined Ratio** = Loss Ratio + Expense Ratio
- < 100% = Underwriting profit
- > 100% = Underwriting loss (relies on investment income)
- Industry avg: 95-105% depending on line

**Loss Ratio** = Incurred Losses / Earned Premium
- Varies by product: Auto (60-70%), Property (55-65%), Liability (65-75%)

**Investment Yield**
- Insurance companies invest premiums until claims are paid
- Typical portfolio: 80% bonds, 10% equity, 10% other
- Target yield: Varies by risk appetite and duration needs

**Duration Matching (ALM)**
- Long-tail lines (liability) = longer duration assets
- Short-tail lines (auto) = shorter duration assets
- Mismatch = interest rate risk

---

## 🔧 Known Issues & Solutions

### Data Loading
- **Issue**: Column count mismatch errors during data loading
- **Solution**: Ensure you're using the latest version of `02_load_sample_data.sql` which includes explicit column lists for all INSERT statements

### View Queries
- **Issue**: "Division by zero" errors in analytical queries
- **Solution**: Re-run `03_setup_intelligence.sql` to update views with proper division-by-zero protections
- **Details**: The VW_UNDERWRITING_PERFORMANCE view now checks for zero denominators before division

### Performance
- **Data Loading Time**: 2-4 minutes depending on warehouse size
- **Query Performance**: First run may take 3-5 seconds (cold cache), subsequent runs are faster
- **Recommendation**: Use Medium or Large warehouse for optimal performance

---

## 🧹 Cleanup

To remove all demo artifacts:

```sql
DROP DATABASE IF EXISTS INSURANCE_DEMO CASCADE;
DROP WAREHOUSE IF EXISTS DEMO_WH;
```

---

## 📞 Support

For questions or issues:
- Check `DEMO_GUIDE.md` for troubleshooting
- Review Snowflake documentation
- Contact your Snowflake account team

---

## 📊 Success Metrics

A successful demo typically results in:
- ✅ Engagement from actuarial, underwriting, and investment teams
- ✅ Questions about integrating with existing data
- ✅ Requests for POC with real data
- ✅ Discussion of governance and security
- ✅ Follow-up meeting scheduled

---

**Built for Insurance Professionals | Powered by Snowflake Intelligence**

*Last Updated: January 2026*

