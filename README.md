# Snowflake Intelligence Demo Package

Welcome to the Snowflake Intelligence Demo Package repository!

## 📦 What's Inside

This repository contains ready-to-use demo packages for showcasing Snowflake Intelligence (Cortex Analyst) capabilities across various vertical industries. Each demo is designed to be deployed in 15 minutes or less, with realistic data and business scenarios.

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
Step 1: Setup Environment (SQL script 1) - 3 min
   ↓
Step 2: Load Data (SQL script 2) - 3 min
   ↓
Step 3: Configure Intelligence (SQL script 3) - 1 min
   ↓
Step 4: Run Demo (Cortex Analyst + queries) - 8 min
```

---

## 📂 Demo Package Structure

Each demo package contains:

```
/[industry_demo_folder]/
├── README.md                      # Comprehensive documentation
├── QUICK_START.md                 # Fast setup guide
├── PACKAGE_SUMMARY.md             # High-level overview
├── 01_setup_environment.sql       # Database & table creation
├── 02_load_sample_data.sql        # Synthetic data generation
├── 03_setup_intelligence.sql      # Cortex Analyst setup
├── 04_demo_queries.sql            # Sample analytical queries
├── semantic_model.yaml            # Cortex Analyst configuration
└── demo_script.md                 # Detailed talking points
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

## 🔮 Coming Soon

### Planned Demo Packages

**Mining & Minerals** 🔨
- Mine operations
- Equipment monitoring
- Safety management
- Production optimization

**Utilities & Energy** ⚡
- Grid operations
- Asset management
- Outage management
- Renewable integration

**Manufacturing** 🏭
- Production lines
- Quality control
- Supply chain
- Predictive maintenance

**Healthcare** 🏥
- Patient outcomes
- Operational efficiency
- Cost management
- Regulatory compliance

**Financial Services** 💰
- Risk management
- Fraud detection
- Customer analytics
- Regulatory compliance

*Want a specific industry? Let us know!*

---

## 📖 Documentation Standards

All demo packages follow consistent documentation:

1. **QUICK_START.md** - Get running in 15 minutes
2. **README.md** - Comprehensive reference
3. **demo_script.md** - Minute-by-minute talking points
4. **PACKAGE_SUMMARY.md** - High-level overview

Each SQL script is heavily commented with:
- Business context
- What the code does
- Why it matters
- Expected results

---

## 🎓 Learning Resources

### Understanding Snowflake Intelligence

- **Cortex Analyst**: AI-powered natural language to SQL
- **Semantic Models**: Define business context for AI
- **Governance**: Security and access control built-in
- **Integration**: Works with existing data and BI tools

### Key Concepts

1. **Natural Language Queries**: Business users ask questions in plain English
2. **Semantic Understanding**: AI knows your data model and terminology
3. **SQL Generation**: Accurate SQL generated behind the scenes
4. **Instant Insights**: From days to seconds for answers
5. **Democratization**: Everyone accesses data, not just analysts

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

- **Demo Packages**: 3 (more coming soon)
- **Total Tables**: 31 (across all demos)
- **Total Records**: 320,000+
- **Industries Covered**: Energy, FMCG/Retail, Insurance/Financial Services
- **Setup Time**: ~7 minutes per demo
- **Demo Time**: 5-8 minutes per demo
- **Documentation Pages**: 120+

---

*Happy Demoing! 🚀*

**Built with ❤️ for the Snowflake community**  
*Last Updated: December 2025*

