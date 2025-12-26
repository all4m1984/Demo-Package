# 🎯 Snowflake Intelligence Demo Guide
## Oil & Gas Upstream Operations

**Duration**: 5-8 minutes  
**Audience**: Executives, Operations Managers, Analytics Leaders  
**Objective**: Demonstrate how Snowflake Intelligence enables natural language queries to derive critical business insights instantly

---

## 📋 Pre-Demo Checklist (15 minutes setup)

### 1. Environment Setup
```sql
-- Execute these scripts in order:
✅ 01_setup_environment.sql    (1 min)  - Creates database, schema, tables
✅ 02_load_sample_data.sql     (3-5 min) - Loads synthetic operational data
✅ 03_setup_intelligence.sql   (1 min)  - Creates analytical views and stage
```

### 2. Semantic Model Deployment
```sql
-- Upload the semantic model to Snowflake stage:
✅ Run: 04_upload_semantic_model.sql
-- Or manually: PUT file://semantic_model.yaml @CORTEX_STAGE AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
```

### 3. Verify Data
```sql
-- Quick validation queries:
SELECT COUNT(*) FROM WELLS;              -- Should show 200 wells
SELECT COUNT(*) FROM PRODUCTION_DAILY;   -- Should show 36,500 records
SELECT COUNT(*) FROM EQUIPMENT_ASSETS;   -- Should show 600+ assets
```

### 4. Open Cortex Analyst
- Navigate to: **Projects** → **Cortex Analyst**
- Select your semantic model from `@CORTEX_STAGE/semantic_model.yaml`
- Test connection with a simple query: "How many wells do we have?"

---

## 🎬 Demo Script: 5-8 Minute Executive Walkthrough

### **Introduction (30 seconds)**
> "Today I'll show you how Snowflake Intelligence empowers executives to get instant answers to critical operational questions using natural language—no SQL or technical expertise required. We're using real-world oil & gas upstream operations data."

---

## 📊 Demo Flow: Structured Question Types

### **1️⃣ WHEN Questions - Temporal Analysis (1 min)**

#### **Q1: Production Timing**
**Ask Cortex Analyst:**
> "When did we achieve our highest daily production rates in the last year?"

**Expected Insights:**
- Peak production dates and volumes
- Seasonal patterns
- Correlation with operational events

**Business Value:**
> "Executives can instantly identify peak performance periods and understand what drove success—without waiting for analyst reports."

---

#### **Q2: Maintenance Windows**
**Ask Cortex Analyst:**
> "When are our critical equipment assets due for maintenance in the next 3 months?"

**Expected Insights:**
- Upcoming maintenance schedules
- Equipment at risk of downtime
- Proactive planning opportunities

**Business Value:**
> "Operations teams can proactively schedule maintenance, avoiding unplanned downtime and production losses."

---

### **2️⃣ WHICH Questions - Identification & Ranking (1.5 min)**

#### **Q3: Top Performers**
**Ask Cortex Analyst:**
> "Which wells are our top 10 producers by oil volume?"

**Expected Insights:**
- Well IDs and production volumes
- Field and project breakdown
- Production efficiency metrics

**Business Value:**
> "Identify star performers instantly to replicate success factors across other assets."

---

#### **Q4: Underperformers**
**Ask Cortex Analyst:**
> "Which wells have declining production rates over the past 6 months?"

**Expected Insights:**
- Wells with negative trends
- Magnitude of decline
- Potential intervention candidates

**Business Value:**
> "Early detection of underperforming assets enables timely intervention and optimization strategies."

---

#### **Q5: Equipment Risk**
**Ask Cortex Analyst:**
> "Which equipment assets have the highest maintenance costs?"

**Expected Insights:**
- Costliest assets to maintain
- Replacement vs. repair economics
- Budget allocation priorities

**Business Value:**
> "Focus capital expenditure on assets with poor maintenance economics, improving ROI."

---

### **3️⃣ WHERE Questions - Geographic & Location Analysis (1 min)**

#### **Q6: Field Performance**
**Ask Cortex Analyst:**
> "Where are our most productive fields located?"

**Expected Insights:**
- Field names and locations
- Total production by field
- Regional performance comparison

**Business Value:**
> "Guide expansion and investment decisions based on proven field performance."

---

#### **Q7: Regional Issues**
**Ask Cortex Analyst:**
> "Where are we experiencing the most HSE incidents?"

