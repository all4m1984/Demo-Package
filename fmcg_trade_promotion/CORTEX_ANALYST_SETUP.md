# Cortex Analyst Setup Guide - FMCG Trade Promotion & Demand Intelligence

## Overview

This guide provides detailed instructions for setting up and using **Snowflake Cortex Analyst** with the FMCG Trade Promotion & Demand Intelligence demo package.

## Prerequisites

- Snowflake account with **Cortex Analyst** enabled
- Completed execution of scripts:
  - `01_setup_environment.sql`
  - `02_load_sample_data.sql`
  - `03_setup_intelligence.sql`
- The `semantic_model.yaml` file from this package

## Semantic Model Upload

### Method 1: Snowsight UI (Recommended for Demos)

1. **Navigate to Stages**
   - In Snowsight, click **Data** in the left sidebar
   - Expand **Databases** → **FMCG_TRADE_DEMO** → **ANALYTICS**
   - Click on **Stages**

2. **Access CORTEX_STAGE**
   - Click on **CORTEX_STAGE** in the list
   - You should see an empty stage (or existing files if previously uploaded)

3. **Upload File**
   - Click the **+ Files** button in the top right
   - Browse and select `semantic_model.yaml` from this folder
   - Click **Upload**
   - Wait for the upload to complete (usually <5 seconds)

4. **Verify Upload**
   - Confirm `semantic_model.yaml` appears in the file list
   - Note the file size and upload timestamp

### Method 2: SnowSQL Command Line

1. **Open Terminal/Command Prompt**
   - Navigate to the folder containing `semantic_model.yaml`
   ```bash
   cd "/path/to/fmcg_trade_promotion"
   ```

2. **Execute PUT Command**
   ```sql
   PUT file://semantic_model.yaml 
   @FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE 
   AUTO_COMPRESS=FALSE 
   OVERWRITE=TRUE;
   ```

3. **Verify Upload**
   ```sql
   LIST @FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE;
   ```

### Method 3: Python (Snowflake Connector)

```python
import snowflake.connector

# Connect to Snowflake
conn = snowflake.connector.connect(
    user='YOUR_USERNAME',
    password='YOUR_PASSWORD',
    account='YOUR_ACCOUNT',
    warehouse='FMCG_WH',
    database='FMCG_TRADE_DEMO',
    schema='ANALYTICS'
)

# Upload semantic model
cursor = conn.cursor()
cursor.execute("""
    PUT file://semantic_model.yaml 
    @CORTEX_STAGE 
    AUTO_COMPRESS=FALSE 
    OVERWRITE=TRUE
""")

# Verify
cursor.execute("LIST @CORTEX_STAGE")
for row in cursor:
    print(row)

cursor.close()
conn.close()
```

## Connecting Cortex Analyst

### Step 1: Open Cortex Analyst

1. In Snowsight, look for **Cortex Analyst** in the left navigation
   - It may be under **AI & ML** section
   - Or directly in the main navigation

2. Click **Cortex Analyst** to open

3. Click **New Conversation** or **+ New** to start

### Step 2: Select Semantic Model

When prompted to select a semantic model:

1. **Enter the stage path:**
   ```
   @FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE/semantic_model.yaml
   ```

2. **Or browse:**
   - Click **Browse** button
   - Navigate to: FMCG_TRADE_DEMO → ANALYTICS → CORTEX_STAGE
   - Select `semantic_model.yaml`

3. **Click Connect** or **Load**

### Step 3: Verify Connection

The interface should display:
- ✅ Semantic model loaded successfully
- Model name: "FMCG Trade Promotion & Demand Intelligence"
- Ready to accept natural language questions

**Test with a simple question:**
```
How many stores do we have?
```

Expected response should mention 250 stores.

## Using Cortex Analyst

### Natural Language Query Patterns

Cortex Analyst understands various question formats:

**Direct Questions:**
- "What is the total revenue last month?"
- "How many SKUs are in the Beverages category?"
- "Which stores are in the West region?"

**Comparative Questions:**
- "Compare promotion ROI across different promotion types"
- "Show me forecast accuracy vs actual sales"
- "What is the difference between promoted and baseline sales?"

**Analytical Questions:**
- "Which promotions had the best ROI?"
- "What are the top 10 products by revenue?"
- "Show me stores with the worst OSA performance"

**Time-Based Questions:**
- "What was total revenue last quarter?"
- "Show me sales trend over the last 90 days"
- "What is next week's demand forecast?"

**Aggregated Questions:**
- "Average promotion lift by category"
- "Total lost revenue from stockouts"
- "Sum of incremental revenue by region"

### Sample Demo Questions

#### Trade Promotion Optimization

```
Which promotions had the highest ROI last quarter?

Show me promotion lift by promotion type

What is the incremental revenue from promotions in the Beverages category?

Which product categories respond best to discounts?

Compare BOGO promotions vs Discount promotions

Show me top 5 stores by promotion ROI in the West region

What is the average compliance score for Feature promotions?

Which brands have the highest promotion lift?
```

#### Demand Forecasting

```
What is the demand forecast for our top 10 products next week?

Show me forecast accuracy by category last month

Which products have the highest forecast error?

What is the expected demand for beverages in the West region?

Show me forecast bias by region

What is the MAPE for Dairy products?

Compare forecasted vs actual units for the last 30 days

Which stores have the best forecast accuracy?
```

#### On-Shelf Availability

```
Which stores have the highest out-of-stock rates?

What is the estimated lost revenue from stockouts this month?

Show me OSA percentage by product category

Which SKUs have critical out-of-stock risk?

What is the average inventory level for top-selling products?

Show me stores with OSA below 85%

What is the total lost revenue in the North region?

Which categories have the worst OSA performance?
```

