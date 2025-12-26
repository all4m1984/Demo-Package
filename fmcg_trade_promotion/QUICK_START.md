# FMCG Trade Promotion & Demand Intelligence - Quick Start Guide

## ⚡ Fast Setup (10 Minutes)

### Step 1: Create Environment & Load Data (7 minutes)

Execute these scripts **in order** in Snowsight or SnowSQL:

```sql
-- 1. Setup environment (creates database, schema, tables, warehouse)
@01_setup_environment.sql

-- 2. Load sample data (generates realistic FMCG data)
@02_load_sample_data.sql
```

**Expected Results:**
- ✅ Database: `FMCG_TRADE_DEMO`
- ✅ Schema: `ANALYTICS`
- ✅ Warehouse: `FMCG_WH`
- ✅ 8 Core Tables with data
- ✅ 500 SKUs, 250 Stores, 180 days of sales history

### Step 2: Setup Intelligence (3 minutes)

```sql
-- 3. Create analytical views and stage
@03_setup_intelligence.sql

-- 4. Review upload instructions
@04_upload_semantic_model.sql
```

**Expected Results:**
- ✅ 4 Analytical Views created
- ✅ CORTEX_STAGE created and ready

### Step 3: Upload Semantic Model

**Option A - Snowsight UI (Recommended):**
1. Navigate to: **Data** → **Databases** → **FMCG_TRADE_DEMO** → **ANALYTICS** → **Stages**
2. Click **CORTEX_STAGE**
3. Click **+ Files** button
4. Upload `semantic_model.yaml` from this folder
5. Verify file appears in the list

**Option B - SnowSQL Command Line:**
```bash
PUT file://semantic_model.yaml @FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

**Verify Upload:**
```sql
LIST @CORTEX_STAGE;
```

### Step 4: Connect Cortex Analyst

1. In Snowsight, navigate to **Cortex Analyst** (left sidebar)
2. Click **New Conversation**
3. When prompted, select semantic model:
   ```
   @FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE/semantic_model.yaml
   ```
4. Start asking questions!

---

## 🎯 Demo Flow (15 Minutes)

### Part 1: Trade Promotion Optimization (5 min)

**Try these questions:**

```
Which promotions had the highest ROI last quarter?

Show me promotion lift by promotion type

What is the incremental revenue from promotions in the Beverages category?

Which product categories respond best to discounts?

Show me top 5 stores by promotion ROI
```

**Key Insights to Highlight:**
- Promotion ROI calculation (incremental profit / cost)
- Lift analysis (promoted vs baseline sales)
- Category responsiveness to different promotion mechanics
- Regional performance variations

### Part 2: Demand Forecasting (5 min)

**Try these questions:**

```
What is the demand forecast for our top 10 products next week?

Show me forecast accuracy by category last month

Which products have the highest forecast error?

What is the expected demand for beverages in the West region?

Show me forecast bias by region
```

**Key Insights to Highlight:**
- Forecast accuracy metrics (MAPE)
- Bias patterns (over-forecast vs under-forecast)
- Seasonal trends and patterns
- Confidence intervals and prediction quality

### Part 3: On-Shelf Availability & Gap Analysis (5 min)

**Try these questions:**

```
Which stores have the highest out-of-stock rates?

What is the estimated lost revenue from stockouts this month?

Show me OSA percentage by product category

Which SKUs have critical out-of-stock risk?

What is the average inventory level for top-selling products?
```

**Key Insights to Highlight:**
- OSA % (On-Shelf Availability) metrics
- Lost sales opportunity calculations
- Inventory turnover and days of supply
- Risk classifications (Critical, High, Medium, Low)

---

## 📊 Key Metrics Reference

### Promotion Metrics
- **ROI (%)**: (Incremental Profit - Promo Cost) / Promo Cost × 100
- **Lift (%)**: (Promoted Sales - Baseline) / Baseline × 100
- **Incremental Revenue**: Promoted Sales - Expected Baseline Sales

### Forecast Metrics
- **MAPE**: Mean Absolute Percentage Error (accuracy measure)
- **Forecast Bias**: Over-forecast or Under-forecast tendency
- **Confidence Level**: Prediction confidence (0-100)

### OSA Metrics
- **OSA %**: Days In-Stock / Total Days × 100
- **Lost Revenue**: OOS Days × Avg Daily Sales × Unit Price
- **Days of Supply**: Avg Inventory / Avg Daily Sales

---

## ⚠️ Troubleshooting

### Issue: Tables are empty after running scripts
**Solution:** Make sure you executed scripts in order:
1. `01_setup_environment.sql` first
2. `02_load_sample_data.sql` second
3. Wait for completion before proceeding

### Issue: Semantic model upload fails
**Solution:** 
- Check file name is exactly `semantic_model.yaml`
- Verify you're uploading to correct stage: `CORTEX_STAGE`
- Try deleting old file from stage before re-uploading

### Issue: Cortex Analyst can't find semantic model
**Solution:**
- Verify file is in stage: `LIST @CORTEX_STAGE;`
- Use full path: `@FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE/semantic_model.yaml`
- Check Cortex Analyst is enabled in your account

### Issue: Queries return no data
**Solution:**
- Verify warehouse is running: `SHOW WAREHOUSES;`
- Check data was loaded: `SELECT COUNT(*) FROM DAILY_SALES;`
- Confirm you're in correct database/schema:
  ```sql
  USE DATABASE FMCG_TRADE_DEMO;
  USE SCHEMA ANALYTICS;
  ```

---

## 🔄 Data Refresh

To regenerate data with different patterns:

```sql
-- Re-run data loading script
@02_load_sample_data.sql
```

To completely reset the demo:

```sql
-- Drop and recreate everything
DROP DATABASE IF EXISTS FMCG_TRADE_DEMO;
DROP WAREHOUSE IF EXISTS FMCG_WH;

-- Then re-run all setup scripts
@01_setup_environment.sql
@02_load_sample_data.sql
@03_setup_intelligence.sql
```

---

## 📚 Additional Resources

- **Full Documentation**: See `README.md`
- **Cortex Analyst Setup**: See `CORTEX_ANALYST_SETUP.md`
- **Sample SQL Queries**: See `05_demo_queries.sql`

---

## ✅ Validation Checklist

Before starting your demo:

- [ ] All 8 tables populated with data
- [ ] 4 analytical views created and queryable
- [ ] CORTEX_STAGE exists and contains `semantic_model.yaml`
- [ ] Cortex Analyst connected to semantic model
- [ ] Test question works: "How many stores do we have?"
- [ ] Warehouse `FMCG_WH` is running

---

**Need Help?** Check the full `README.md` for detailed explanations and business context.

**Ready to Demo?** Start with simple questions and progressively ask more complex analytical queries!

