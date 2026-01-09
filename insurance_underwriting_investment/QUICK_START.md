# Insurance Underwriting & Investment Management - Quick Start Guide
## Southeast Asia Edition

## ⚡ 15-17 Minute Setup + Demo

Get from zero to a working demo in 15-17 minutes for Southeast Asian insurance markets!

---

## 📋 Prerequisites

- **Snowflake Account** with Cortex Analyst enabled
- **Role**: ACCOUNTADMIN or equivalent
- **Warehouse**: Medium or Large (recommended for faster setup)
- **Time**: 15-17 minutes total (7-9 min setup + 8 min demo)

---

## 🚀 Step-by-Step Setup (7-9 minutes)

### Step 1: Setup Environment (2 minutes)

```sql
-- Open and run: 01_setup_environment.sql
```

**What this does:**
- Creates database `INSURANCE_DEMO`
- Creates schema `UNDERWRITING_INV`
- Creates 10 tables (underwriting + investment)

**Expected Output:**
```
✓ Environment setup complete
✓ 10 tables created
```

---

### Step 2: Load Sample Data (2-4 minutes)

```sql
-- Open and run: 02_load_sample_data.sql
```

**What this does:**
- Generates 100,000+ realistic synthetic records
- Populates all 10 tables with interconnected data
- Creates realistic loss ratios, claim patterns, investment holdings
- **Note**: Time varies by warehouse size (Medium warehouse recommended)

**Expected Output:**
```
✓ Sample data loaded successfully!
✓ 100,000+ records across 10 tables
```

**Data Generated:**
- 10 Products (9 active across 8 product lines)
- 500 Underwriters
- 10,000 Policyholders
- 5,000 Policies
- 20,000+ Premium transactions
- 15,000 Claims
- 5,000+ Reserve records
- 500 Investment holdings
- 10,000+ Investment transactions
- 50 Reinsurance treaties

---

### Step 3: Setup Intelligence (1 minute)

```sql
-- Open and run: 03_setup_intelligence.sql
```

**What this does:**
- Creates 6 analytical views for Cortex Analyst
- Aggregates data for optimal query performance
- Creates stage for semantic model upload

**Expected Output:**
```
✓ Intelligence setup complete!
✓ 6 analytical views created
✓ CORTEX_STAGE ready for semantic model
```

**Views Created:**
1. `VW_UNDERWRITING_PERFORMANCE` - Product line metrics
2. `VW_CLAIMS_ANALYSIS` - Detailed claims data
3. `VW_RESERVE_ADEQUACY` - Reserve adequacy analysis
4. `VW_POLICY_SUMMARY` - Policy-level summary
5. `VW_INVESTMENT_PORTFOLIO` - Portfolio holdings
6. `VW_INVESTMENT_PERFORMANCE` - Investment performance metrics

---

### Step 4: Upload Semantic Model (1 minute)

**Option A: Using SnowSQL (Command Line)**

