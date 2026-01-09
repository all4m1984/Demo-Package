# Snowflake Cortex Analyst Demo Package

Welcome to the Snowflake Cortex Analyst Demo Package repository!

## 📦 What's Inside

This repository contains ready-to-use demo packages for showcasing **Snowflake Cortex Analyst** capabilities across various vertical industries. Each demo is designed to be deployed in 15 minutes or less, with realistic data and business scenarios.

**About Cortex Analyst:** Cortex Analyst is Snowflake's AI-powered semantic layer that enables users to ask questions in natural language and receive accurate, SQL-powered answers. These demos showcase standalone Cortex Analyst capabilities and can also be integrated as tools within Snowflake AI Agents for more complex, multi-step workflows.

## 🎯 Available Demos

### 1. Oil & Gas Upstream Operations ✅ COMPLETED
**Location:** `/oil_gas_upstream_operations/`

**Industry:** Energy - Oil & Gas  
**Focus:** Upstream operations (drilling, production, wells management)  
**Setup Time:** 7 minutes  
**Demo Time:** 8 minutes  
**Total Duration:** 15 minutes

**Key Features:**
- 120,000+ realistic synthetic records
- 11 interconnected tables (Wells, Production, Equipment, HSE, Emissions, etc.)
- 10 critical executive questions with real business impact
- Complete semantic model for Cortex Analyst
- Comprehensive documentation and demo scripts

**Use Cases Covered:**
- Production optimization
- Cost management
- Equipment reliability
- Reservoir performance
- HSE compliance
- Capital efficiency
- Production forecasting
- Supply chain management
- ESG & emissions tracking
- Field development planning

[→ Go to Oil & Gas Demo](./oil_gas_upstream_operations/README.md)

---

### 2. FMCG Trade Promotion ✅ COMPLETED
**Location:** `/fmcg_trade_promotion/`

**Industry:** FMCG (Fast-Moving Consumer Goods) / Retail  
**Focus:** Trade promotion optimization, demand forecasting, on-shelf availability  
**Setup Time:** 7 minutes  
**Demo Time:** 8 minutes  
**Total Duration:** 15 minutes

**Key Features:**
- 100,000+ realistic synthetic records
- 10 interconnected tables (Products, Stores, Promotions, Sales, Inventory, etc.)
- 10+ critical business questions with real impact
- Complete semantic model for Cortex Analyst
- Comprehensive documentation and quick start guide

**Use Cases Covered:**
- Trade promotion effectiveness
- Demand forecasting
- On-shelf availability & gap analysis
- Inventory optimization
- Promotional ROI analysis
- Store performance analytics
- Category management
- Supply chain lead times
- Product performance tracking
- Promotional planning

[→ Go to FMCG Demo](./fmcg_trade_promotion/README.md)

---

### 3. Insurance Underwriting & Investment Management (Southeast Asia) ✅ COMPLETED
**Location:** `/insurance_underwriting_investment/`

**Industry:** Insurance / Financial Services  
**Region:** Southeast Asia (Singapore, Malaysia, Indonesia, Thailand, Philippines, Vietnam)  
**Focus:** Underwriting profitability, loss ratios, investment portfolio management  
**Setup Time:** 7 minutes  
**Demo Time:** 8 minutes  
**Total Duration:** 15 minutes

**Key Features:**
- 100,000+ realistic synthetic records
- 10 interconnected tables (Policies, Claims, Premiums, Reserves, Investments, etc.)
- 10+ critical executive questions with real business impact
- Complete semantic model for Cortex Analyst
- Regional brokers and reinsurers (DBS, UOB, CGS-CIMB, Asia Capital Re, etc.)
- Comprehensive documentation and demo guides

**Use Cases Covered:**
- Loss ratio analysis & combined ratio management
- Product line profitability
- Underwriter performance tracking
- Claims frequency & severity analysis
- Reserve adequacy monitoring
- Investment portfolio allocation
- Portfolio yield optimization
- Duration matching (Asset-Liability Management)
- Investment income analysis
- Reinsurance effectiveness

[→ Go to Insurance Demo](./insurance_underwriting_investment/README.md)

---

## 🚀 Quick Start

### For First-Time Users

1. Navigate to the demo folder of your choice
2. Read the `QUICK_START.md` file
3. Execute the setup scripts (typically 3 SQL files)
4. Run the demo using provided talking points
5. Clean up when done (optional)

### Typical Flow

