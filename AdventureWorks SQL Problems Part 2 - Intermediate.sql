/*

Title: AdventureWorks SQL Practice sheet - Intermediate
Created by: Arpita Deb
Dated: 22-08-2024 14:06

About: Intermediate SQL Practice Queries from AdventureWorks Database

AdventureWorks Data Dictionary: https://www.sqldatadictionary.com/AdventureWorks2014/

*/



-- Initiating The Database
USE AdventureWorks2022;



/*
Q1: Find the top 10 customers with the highest total sales. Include their total order count and average order value.
*/
-- Created a temp table #CustomerDetails with 4 columns
CREATE TABLE #CustomerDetails
(
SalesOrderID INT,
CustomerID INT,
CustomerName VARCHAR(50),
TotalDue MONEY,
)

-- Inserted the values from a SELECT query which joins [Customer] and [Person] tables with [SalesOrderHeader] table.
INSERT INTO #CustomerDetails
(
SalesOrderID,
CustomerID,
CustomerName,
TotalDue
)
SELECT [SalesOrderID], 
	c.[CustomerID],
	CustomerName = p.FirstName + ' ' + p.[LastName],
	[TotalDue]
FROM 
	[Sales].[SalesOrderHeader] s
LEFT JOIN 
	[Sales].[Customer] c ON s.CustomerID = c.CustomerID
LEFT JOIN 
	[Person].[Person] p ON c.PersonID = p.BusinessEntityID

-- Finally calculated the total sales, order count per customer and average sales from the Temp table. 
-- Showed the top 10 customers with highest sales value
SELECT TOP 10 CustomerName
	, TotalSales = SUM([TotalDue])
	, NumberOfSales = COUNT(*)
	, AverageSales = AVG([TotalDue])
FROM 
	#CustomerDetails
GROUP BY 
	CustomerName
ORDER BY 
	SUM([TotalDue]) DESC;

-- Dropping the Temp Table
DROP TABLE #CustomerDetails;



/*
Q2: Which product categories have seen the highest growth in sales year over year?
*/

/*
-- APPROACH 1: Using Subquery
Steps taken:
1. Wrote an inner query that joins 4 tables to access to the Category column and find their LineTotal for each year
		a) Found the year from ModifiedDate using YEAR Function
		b) Using an window function calculated the Sum of LineTotal for each category.
2. In the outer query, created 2 new columns using LAG() window function PrevYear and PrevYearSales

3. Finally calculated the YoYGrowth using the formula (Current Year Sales - Prev year sales ) * 100 / Previous Year Sales

4. Showed the data in descending order of YoYGrowth.

*/
SELECT Category	-- Outer Query
	, OrderYear
	, PrevYear = LAG(OrderYear, 1) OVER(PARTITION BY Category ORDER BY OrderYear)
	, CurrentLineTotal = LineTotal
	, PrevYearSales = CAST(LAG(LineTotal, 1) OVER(PARTITION BY Category ORDER BY OrderYear) AS NUMERIC (36, 2))
	, YoYGrowth = CAST((LineTotal - LAG(LineTotal, 1) OVER(PARTITION BY Category ORDER BY OrderYear)) * 100.00/ LAG(LineTotal, 1) OVER(PARTITION BY Category ORDER BY OrderYear) AS NUMERIC (36, 2))
FROM 
( -- Inner query
		SELECT DISTINCT 
				Category = C.Name
				,OrderYear = YEAR(D.[ModifiedDate])
				,LineTotal = CAST(SUM(D.[LineTotal]) OVER(PARTITION BY C.Name, YEAR(D.[ModifiedDate]) ORDER BY YEAR(D.[ModifiedDate])) AS NUMERIC (36, 2))
		FROM 
				[Sales].[SalesOrderDetail] D
		LEFT JOIN 
				[Production].[Product] P ON P.ProductID = D.ProductID
		LEFT JOIN 
				[Production].[ProductSubcategory] SC ON SC.ProductSubcategoryID = P.ProductSubcategoryID
		LEFT JOIN 
				[Production].[ProductCategory] C ON C.ProductCategoryID = SC.ProductCategoryID

) c

