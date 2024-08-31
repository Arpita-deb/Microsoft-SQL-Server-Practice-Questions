-- Initiating the database

USE AdventureWorks2022;

-- Creating 'Addresses' Look Up Table

CREATE TABLE AdventureWorks2022.dbo.Addresses
(
[BusinessEntityID] INT
,[AddressID] INT 
,[AddressTypeID] INT 
,[AddressType] VARCHAR(50)
,[AddressLine1] VARCHAR(60)
,[AddressLine2] VARCHAR(60)
,[City] VARCHAR(30)
,[PostalCode] VARCHAR(15)
,[StateProvinceID] INT
,[StateProvinceCode] CHAR(3)
,[StateProvince] VARCHAR(50)
,[CountryRegionCode] CHAR(3)
,[CountryRegion] VARCHAR(50)
,[TerritoryID] INT
,[Territory] VARCHAR(50)
,[Group] VARCHAR(50)
)

INSERT INTO AdventureWorks2022.dbo.Addresses
(
[BusinessEntityID]
)
SELECT [BusinessEntityID]
FROM [Person].[Person]


-- updating AddressID and AddressTypeID columns

UPDATE AdventureWorks2022.dbo.Addresses
SET AddressID = A.AddressID, 
	AddressTypeID = A.AddressTypeID
FROM AdventureWorks2022.dbo.Addresses X
JOIN [Person].[BusinessEntityAddress] A ON X.BusinessEntityID = A.BusinessEntityID

-- updating AddressType column

UPDATE AdventureWorks2022.dbo.Addresses
SET AddressType = A.Name
FROM AdventureWorks2022.dbo.Addresses X
JOIN [Person].[AddressType] A ON X.AddressTypeID = A.AddressTypeID


-- updating AddressLine1,AddressLine2, City, PostalCOde, StateProvinceID columns

UPDATE AdventureWorks2022.dbo.Addresses
SET AddressLine1 = A.AddressLine1,
	AddressLine2 = A.AddressLine2,
	City = A.City,
	PostalCode = A.PostalCode,
	StateProvinceID = A.StateProvinceID
FROM AdventureWorks2022.dbo.Addresses X
JOIN [Person].[Address] A ON X.AddressID = A.AddressID


-- updating StateProvinceCode, StateProvince, CountryRegionCode and TerritoryID columns

UPDATE AdventureWorks2022.dbo.Addresses
SET StateProvinceCode = A.StateProvinceCode,
	StateProvince = A.Name,
	CountryRegionCode = A.CountryRegionCode,
	TerritoryID = A.TerritoryID
FROM AdventureWorks2022.dbo.Addresses X
JOIN [Person].[StateProvince] A ON X.StateProvinceID = A.StateProvinceID


-- updating StateProvinceCode, StateProvince, CountryRegionCode and TerritoryID columns
UPDATE AdventureWorks2022.dbo.Addresses
SET CountryRegion = A.Name
FROM AdventureWorks2022.dbo.Addresses X
JOIN [Person].[CountryRegion] A ON X.CountryRegionCode = A.CountryRegionCode

-- updating Territory and Group columns
UPDATE AdventureWorks2022.dbo.Addresses
SET Territory= T.Name,
	[Group] = T.[Group]
FROM AdventureWorks2022.dbo.Addresses X
JOIN [Sales].[SalesTerritory] T ON X.TerritoryID= T.TerritoryID



SELECT * 
FROM [Sales].[Customer] C
JOIN AdventureWorks2022.dbo.Addresses A
ON C.PersonID = A.BusinessEntityID