#### Integrated Analysis

```
How do promotions impact on-shelf availability?

What is the forecast accuracy for highly promoted categories?

Show me correlation between OSA and sales performance

Which stores have both high promotion ROI and high OSA?

Compare OSA during promotional vs non-promotional periods
```

## Semantic Model Structure

The semantic model includes:

### Tables (10)
1. **PRODUCTS** - Product master data
2. **STORES** - Store master data
3. **DAILY_SALES** - Sales transactions
4. **TRADE_PROMOTIONS** - Promotion master
5. **INVENTORY_LEVELS** - Inventory tracking
6. **DEMAND_FORECAST** - Forecast data
7. **VW_PROMOTION_PERFORMANCE** - Promotion analytics
8. **VW_FORECAST_ACCURACY** - Forecast metrics
9. **VW_OSA_METRICS** - OSA analytics
10. **VW_CATEGORY_PERFORMANCE** - Category analytics

### Key Metrics
- **Promotion ROI %**: Return on investment for promotions
- **Promotion Lift %**: Sales uplift from promotions
- **Incremental Revenue**: Revenue above baseline
- **OSA %**: On-shelf availability percentage
- **MAPE**: Mean absolute percentage error (forecast accuracy)
- **Lost Revenue**: Estimated revenue lost from stockouts

### Relationships
- Sales ↔ Products
- Sales ↔ Stores
- Sales ↔ Promotions
- Inventory ↔ Products/Stores
- Forecast ↔ Products/Stores

## Troubleshooting

### Issue: "Unable to parse yaml to protobuf"

**Cause:** Semantic model YAML has syntax or schema errors

**Solution:**
1. Verify the YAML file is not corrupted
2. Check for proper indentation (use spaces, not tabs)
3. Ensure all required fields are present
4. Re-download the `semantic_model.yaml` from the package

### Issue: "Semantic model not found"

**Cause:** File not uploaded or incorrect path

**Solution:**
1. Verify file exists in stage:
   ```sql
   LIST @FMCG_TRADE_DEMO.ANALYTICS.CORTEX_STAGE;
   ```
2. Check exact path used in Cortex Analyst
3. Ensure path format is correct:
   ```
   @DATABASE.SCHEMA.STAGE/filename.yaml
   ```

### Issue: "No data returned" or "Empty results"

**Cause:** Data not loaded or tables are empty

**Solution:**
1. Verify data was loaded:
   ```sql
   SELECT COUNT(*) FROM DAILY_SALES;
   SELECT COUNT(*) FROM PRODUCTS;
   SELECT COUNT(*) FROM STORES;
   ```
2. Re-run `02_load_sample_data.sql` if tables are empty
3. Check warehouse is running

### Issue: Cortex Analyst returns errors for valid questions

**Cause:** Semantic model doesn't cover the requested data

**Solution:**
1. Review the semantic model structure
2. Rephrase question using terms defined in the model
3. Check if the requested table/column is included
4. Use verified queries as examples

### Issue: Slow query response

**Cause:** Warehouse size or data volume

**Solution:**
1. Resize warehouse:
   ```sql
   ALTER WAREHOUSE FMCG_WH SET WAREHOUSE_SIZE = 'SMALL';
   ```
2. Add indexes or clustering keys to large tables
3. Use views for complex aggregations

## Best Practices

### For Demos

1. **Start Simple**
   - Begin with basic questions to verify setup
   - Example: "How many stores do we have?"

2. **Build Complexity**
   - Move to aggregations: "What is total revenue?"
   - Then to analytics: "Which promotions had best ROI?"

3. **Showcase Different Use Cases**
   - Trade Promotion → Demand Forecasting → OSA
   - Show cross-functional insights

4. **Highlight Natural Language**
   - Ask questions in different ways
   - Show synonyms work (e.g., "revenue" vs "sales")

5. **Compare to Traditional BI**
   - Show equivalent SQL query complexity
   - Demonstrate time savings

### For Development

1. **Test Verified Queries First**
   - Use the 4 verified queries in the semantic model
   - Ensure they return correct results

2. **Iteratively Expand**
   - Start with core tables
   - Add views and relationships incrementally
   - Test after each addition

3. **Document Business Context**
   - Use `customInstructions` to explain metrics
   - Define synonyms for common terms
   - Provide examples of typical questions

4. **Monitor Performance**
   - Track query execution time
   - Optimize underlying views if needed
   - Consider materialized views for large datasets

## Advanced Configuration

### Adding Custom Metrics

To add new calculated metrics to the semantic model:

1. Create a view with the metric:
```sql
CREATE OR REPLACE VIEW VW_MY_METRIC AS
SELECT 
    ...,
    (calculation) as MY_METRIC
FROM ...;
```

2. Add to `semantic_model.yaml`:
```yaml
- name: VW_MY_METRIC
  description: "Description of the metric"
  base_table:
    database: FMCG_TRADE_DEMO
    schema: ANALYTICS
    table: VW_MY_METRIC
  facts:
    - name: MY_METRIC
      synonyms: ["alternate names"]
      description: "What this metric measures"
      expr: MY_METRIC
      dataType: number
      defaultAggregation: sum
```

3. Re-upload semantic model to stage

4. Reconnect Cortex Analyst

### Updating the Semantic Model

When you modify `semantic_model.yaml`:

1. Upload the updated file (use OVERWRITE=TRUE)
2. In Cortex Analyst, start a new conversation
3. Select the updated semantic model
4. Test changes with relevant questions

## Support

For issues with:
- **Snowflake Cortex Analyst**: Contact Snowflake Support
- **Demo Package**: Review README.md and this guide
- **Data Issues**: Re-run setup scripts

---

**Ready to demonstrate Snowflake Intelligence for FMCG!** 🎯📊

