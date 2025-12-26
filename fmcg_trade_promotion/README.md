# FMCG Trade Promotion & Demand Intelligence Demo Package

## Overview

This demo package showcases **Snowflake Intelligence** and **Cortex Analyst** capabilities for the **Fast-Moving Consumer Goods (FMCG)** industry, specifically addressing:

- 🎯 **Trade Promotion Optimization**
- 📊 **Demand Forecasting** 
- 📦 **On-Shelf Availability & Gap Analysis**

## Top 10 Critical Business Questions

This demo helps FMCG executives answer these critical questions:

1. **Which trade promotions are delivering the best ROI and incremental lift?**
2. **What is the demand forecast for our top products next month?**
3. **Which stores have the highest out-of-stock rates and what is the lost revenue?**
4. **How effective are different promotion mechanics (discount vs display vs feature)?**
5. **What is the optimal promotion calendar to maximize revenue without cannibalizing margins?**
6. **Which product categories show the highest promotional elasticity?**
7. **What is our on-shelf availability by store format and region?**
8. **How do promotional sales compare to baseline sales across different channels?**
9. **What is the impact of stockouts on customer satisfaction and market share?**
10. **Which SKUs should we prioritize for promotion investment based on forecast and inventory?**

## Demo Duration

- **Preparation Time**: 10 minutes
- **Demo Time**: 15 minutes
- **Total**: ~25 minutes

## Data Model

### Core Tables

1. **PRODUCTS** - Product master data (SKU, brand, category, pricing)
2. **STORES** - Store master data (location, format, region, size)
3. **DAILY_SALES** - Daily sales transactions by product and store
4. **TRADE_PROMOTIONS** - Promotion master data (mechanics, discounts, timing)
5. **PROMOTION_EVENTS** - Specific promotion executions at stores
6. **INVENTORY_LEVELS** - Daily inventory and out-of-stock tracking
7. **DEMAND_FORECAST** - Forecasted demand by product and store
8. **SUPPLY_CHAIN_LEAD_TIMES** - Supplier lead times for replenishment

### Analytical Views

1. **VW_PROMOTION_PERFORMANCE** - Aggregated promotion effectiveness metrics
2. **VW_FORECAST_ACCURACY** - Forecast vs actual comparison
3. **VW_OSA_METRICS** - On-shelf availability metrics by product/store

## Data Volume

- **500 SKUs** across multiple categories and brands
- **250 Stores** across different formats and regions
- **180 days** of daily sales history (~45K sales records per day)
- **100 Trade Promotions** with various mechanics
- **5,000+ Promotion Events** across stores
- **180 days** of inventory tracking
- **30 days** of forward-looking demand forecasts

## Setup Instructions

### Prerequisites

- Snowflake account with Cortex Analyst enabled
- ACCOUNTADMIN or sufficient privileges to create database, schema, warehouse, and stage
- SnowSQL or Snowsight access

### Step-by-Step Setup

#### 1. Create Environment & Load Data (7 minutes)

```sql
-- Execute these scripts in order:
01_setup_environment.sql    -- Creates database, schema, tables, warehouse
02_load_sample_data.sql     -- Loads synthetic FMCG data
```

#### 2. Setup Intelligence & Semantic Model (3 minutes)

```sql
-- Execute these scripts:
03_setup_intelligence.sql   -- Creates analytical views and stage
04_upload_semantic_model.sql -- Instructions to upload semantic model
```

Upload the `semantic_model.yaml` file to the Snowflake stage:
- Via Snowsight UI: Data > Databases > FMCG_TRADE_DEMO > ANALYTICS > Stages > CORTEX_STAGE
- Or via SnowSQL: `PUT file://semantic_model.yaml @FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE`

#### 3. Connect Cortex Analyst

In Snowsight:
1. Navigate to **Cortex Analyst**
2. Select semantic model: `@FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE/semantic_model.yaml`
3. Start asking natural language questions!

## Demo Flow (15 minutes)

### Part 1: Trade Promotion Optimization (5 minutes)

