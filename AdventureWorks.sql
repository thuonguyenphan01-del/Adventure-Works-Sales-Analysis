
create procedure Checknull
@input Nvarchar(100)
as
begin
		declare @SQL Nvarchar(Max) ='';
		select @SQL = STRING_AGG('Sum(Case When ' + COLUMN_NAME+ ' IS NULL THEN 1 ELSE 0 END) as null_' + COLUMN_NAME,',')
		from INFORMATION_SCHEMA.COLUMNS
		where TABLE_NAME =@input;
		Set @SQL = 'Select ' + @SQL + ' from ' + @input;
		EXEC (@SQL);
end;
Checknull DimProduct

--- Profit , Revenue, COGS by Year
SELECT YEAR(OrderDateKey) AS "Year", CONCAT(CAST(SUM(Profit)/1000000 AS DECIMAL(10,2)),' M') AS "Profit",
LAG(SUM(Profit)) OVER (ORDER BY YEAR(OrderDateKey)) as "Profit_Pre_Year",
CONCAT(CAST(SUM(Revenue)/1000000 AS DECIMAL(10,2)),' M') AS "Revenue",
CONCAT(CAST(SUM(COGS)/1000000 AS DECIMAL(10,2)),' M') AS "COGS"
FROM FactInternetSales
GROUP BY Year(OrderDateKey)
ORDER BY Year(OrderDateKey)
--Profit , Revenue, COGS by Month,Year
SELECT YEAR(OrderDateKey) AS "Year", 
MONTH(OrderDateKey) AS "Month",
CONCAT(CAST(SUM(Profit)/1000000 AS DECIMAL(10,2)),' M') AS "Profit",
CONCAT(CAST(SUM(Revenue)/1000000 AS DECIMAL(10,2)),' M') AS "Revenue",
CONCAT(CAST(SUM(COGS)/1000000 AS DECIMAL(10,2)),' M') AS "COGS"
FROM FactInternetSales
GROUP BY Year(OrderDateKey),MONTH(OrderDateKey)
ORDER BY Year(OrderDateKey),MONTH(OrderDateKey)
--Profit by Day, Month
SELECT DATENAME(DW,OrderDateKey) AS "DW",
MONTH(OrderDateKey) AS "Month",
CONCAT(CAST(SUM(Profit)/1000000 AS DECIMAL(10,2)),' M') as "Profit"
FROM FactInternetSales
GROUP BY DATENAME(DW,OrderDateKey),MONTH(OrderDateKey)
ORDER BY MONTH(OrderDateKey)
-- Quantity Products sold
SELECT Count(OrderQuantity) as "Quantity",
DATETRUNC(YEAR, OrderDateKey) as "Year"
FROM FactInternetSales
GROUP BY DATETRUNC(Year, OrderDateKey)
ORDER BY DATETRUNC(Year, OrderDateKey)
-- Transaction Per Year
SELECT 
YEAR(OrderDateKey) as "Year",
COUNT(DISTINCT SalesOrderNumber) as "Order_Number"
FROM FactInternetSales
GROUP BY YEAR(OrderDateKey)
ORDER BY YEAR(OrderDateKey)
-- Top 5 Product with Highest Profit
WITH B AS (
SELECT
d.EnglishProductName, SUM(f.Profit) as "Total_Profit"
FROM FactInternetSales f
JOIN DimProduct d
ON f.ProductKey=d.ProductKey
WHERE YEAR(f.OrderDateKey) =2007
GROUP BY d.EnglishProductName),
A AS (SELECT B.EnglishProductName, B.Total_Profit, DENSE_RANK() OVER (ORDER BY B.Total_Profit DESC) AS "rk"
FROM B)
SELECT A.EnglishProductName,A.Total_Profit,a.rk
FROM A
WHERE rk <=5
ORDER BY rk
-- % Top 5 Product Compare vs total_Profit
WITH B AS (
SELECT
d.EnglishProductName, SUM(f.Profit) as "Total_Profit"
FROM FactInternetSales f
JOIN DimProduct d
ON f.ProductKey=d.ProductKey
WHERE YEAR(f.OrderDateKey) =2007
GROUP BY d.EnglishProductName),
A AS (SELECT B.EnglishProductName, B.Total_Profit, DENSE_RANK() OVER (ORDER BY B.Total_Profit DESC) AS "rk"
FROM B)
SELECT Sum(Total_Profit) /(SElECT Sum(Profit) FROM FactInternetSales WHERE YEAR(OrderDateKey) =2007)
FROM A
WHERE rk <=5;
-- Profit By Products's Colors
SELECT d.Color, SUM(f.Profit) AS "Total_Profit"
FROM FactInternetSales F
JOIN DimProduct d
ON  f.ProductKey=d.ProductKey
WHERE YEAR(OrderDateKey) =2007
GROUP BY d.Color
ORDER BY SUM(f.Profit) DESC
-- AVERAGE CUSTOMER AGE
WITH B AS (
SELECT d.CustomerKey,
YEAR(f.OrderDateKey) AS "Year_Purchase",
YEAR(d.BirthDate) as "BirthYear", (YEAR(f.OrderDateKey)-YEAR(d.BirthDate)) AS "age"
FROM FactInternetSales f
JOIN DimCustomer d
On f.CustomerKey=d.CustomerKey
GROUP BY YEAR(f.OrderDateKey),d.CustomerKey,YEAR(d.BirthDate)
)
SELECT Year_Purchase, AVG(age) as "AVG_Age"
FROM B
GROUP BY Year_Purchase
ORDER BY Year_Purchase;
-- NEW CUSTOMER
WITH B AS (
SELECT YEAR(d.DateFirstPurchase) AS "Yr", COUNT(d.CustomerKey) AS "Number_New_Customer"
FROM DimCustomer d
GROUP BY YEAR(d.DateFirstPurchase)),
A AS (
SELECT YEAR(OrderDateKey) as "Yr", COUNT(DISTINCT CustomerKey) AS "Total_Customer"
FROM FactInternetSales
GROUP BY YEAR(OrderDateKey) )
SELECT a.Yr,A.Total_Customer,B.Number_New_Customer
FROM A
JOIN B
ON A.Yr=B.Yr
ORDER BY A.Yr
--Female and Male Customer to Profit
SELECT d.Gender, SUM(f.Profit) AS "Total_Profit"
FROM FactInternetSales f
JOIN DimCustomer d
On f.CustomerKey = d.CustomerKey
GROUP BY d.Gender
-- Profit By Cơuntry
SELECT d.EnglishCountryRegionName, SUM(Profit) AS "Profit"
FROM DimGeography d
JOIN FactInternetSales f
ON d.SalesTerritoryKey=f.SalesTerritoryKey
GROUP BY d.EnglishCountryRegionName
-- Tạo View
CREATE VIEW View_Product_Customer AS
SELECT f.ProductKey,f.Profit,f.OrderDateKey,f.SalesOrderNumber,f.OrderQuantity,d.Color,d.EnglishProductName,c.BirthDate,c.DateFirstPurchase,c.Gender,
g.EnglishCountryRegionName
FROM FactInternetSales f
JOIN DimProduct d
ON d.ProductKey = f.ProductKey
JOIN DimCustomer c
ON f.CustomerKey =c.CustomerKey
JOIN DimGeography g
ON f.SalesTerritoryKey = g.SalesTerritoryKey