**Expected Insights:**
- Fields/projects with incident concentrations
- Severity patterns
- Geographic risk mapping

**Business Value:**
> "Target safety improvements and resource allocation to high-risk areas."

---

### **4️⃣ WHY Questions - Root Cause & Causation (1.5 min)**

#### **Q8: Production Variance**
**Ask Cortex Analyst:**
> "Why did production drop in Eagle Ford field during Q2?"

**Expected Insights:**
- Equipment downtime correlation
- Well status changes
- Maintenance activities impact

**Business Value:**
> "Quickly diagnose production issues and implement corrective actions without lengthy root cause analysis."

---

#### **Q9: Cost Overruns**
**Ask Cortex Analyst:**
> "Why are operating costs higher for horizontal wells compared to vertical wells?"

**Expected Insights:**
- Cost breakdowns by well type
- Equipment utilization differences
- Maintenance frequency comparison

**Business Value:**
> "Understand cost drivers to optimize drilling strategies and improve margins."

---

### **5️⃣ HOW Questions - Methods & Trends (1.5 min)**

#### **Q10: Efficiency Improvement**
**Ask Cortex Analyst:**
> "How can we improve our overall production efficiency?"

**Expected Insights:**
- Efficiency metrics by well/field
- Best practice identification
- Optimization opportunities

**Business Value:**
> "Data-driven recommendations for operational excellence without manual analysis."

---

#### **Q11: Cost Optimization**
**Ask Cortex Analyst:**
> "How have our operating costs per barrel trended over the past year?"

**Expected Insights:**
- Cost trends over time
- Efficiency improvements or degradation
- Benchmark comparisons

**Business Value:**
> "Track cost management effectiveness and identify emerging efficiency challenges early."

---

#### **Q12: Resource Allocation**
**Ask Cortex Analyst:**
> "How should we prioritize our workover budget across wells?"

**Expected Insights:**
- Wells with highest ROI potential
- Production uplift estimates
- Economic ranking

**Business Value:**
> "Optimize capital allocation for maximum production and financial returns."

---

## 🎯 Suggested Demo Paths

### **Path A: Executive Overview (5 min)**
Focus on high-impact questions:
- Q3: Which wells are our top producers?
- Q4: Which wells are declining?
- Q8: Why did production drop in Q2?
- Q11: How have costs per barrel trended?

**Narrative:** *"Show the C-suite how to monitor performance, identify issues, and drive decisions."*

---

### **Path B: Operations Focus (6 min)**
Deep dive into operational efficiency:
- Q1: When did we achieve peak production?
- Q2: When is maintenance due?
- Q5: Which equipment has high costs?
- Q10: How can we improve efficiency?
- Q12: How should we prioritize workover budget?

**Narrative:** *"Empower operations teams with self-service analytics for day-to-day decisions."*

---

### **Path C: Risk & Safety (6 min)**
Emphasize HSE and risk management:
- Q7: Where are HSE incidents concentrated?
- Q2: When is critical equipment due for maintenance?
- Q5: Which assets have highest maintenance costs?
- Q8: Why did production drop? (equipment failures)

**Narrative:** *"Demonstrate proactive risk management and safety culture through data."*

---

### **Path D: Financial Performance (7 min)**
Focus on economics and profitability:
- Q3: Top producing wells
- Q9: Why are horizontal wells more expensive?
- Q11: Cost per barrel trends
- Q12: Workover budget prioritization
- Custom: "What is our break-even price per barrel by field?"

**Narrative:** *"Show CFOs and finance teams how to track margins and optimize spend."*

---

## 💡 Pro Tips for Effective Demo Delivery

### **1. Start Simple**
- Begin with a straightforward question like Q3 (top producers)
- Build confidence before complex queries

### **2. Show Flexibility**
- Demonstrate how questions can be rephrased
- Example: "Show me our best wells" vs. "Which wells produce the most oil?"

### **3. Highlight Speed**
- Emphasize: "This would typically take an analyst 30-60 minutes"
- Snowflake Intelligence delivers in seconds

### **4. Connect to Business Impact**
- After each answer, pause and explain the business value
- Link insights to real decisions: "This helps you decide where to drill next"

### **5. Handle Follow-Ups**
- Show conversational capabilities: "Now show me just the Gulf Coast fields"
- Demonstrate drill-down analysis