```
Step 1: Setup Environment (SQL script 1) - 2 min
   ↓
Step 2: Load Data (SQL script 2) - 2-4 min
   ↓
Step 3: Setup Views & Upload Semantic Model (SQL script 3) - 1 min
   ↓
Step 4: Run Demo (Ask questions via Cortex Analyst) - 8 min
```

---

## 📂 Demo Package Structure

Each demo package contains:

```
/[industry_demo_folder]/
├── README.md                      # Comprehensive documentation
├── QUICK_START.md                 # Fast setup guide
├── DEMO_GUIDE.md                  # Detailed talking points & demo script
├── 01_setup_environment.sql       # Database & table creation
├── 02_load_sample_data.sql        # Synthetic data generation
├── 03_setup_intelligence.sql      # Analytical views creation
├── 04_upload_semantic_model.sql   # Helper script for semantic model upload
├── 05_demo_queries.sql            # Sample analytical SQL queries (fallback)
└── semantic_model.yaml            # Cortex Analyst semantic model configuration
```

---

## 🎯 Target Audiences

### Sales Engineers
- **Use for:** Customer demos and POCs
- **Benefit:** Production-ready demos in minutes
- **Value:** Win more deals with compelling demos

### Solution Architects
- **Use for:** Architecture workshops and design sessions
- **Benefit:** Real-world data models and patterns
- **Value:** Accelerate customer implementations

### Customer Success Teams
- **Use for:** Customer enablement and training
- **Benefit:** Industry-specific examples
- **Value:** Drive product adoption

### Marketing & Field Teams
- **Use for:** Conference demos and presentations
- **Benefit:** Consistent, high-quality demos
- **Value:** Strong brand impression

---

## 💡 Why These Demos Stand Out

### ✅ Production-Quality
- Realistic data with proper relationships
- Industry-standard terminology
- Business logic (decline curves, cost patterns, etc.)
- Not toy examples

### ✅ Complete Documentation
- Step-by-step setup guides
- Detailed talking points
- Q&A preparation
- Troubleshooting tips

### ✅ Fast to Deploy
- 15 minutes from zero to demo
- Automated data generation
- No external dependencies
- Works in any Snowflake account

### ✅ Business-Focused
- Real executive questions
- Quantified business impact
- Industry-specific scenarios
- ROI-driven messaging

### ✅ Reusable & Extensible
- Modular structure
- Easy to customize
- Can extend to other use cases
- Template for new verticals

---

## 🤖 Using Cortex Analyst with Snowflake AI Agents

### Beyond Standalone Demos

While these demos showcase Cortex Analyst as a standalone tool, you can also integrate Cortex Analyst as a **tool within Snowflake AI Agents** to create more sophisticated, multi-step AI workflows.

### What are Snowflake AI Agents?

Snowflake AI Agents combine multiple tools (including Cortex Analyst, Cortex Search, Python code execution, and custom tools) to handle complex business tasks that require multiple steps, reasoning, and decision-making.

### Example Use Cases

**Oil & Gas:**
- Agent uses Cortex Analyst to query production data, then calls external API to get commodity prices, and recommends optimization strategies

**FMCG/Retail:**
- Agent analyzes promotion performance with Cortex Analyst, searches documents for similar campaigns, and generates a promotion plan

**Insurance:**
- Agent queries loss ratios with Cortex Analyst, retrieves policy documents, and provides underwriting recommendations

### Getting Started with Agents

To use Cortex Analyst as a tool in an Agent:

1. **Deploy any demo from this repository** (sets up data + semantic model)
2. **Create an AI Agent** in Snowflake
3. **Add Cortex Analyst as a tool** (reference your semantic model)
4. **Configure additional tools** as needed (Python, APIs, Search, etc.)
5. **Test multi-step workflows** that leverage your demo data

### Documentation & Resources