```bash
snowsql -c your_connection

USE DATABASE INSURANCE_DEMO;
USE SCHEMA UNDERWRITING_INV;

PUT file:///path/to/semantic_model.yaml @CORTEX_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

**Option B: Using Snowsight UI**

1. Navigate to **Data > Databases > INSURANCE_DEMO > UNDERWRITING_INV > Stages**
2. Click on **CORTEX_STAGE**
3. Click **"+ Files"** button
4. Select **`semantic_model.yaml`** from your local machine
5. Click **"Upload"**

**Verify Upload:**
```sql
LIST @CORTEX_STAGE;
-- You should see semantic_model.yaml
```

---

## 🎯 Step 5: Configure Cortex Analyst (< 1 minute)

1. In Snowsight, navigate to **Projects > Cortex Analyst**
2. Click **"+ New Analyst App"**
3. Configure:
   - **Name**: Insurance Underwriting & Investment Demo
   - **Database**: INSURANCE_DEMO
   - **Schema**: UNDERWRITING_INV
   - **Stage**: CORTEX_STAGE
   - **Semantic Model File**: semantic_model.yaml
4. Click **"Create"**

---

## 🎬 Demo Time! (8 minutes)

Now you're ready to ask questions in natural language!

### Sample Questions to Try:

**Underwriting Questions:**
1. *"What is the combined ratio by product line for the last 12 months?"*
2. *"Which product lines have loss ratios above 65%?"*
3. *"Who are the top 10 underwriters by combined ratio?"*
4. *"Show me claims frequency and severity by product type"*
5. *"What is our reserve adequacy by accident year?"*

**Investment Questions:**
6. *"What is our current asset allocation?"*
7. *"What is our portfolio yield compared to last quarter?"*
8. *"How much investment income are we generating monthly?"*
9. *"Show me investment performance by asset class for this year"*
10. *"What is our average portfolio duration?"*

---

## 💡 Key Demo Talking Points

### Why This Matters

**Before Snowflake Intelligence:**
- ❌ Actuaries spend days building loss ratio reports
- ❌ Investment analysts manually aggregate portfolio data
- ❌ Executives wait for scheduled reports
- ❌ Ad-hoc questions require SQL development
- ❌ Only technical users can access insights

**After Snowflake Intelligence:**
- ✅ Any user asks questions in natural language
- ✅ Instant answers with accurate SQL generation
- ✅ Real-time decision making
- ✅ Self-service analytics for all roles
- ✅ Actuaries focus on modeling, not reporting

### Business Impact

**Underwriting:**
- 💰 **5-10% improvement in combined ratio** = millions in profitability
- ⚡ **Faster rate adequacy decisions** = competitive advantage
- 🎯 **Better risk selection** = lower loss ratios

**Investment:**
- 💰 **20-50 bps yield improvement** = significant income increase
- ⚡ **Faster rebalancing** = better risk management
- 🎯 **Optimized allocation** = higher returns

---

## 🔧 Troubleshooting

### Issue: "Table does not exist"
**Solution**: Ensure you ran scripts 1-3 in order

### Issue: "Cortex Analyst not available"
**Solution**: Contact your Snowflake account team to enable

### Issue: "No data returned"
**Solution**: Verify data was loaded:
```sql
SELECT COUNT(*) FROM VW_UNDERWRITING_PERFORMANCE;
-- Should return > 0
```

### Issue: "Division by zero" error in queries
**Solution**: Ensure you ran the latest version of `03_setup_intelligence.sql` which includes division-by-zero protections in views. Re-run the script if needed:
```sql
-- Re-run to update views
USE DATABASE INSURANCE_DEMO;
USE SCHEMA UNDERWRITING_INV;
@03_setup_intelligence.sql
```

### Issue: "Semantic model validation failed"
**Solution**: Verify YAML file syntax and structure

### Issue: Data loading takes longer than expected
**Solution**: 
- Ensure you're using a Medium or Large warehouse for faster processing
- Data generation involves RANDOM() functions which can vary in performance
- Expected time: 2-4 minutes depending on warehouse size

---

## 📊 Verification Checklist

Before starting demo, verify:

- [ ] All 10 tables created
- [ ] All 6 views created
- [ ] Data loaded (100,000+ records)
- [ ] Semantic model uploaded to stage
- [ ] Cortex Analyst app configured
- [ ] Sample question returns results

**Quick Verification Query:**
```sql
SELECT 
    'Products' as TABLE_NAME, COUNT(*) as COUNT FROM PRODUCTS
UNION ALL
SELECT 'Policies', COUNT(*) FROM POLICIES
UNION ALL
SELECT 'Claims', COUNT(*) FROM CLAIMS
UNION ALL
SELECT 'Investments', COUNT(*) FROM INVESTMENTS
UNION ALL
SELECT 'VW_UNDERWRITING_PERFORMANCE', COUNT(*) FROM VW_UNDERWRITING_PERFORMANCE
UNION ALL
SELECT 'VW_INVESTMENT_PORTFOLIO', COUNT(*) FROM VW_INVESTMENT_PORTFOLIO;
```

---

## 🧹 Cleanup (Optional)

After demo, to remove all artifacts:

```sql
DROP DATABASE IF EXISTS INSURANCE_DEMO CASCADE;
DROP WAREHOUSE IF EXISTS DEMO_WH;
```

---

## 📚 Next Steps

- **For detailed demo script**: See `DEMO_GUIDE.md`
- **For sample SQL queries**: See `05_demo_queries.sql`
- **For comprehensive documentation**: See `README.md`

---

## 🆘 Support

- **Documentation**: Check `README.md` for detailed information
- **Snowflake Docs**: [docs.snowflake.com/cortex-analyst](https://docs.snowflake.com/en/user-guide/cortex-analyst)
- **Account Team**: Contact your Snowflake representative

---

**Ready to go? Start with Step 1!** 🚀

*Good luck with your demo!*

---

*Last Updated: January 2026*
