# Insurance Underwriting & Investment Management - Demo Guide
## Southeast Asia Edition

## 🎯 Demo Overview

**Duration:** 5-8 minutes  
**Audience:** Insurance executives, actuaries, underwriters, investment managers  
**Markets:** Singapore, Malaysia, Indonesia, Thailand, Philippines, Vietnam  
**Goal:** Demonstrate how Snowflake Intelligence enables self-service analytics for complex insurance questions across Southeast Asian markets

---

## 📋 Pre-Demo Checklist

Before starting your demo, ensure:

- [ ] All setup scripts (01-03) executed successfully
- [ ] semantic_model.yaml uploaded to CORTEX_STAGE
- [ ] Cortex Analyst app configured and tested
- [ ] Sample question returns results
- [ ] Demo environment is accessible
- [ ] Backup SQL queries ready (05_demo_queries.sql)

**Quick Test:**
Ask Cortex Analyst: *"What is the combined ratio by product line?"*
- Should return results with product names and ratios

---

## 🎬 5-8 Minute Demo Script

### Introduction (30 seconds)

**Setup the Context:**

> *"Today I'll show you how Snowflake Intelligence transforms insurance analytics. We have a realistic dataset with 100,000+ records covering underwriting performance and investment management. Instead of waiting for reports or writing SQL, executives and analysts can now ask questions in plain English and get instant answers."*

**Show the Data:**
- Mention 10 tables: Policies, Claims, Premiums, Reserves, Investments, etc.
- 5,000 policies across 8 product lines in 6 Southeast Asian markets
- 15,000 claims with detailed loss information
- 500 investment holdings across multiple asset classes
- Markets: Singapore, Malaysia, Indonesia, Thailand, Philippines, Vietnam

---

### Demo Flow: 12 Questions Covering Key Question Types

---

## 📊 WHEN Questions (Time-Based Analysis)

### Question 1: Loss Ratio Trends
**Ask:** *"When did our loss ratios start increasing?"*

or

*"Show me the loss ratio trend by quarter for the last 2 years"*

**What to Highlight:**
- ✅ Natural language understands "when" = time analysis
- ✅ Automatically aggregates by quarter
- ✅ Identifies trends and inflection points
- 💼 **Business Value**: Early detection of deteriorating performance

**Expected Insight:** Identify periods of loss ratio increases

---

### Question 2: Investment Income Timing
**Ask:** *"When do we generate the most investment income during the year?"*

or

*"Show me monthly investment income for this year"*

**What to Highlight:**
- ✅ Analyzes seasonality patterns
- ✅ Combines interest and dividend income
- 💼 **Business Value**: Cash flow planning and liquidity management

---

## 🔍 WHICH Questions (Identification/Comparison)

### Question 3: Problem Products
**Ask:** *"Which product lines have loss ratios above 65%?"*

or

*"Which products are underperforming their target loss ratios?"*

**What to Highlight:**
- ✅ Identifies specific problematic products
- ✅ Compares actual vs. target metrics
- ✅ Quantifies the variance
- 💼 **Business Value**: Prioritize rate increases or underwriting tightening
- 💰 **Impact**: Each 5% improvement in loss ratio on $10M premium = $500K

**Expected Insight:** 2-3 product lines likely above threshold (Auto, Workers Comp)

---

### Question 4: Top Performers
**Ask:** *"Which underwriters have the best combined ratios?"*

or

*"Show me the top 10 underwriters by performance"*

**What to Highlight:**
- ✅ Ranks underwriters by key metric
- ✅ Includes experience level and region context
- 💼 **Business Value**: Identify best practices, reward top performers

---

### Question 5: Asset Allocation
**Ask:** *"Which asset classes make up our portfolio?"*

or

*"What is our current asset allocation?"*

**What to Highlight:**
- ✅ Breaks down portfolio by asset class
- ✅ Shows allocation percentages
- ✅ Includes yield and duration metrics
- 💼 **Business Value**: Ensure alignment with investment policy

**Expected Insight:** ~45% Corporate Bonds, ~20% Government Bonds, ~15% Munis, etc.

---

## 📍 WHERE Questions (Geographic/Locational Analysis)

### Question 6: Regional Performance
**Ask:** *"Where are we seeing the highest combined ratios?"*

or

*"Show me underwriting performance by region"*

**What to Highlight:**
- ✅ Geographic aggregation and comparison
- ✅ Identifies problem regions
- 💼 **Business Value**: Regional pricing or underwriting adjustments

---

### Question 7: State-Level Claims
**Ask:** *"Where are most of our high-severity claims occurring?"*

or

*"Show me claim frequency by state for catastrophic claims"*

**What to Highlight:**
- ✅ Filters by severity category
- ✅ Aggregates geographically
- 💼 **Business Value**: Catastrophe exposure management, reinsurance decisions

---

## ❓ WHY Questions (Root Cause Analysis)

