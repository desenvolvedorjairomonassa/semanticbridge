-- ============================================================================
-- SCRIPT DE POPULAÇÃO COMPLETA: CPG SEMANTICBRIDGE
-- Execução direta no Microsoft Fabric Warehouse (T-SQL Nativo)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. POPULAR DIMENSÕES CADASTRAIS (ESTÁTICAS)
-- ----------------------------------------------------------------------------

-- DIM_GEOGRAPHY (4 Territórios)
INSERT INTO dbo.DIM_GEOGRAPHY (Territory_Key, Region, Country, State, Sales_District)
VALUES
(1, 'North America', 'USA', 'California', 'West Coast'),
(2, 'North America', 'USA', 'New York', 'East Coast'),
(3, 'Europe', 'Germany', 'Bavaria', 'Central Europe'),
(4, 'APAC', 'Australia', 'New South Wales', 'Oceania');

-- DIM_DISTRIBUTOR (SCD Tipo 2)
INSERT INTO dbo.DIM_DISTRIBUTOR (Distributor_Key, Distributor_Code, Distributor_Name, Tier, Valid_From_Date, Valid_To_Date, Is_Current_Version)
VALUES
(1, 'DIST-001', 'Global Logistics Corp', 'Tier 1', '2024-01-01', '2024-06-30', 0),
(2, 'DIST-001', 'Global Logistics & Supply Solutions', 'Tier 1', '2024-07-01', '9999-12-31', 1),
(3, 'DIST-002', 'Apex Distribution Partners', 'Tier 1', '2024-01-01', '9999-12-31', 1),
(4, 'DIST-003', 'FastTrack CPG Logistics', 'Tier 2', '2024-01-01', '9999-12-31', 1);

-- DIM_MEASURE_CATALOG (Ontologia de Perguntas)
INSERT INTO dbo.DIM_MEASURE_CATALOG (Measure_Key, Business_Question, Certified_Measure_Name, Owner, Definition)
VALUES
(1, 'What is total sell-in revenue by region?', 'Total Sell-In Revenue', 'Sales Operations', 'Sum of (Shipped Quantity * List Price) across all factory shipments.'),
(2, 'How many active distributors are currently contracted?', 'Active_Distributors_Contracted', 'Channel Management', 'Count of distributors with active contracts in the master ledger.'),
(3, 'What is the distributor inventory stock-out rate?', 'Inventory Stockout Rate', 'Supply Chain', 'Percentage of days where ending inventory equals zero.');

-- ----------------------------------------------------------------------------
-- 2. POPULAR DIM_PRODUCT (27 SKUs)
-- ----------------------------------------------------------------------------
WITH Categories AS (
    SELECT 'Beverages' AS Category, 'Sparkling Water' AS Subcategory UNION ALL
    SELECT 'Beverages', 'Energy Drink' UNION ALL
    SELECT 'Beverages', 'Iced Tea' UNION ALL
    SELECT 'Snacks', 'Potato Chips' UNION ALL
    SELECT 'Snacks', 'Tortilla Chips' UNION ALL
    SELECT 'Snacks', 'Protein Bars' UNION ALL
    SELECT 'Personal Care', 'Shampoo' UNION ALL
    SELECT 'Personal Care', 'Body Wash' UNION ALL
    SELECT 'Personal Care', 'Hand Sanitizer'
),
Variants AS (
    SELECT 1 AS Variant_Num UNION ALL
    SELECT 2 UNION ALL
    SELECT 3
),
BaseProducts AS (
    SELECT 
        c.Category,
        c.Subcategory,
        v.Variant_Num,
        ROW_NUMBER() OVER (ORDER BY c.Category, c.Subcategory, v.Variant_Num) AS Prod_Seq
    FROM Categories c
    CROSS JOIN Variants v
)
INSERT INTO dbo.DIM_PRODUCT (
    Product_Key, SKU_Code, Product_Name, Subcategory, Category, Brand, Unit_Cost, List_Price
)
SELECT 
    1000 + Prod_Seq AS Product_Key,
    CONCAT('SKU-', UPPER(SUBSTRING(Category, 1, 3)), '-', UPPER(SUBSTRING(Subcategory, 1, 3)), '-', FORMAT(Variant_Num, '000')) AS SKU_Code,
    CONCAT(Subcategory, ' BrandVariant ', Variant_Num) AS Product_Name,
    Subcategory,
    Category,
    CONCAT('Eco', SUBSTRING(Category, 1, 3)) AS Brand,
    CAST(ROUND(1.50 + (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(Prod_Seq, 'Cost')))) % 1350) / 100.0, 2) AS DECIMAL(18,2)) AS Unit_Cost,
    CAST(ROUND(3.00 + (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(Prod_Seq, 'Price')))) % 2700) / 100.0, 2) AS DECIMAL(18,2)) AS List_Price
FROM BaseProducts;