### **6. Address Data Concerns**
- Mention: "This works on your existing Snowflake data—no data movement"
- Emphasize security: "All governed by your existing RBAC policies"

---

## 🔥 Wow Factor Moments

### **Moment 1: Complex Financial Analysis**
**Ask:**
> "Compare the NPV of all active projects and show me which ones are underperforming their initial forecasts"

**Impact:** Show executives they can perform sophisticated financial analysis conversationally.

---

### **Moment 2: Multi-Dimensional Analysis**
**Ask:**
> "Show me production trends by field, well type, and completion date for the past 2 years"

**Impact:** Demonstrate handling of complex analytical requests that would require multiple reports.

---

### **Moment 3: Predictive Insight**
**Ask:**
> "Based on current decline rates, when will each well require artificial lift?"

**Impact:** Show forward-looking analytics, not just historical reporting.

---

## 📈 Success Metrics to Highlight

After the demo, emphasize these benefits:

### **Time Savings**
- **Before:** 30-60 minutes per analysis request
- **With Snowflake Intelligence:** <10 seconds
- **Impact:** 200x+ productivity improvement for executives

### **Accessibility**
- **Before:** Requires SQL skills or analyst support
- **With Snowflake Intelligence:** Natural language for anyone
- **Impact:** Self-service analytics for all decision-makers

### **Cost Efficiency**
- **Before:** Analysts spend 60-70% of time on ad-hoc queries
- **With Snowflake Intelligence:** Analysts focus on strategic analysis
- **Impact:** 3-5x improvement in analytics team effectiveness

### **Decision Speed**
- **Before:** Decisions wait for reports (days/weeks)
- **With Snowflake Intelligence:** Real-time insights
- **Impact:** Faster response to market conditions and operational issues

---

## 🎤 Closing Statement (30 seconds)

> "What you've seen today is Snowflake Intelligence transforming how executives and operators interact with their data. No SQL, no waiting, no technical barriers—just questions and instant answers. This same approach works across any industry vertical, from manufacturing to retail to finance. **Ready to try it with your own data?**"

---

## 📞 Next Steps for Prospects

1. **POC Planning:** Identify 5-10 critical questions their executives ask regularly
2. **Data Mapping:** Connect their existing Snowflake tables
3. **Semantic Model:** Build custom semantic model (we can help!)
4. **Pilot Program:** 2-week pilot with key stakeholders
5. **Rollout:** Expand to broader organization

---

## 🛠️ Troubleshooting Tips

### **If Cortex Analyst doesn't understand a question:**
- Rephrase using terms from the semantic model
- Example: Use "wells" instead of "assets" or "bore holes"

### **If results seem incorrect:**
- Verify data load: `SELECT COUNT(*) FROM [table]`
- Check date ranges: Data spans 2 years
- Confirm semantic model upload

### **If performance is slow:**
- Ensure warehouse is running (SMALL recommended)
- Check data volume expectations (normal for first query after idle)

---

## 📚 Additional Resources

- **semantic_model.yaml:** Complete data model documentation
- **04_demo_queries.sql:** Pre-written SQL versions of demo questions
- **CORTEX_ANALYST_SETUP.md:** Detailed setup instructions

---

**Demo Package Version:** 1.0  
**Last Updated:** December 2025  

---

## ⚡ Quick Reference: Top 10 Demo Questions

| # | Question | Focus Area | Business Impact |
|---|----------|------------|-----------------|
| 1 | Which wells are our top 10 producers? | Performance | Replicate success |
| 2 | Which wells have declining production? | Risk | Early intervention |
| 3 | When did we achieve peak production? | Timing | Understand success factors |
| 4 | Where are most HSE incidents occurring? | Safety | Target improvements |
| 5 | Why did production drop in Q2? | Root Cause | Fix issues faster |
| 6 | How have costs per barrel trended? | Financial | Track efficiency |
| 7 | Which equipment has highest maintenance costs? | OpEx | Optimize spending |
| 8 | When is critical maintenance due? | Operations | Prevent downtime |
| 9 | How can we improve production efficiency? | Optimization | Drive performance |
| 10 | How should we prioritize workover budget? | Capital Allocation | Maximize ROI |

---

**🎯 Ready to deliver an impactful demo? Follow this guide and adapt based on your audience!**