ORDER BY 
	6 DESC;


/*
Approach 2: Using Common Table Expression(CTE)

1. In the first CTE 'LineTotals', joined the [SalesOrderDetail] table with   [Product], [ProductSubcategory] and 
   [ProductCategory] tables to access to the 'Category' column

2. Here I selected these columns:
    a) Category
    b) OrderYear : found the year from ModifiedDate using YEAR() Function
    c) LineTotal : Using an window function calculated the Sum of LineTotal 
                   for each category. Used CAST() to round the number to 2 decimal points.

3. In the second CTE, in addition to the 3 columns, I created 2 new columns 'PrevYear' and 'PrevYearSales' using LAG() window function 

4. Finally calculated the YoYGrowth using the formula:(Current Year Sales - Prev year sales ) * 100 / Previous Year Sales

5. In the final query, filtered the data to show only categories with positive YoYGrowth.

*/

WITH LineTotals AS -- CTE 1
(
SELECT DISTINCT 
				Category = C.Name
				,OrderYear = YEAR(D.[ModifiedDate])
				,LineTotal = CAST(SUM(D.[LineTotal]) OVER(PARTITION BY C.Name, YEAR(D.[ModifiedDate]) ORDER BY YEAR(D.[ModifiedDate])) AS NUMERIC (36, 2))
FROM 
				[Sales].[SalesOrderDetail] D
LEFT JOIN 
				[Production].[Product] P ON P.ProductID = D.ProductID
LEFT JOIN 
				[Production].[ProductSubcategory] SC ON SC.ProductSubcategoryID = P.ProductSubcategoryID
LEFT JOIN 
				[Production].[ProductCategory] C ON C.ProductCategoryID = SC.ProductCategoryID
),

Categories AS -- CTE 2
(
SELECT Category
	, OrderYear
	, PrevYear = LAG(OrderYear, 1) OVER(PARTITION BY Category ORDER BY OrderYear)
	, CurrentLineTotal = LineTotal
	, PrevYearSales = CAST(LAG(LineTotal, 1) OVER(PARTITION BY Category ORDER BY OrderYear) AS NUMERIC (36, 2))
	, YoYGrowth = CAST((LineTotal - LAG(LineTotal, 1) OVER(PARTITION BY Category ORDER BY OrderYear)) * 100.00/ LAG(LineTotal, 1) OVER(PARTITION BY Category ORDER BY OrderYear) AS NUMERIC (36, 2))

FROM 
	LineTotals
) 
	
SELECT Category, -- Final Query
	OrderYear, 
	PrevYear, 
	YoYGrowth
FROM 
	Categories
WHERE 
	YoYGrowth > 0
ORDER BY 
	YoYGrowth DESC, OrderYear;



/*
Q3: Identify the top 5 salespersons based on total sales. Additionally, calculate the percentage of the total company sales each contributed.
*/

/*
Steps: 
1. Created a CTE SalesPersonDetails which joins [SalesOrderHeader] and [Person] tables with [SalesPersonQuotaHistory] table.
2. Here added these columns:
		- SalesPerson
		- [TotalSalesPerSalesperson]: Total overall Sales per Salesperson
		- TotalSales: Overall sales for AdventureWorks
		- [% Contribution]: % of sales person's sales of Adventureworks' overall sales 

3. In the final query ranked the salesperson by their % contribution and showed the top 5 results.
*/

