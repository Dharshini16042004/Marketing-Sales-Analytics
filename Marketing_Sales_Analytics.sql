CREATE DATABASE SalesDB 



/* =========================
   DATA PREVIEW
   ========================= */

SELECT *
FROM [dbo].[DIM_Calendar]



/* =========================
   1. CHECK FOR NULL VALUES
   ========================= */
SELECT *
FROM DIM_Calendar
WHERE DateKey IS NULL
   OR Date IS NULL
   OR Day IS NULL
   OR Month IS NULL
   OR MonthShort IS NULL
   OR MonthNo IS NULL
   OR Quarter IS NULL
   OR Year IS NULL

/* =========================
   2. CHECK FOR MISSING DATES
   ========================= */

SELECT MIN(Date) AS StartDate,
       MAX(Date) AS EndDate,
       COUNT(*) AS TotalRows
FROM DIM_Calendar

/* =========================
   3. CHECK FOR DUPLICATE DATES
   ========================= */

SELECT Date, COUNT(*) AS CountDate
FROM DIM_Calendar
GROUP BY Date
HAVING COUNT(*) > 1

/* =========================
   4. CHECK FOR FUTURE DATES
   ========================= */
SELECT *
FROM DIM_Calendar
WHERE Date > GETDATE()

/* =========================
   5. VALIDATE DATEKEY vs DATE
   ========================= */
SELECT *
FROM DIM_Calendar
WHERE DateKey <> Date


/* =========================
   6. VALIDATE DAY / MONTH / YEAR
   ========================= */
SELECT *
FROM DIM_Calendar
WHERE 
    DATENAME(weekday, Date) <> Day
    OR DATENAME(month, Date) <> Month
    OR MONTH(Date) <> MonthNo
    OR YEAR(Date) <> Year

/* =========================
   7. VALIDATE MONTH SHORT NAME
   ========================= */

SELECT *
FROM DIM_Calendar
WHERE MonthShort <> LEFT(Month, 3)

/* =========================
   8. VALIDATE QUARTER
   ========================= */

SELECT *
FROM DIM_Calendar
WHERE Quarter <> DATEPART(QUARTER, Date)



/* =========================
   DATA PREVIEW
   ========================= */
SELECT *
FROM [dbo].[DIM_Customer]

/* =========================
   1. CHECK FOR MISSING VALUES
   ========================= */
SELECT *
FROM DIM_Customer
WHERE CustomerKey IS NULL
   OR Full_Name IS NULL
   OR Gender IS NULL
   OR Customer_City IS NULL


/* =========================
   2. CHECK FOR DUPLICATE CUSTOMERS
   ========================= */

SELECT CustomerKey, COUNT(*) AS CountCustomer
FROM DIM_Customer
GROUP BY CustomerKey
HAVING COUNT(*) > 1

/* =========================
   3.  CHECK GENDER VALUES
   ========================= */

SELECT *
FROM DIM_Customer
WHERE Gender NOT IN ('Male', 'Female')

/* =========================
   4. CHECK WRONG DATES
   ========================= */

SELECT *
FROM DIM_Customer
WHERE DateFirstPurchase > GETDATE()

/* =========================
   5. VALIDATE FULL NAME FORMAT
   ========================= */

SELECT *
FROM DIM_Customer
WHERE Full_Name <> First_Name + ' ' + Last_Name


/* =========================
   DATA PREVIEW
   ========================= */
SELECT *
FROM [dbo].[DIM_Product]

/* =========================
   1. CHECK MISSING VALUES
   ========================= */

SELECT *
FROM DIM_Product
WHERE ProductKey IS NULL
   OR ProductItemCode IS NULL
   OR Product_Name IS NULL
   OR Sub_Category IS NULL
   OR Product_Category IS NULL
   OR Product_Color IS NULL
   OR Product_Size IS NULL
   OR Product_Line IS NULL
   OR Product_Model_Name IS NULL
   OR Product_Description IS NULL
   OR Product_Status IS NULL

/* =========================
   2. CHECK DUPLICATE PRODUCTKEYS
   ========================= */

SELECT ProductKey, COUNT(*) AS CountProduct
FROM DIM_Product
GROUP BY ProductKey
HAVING COUNT(*) > 1


/* =========================
   3. CHECK DUPLICATE PRODUCTITEMCODE 
   ========================= */
SELECT ProductItemCode, COUNT(*) AS cnt
FROM DIM_Product
GROUP BY ProductItemCode
HAVING COUNT(*) > 1

/* =========================
   4.VIEW THE DUPLICATE RECORDS
   ========================= */
SELECT *
FROM DIM_Product
WHERE ProductItemCode IN (
    SELECT ProductItemCode
    FROM DIM_Product
    GROUP BY ProductItemCode
    HAVING COUNT(*) > 1
)
ORDER BY ProductItemCode;


/* =========================
  5.CHECK PRODUCT STATUS VALUES
   ========================= */
SELECT DISTINCT Product_Status
FROM DIM_Product

/* =========================
  6.COUNT PRODUCTS IN EACH STATUS
   ========================= */
SELECT Product_Status, COUNT(*) AS Status_Count
FROM DIM_Product
GROUP BY Product_Status

/* =========================
  7.REPLACE 'NA' IN PRODUCT_COLOR WITH NULL
   ========================= */
--Check before updating
SELECT *
FROM DIM_Product
WHERE Product_Color = 'NA'

--Update 'NA' to NULL
UPDATE DIM_Product
SET Product_Color = NULL
WHERE Product_Color = 'NA'


--Verify after update
SELECT *
FROM DIM_Product
WHERE Product_Color IS NULL

