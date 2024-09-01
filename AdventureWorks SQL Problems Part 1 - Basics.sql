/*

Title: AdventureWorks SQL Practice sheet - Basic
Created by: Arpita Deb
Dated: 2024-08-28 01:20:49.883

About: Basic SQL Practice Queries from AdventureWorks Database

AdventureWorks Data Dictionary: https://www.sqldatadictionary.com/AdventureWorks2014/

*/


-- Initiating The Database
USE AdventureWorks2022;


-- 1. Show all the addresses listed for stores 'Friendly Bike Shop' and 'Sports Products Store'.

SELECT Store = S.[Name]
	  ,[AddressLine1]
	  , [AddressLine2]
	  , [City]
	  , [PostalCode]
	  , Country = R.Name
	  , State = ST.Name
	  , Territory= T.Name
FROM 
	[AdventureWorks2022].[Sales].[Store] S
JOIN 
	[Person].[BusinessEntityAddress] B ON B.BusinessEntityID = S.BusinessEntityID
JOIN 
	[Person].[Address] A ON A.AddressID = B.AddressID
JOIN 
	[Person].[StateProvince] ST ON ST.StateProvinceID = A.StateProvinceID
JOIN 
	[Person].[CountryRegion] R ON R.CountryRegionCode = ST.CountryRegionCode
JOIN 
	[Sales].[SalesTerritory] T ON ST.TerritoryID = T.TerritoryID
WHERE 
	S.[Name] IN ( 'Friendly Bike Shop', 'Sports Products Store')
ORDER BY 1;




-- 2. Show the Name of the customer, sales order id, date of order placed, quatity of products ordered per order, ListPrice of the products and total due for CustomerID 13590.

SELECT 
	CustomerName = P.[FirstName] + ' ' + P.MiddleName + ' ' + P.[LastName],
	H.[SalesOrderID],
	OrderDate = CAST([OrderDate] AS Date),
	ItemPerOrder = SUM([OrderQty]) OVER(PARTITION BY H.[SalesOrderID]), 
	[UnitPrice],
	[TotalDue]
FROM 
	[Sales].[SalesOrderHeader] H
JOIN 
	[Sales].[SalesOrderDetail] D ON H.SalesOrderID = D.SalesOrderID
JOIN 
	[Person].[Person] P ON P.BusinessEntityID = H.CustomerID
WHERE 
	[CustomerID] = 13590;



-- 3. Show the full name and the email address of customer with Store name 'Bike World'.

SELECT 
	CustomerName = P.[FirstName] + ' ' + P.[LastName], 
	EmailAddress
FROM 
	[Sales].[Store] S 
JOIN 
	[Sales].[Customer] C ON C.[StoreID] = S.BusinessEntityID
JOIN 
	[Person].[Person] P ON C.[PersonID]= P.BusinessEntityID
JOIN 
	[Person].[EmailAddress] E ON E.BusinessEntityID = P.BusinessEntityID
WHERE 
	S.Name = 'Bike World';




-- 4. Show all the stores with an address in City 'Dallas'.

SELECT 
	Store = S.[Name]
FROM 
	[AdventureWorks2022].[Sales].[Store] S
JOIN 
	[Person].[BusinessEntityAddress] B ON B.BusinessEntityID = S.BusinessEntityID
JOIN 
	[Person].[Address] A ON A.AddressID = B.AddressID
WHERE 
	A.City = 'Dallas';



-- 5. How many items with ListPrice more than $1000 have been sold?

SELECT 
	CountOfItems = COUNT(*) 
FROM 
	[Sales].[SalesOrderDetail]
WHERE 
	[UnitPrice] > 1000



-- 6. Give the Store names of those customers with orders over $100000. Include the subtotal plus tax plus freight.

SELECT Store,
	TotalDue = CAST(Subtotal + Tax + Freight AS NUMERIC(36,2)),
	PercentTax = FORMAT(Tax / (Subtotal + Tax + Freight), 'p'),
	PercentFreight = FORMAT(Freight/(Subtotal + Tax + Freight), 'p')