WITH SalesPersonDetails AS
(
SELECT DISTINCT 
	SalesPerson = P.FirstName + ' ' + P.LastName
	, [TotalSalesPerSalesperson] = SUM([TotalDue]) OVER(PARTITION BY H.SalesPersonID)
	, TotalSales = SUM([TotalDue]) OVER()
	, [% Contribution]	= SUM([SalesQuota]) OVER(PARTITION BY S.[BusinessEntityID]) * 100.0 / SUM([TotalDue]) OVER()
FROM 
	[Sales].[SalesPersonQuotaHistory] S
LEFT JOIN 
	[Sales].[SalesOrderHeader] H ON H.SalesPersonID = S.BusinessEntityID
LEFT JOIN 
	[Person].[Person] P ON P.BusinessEntityID = S.BusinessEntityID
)

SELECT TOP 5 SalesPerson
	, [% Contribution] = CAST([% Contribution] AS NUMERIC(36,2))
	, Ranking = ROW_NUMBER() OVER(ORDER BY [% Contribution] DESC)
FROM 
	SalesPersonDetails
ORDER BY 3;




/*
Q4: Determine which products have not been sold in the last 6 months. Also, provide the current inventory level 
for these products.
*/

-- Temp table 1: List of Products sold in past 6 months 

CREATE TABLE #ProductsSold
(
ProductID INT
,ProductName VARCHAR(50)
)
-- Inserting values in the Temp Table 1
INSERT INTO #ProductsSold
(ProductID
,ProductName 
)
SELECT DISTINCT ProductID = D.ProductID, 
		ProductName = P.Name
FROM 
		[Sales].[SalesOrderHeader] H
JOIN 
		[Sales].[SalesOrderDetail] D ON D.SalesOrderID = H.SalesOrderID
JOIN 
		[Production].[Product] P ON P.ProductID = D.ProductID
WHERE 
		[OrderDate] >= DATEADD(DAY, -180, '2014-06-30'); -- 2014-06-30 is the last date of order in the database 

-- Temp table 2: All the products from the product table

CREATE TABLE #Allproducts 
(
ProductID INT
,ProductName VARCHAR(50)
,OrderQuantity INT
)

-- Inserting values in the Temp Table 2
INSERT INTO #Allproducts 
(
ProductID 
,ProductName
)
SELECT DISTINCT [ProductID], 
	[Name]
FROM [Production].[Product]

/*	
Final Query : Using EXCEPT() selected only those products that weren't sold in last 6 months
Transformed the query into a CTE ProductsNotSold and Left Joined it with [Production].[ProductInventory] table to
get the inventory label for each product
*/
With ProductsNotSold AS
(
SELECT 
	ProductID, 
	ProductName
FROM 
	#Allproducts

EXCEPT

SELECT 
	ProductID, 
	ProductName
FROM 
	#ProductsSold
)
SELECT S.ProductID, 
	S.ProductName,
	Quantity = SUM(I.Quantity)
FROM 
	ProductsNotSold S
LEFT JOIN 
	[Production].[ProductInventory] I ON I.ProductID = S.ProductID
GROUP BY 
	S.ProductID, S.ProductName
; 

-- Dropping the temp tables
DROP TABLE #ProductsSold;
DROP TABLE #Allproducts;




/*
Q5: List suppliers who have provided more than 5 different products. For each, calculate the average price of 
products supplied.

Steps:
1. In the Inner Subquery, calculated product count and average price of products for each vendor
2. From the Outer Query, selected only those vendors with a product count > 5
*/

SELECT DISTINCT VendorName, -- Outer Query
	ProductCount, 
	AveragePrice
FROM ( 
	-- Inner Query		
		SELECT 
		PV.[BusinessEntityID],
		VendorName = V.Name,
		ProductCount = COUNT(DISTINCT [ProductID]),
		AveragePrice = CAST(AVG([StandardPrice]) AS NUMERIC(36, 2))
		
		FROM [AdventureWorks2022].[Purchasing].[ProductVendor] PV
		
		JOIN [Purchasing].[Vendor] V ON V.BusinessEntityID = PV.BusinessEntityID
		
		GROUP BY PV.[BusinessEntityID], V.Name
) c

WHERE 
	ProductCount > 5
ORDER BY 
	ProductCount DESC;