### Question 8: Loss Ratio Drivers
**Ask:** *"Why is the auto product line loss ratio high?"*

or

*"Show me claims frequency and severity for personal auto"*

**What to Highlight:**
- ✅ Breaks down loss ratio into frequency vs. severity
- ✅ Identifies root cause (more claims vs. larger claims)
- 💼 **Business Value**: Take targeted action (frequency = underwriting, severity = subrogation)

**Expected Insight:** See if high loss ratio is driven by:
- **Frequency** problem → tighten underwriting, improve risk selection
- **Severity** problem → improve claims management, subrogation

---

### Question 9: Reserve Adequacy Issues
**Ask:** *"Why are our reserves understated for certain products?"*

or

*"Show me reserve adequacy by product and accident year"*

**What to Highlight:**
- ✅ Identifies products with inadequate reserves
- ✅ Shows development patterns by accident year
- 💼 **Business Value**: Avoid adverse development and earnings surprises

---

## 🛠️ HOW Questions (Process/Methodology)

### Question 10: Portfolio Optimization
**Ask:** *"How can we improve our portfolio yield?"*

or

*"Show me yield by asset class and rating"*

**What to Highlight:**
- ✅ Compares yield across asset classes
- ✅ Shows yield vs. rating (risk vs. return)
- 💼 **Business Value**: Identify yield improvement opportunities
- 💰 **Impact**: 25 bps yield improvement on $500M portfolio = $1.25M/year

---

### Question 11: Profitability Improvement
**Ask:** *"How do we achieve our combined ratio target of 95%?"*

or

*"Show me the gap between current and target combined ratios by product"*

**What to Highlight:**
- ✅ Calculates gap to target
- ✅ Prioritizes products by premium volume
- 💼 **Business Value**: Action plan for profitability improvement

---

### Question 12: Investment Income Contribution
**Ask:** *"How much does investment income contribute to our profitability?"*

or

*"Show me underwriting profit vs. investment income by quarter"*

**What to Highlight:**
- ✅ Integrates underwriting and investment data
- ✅ Shows total insurer profitability
- 💼 **Business Value**: Holistic view of performance

**Expected Insight:** Investment income often offsets underwriting losses

---

## 🎭 Four Curated Demo Paths

### Path 1: Underwriting Performance Focus (5 minutes)
**Best for:** CFO, Chief Underwriting Officer

1. **Which** products have loss ratios above 65%? → *Identify problems*
2. **Why** is auto loss ratio high? → *Root cause (frequency vs. severity)*
3. **Which** underwriters perform best? → *Best practices*
4. **When** did loss ratios start increasing? → *Trend analysis*
5. **How** do we reach our 95% combined ratio target? → *Action plan*

---

### Path 2: Investment Management Focus (5 minutes)
**Best for:** CIO, Chief Investment Officer, Investment Committee

1. **Which** asset classes make up our portfolio? → *Current allocation*
2. **How** can we improve portfolio yield? → *Optimization*
3. **When** do we generate most investment income? → *Timing/seasonality*
4. **Where** is our portfolio duration vs. liabilities? → *ALM/interest rate risk*
5. **What** is our unrealized gain/loss position? → *Mark-to-market*

---

### Path 3: Risk Management Focus (6 minutes)
**Best for:** CRO, Chief Risk Officer, Risk Committee

1. **Where** are we seeing highest combined ratios? → *Geographic risk*
2. **Which** claims types are most frequent? → *Risk concentration*
3. **Why** are reserves understated? → *Reserve adequacy*
4. **Where** are catastrophic claims occurring? → *Cat exposure*
5. **What** is our reinsurance recovery rate? → *Reinsurance effectiveness*

---

### Path 4: Executive Summary (8 minutes)
**Best for:** CEO, Board of Directors

1. **What** is our combined ratio by product? → *Overall performance*
2. **Which** products are profitable vs. unprofitable? → *Portfolio quality*
3. **When** did performance change? → *Trend identification*
4. **How** much investment income offsets underwriting losses? → *Total profitability*
5. **What** actions drive improvement? → *Strategic priorities*
6. **Where** are our biggest opportunities? → *Focus areas*

---

## 💡 Pro Tips for a Great Demo

### Do's:
- ✅ Start with simple questions, build to complex
- ✅ Explain business context ("combined ratio < 100% = profit")
- ✅ Show how fast insights are generated (seconds vs. days)
- ✅ Highlight the SQL that was auto-generated
- ✅ Emphasize self-service for non-technical users
- ✅ Relate to their specific pain points
- ✅ Have backup SQL queries ready (05_demo_queries.sql)

### Don'ts:
- ❌ Don't use jargon without explaining
- ❌ Don't skip the "why it matters" context
- ❌ Don't show only technical features
- ❌ Don't forget to quantify business impact
- ❌ Don't move too fast - let insights sink in

---

## 🌟 Wow Factor Moments