- **Cortex Analyst Documentation:** [docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst)
- **AI Agents Documentation:** [docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents)
- **Using Cortex Analyst in Agents:** [docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents/tools](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents/tools)
- **Snowflake Cortex Overview:** [docs.snowflake.com/en/user-guide/snowflake-cortex/overview](https://docs.snowflake.com/en/user-guide/snowflake-cortex/overview)

---

## 📖 Documentation Standards

All demo packages follow consistent documentation:

1. **QUICK_START.md** - Get running in 15-17 minutes
2. **README.md** - Comprehensive reference with business context
3. **DEMO_GUIDE.md** - Minute-by-minute talking points and demo flow
4. **semantic_model.yaml** - Cortex Analyst configuration with metrics and relationships

Each SQL script is heavily commented with:
- Business context and purpose
- Execution time and record counts
- What the code does
- Why it matters
- Expected results and verification queries

---

## 🎓 Learning Resources

### Understanding Cortex Analyst

- **Cortex Analyst**: AI-powered natural language interface that converts questions into accurate SQL
- **Semantic Models**: YAML-based configuration that defines business context, metrics, and relationships
- **Governance**: Row-level security and access control built-in through Snowflake's native features
- **Integration**: Works with existing Snowflake data, views, and can be embedded in applications or used in AI Agents

### Key Concepts

1. **Natural Language Queries**: Business users ask questions in plain English
2. **Semantic Understanding**: AI understands your data model, business terminology, and relationships through the semantic model
3. **Accurate SQL Generation**: Cortex Analyst generates precise SQL based on your semantic model definition
4. **Instant Insights**: Complex queries that used to take days now return answers in seconds
5. **Data Democratization**: Self-service analytics for all users, not just SQL experts
6. **Agent Integration**: Use as a tool within Snowflake AI Agents for multi-step workflows

### Additional Learning

- **Cortex Analyst Tutorial:** [docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/tutorials](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/tutorials)
- **Semantic Model Guide:** [docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/semantic-model-spec](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/semantic-model-spec)
- **Best Practices:** [docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/working-with](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-analyst/working-with)

---

## 🛠️ Technical Requirements

### Snowflake Environment
- **Account**: Standard or higher tier
- **Role**: ACCOUNTADMIN or database creation rights
- **Features**: Cortex Analyst access (check with your account team)
- **Warehouse**: Medium or Large recommended

### Browser
- Modern web browser (Chrome, Firefox, Edge, Safari)
- Access to Snowsight UI

### Time
- Setup: 5-10 minutes (one-time per demo)
- Demo: 8-15 minutes (repeatable)
- Cleanup: 1 minute (optional)

### Cost
- Typical demo: <$1 in compute credits
- Rerunnable: Cleanup and redeploy anytime

---

## 📊 Demo Success Metrics

A successful demo typically results in:

✅ Audience engagement (questions, nodding, note-taking)  
✅ "Can we do this with our data?" question  
✅ Follow-up meeting scheduled  
✅ Technical deep-dive requested  
✅ POC discussion initiated

---

## 🤝 Contributing

### Want to Add a Demo?

Follow this template structure:
1. Identify 10 critical business questions for the industry
2. Design realistic data model (10-15 tables)
3. Generate synthetic data (100K+ records)
4. Create semantic model for Cortex Analyst
5. Write comprehensive documentation
6. Test end-to-end (setup to demo to cleanup)

### Quality Standards

All demos must have:
- [ ] Realistic, industry-specific data
- [ ] Proper data relationships
- [ ] Complete documentation
- [ ] 15-minute setup + demo time
- [ ] Sample queries addressing business questions
- [ ] Semantic model for Cortex Analyst
- [ ] Troubleshooting guide
- [ ] Cleanup instructions

---

## 📞 Support & Feedback

### Need Help?
- Check the demo's `QUICK_START.md` for troubleshooting
- Review Snowflake documentation: [docs.snowflake.com](https://docs.snowflake.com)
- Contact your Snowflake account team

### Have Feedback?
- What worked well?
- What could be improved?
- What other industries should we add?
- What features are missing?

---

## 📜 License

These demo packages are provided for Snowflake enablement and demonstration purposes.

---

## 🎉 Get Started!

1. **Choose a demo** from the list above
2. **Navigate to its folder**
3. **Open QUICK_START.md**
4. **Follow the steps**
5. **Deliver an amazing demo!**

**Current available demos:**
- [Oil & Gas Upstream Operations](./oil_gas_upstream_operations/DEMO_GUIDE.md) ← Energy industry
- [FMCG Trade Promotion](./fmcg_trade_promotion/QUICK_START.md) ← Retail/FMCG industry
- [Insurance Underwriting & Investment](./insurance_underwriting_investment/QUICK_START.md) ← Insurance/Financial Services

---

## 📈 Repository Statistics

- **Demo Packages**: 3 complete industry demos
- **Total Tables**: 31 (across all demos)
- **Total Records**: 320,000+
- **Industries Covered**: Energy, FMCG/Retail, Insurance/Financial Services
- **Setup Time**: ~7 minutes per demo
- **Demo Time**: 5-8 minutes per demo
- **Documentation Pages**: 120+
- **Semantic Models**: 3 production-ready YAML files

---

*Happy Demoing! 🚀*

**Built with ❤️ for the Snowflake community**  
*Last Updated: January 2026*