SELECT DISTINCT Product_color
FROM DIM_Product

/* =========================
  8. REPLACE STRING 'NULL' WITH ACTUAL NULL IN COLUMNS
   ========================= */

-- Update Sub_Category
UPDATE DIM_Product
SET Sub_Category = NULL
WHERE Sub_Category = 'NULL'

-- Update multiple columns with CASE

UPDATE DIM_Product
SET
    Product_Category = CASE WHEN Product_Category = 'NULL' THEN NULL ELSE Product_Category END,
    Product_Size = CASE WHEN Product_Size = 'NULL' THEN NULL ELSE Product_Size END,
	Product_Line = CASE WHEN Product_Line = 'NULL' THEN NULL ELSE Product_Line END,
    Product_Model_Name = CASE WHEN Product_Model_Name = 'NULL' THEN NULL ELSE Product_Model_Name END,
    Product_Description = CASE WHEN Product_Description = 'NULL' THEN NULL ELSE Product_Description END


/* =========================
   DATA PREVIEW
   ========================= */

SELECT *
FROM [dbo].[FACT_InternetSales]

/* =========================
   1. Check for MISSING VALUES
   ========================= */
SELECT *
FROM FACT_InternetSales
WHERE ProductKey IS NULL
   OR OrderDateKey IS NULL
   OR DueDateKey IS NULL
   OR ShipDateKey IS NULL
   OR CustomerKey IS NULL
   OR SalesOrderNumber IS NULL
   OR SalesAmount IS NULL

/* =========================
   2.CHECK FOR DUPLICATE
   ========================= */

SELECT ProductKey, OrderDateKey, CustomerKey, SalesOrderNumber, COUNT(*)
FROM FACT_InternetSales
GROUP BY ProductKey, OrderDateKey, CustomerKey, SalesOrderNumber
HAVING COUNT(*) > 1

/* =========================
   3.CHECK FOR NEGATIVE OR ZERO SALES AMOUNT
   ========================= */

SELECT *
FROM FACT_InternetSales
WHERE SalesAmount <=0


/* =========================
   4: Check DATE CONSISTENCY
   ========================= */

-- Ship date should not be before order date
SELECT *
FROM FACT_InternetSales
WHERE ShipDateKey < OrderDateKey

-- Due date should not be before order date
SELECT *
FROM FACT_InternetSales
WHERE DueDateKey < OrderDateKey


/* =========================
   5: CHECK FOR INVALID FOREIGN KEYS
   ========================= */

-- ProductKey validation
SELECT *
FROM FACT_InternetSales f
LEFT JOIN DIM_Product p ON f.ProductKey = p.ProductKey
WHERE p.ProductKey IS NULL

-- CustomerKey validation
SELECT *
FROM FACT_InternetSales f
LEFT JOIN DIM_Customer c ON f.CustomerKey = c.CustomerKey
WHERE c.CustomerKey IS NULL
/* =========================
  6: STANDARDIZE NUMERIC PRECISION
   ========================= */

-- Round SalesAmount to 2 decimal places
UPDATE FACT_InternetSales
SET SalesAmount = ROUND(SalesAmount, 2)

/* =========================
  7: Referential INTEGRITY CHECKS
   ========================= */

-- Validate ProductKey exists in DIM_Product
SELECT DISTINCT ProductKey
FROM FACT_InternetSales
WHERE ProductKey NOT IN (SELECT ProductKey FROM DIM_Product)

-- Validate CustomerKey exists in DIM_Customer

SELECT DISTINCT CustomerKey
FROM FACT_InternetSales
WHERE CustomerKey NOT IN (SELECT CustomerKey FROM DIM_Customer)

-- Validate OrderDateKey exists in DIM_Calendar

SELECT DISTINCT OrderDateKey
FROM FACT_InternetSales
WHERE OrderDateKey NOT IN (SELECT DateKey FROM DIM_Calendar)

/* =========================
   DATA PREVIEW
   ========================= */

SELECT *
FROM [dbo].[SalesBudget]

/* =========================
  1: CHECK FOR MISSING BUDGETS and DATE RANGE ISSUES
   ========================= */

-- Identify minimum & maximum dates and count NULL budgets
SELECT 
    MIN([Date]) AS MinDate,
    MAX([Date]) AS MaxDate,
    COUNT(*)    AS TotalRows,
    SUM(CASE WHEN Budget IS NULL THEN 1 ELSE 0 END) AS NullBudgetCount
FROM SalesBudget

/* =========================
   2: FIX DATA TYPES and STANDARDIZE FORMATS
   ========================= */

-- Convert Date and Budget into consistent data types

SELECT 
    CAST([Date] AS date)      AS CleanDate,
    CAST(Budget AS decimal(18,2)) AS CleanBudget
INTO SalesBudget_Clean
FROM SalesBudget

/* =========================
   3: IDENTIFY NULL or INVALID VALUES
   ========================= */

-- Check for missing dates, missing budgets, or negative budgets
SELECT *
FROM SalesBudget_Clean
WHERE CleanDate IS NULL
   OR CleanBudget IS NULL
   OR CleanBudget < 0

/* =========================
   4: DETECT DUPLICATE RECORDS
   ========================= */

-- Identify multiple budget entries for the same date

SELECT CleanDate, COUNT(*) AS cnt
FROM SalesBudget_Clean
GROUP BY CleanDate
HAVING COUNT(*) > 1

/* =========================
   5: VALIDATE BUDGET RANGE
   ========================= */

-- Budget values should fall within the expected range
SELECT *
FROM SalesBudget_Clean
WHERE CleanBudget NOT BETWEEN 0 AND 2000000;