### Moment 1: Complex Aggregation in Seconds
**Show:** Ask about combined ratio by product, region, and quarter
**Wow:** *"This query just joined 5 tables, aggregated 20K+ records, and calculated 3 different ratios - in 2 seconds. Previously, this report took an actuary 2 days."*

### Moment 2: Self-Service for Non-Technical Users
**Show:** Point out the generated SQL
**Wow:** *"Notice the SQL that was automatically generated. Your underwriters and actuaries can now get these insights without knowing SQL or waiting for the BI team."*

### Moment 3: Real Business Impact
**Show:** Loss ratio improvement opportunity
**Wow:** *"If we reduce the Auto loss ratio from 68% to 65% on $10M in premium, that's $300K in additional profit. This tool helps identify these opportunities instantly."*

### Moment 4: Investment Income Insight
**Show:** Investment income offsetting underwriting losses
**Wow:** *"Many insurers operate with combined ratios of 100-105%, relying on investment income for profitability. This integrated view shows your total picture."*

---

## 📊 Success Metrics

A successful demo typically results in:

- ✅ **Engagement**: Audience asks follow-up questions
- ✅ **Recognition**: "Can we do this with our data?" question
- ✅ **Technical Interest**: Questions about security, governance, integration
- ✅ **Business Relevance**: "This would help with [specific problem]"
- ✅ **Next Steps**: Request for POC or follow-up meeting

---

## 🆘 Troubleshooting During Demo

### Issue: Question doesn't return results
**Fix:** Rephrase or ask a verified question from the list

### Issue: Results seem wrong
**Fix:** Explain this is synthetic demo data, not production

### Issue: "Division by zero" error appears
**Fix:** This has been fixed in the latest views. If it occurs, explain you'll re-run the view creation after the demo. Use backup queries from `05_demo_queries.sql` in the meantime.

### Issue: Cortex Analyst unavailable
**Fix:** Fall back to pre-written SQL queries (05_demo_queries.sql)

### Issue: Query runs slowly
**Fix:** 
- Verify warehouse is running and appropriately sized (Medium recommended)
- Some queries may take 3-5 seconds on first run (cold cache)
- Subsequent runs should be faster

### Issue: Audience wants specific metric
**Fix:** Show how to add it to semantic model for future queries

---

## 📞 Follow-Up Questions to Expect

### "How does governance work?"
**Answer:** Role-based access control (RBAC) at table and column level. Users only see data they're authorized for.

### "Can it handle our data volume?"
**Answer:** Yes, Snowflake scales to petabytes. This demo uses 100K+ records but works identically with millions.

### "What about data prep?"
**Answer:** The semantic model (YAML file) maps business terms to your existing tables. One-time setup, then natural language works.

### "How long to implement?"
**Answer:** With existing data warehouse: 1-2 weeks for POC, 4-8 weeks for production (mostly semantic model creation and testing).

### "What about cost?"
**Answer:** Runs on your existing Snowflake infrastructure. Cortex Analyst is included with certain tiers - check with your account team.

---

## 🎯 Closing the Demo

**Summary Statement:**

> *"In 8 minutes, we've answered 12 complex insurance questions that normally require actuaries, SQL developers, and days of work. Snowflake Intelligence democratizes data access, letting every underwriter, actuary, and executive get instant insights. The result: faster decisions, better risk selection, and millions in improved profitability."*

**Call to Action:**

> *"Would you like to see this with your actual data? We can set up a POC in 2-3 weeks and start demonstrating value immediately."*

---

## 📚 Additional Resources

- **Comprehensive Documentation**: `README.md`
- **Quick Setup Guide**: `QUICK_START.md`
- **Sample SQL Queries**: `05_demo_queries.sql`
- **Semantic Model**: `semantic_model.yaml`

---

## 📊 Quick Reference: Key Insurance Metrics

| Metric | Formula | Target | Interpretation |
|--------|---------|--------|----------------|
| **Loss Ratio** | Incurred Loss / Earned Premium × 100 | Varies by product (55-75%) | Lower is better |
| **Expense Ratio** | Expenses / Written Premium × 100 | 20-30% | Lower is better |
| **Combined Ratio** | Loss Ratio + Expense Ratio | < 100% | < 100% = underwriting profit |
| **Claim Frequency** | # Claims / # Policies | Varies by product | Measures how often claims occur |
| **Claim Severity** | Total Loss / # Claims | Varies by product | Average claim size |
| **Reserve Adequacy** | (Paid + Reserves - Ultimate) / Ultimate × 100 | 0% (adequate) | Negative = understated |
| **Portfolio Yield** | Annual Income / Portfolio Value × 100 | 3-6% (current market) | Higher is better (with same risk) |
| **Duration** | Weighted average time to cash flows | Match liability duration | Measures interest rate risk |

---

**Good luck with your demo! 🚀**

*Remember: Focus on business value, not just technical features. Insurance executives care about profitability, risk management, and regulatory compliance.*

---

*Last Updated: January 2026*
