# SemanticBridge: Executive Semantic Model Factory with Conversational BI

[![Microsoft Fabric](https://img.shields.io/badge/Microsoft_Fabric-Direct_Lake-blue.svg)](https://app.fabric.microsoft.com/)
[![Azure AI Foundry](https://img.shields.io/badge/Azure_AI-Foundry_&_OpenAI-0078D4.svg)](https://ai.azure.com/)
[![Power BI](https://img.shields.io/badge/Power_BI-Certified_Model-F2C811.svg)](https://powerbi.microsoft.com/)
[![Governance](https://img.shields.io/badge/Governance-Purview_&_Data_Activator-brightgreen.svg)](https://purview.microsoft.com/)

> *"Every team builds its own dashboard, and nobody agrees on the numbers. Build the one BI model you can just ask a question — and get the right answer."*

---

## 📌 Executive Summary

In enterprise Consumer Packaged Goods (CPG) companies, commercial systems across **Sell-In** (manufacturer to distributor), **Sell-Out** (distributor to retailer/POS), and **Field Execution** (in-store audits) operate in silos. Each platform names, codes, and aggregates entities (distributors, outlets, SKUs, and territories) differently. 

When executives query conversational AI interfaces (e.g., *"How many active distributors do we have by region?"*), generic tools pick an arbitrary definition—producing confident, conflicting, and audit-failing metrics.

**SemanticBridge** solves this crisis by introducing a governed, active semantic fabric:
1. **Governed Canonical Star Schema:** Persisted in **Microsoft Fabric Warehouse** over OneLake Delta tables.
2. **Sub-second Direct Lake Semantic Model:** Certified DAX measures mapped 1:1 against business definitions.
3. **Ontology & Identity Resolution:** Fabric IQ and entity crosswalks resolve schema and code drift across systems.
4. **Governed Conversational AI:** A Microsoft Foundry / Fabric Data Agent that enforces certified definitions, answers with coverage/confidence scores, and **explicitly refuses with a quantified gap explanation** when competing KPI definitions conflict.
5. **Continuous Governance Loop:** Automated drift detection using Data Activator alerts domain owners with calculated blast radius impact before executive reports break.

---

## 🏛 Solution Architecture

```
 ┌────────────────────────────────────────────────────────────────────────┐
 │                      RAW CPG ENTERPRISE SYSTEMS                        │
 │        [ERP / Sell-In]    [DMS / Sell-Out]    [CRM / Audits]           │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ (Data Pipelines / OneLake Landing)
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                   ONELAKE & FABRIC DATA WAREHOUSE                      │
 │                     (WH_CPG_SemanticBridge)                            │
 │  ┌──────────────────────────────────────────────────────────────────┐  │
 │  │ Dimension Tables:  DIM_DATE, DIM_GEOGRAPHY, DIM_PRODUCT,         │  │
 │  │                    DIM_DISTRIBUTOR (SCD2), DIM_OUTLET            │  │
 │  │ Fact Tables:       FACT_SELL_IN, FACT_SELL_OUT                   │  │
 │  │ Governance Tables: XWALK, DIM_MEASURE_CATALOG,                   │  │
 │  │                    CONFLICT_LOG, DRIFT_AUDIT                     │  │
 │  └──────────────────────────────────────────────────────────────────┘  │
 └───────────────────────────────────┬────────────────────────────────────┘
                                     │ Direct Lake (Pure Delta Parquet)
                                     ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │                CERTIFIED DIRECT LAKE SEMANTIC MODEL                    │
 │                       (SM_CPG_DirectLake)                              │
 │  • Certified DAX Business Measures                                     │
 │  • Endorsed in OneLake Catalog & Microsoft Purview                     │
 └──────────────────┬─────────────────────────────────┬───────────────────┘
                    │                                 │
                    ▼                                 ▼
 ┌──────────────────────────────────────┐ ┌───────────────────────────────┐
 │       FABRIC IQ & DATA AGENT         │ │     DATA ACTIVATOR & LOOP     │
 │ • Query planner against Catalog      │ │ • Drift detection alerts      │
 │ • Confidence & Coverage Verdict      │ │ • Blast radius routing to     │
 │ • Conflict Refusal & Gap Explainer   │ │   domain data stewards        │
 └──────────────────────────────────────┘ └───────────────────────────────┘
```

---

## 🎯 Key Hackathon Deliverables

| Deliverable | Description | Implementation Status |
| :--- | :--- | :---: |
| **1. Rationalisation Analysis** | Identification and elimination of duplicated dashboards across Sell-In, Sell-Out, and POS tiers. |  |
| **2. Business Questions Library** | Catalog of agreed executive questions mapped 1-to-1 to ratified measures, owners, and definitions. | |
| **3. Direct Lake Semantic Model** | Fabric Warehouse star schema operating in Direct Lake mode; validated against control totals. |  |
| **4. Fabric IQ Ontology** | Published entity-relationship graph binding outlets, distributors, brands, and territories. | |
| **5. Fabric Data Agent** | Conversational agent answering executive questions with certified definitions and quantified conflict refusals. |  |
| **6. Catalog Certification** | Semantic model endorsed as **Certified** in OneLake Catalog with automated lineage. |  |

---

## 🗄 Conformed Star Schema & DDL Reference

The physical data model in `WH_CPG_SemanticBridge` is organized into canonical dimensions, multi-tier fact tables, and active governance entities:

### 1. Master Dimensions
* `DIM_DATE`: Canonical calendar table (`Date_Key`, `Full_Date`, `Year`, `Quarter`, `Month`, `Month_Name`, `Day_Of_Week`, `Is_Weekend`).
* `DIM_GEOGRAPHY`: Resolves organizational hierarchy boundaries (`Territory_Key`, `Region`, `Country`, `State`, `Sales_District`).
* `DIM_DISTRIBUTOR`: SCD Type 2 tracking partner recoding and contract status (`Distributor_Key`, `Distributor_Code`, `Distributor_Name`, `Tier`, `Valid_From_Date`, `Valid_To_Date`, `Is_Current_Version`).
* `DIM_OUTLET`: Stores and points-of-sale (`Outlet_Key`, `Outlet_Code`, `Outlet_Name`, `Outlet_Type`, `Territory_Key`, `Square_Feet`).
* `DIM_PRODUCT`: Master product taxonomy (`Product_Key`, `SKU_Code`, `Product_Name`, `Subcategory`, `Category`, `Brand`, `Unit_Cost`, `List_Price`).
* `DIM_MEASURE_CATALOG`: Semantic layer question and measure definition registry (`Measure_Key`, `Business_Question`, `Certified_Measure_Name`, `Owner`, `Definition`).

### 2. Multi-Tier Commercial Facts
* `FACT_SELL_IN`: Primary sales from manufacturer to wholesale partners (`Date_Key`, `Distributor_Key`, `Product_Key`, `Shipped_Quantity`, `Gross_Invoice_Amount`).
* `FACT_SELL_OUT`: Secondary sales from wholesale partners to retail outlets (`Date_Key`, `Outlet_Key`, `Product_Key`, `Units_Sold`, `POS_Sales_Amount`).

### 3. Autonomous Governance & Conflict Layer
* `XWALK`: Crosswalk identity bridge mapping raw source feed codes to unified keys (`XWalk_ID`, `Source_System`, `Source_Entity_ID`, `Target_Entity_ID`, `Identity_Confidence_Score`, `Review_Status`).
* `CONFLICT_LOG`: Quantified discrepancies between competing definitions (`Log_ID`, `Date_Key`, `Territory_Key`, `Metric_Name`, `Invoiced_Active_Count`, `Contracted_Active_Count`, `Variance_Percentage`, `Status`).
* `DRIFT_AUDIT`: Schema/reference drift logger with dollar-measured blast radius (`Audit_ID`, `Detection_Date`, `Source_Table`, `Drift_Type`, `Affected_Outlet_Count`, `Calculated_Blast_Radius_USD`, `Resolution_Status`).

---

## 📐 Governed DAX Metric Formulations

Ratified DAX measures defined in the `SM_CPG_DirectLake` semantic model:

```dax
-- Total Sell-In Revenue (Direct Factory Sales)
Total_SellIn_Revenue = SUM(FACT_SELL_IN[Gross_Invoice_Amount])

-- Total Sell-Out Revenue (Store Point of Sale Demand)
Total_SellOut_Revenue = SUM(FACT_SELL_OUT[POS_Sales_Amount])

-- Active Distributors: Definition A (Contractual Standing)
Active_Distributors_Contracted = 
CALCULATE(
    DISTINCTCOUNT(DIM_DISTRIBUTOR[Distributor_Code]),
    DIM_DISTRIBUTOR[Is_Current_Version] = TRUE()
)

-- Active Distributors: Definition B (Transactional Invoiced Movement)
Active_Distributors_Invoiced = 
CALCULATE(
    DISTINCTCOUNT(FACT_SELL_IN[Distributor_Key])
)
```

---

## 🤖 Fabric Data Agent: Conflict Refusal Scenario

When an executive asks:
> *"How many active distributors do we have in the North Region?"*

Instead of returning an unverified or arbitrary number, the Fabric Data Agent inspects the ontology catalog, evaluates the variance, and returns a **governed refusal with quantified justification**:

```text
[AGENT RESPONSE: CONFLICT REFUSAL]
I cannot provide a single number for 'Active Distributors' in the North Region because 
there are two certified, conflicting enterprise definitions currently in effect:

1. Contracted Status (Legal / Commercial): 
   • 58 distributors hold active commercial distribution contracts.
2. Transactional Status (Supply Chain / Billing): 
   • 42 distributors have active invoice movements in the last 30 days.

Discrepancy Analysis:
• Quantified Gap: 16 contracted distributors have zero recent purchases.
• Commercial Blast Radius: ~$2,450,000 in unfulfilled run-rate demand.

Action:
Please specify whether you require 'Contracted' or 'Invoiced' distributors, or notify 
the Commercial Domain Steward (steward-commercial@cpg-enterprise.com) to initiate SLA reconciliation.
```

---

## 🚀 Setup & Deployment Guide

### Prerequisites
* Azure Subscription with Hackathon / Enterprise Credits.
* Microsoft Fabric Capacity (`F2` or higher recommended).
* Fabric Workspace assigned to the dedicated capacity.

### Step 1: Provision Capacity and Workspace
1. Create a Fabric Capacity in the [Azure Portal](https://portal.azure.com) (e.g., `hackhatonFabric`).
2. Navigate to [app.fabric.microsoft.com](https://app.fabric.microsoft.com).
3. Create a workspace (e.g., `CPG_SemanticBridge_WS`).
4. In **Workspace settings** $\rightarrow$ **License info**, select **Fabric capacity** and bind to `hackhatonFabric`.

### Step 2: Deploy Warehouse & DDL
1. Inside the workspace, create a new **Warehouse** named `WH_CPG_SemanticBridge`.
2. Open a **New SQL Query** tab and execute the DDL script located at `sql/cpg_warehouse_ddl.sql`.

### Step 3: Ingest Data via Fabric Data Pipeline
1. Upload the generated CSV files to the Lakehouse/OneLake landing zone (`Files/cpg_semantic/`).
2. Create a **Data Pipeline** (`PL_Load_Warehouse`).
3. Add **Copy Data** activities mapping each CSV to its corresponding `dbo.DIM_*` or `dbo.FACT_*` Delta table.
4. Run the pipeline and confirm record counts via `SELECT COUNT(*)`.

### Step 4: Build Direct Lake Semantic Model
1. Within `WH_CPG_SemanticBridge`, switch to the **Reporting** tab and click **New semantic model**.
2. Select all conformed dimensions, facts, and governance tables; name it `SM_CPG_DirectLake`.
3. In Model View, configure $1:N$ single-direction relationships from dimensions to facts.
4. Set technical keys (`*_Key`, `*_ID`) to **Hide in report view**.
5. Add certified DAX measures.
6. Open Semantic Model Settings $\rightarrow$ **Endorsement and discovery** $\rightarrow$ set to **Certified**.

### Step 5: Connect AI Services & Copilot Studio
1. Deploy Azure OpenAI `gpt-4o` in [Azure AI Foundry](https://ai.azure.com).
2. Connect the Fabric Data Agent knowledge source to `SM_CPG_DirectLake`.
3. Register query evaluation tests using the Business Questions Library.

---

## 📂 Repository Structure

```tree
├── sql/
│   ├── cpg_warehouse_ddl.sql          # T-SQL DDL scripts for Fabric Warehouse Delta tables
│   └── test_parity_queries.sql        # Measure parity testing scripts (DAX vs. SQL totals)
├── data_generator/
│   └── ms_hackathon_data_generator.py # Synthetic CPG data generator for CSVs
├── semantic_model/
│   ├── dax_measures_catalog.dax       # Production certified DAX metric formulas
│   └── model_diagram_schema.json      # Relationship and cardinality schema export
├── agent/
│   ├── system_prompt_guardrails.md    # Instructions for Foundry / Copilot Data Agent
│   └── business_questions_library.csv # 10 executive queries with verified gold standards
└── README.md
```

---

## 👥 Contributors & Stewardship

* **Project:** SemanticBridge (Executive Semantic Model Factory)
* **Target Industry:** Consumer Packaged Goods (CPG)
* **Domain Stewards:** Commercial Governance Council & Enterprise Data Office
