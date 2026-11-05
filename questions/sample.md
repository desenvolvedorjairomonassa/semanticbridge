Aqui está a lista formatada em Markdown pronta para ser copiada e colada na documentação do seu repositório Git (por exemplo, na seção **Business Questions Library & Agent Validation** do seu `README.md`):

---

### Business Questions Library & Conversational Agent Validation

| # | Business Question (Natural Language) | Target Tables & Relationship Path | Certified DAX / Metric Logic | Ground Truth / Expected Output |
| --- | --- | --- | --- | --- |
| **1** | *What is total sell-out revenue by region?* | `FACT_SELL_OUT` $\rightarrow$ `DIM_OUTLET` $\rightarrow$ `DIM_GEOGRAPHY[Region]` | `SUM(FACT_SELL_OUT[POS_Sales_Amount])` | Total POS sales broken down by geographical region.
| **2** | *What is total sell-out POS revenue across all stores?* | `FACT_SELL_OUT` | `[Total_SellOut_Revenue] = SUM(FACT_SELL_OUT[POS_Sales_Amount])` | Consolidated sales volume and revenue at retail level.
 | **3** | *What is total sell-in revenue by product category?* | `FACT_SELL_IN` $\rightarrow$ `DIM_PRODUCT[Category]` | `SUM(FACT_SELL_IN[Gross_Invoice_Amount])` | Primary factory shipments aggregated by product category.
| **4** | *What is total sell-in revenue by distributor tier?* | `FACT_SELL_IN` $\rightarrow$ `DIM_DISTRIBUTOR[Tier]` | `SUM(FACT_SELL_IN[Gross_Invoice_Amount])` grouped by `Tier` | Factory revenue grouped across Tier 1, Tier 2, etc.
| **5** | *How many outlets are there per store type?* | `DIM_OUTLET[Outlet_Type]` | `DISTINCTCOUNT(DIM_OUTLET[Outlet_Key])` | Total stores classified by Supermarket, Hypermarket, Convenience, E-Commerce.
| **6** | *List the top 5 products by list price.* | `DIM_PRODUCT` | `TOPN(5, DIM_PRODUCT, DIM_PRODUCT[List_Price], DESC)` | Highest priced catalog SKUs with unit list prices
| **7** | *What is the monthly trend of sell-in revenue for 2024?* | `FACT_SELL_IN` $\rightarrow$ `DIM_DATE[Month_Name]` | `SUM(FACT_SELL_IN[Gross_Invoice_Amount])` filtered by `Year = 2024` | 12-month shipment trajectory for factory sales.
| **8** | *Are there any active schema drift events logged?* | `DRIFT_AUDIT` | Direct query on `DRIFT_AUDIT` | Returns Event ID 1 (`SCHEMA_COLUMN_RENAMED`, 14 affected outlets, $142,500 blast radius).
| **9** | *Who owns the Active Distributors Contracted metric?* | `DIM_MEASURE_CATALOG` | Metadata query where `Certified_Measure_Name = 'Active_Distributors_Contracted'` | `Channel Management` (Governance Domain Steward).
| **10** | **[REFUSAL SCENARIO]** *How many active distributors do we have?* | `CONFLICT_LOG`, `DIM_MEASURE_CATALOG`, `DIM_DISTRIBUTOR`, `FACT_SELL_IN` | Evaluates `[Active_Distributors_Contracted]` (48) vs `[Active_Distributors_Invoiced]` (42) | **Policy-driven refusal:** States the 12.50% variance gap and references domain stewardship rather than guessing.

 |