-- ============================================================================
-- 3. POPULAR DIM_OUTLET (50 Lojas) - Compatível com Fabric Warehouse
-- Gera 50 IDs limpos sem consultar tabelas de sistema distribuídas
-- ============================================================================

WITH 
-- Tabela de 10 dígitos (0 a 9)
Digits AS (
    SELECT v FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t(v)
),
-- Gera números de 1 a 50 via produto cartesiano puro em memória
Numbers AS (
    SELECT (d1.v * 10 + d2.v + 1) AS Id
    FROM Digits d1
    CROSS JOIN Digits d2
    WHERE (d1.v * 10 + d2.v + 1) <= 50
),
-- Tipos de canal de loja
OutletTypes AS (
    SELECT 0 AS Type_Id, 'Hypermarket' AS Outlet_Type UNION ALL
    SELECT 1, 'Supermarket' UNION ALL
    SELECT 2, 'Convenience' UNION ALL
    SELECT 3, 'E-Commerce'
)
INSERT INTO dbo.DIM_OUTLET (
    Outlet_Key, Outlet_Code, Outlet_Name, Outlet_Type, Territory_Key, Square_Feet
)
SELECT 
    n.Id AS Outlet_Key,
    CONCAT('OUT-', FORMAT(n.Id, '0000')) AS Outlet_Code,
    CONCAT('Retail Store ', n.Id) AS Outlet_Name,
    ot.Outlet_Type,
    (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(n.Id AS VARCHAR), 'Territory')))) % 4) + 1 AS Territory_Key,
    1500 + (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(n.Id AS VARCHAR), 'Square')))) % 43501) AS Square_Feet
FROM Numbers n
JOIN OutletTypes ot 
    ON ot.Type_Id = (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(n.Id AS VARCHAR), 'Type')))) % 4);

-- ============================================================================
-- 4. POPULAR DIM_DATE (731 Dias: 2024-01-01 a 2025-12-31)
-- Compatível com o modo distribuído do Fabric Warehouse
-- ============================================================================

WITH 
-- 10 dígitos na memória
Digits AS (
    SELECT v FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t(v)
),
-- Gera números de 0 a 730 (exatamente 731 dias)
DayNumbers AS (
    SELECT (d1.v * 100 + d2.v * 10 + d3.v) AS DayOffset
    FROM Digits d1
    CROSS JOIN Digits d2
    CROSS JOIN Digits d3
    WHERE (d1.v * 100 + d2.v * 10 + d3.v) < 731
),
-- Calcula cada data a partir de 2024-01-01
CalendarBase AS (
    SELECT DATEADD(DAY, DayOffset, CAST('2024-01-01' AS DATE)) AS Full_Date
    FROM DayNumbers
)
INSERT INTO dbo.DIM_DATE (
    Date_Key, 
    Full_Date, 
    Year, 
    Quarter, 
    Month, 
    Month_Name, 
    Day_Of_Week, 
    Is_Weekend
)
SELECT 
    CAST(FORMAT(Full_Date, 'yyyyMMdd') AS INT) AS Date_Key,
    Full_Date,
    YEAR(Full_Date) AS Year,
    CONCAT(YEAR(Full_Date), 'Q', DATEPART(QUARTER, Full_Date)) AS Quarter,
    MONTH(Full_Date) AS Month,
    DATENAME(MONTH, Full_Date) AS Month_Name,
    DATENAME(WEEKDAY, Full_Date) AS Day_Of_Week,
    CASE 
        WHEN DATEPART(WEEKDAY, Full_Date) IN (1, 7) THEN 1 
        ELSE 0 
    END AS Is_Weekend
FROM CalendarBase;

-- ----------------------------------------------------------------------------
-- 5. POPULAR TABELAS DE GOVERNANÇA, DRIFT E CONFLITO (ESTÁTICAS)
-- ----------------------------------------------------------------------------

-- CONFLICT_LOG (Conflito intencional >5% para recusa do Fabric Data Agent)
INSERT INTO dbo.CONFLICT_LOG (
    Log_ID, Date_Key, Territory_Key, Metric_Name, Invoiced_Active_Count, Contracted_Active_Count, Variance_Percentage, Status
)
VALUES (1, 20241015, 1, 'Active_Distributors', 42, 48, 12.50, 'FLAGGED_CONFLICT');

-- XWALK (Resolução de Entidades)
INSERT INTO dbo.XWALK (
    XWalk_ID, Source_System, Source_Entity_ID, Target_Entity_ID, Identity_Confidence_Score, Review_Status
)
VALUES (1, 'SAP_ECC', 'DIST_9981', 'DIST-001', 0.82, 'DISPUTED');

-- DRIFT_AUDIT (Auditoria de Drift de Schema e Blast Radius)
INSERT INTO dbo.DRIFT_AUDIT (
    Audit_ID, Detection_Date, Source_Table, Drift_Type, Affected_Outlet_Count, Calculated_Blast_Radius_USD, Resolution_Status
)
VALUES (1, '2024-10-20', 'FACT_SELL_IN', 'SCHEMA_COLUMN_RENAMED', 14, 142500.00, 'PENDING_REVIEW');