**Natural Language Questions:**
- "Which trade promotions had the highest ROI last quarter?"
- "Show me promotion lift by promotion type"
- "What is the incremental revenue from promotions vs baseline sales?"
- "Which product categories respond best to discounts?"

**Key Insights to Highlight:**
- Promotion ROI calculation (incremental profit / promotion cost)
- Lift analysis (promotional sales vs baseline)
- Cross-promotion cannibalization effects
- Optimal promotion mechanics by category

### Part 2: Demand Forecasting (5 minutes)

**Natural Language Questions:**
- "What is the demand forecast for our top 10 products next week?"
- "Show me forecast accuracy for the last month"
- "Which products have the highest forecast error?"
- "What is expected demand for beverages in the West region?"

**Key Insights to Highlight:**
- Forecast accuracy metrics (MAPE, bias)
- Seasonal patterns and trends
- Forecast-driven replenishment recommendations
- Impact of promotions on forecast accuracy

### Part 3: On-Shelf Availability & Gap Analysis (5 minutes)

**Natural Language Questions:**
- "Which stores have the highest out-of-stock rates?"
- "What is the lost revenue from stockouts this month?"
- "Show me on-shelf availability by product category"
- "Which SKUs have the worst inventory turnover?"

**Key Insights to Highlight:**
- OSA (On-Shelf Availability) % by store/category
- Estimated lost sales from stockouts
- Phantom inventory (system says in stock but shelf is empty)
- Replenishment gap analysis

## Files Included

- `README.md` - This file
- `QUICK_START.md` - Quick reference guide
- `01_setup_environment.sql` - Database, schema, tables, warehouse creation
- `02_load_sample_data.sql` - Synthetic data generation and loading
- `03_setup_intelligence.sql` - Analytical views and Cortex setup
- `04_upload_semantic_model.sql` - Semantic model upload instructions
- `05_demo_queries.sql` - Sample SQL queries for validation
- `semantic_model.yaml` - Cortex Analyst semantic model definition
- `CORTEX_ANALYST_SETUP.md` - Detailed Cortex Analyst setup guide

## Key Metrics Explained

### Trade Promotion Metrics

- **Promotion ROI**: (Incremental Profit - Promotion Cost) / Promotion Cost
- **Promotion Lift**: (Promoted Sales - Baseline Sales) / Baseline Sales
- **Incremental Sales**: Promoted Sales - Baseline Sales
- **Discount Depth**: (Regular Price - Promoted Price) / Regular Price

### Demand Forecast Metrics

- **MAPE** (Mean Absolute Percentage Error): Average forecast accuracy
- **Forecast Bias**: Tendency to over/under forecast
- **Safety Stock**: Buffer inventory for demand variability

### On-Shelf Availability Metrics

- **OSA %**: (Days In-Stock / Total Days) * 100
- **Lost Sales**: Out-of-Stock Days * Average Daily Demand * Unit Price
- **Inventory Turnover**: Sales / Average Inventory

## Business Impact

Using Snowflake Intelligence for FMCG operations can deliver:

- **15-25% improvement** in promotion ROI through better targeting
- **10-15% reduction** in forecast error leading to optimized inventory
- **2-5% sales uplift** from improved on-shelf availability
- **20-30% faster** insights from natural language querying vs traditional BI

## Support & Customization

This demo uses synthetic data designed to represent realistic FMCG scenarios. For production use:

- Integrate with your ERP/POS systems for real sales data
- Connect to your trade promotion management system
- Incorporate external data (weather, holidays, competitor activity)
- Customize the semantic model with your specific product hierarchies and KPIs

## Next Steps

1. Execute the setup scripts in order
2. Upload the semantic model
3. Try the sample questions in Cortex Analyst
4. Explore your own business questions using natural language!

---

**Version**: 1.0  
**Last Updated**: December 2025  
**Industry**: Fast-Moving Consumer Goods (FMCG)  
**Use Cases**: Trade Promotion Optimization, Demand Forecasting, On-Shelf Availability

