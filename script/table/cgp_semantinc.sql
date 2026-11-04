-- ============================================================================
-- SCRIPT DDL: CPG SEMANTICBRIDGE CONFORMED STAR SCHEMA
-- Alinhado rigorosamente com os CSVs e o gerador de dados sintéticos
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. DIMENSÕES CANÔNICAS (CONFORMED DIMENSIONS)
-- ----------------------------------------------------------------------------

-- Calendário / Tempo
CREATE TABLE DIM_DATE (
    Date_Key INT NOT NULL,
    Full_Date DATE NOT NULL,
    Year INT NOT NULL,
    Quarter VARCHAR(10) NOT NULL,
    Month INT NOT NULL,
    Month_Name VARCHAR(30) NOT NULL,
    Day_Of_Week VARCHAR(30) NOT NULL,
    Is_Weekend BIT NOT NULL
);

-- Território / Geografia
CREATE TABLE DIM_GEOGRAPHY (
    Territory_Key INT NOT NULL,
    Region VARCHAR(100) NOT NULL,
    Country VARCHAR(100) NOT NULL,
    State VARCHAR(100) NOT NULL,
    Sales_District VARCHAR(100) NOT NULL
);

-- Distribuidores (SCD Tipo 2 com histórico de recodificação)
CREATE TABLE DIM_DISTRIBUTOR (
    Distributor_Key INT NOT NULL,
    Distributor_Code VARCHAR(50) NOT NULL,
    Distributor_Name VARCHAR(150) NOT NULL,
    Tier VARCHAR(50) NOT NULL,
    Valid_From_Date DATE NOT NULL,
    Valid_To_Date DATE NOT NULL,
    Is_Current_Version BIT NOT NULL
);

-- Pontos de Venda / Lojas (Outlets)
CREATE TABLE DIM_OUTLET (
    Outlet_Key INT NOT NULL,
    Outlet_Code VARCHAR(50) NOT NULL,
    Outlet_Name VARCHAR(150) NOT NULL,
    Outlet_Type VARCHAR(100) NOT NULL,
    Territory_Key INT NOT NULL,
    Square_Feet INT NOT NULL
);

-- Produtos e Marcas
CREATE TABLE DIM_PRODUCT (
    Product_Key INT NOT NULL,
    SKU_Code VARCHAR(50) NOT NULL,
    Product_Name VARCHAR(150) NOT NULL,
    Subcategory VARCHAR(100) NOT NULL,
    Category VARCHAR(100) NOT NULL,
    Brand VARCHAR(100) NOT NULL,
    Unit_Cost DECIMAL(18,2) NOT NULL,
    List_Price DECIMAL(18,2) NOT NULL
);

-- Catálogo de Medidas da Ontologia (Business Questions Library)
CREATE TABLE DIM_MEASURE_CATALOG (
    Measure_Key INT NOT NULL,
    Business_Question VARCHAR(500) NOT NULL,
    Certified_Measure_Name VARCHAR(150) NOT NULL,
    Owner VARCHAR(150) NOT NULL,
    Definition VARCHAR(1000) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 2. TABELAS DE FATOS (SELL-IN & SELL-OUT)
-- ----------------------------------------------------------------------------

-- Fato Sell-In: Fábrica -> Distribuidor
CREATE TABLE FACT_SELL_IN (
    Date_Key INT NOT NULL,
    Distributor_Key INT NOT NULL,
    Product_Key INT NOT NULL,
    Shipped_Quantity INT NOT NULL,
    Gross_Invoice_Amount DECIMAL(18,2) NOT NULL
);

-- Fato Sell-Out: Distribuidor -> PDV / Lojas
CREATE TABLE FACT_SELL_OUT (
    Date_Key INT NOT NULL,
    Outlet_Key INT NOT NULL,
    Product_Key INT NOT NULL,
    Units_Sold INT NOT NULL,
    POS_Sales_Amount DECIMAL(18,2) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 3. CAMADA DE GOVERNANÇA, DRIFT E CONFLITOS (FABRIC IQ & AGENT)
-- ----------------------------------------------------------------------------

-- Registro de Conflitos de KPIs (Dispara recusa do agente por divergência > 5%)
CREATE TABLE CONFLICT_LOG (
    Log_ID INT NOT NULL,
    Date_Key INT NOT NULL,
    Territory_Key INT NOT NULL,
    Metric_Name VARCHAR(100) NOT NULL,
    Invoiced_Active_Count INT NOT NULL,
    Contracted_Active_Count INT NOT NULL,
    Variance_Percentage DECIMAL(5,2) NOT NULL,
    Status VARCHAR(50) NOT NULL
);

-- Resolução de Entidades / Crosswalk (Sistemas Legados -> Conformed)
CREATE TABLE XWALK (
    XWalk_ID INT NOT NULL,
    Source_System VARCHAR(100) NOT NULL,
    Source_Entity_ID VARCHAR(100) NOT NULL,
    Target_Entity_ID VARCHAR(100) NOT NULL,
    Identity_Confidence_Score DECIMAL(5,2) NOT NULL,
    Review_Status VARCHAR(50) NOT NULL
);

-- Auditoria de Mudança de Schema / Drift e Blast Radius Financeiro
CREATE TABLE DRIFT_AUDIT (
    Audit_ID INT NOT NULL,
    Detection_Date DATE NOT NULL,
    Source_Table VARCHAR(100) NOT NULL,
    Drift_Type VARCHAR(100) NOT NULL,
    Affected_Outlet_Count INT NOT NULL,
    Calculated_Blast_Radius_USD DECIMAL(18,2) NOT NULL,
    Resolution_Status VARCHAR(50) NOT NULL
);