FROM
(
	SELECT 
		Store =	S.Name,
		Subtotal = SUM([SubTotal]), 
		Tax = SUM([TaxAmt]), 
		Freight = SUM([Freight])
	FROM 
		[Sales].[SalesOrderHeader] H
	JOIN 
		[Sales].[Customer] C ON H.CustomerID = C.CustomerID
	JOIN 
		[Sales].[Store] S ON C.StoreID = S.BusinessEntityID
	WHERE 
		[TotalDue] > 100000
	GROUP BY 
		S.Name
) S
ORDER BY 1;



-- 7.Find the number of left racing socks ('Racing Socks, L') ordered by Company(/Store) 'Riding Cycles'.

WITH Orders AS
(
	SELECT [ProductID], 
			OrderQuantity = SUM([OrderQty])
	FROM 
		[Sales].[SalesOrderDetail] D
	JOIN 
		[Sales].[SalesOrderHeader] H ON D.SalesOrderID = H.SalesOrderID
	JOIN 
		[Sales].[Customer] C ON H.CustomerID = C.CustomerID
	JOIN 
		[Sales].[Store] S ON S.BusinessEntityID = C.StoreID
	WHERE 
		S.[Name] = 'Riding Cycles'
	GROUP BY 
		[ProductID]
),
Products AS
(
	SELECT [ProductID], 
		Product = [Name]
	FROM 
		[Production].[Product]
	WHERE 
		[Name] = 'Racing Socks, L'
)
SELECT Product, 
	OrderQuantity
FROM 
	Orders O 
JOIN 
	Products P ON O.ProductID = P.ProductID
;



-- 8.  A "Single Item Order" is a customer order where only one item is ordered. Show the SalesOrderID and the UnitPrice for every Single Item Order.
-- Also include the number of SingleItemOrders per SalesOrderID.

SELECT [SalesOrderID]
	, SalesOrderDetailID
	, SingleItemOrders = COUNT([SalesOrderID]) OVER(PARTITION BY [SalesOrderID])
	, UnitPrice
FROM
(
	SELECT [SalesOrderID]
		   ,[SalesOrderDetailID]
		   ,[UnitPrice]

	FROM [AdventureWorks2022].[Sales].[SalesOrderDetail]
	WHERE [OrderQty] = 1
) C;



-- 9. Where did the racing socks go? List the product name and the CompanyName for all Customers who ordered ProductModel 'Racing Socks'.
-- Add a derived column which gives the total quantity of socks per order.

SELECT D.[SalesOrderID], 
	[SalesOrderDetailID], 
	CustomerName = PR.FirstName + ' ' + PR.LastName,
	StoreName = S.Name, 
	ProductName = P.Name,
	Quantity = SUM([OrderQty]) OVER(PARTITION BY D.[SalesOrderID], [SalesOrderDetailID])
FROM 
	[Sales].[SalesOrderDetail] D
JOIN 
	[Sales].[SalesOrderHeader] H ON H.SalesOrderID = D.SalesOrderID
JOIN 
	[Sales].[Customer] C ON C.CustomerID = H.CustomerID
JOIN 
	[Sales].[Store] S ON S.BusinessEntityID = C.StoreID
JOIN 
	[Person].[Person] PR ON PR.BusinessEntityID = C.PersonID
JOIN 
	[Production].[Product] P ON P.ProductID = D.ProductID
JOIN 
	[Production].[ProductModel] M ON M.ProductModelID = P.ProductModelID
WHERE 
	M.Name = 'Racing Socks'
ORDER BY
	3, 4, 5, 6;




--10. Show the product description for culture 'fr' for product with ProductID 736.


SELECT Description
FROM 
	[Production].[ProductModelProductDescriptionCulture] MC
JOIN 
	[Production].[Culture] C ON C.CultureID = MC.CultureID
JOIN 
	[Production].[ProductDescription] D ON D.ProductDescriptionID = MC.ProductDescriptionID
JOIN 
	[Production].[Product] P ON MC.ProductModelID = P.ProductModelID
WHERE 
	C.CultureID = 'fr' AND P.ProductID = 736; 





/*
11. Show how many orders are in the following ranges (in $):

    RANGE
    0-  99
  100- 999
 1000-9999
10000-

*/

SELECT OrderRange
	, TotalValue = CAST(SUM(TotalValue) AS NUMERIC(36,2))
	, OrderCount = COUNT([SalesOrderID])