-- ----------------------------------------------------------------------------
-- 6. POPULAR FACT_SELL_IN (10.000 Transações)
-- ----------------------------------------------------------------------------
WITH 
Digits AS (
    SELECT v FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t(v)
),
Numbers10k AS (
    SELECT (d1.v * 1000 + d2.v * 100 + d3.v * 10 + d4.v + 1) AS Seq
    FROM Digits d1
    CROSS JOIN Digits d2
    CROSS JOIN Digits d3
    CROSS JOIN Digits d4
),
Dates2024 AS (
    SELECT Date_Key, ROW_NUMBER() OVER (ORDER BY Date_Key) AS Day_Num
    FROM dbo.DIM_DATE
    WHERE Year = 2024
)
INSERT INTO dbo.FACT_SELL_IN (
    Date_Key, Distributor_Key, Product_Key, Shipped_Quantity, Gross_Invoice_Amount
)
SELECT 
    d.Date_Key,
    (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'Dist')))) % 4) + 1 AS Distributor_Key,
    1001 + (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'Prod')))) % 27) AS Product_Key,
    100 + (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'Qty')))) % 1901) AS Shipped_Quantity,
    CAST(ROUND(1000.00 + (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'Amount')))) % 2400001) / 100.0, 2) AS DECIMAL(18,2)) AS Gross_Invoice_Amount
FROM Numbers10k g
JOIN Dates2024 d 
    ON d.Day_Num = ((ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'Date')))) % 366) + 1);

-- ----------------------------------------------------------------------------
-- 7. POPULAR FACT_SELL_OUT (15.000 Transações)
-- ----------------------------------------------------------------------------
WITH 
Digits AS (
    SELECT v FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) AS t(v)
),
Tens AS (
    SELECT v FROM (VALUES (0),(1)) AS t(v)
),
Numbers15k AS (
    SELECT (t.v * 10000 + d1.v * 1000 + d2.v * 100 + d3.v * 10 + d4.v + 1) AS Seq
    FROM Tens t
    CROSS JOIN Digits d1
    CROSS JOIN Digits d2
    CROSS JOIN Digits d3
    CROSS JOIN Digits d4
    WHERE (t.v * 10000 + d1.v * 1000 + d2.v * 100 + d3.v * 10 + d4.v + 1) <= 15000
),
Dates2024 AS (
    SELECT Date_Key, ROW_NUMBER() OVER (ORDER BY Date_Key) AS Day_Num
    FROM dbo.DIM_DATE
    WHERE Year = 2024
)
INSERT INTO dbo.FACT_SELL_OUT (
    Date_Key, Outlet_Key, Product_Key, Units_Sold, POS_Sales_Amount
)
SELECT 
    d.Date_Key,
    (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'Outlet')))) % 50) + 1 AS Outlet_Key,
    1001 + (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'ProdSO')))) % 27) AS Product_Key,
    5 + (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'Units')))) % 146) AS Units_Sold,
    CAST(ROUND(50.00 + (ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'POSAmount')))) % 145001) / 100.0, 2) AS DECIMAL(18,2)) AS POS_Sales_Amount
FROM Numbers15k g
JOIN Dates2024 d 
    ON d.Day_Num = ((ABS(CHECKSUM(HASHBYTES('MD5', CONCAT(CAST(g.Seq AS VARCHAR(20)), 'DateSO')))) % 366) + 1);

-- check in the load 
SELECT 'DIM_DATE' AS Tabela, COUNT(*) AS Qtd_Linhas FROM dbo.DIM_DATE UNION ALL
SELECT 'DIM_GEOGRAPHY', COUNT(*) FROM dbo.DIM_GEOGRAPHY UNION ALL
SELECT 'DIM_PRODUCT', COUNT(*) FROM dbo.DIM_PRODUCT UNION ALL
SELECT 'DIM_OUTLET', COUNT(*) FROM dbo.DIM_OUTLET UNION ALL
SELECT 'DIM_DISTRIBUTOR', COUNT(*) FROM dbo.DIM_DISTRIBUTOR UNION ALL
SELECT 'DIM_MEASURE_CATALOG', COUNT(*) FROM dbo.DIM_MEASURE_CATALOG UNION ALL
SELECT 'FACT_SELL_IN', COUNT(*) FROM dbo.FACT_SELL_IN UNION ALL
SELECT 'FACT_SELL_OUT', COUNT(*) FROM dbo.FACT_SELL_OUT UNION ALL
SELECT 'CONFLICT_LOG', COUNT(*) FROM dbo.CONFLICT_LOG UNION ALL
SELECT 'XWALK', COUNT(*) FROM dbo.XWALK UNION ALL
SELECT 'DRIFT_AUDIT', COUNT(*) FROM dbo.DRIFT_AUDIT;