/*
Q6: Analyze monthly sales trends over the past 4 years and identify any seasonal patterns. Group the results by year 
and month.

Steps:
1. Created a CTE Sales with OrderYear, OrderMonth and Monthly Sales Value
2. In the final query leveraged LEAD(), CASE WHEN () and ROWS BETWEEN () functions to calculate new columns
3. Used CAST() function to displayed the results upto 2 decimal points
*/

WITH Sales AS
(
SELECT OrderYear = YEAR([OrderDate])
	,OrderMonth = MONTH([OrderDate])
	,TotalSales = SUM([TotalDue])
FROM
	[Sales].[SalesOrderHeader]
GROUP BY 
	YEAR([OrderDate]),  MONTH([OrderDate])
)
SELECT OrderYear
	  , OrderMonth
	  , CurrentMonthSales = CAST(TotalSales AS NUMERIC (36,2))
	  , NextMonthSales= CAST(LEAD(TotalSales, 1) OVER(ORDER BY OrderYear, OrderMonth) AS NUMERIC (36,2))
	  , PercentageChange = CAST((LEAD(TotalSales, 1) OVER(ORDER BY OrderYear, OrderMonth) - TotalSales)* 100.0 /TotalSales AS NUMERIC (36,2))
	  , SalesTrend = (CASE WHEN ((LEAD(TotalSales, 1) OVER(ORDER BY OrderYear, OrderMonth) - TotalSales)* 100.0 /TotalSales) < 0 THEN 'DOWN' ELSE 'UP' END)
	  , Rolling3MonthsTotal = SUM(TotalSales) OVER( ORDER BY OrderYear, OrderMonth ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
	  , MovingAverageNext2Months = AVG(TotalSales) OVER( ORDER BY OrderYear, OrderMonth ROWS BETWEEN CURRENT ROW and 2 FOLLOWING)
FROM 
	Sales;


/*
Q7: Calculate the average lead time for each vendor and product subcategory.
*/

SELECT Vendor = V.Name	
	 , ProductSubCategory = C.Name
	 , AverageLeadTime = AVG([AverageLeadTime])
FROM 
	[AdventureWorks2022].[Purchasing].[ProductVendor] PV
JOIN 
	[Purchasing].[Vendor] V ON V.BusinessEntityID = PV.BusinessEntityID
JOIN 
	[Production].[Product] P ON PV.ProductID = P.ProductID
JOIN 
	[Production].[ProductSubcategory] C ON P.ProductSubcategoryID = C.ProductSubcategoryID
GROUP 
	BY V.Name, C.Name
ORDER BY 
	3 DESC;


/*
Q8: Identify customers who made their first purchase more than 2 years ago but haven't made any purchases in the last year. Calculate the total value of their past purchases.
*/

WITH CustomerOrders AS 
(
    SELECT 
        [CustomerID],
	FirstOrderDate = CAST(MIN([OrderDate]) OVER(PARTITION BY [CustomerID]) AS DATE),
        LastOrderDate = CAST(MAX([OrderDate]) OVER(PARTITION BY [CustomerID]) AS DATE),
	LastOrderDateOverall = CAST(MAX([OrderDate]) OVER() AS DATE),
        TotalOrderValue = SUM([TotalDue]) OVER(PARTITION BY [CustomerID])
    FROM [Sales].[SalesOrderHeader]
)
SELECT 
    	Customer = P.FirstName + ' ' + P.LastName,
	LastOrderDateOverall,
    	FirstOrderDate,
    	LastOrderDate,
    	TotalOrderValue
FROM 
	CustomerOrders CO
JOIN 
	[Person].[Person] P ON P.BusinessEntityID = CO.CustomerID
WHERE 
    	FirstOrderDate < DATEADD(year, -2,LastOrderDateOverall ) -- Customers who made their first purchase more than 2 years ago
    	AND LastOrderDate < DATEADD(year, -1, LastOrderDateOverall) -- But haven't made any purchases in the last year
GROUP BY 
    	P.FirstName, P.LastName, CO.FirstOrderDate, CO.LastOrderDate, CO.TotalOrderValue, CO.LastOrderDateOverall
ORDER BY 
    	LastOrderDate DESC;



/*
9. Rank the salespersons based on Sales YTD. Also rank the salesperson for each Territory
*/

SELECT SalesPerson = P.FirstName + ' '  + P.LastName
	, Territory = T.[Name]
	, S.[SalesYTD]
	, OverallRank = ROW_NUMBER () OVER(ORDER BY S.[SalesYTD] DESC)
	, RankInTerritory = RANK() OVER(PARTITION BY T.[Name] ORDER BY S.[SalesYTD] DESC)
FROM 
	[Sales].[SalesPerson] S
LEFT JOIN 
	[Person].[Person] P ON S.[BusinessEntityID] = P.[BusinessEntityID]
LEFT JOIN 
	[Sales].[SalesTerritory] T ON T.TerritoryID = S.TerritoryID
WHERE 
	T.[Name] IS NOT NULL
ORDER BY 
	T.[Name];



/*
10. Calculate the percentage of SalesQuota achieved by each salesperson. Identify salespersons who have exceeded 
their quota by more than 20%.
*/

/*
Steps: 
1. In the CTE, selected the salesperson, their SalasYTD and SalesQuota from SalesPerson table. In case of 0 sales quota,
   I replaced them with the average sales quota using a subquery in the COALESCE function.
2. In the final query, calculated % quota by dividing SalesYTD with their respective SalesQuota
3. Filtered the saleserson with % quote greater than 120 (which represents 20%) 

*/
WITH SalesPersonDetails AS -- CTE
(
	SELECT SalesPerson = P.FirstName + ' '  + P.LastName
		, SalesYTD = CAST([SalesYTD] AS NUMERIC(36,2)) 
		, SalesQuota = CAST(COALESCE([SalesQuota],(SELECT AVG([SalesQuota]) FROM [Sales].[SalesPerson])) AS NUMERIC(36,2)) -- Replacing the Null values in sales quota with the average sales quota
	FROM 
		[Sales].[SalesPerson] S
	LEFT JOIN 
		[Person].[Person] P ON S.[BusinessEntityID] = P.[BusinessEntityID]
)
SELECT SalesPerson -- Final query
	, [% Quota] = SalesYTD * 100.0 / SalesQuota
FROM 
	SalesPersonDetails
WHERE 
	SalesYTD * 100.0 / SalesQuota > 120 -- Filtering for salesperson who exceeded their quota by 20%.
ORDER BY 
	2 DESC;



/*
11. Calculate the year-over-year growth percentage for each salesperson based on SalesLastYear and SalesYTD. Identify those with the highest and lowest growth.

YoY Change Formula = (Current Year Sale / last Year Sale - 1) * 100.0
In case of 0 division error, flag those records by -99.
*/

SELECT SalesPerson = P.FirstName + ' '  + P.LastName
	, SalesYTD = CAST([SalesYTD] AS NUMERIC(36,2))
	, SalesLastYear = CAST([SalesLastYear] AS NUMERIC(36,2))
	, [% YoY Change] = CAST((CASE 
				WHEN [SalesLastYear] <> 0 THEN (([SalesYTD]/[SalesLastYear] -1) * 100.00) 
				ELSE -99 
			   END) AS NUMERIC(36,2))
FROM 
	[Sales].[SalesPerson] S
LEFT JOIN 
	[Person].[Person] P ON S.[BusinessEntityID] = P.[BusinessEntityID]
ORDER BY 
	4 DESC;



/* 
12. Create a composite ranking system for salespersons that considers SalesYTD, SalesQuota, and Bonus. Rank salespersons by their overall performance score.
*/

/*
Steps:
1. Normalizing Metrics: SalesYTD and Bonus are used directly, while SalesQuota is normalized by calculating the
   ratio SalesYTD / SalesQuota.
2. Composite Score: This is calculated by multiplying SalesYTD, Quota Achievement, and Bonus. This formula 
   assumes that a higher score in all three areas is better.
3. Ranking: The RANK() function is used to assign a rank based on the composite score, where a higher score 
   results in a better rank.
*/

WITH SalesPersonDetails AS
(
    SELECT 
        SalesPerson = P.FirstName + ' ' + P.LastName,
        SalesYTD = CAST([SalesYTD] AS NUMERIC(36, 2)),
        SalesQuota = CAST(COALESCE([SalesQuota], (SELECT AVG([SalesQuota]) FROM [Sales].[SalesPerson])) AS NUMERIC(36, 2)),
        Bonus = CAST(COALESCE([Bonus], 0) AS NUMERIC(36, 2)) -- Assuming null bonuses as 0
    FROM 
        [Sales].[SalesPerson] S
    LEFT JOIN 
        [Person].[Person] P ON S.[BusinessEntityID] = P.[BusinessEntityID]
)
SELECT 
    SalesPerson,
    SalesYTD,
    QuotaAchievement = SalesYTD / SalesQuota,
    Bonus,
    CompositeScore = SalesYTD * (SalesYTD / SalesQuota) * Bonus, -- Calculating the composite score
    OverallRank = RANK() OVER (ORDER BY SalesYTD * (SalesYTD / SalesQuota) * Bonus DESC)
FROM 
    SalesPersonDetails
ORDER BY 
    OverallRank;



/*
Q13: Break down the total revenue by product category and sales region for the current year. Display the percentage 
contribution of each category within each region.
*/


/*
STEPS:
1. In first CTE, I joined several tables to find the ProductCategory, SalesRegion and Total LineTotals for the most current year 2014.

2. In second CTE, used two Window functions to calculate OverallSales for all categories across all regions and PercentSales for each category 

3. In the final query, I used a subquery in the FROM clause where I pivoted the results from the second CTE by transposing the rows and columns i.e., 
   by changing Categories into 4 columns broken down by 10 Sales Region.

*/

WITH SalesData AS ( -- CTE 1
    SELECT 
        C.Name AS ProductCategory,
        T.Name AS SalesRegion,
        SUM(D.LineTotal) AS TotalSales
	FROM
        [Sales].[SalesOrderDetail] D
    LEFT JOIN 
        [Production].[Product] P ON P.ProductID = D.ProductID
    LEFT JOIN 
        [Production].[ProductSubcategory] SC ON SC.ProductSubcategoryID = P.ProductSubcategoryID
    LEFT JOIN 
        [Production].[ProductCategory] C ON C.ProductCategoryID = SC.ProductCategoryID
    LEFT JOIN 
        [Sales].[SalesOrderHeader] H ON D.SalesOrderID = H.SalesOrderID
    LEFT JOIN 
        [Sales].[SalesTerritory] T ON H.TerritoryID = T.[TerritoryID]
    WHERE 
        YEAR(D.[ModifiedDate]) = 2014
    GROUP BY 
        C.Name, T.Name
),
SalesPercent AS ( -- CTE 2
    SELECT 
        ProductCategory,
        SalesRegion,
        TotalSales,
		TotalOverallSales = SUM(TotalSales) OVER(),
        PercentSales = TotalSales * 100.00 / SUM(TotalSales) OVER ()
    FROM 
        SalesData 
)
SELECT -- FINAL QUERY
    SalesRegion, 
    [Accessories], [Bikes], [Clothing], [Components]
FROM ( -- PIVOT SUBQUERY
    SELECT 
        SalesRegion, 
        ProductCategory, 
        PercentSales
    FROM 
        SalesPercent
) X
PIVOT (
    SUM(PercentSales)
    FOR ProductCategory IN ([Accessories], [Bikes], [Clothing], [Components])
) PIV;