FROM 
(
	SELECT [SalesOrderID]
		, TotalValue = SUM([TotalDue])
		, OrderRange = (CASE 
					WHEN SUM([TotalDue]) <100 THEN '0 - 99'
					WHEN SUM([TotalDue]) <1000 THEN '100 - 999'
					WHEN SUM([TotalDue]) <10000 THEN '1000 - 9999'
					ELSE '10000 - '
				END)
	FROM 
		[Sales].[SalesOrderHeader]
	GROUP BY 
		[SalesOrderID]
) C
GROUP BY 
	OrderRange
ORDER BY 
	2, 3 DESC;



-- 12. Identify the three most important cities. Show the break down of top level product category against city.

WITH TopCities AS (
    SELECT TOP 3 a.City, OrderValue = CAST(SUM(H.[TotalDue]) AS NUMERIC(36,2))
    FROM Sales.SalesOrderHeader H
    JOIN Person.Address a ON H.BillToAddressID = a.AddressID
    GROUP BY a.City
    ORDER BY SUM(H.[TotalDue]) DESC
)
SELECT tc.City, 
	ppc.Name AS Category, 
	OrderValue,
	SUM(D.LineTotal) AS TotalSales
FROM 
	Sales.SalesOrderDetail D
JOIN 
	Sales.SalesOrderHeader H ON D.SalesOrderID = H.SalesOrderID
JOIN 
	Production.Product p ON D.ProductID = p.ProductID
JOIN 
	Production.ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
JOIN 
	Production.ProductCategory ppc ON psc.ProductCategoryID = ppc.ProductCategoryID
JOIN 
	Person.Address a ON H.BillToAddressID = a.AddressID
JOIN 
	TopCities tc ON a.City = tc.City
GROUP BY 
	tc.City, ppc.Name, OrderValue
ORDER BY 
	3 DESC;




/*
13.  Rank Customers based on Total Sales?
		Diamond - salesamount >10000
		Gold - 5000< salesamount < 9999
		Silver - 1000<salesamount <4999
		Bronze - salesamount < 1000
*/

WITH TotalSales AS
(
SELECT 
	CustomerID = C.CustomerID, 
	SalesOrderID = H.[SalesOrderID],
	TotalDue = H.TotalDue
FROM 
	[Sales].[SalesOrderHeader] H
JOIN 
	[Sales].[Customer] C ON H.CustomerID = C.CustomerID
)
SELECT CustomerID, 
	SalesOrderID,
	CustomerType = (CASE 
				WHEN TotalDue < 1000 THEN 'Bronze'
				WHEN TotalDue < 4999 THEN 'Silver'
				WHEN TotalDue < 9999 THEN 'Gold'
				ELSE 'Diamond'
			END)
FROM 
	TotalSales
ORDER BY 
	1;




-- 14. List the ProductName and the quantity of what was ordered by 'Futuristic Bikes'.

WITH products AS
(
		SELECT ProductName = P.Name, 
				[OrderQty]
		FROM 
			[Sales].[SalesOrderDetail] D
		LEFT JOIN 
			[Sales].[SalesOrderHeader] H ON D.SalesOrderID = H.SalesOrderID
		LEFT JOIN 
			[Production].[Product] P ON D.ProductID = P.ProductID
		LEFT JOIN 
			[Sales].[Customer] C ON H.CustomerID = C.CustomerID
		LEFT JOIN 
			[Sales].[Store] S ON C.StoreID = S.BusinessEntityID
		WHERE 
			S.Name = 'Futuristic Bikes'
)
SELECT ProductName, 
	OrderQuantity = SUM([OrderQty])
FROM 
	products
GROUP BY 
	ProductName;



-- 15. List the name and addresses of companies containing the word 'Bike' (upper or lower case) and companies containing 
-- 'cycle' (upper or lower case). Ensure that the 'bike's are listed before the 'cycles's.

-- Note: In this example, I've used a look up table called 'Addresses' which is not available in the original database.
-- The code to create this table available in the GitHub Repository.

-- Temp Table 1 which stores all the store names

CREATE TABLE #Stores
(
BusinessEntityID INT
, Name VARCHAR(50)
)


-- Inserting values in Temp Table 1 from [Store] table
INSERT INTO #Stores
(
BusinessEntityID
, Name 
)
SELECT S.[BusinessEntityID], [Name]
FROM [Sales].[Store] S
WHERE LOWER([Name]) LIKE '%bike%' OR -- LOWER() makes the records case-insensitive
      LOWER([Name]) LIKE '%cycle%'



-- Temp Table 2 which stores all the store names along with their addresses

CREATE TABLE #StoresWithAddress
(
BusinessEntityID INT
, Name VARCHAR(50)
, Address TEXT
)

-- Inserting values in Temp Table 2 from #Stores, joining with [Customer] and [Addresses] tables
INSERT INTO #StoresWithAddress 
(
BusinessEntityID
, Name 
, Address
)
SELECT DISTINCT BusinessEntityID = S.BusinessEntityID, 
	StoreName = S.Name, 
	Address = A.[AddressLine1] + ', ' + A.City+ ', ' + A.StateProvince+ ', ' + A.CountryRegion +  ' - ' + A.PostalCode
FROM 
	#Stores S
JOIN 
	[Sales].[Customer] C ON S.[BusinessEntityID] = C.[StoreID]
JOIN 
	[dbo].[Addresses] A ON C.TerritoryID = A.TerritoryID

-- Final Query showing Store Names and their address
SELECT * 
FROM #StoresWithAddress
ORDER BY (CASE  
            WHEN LOWER([Name]) LIKE '%bike%' THEN 1 -- This ensures that the 'bike's are listed before the 'cycles's
            ELSE 2
         END),
         [Name] ASC;


-- 16. Use the SubTotal value in SaleOrderHeader to list orders from the largest to the smallest. 
-- For each order show the CompanyName, the SubTotal and the total weight of the order.


SELECT H.[SalesOrderID],
	Store = S.Name,
	Subtotal = SUM([SubTotal]),
	ProductWeight = SUM(P.Weight),
	ProductWeightUnit = [WeightUnitMeasureCode]
FROM 
	[Sales].[SalesOrderHeader] H
JOIN 
	[Sales].[Customer] C ON C.CustomerID = H.CustomerID
JOIN 
	[Sales].[Store] S ON S.BusinessEntityID = C.StoreID
JOIN 
	[Sales].[SalesOrderDetail] D ON D.SalesOrderID = H.SalesOrderID
JOIN 
	[Production].[Product] P ON P.ProductID = D.ProductID
GROUP BY 
	H.[SalesOrderID], S.Name, p.[WeightUnitMeasureCode]
ORDER BY 
	3;


--17. Show the total order value for each CountryRegion. List by value with the highest first.
-- Note: In this query, I used a different table 'Addresses' which doesn't exist in the original database. I've created this look up 
-- table in advanced so that I can use it as many times as I need without Joining these tables over and over again. I've provided the code to create the table in a separate .sql file in the repository.

SELECT 
	A.CountryRegion, 
	TotalOrderValue = CAST(SUM(H.[TotalDue]) AS MONEY),
	OrderValueInMillion = CAST((SUM(H.[TotalDue])/1000000) AS CHAR) + 'M'
FROM 
	[Sales].[SalesOrderHeader] H
JOIN 
	Addresses A ON A.TerritoryID = H.TerritoryID
GROUP BY 
	A.CountryRegion
ORDER BY 2 DESC;


/*

18. For each order show the SalesOrderID and SubTotal calculated three ways:
		A) From the SalesOrderHeader
		B) Sum of OrderQty*UnitPrice
		C) Sum of OrderQty*ListPrice
*/

SELECT H.[SalesOrderID]
	, Subtotal1 = SUM([SubTotal])
	, Subtotal2 = SUM(D.[OrderQty] * D.[UnitPrice])
	, Subtotal3 = SUM(D.[OrderQty] * P.[ListPrice])

FROM 
	[Sales].[SalesOrderHeader] H
JOIN 
	[Sales].[SalesOrderDetail] D ON H.[SalesOrderID] = D.[SalesOrderID]
JOIN 
	[Production].[Product] P ON P.[ProductID] = D.[ProductID]
GROUP BY 
	H.[SalesOrderID];
