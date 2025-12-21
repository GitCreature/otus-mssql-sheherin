/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--1
SELECT 
    PersonID,
    FullName
FROM Application.People
WHERE IsSalesPerson = 1
    AND PersonID NOT IN (
        SELECT DISTINCT SalespersonPersonID
        FROM Sales.Invoices
        WHERE InvoiceDate = '2015-07-04'
    )
ORDER BY PersonID;

--2
WITH SalesOnDate AS (
    SELECT DISTINCT SalespersonPersonID
    FROM Sales.Invoices
    WHERE InvoiceDate = '2015-07-04'
)
SELECT 
    People.PersonID,
    People.FullName
FROM Application.People as People
LEFT JOIN SalesOnDate as SalesOnDate ON People.PersonID = SalesOnDate.SalespersonPersonID
WHERE People.IsSalesPerson = 1
    AND SalesOnDate.SalespersonPersonID IS NULL
ORDER BY People.PersonID;

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
go

--1
SELECT 
    StockItemID,
    StockItemName,
    UnitPrice
FROM Warehouse.StockItems
WHERE UnitPrice = (
    SELECT MIN(UnitPrice)
    FROM Warehouse.StockItems
);

--2
SELECT 
    StockItemID,
    StockItemName,
    UnitPrice
FROM Warehouse.StockItems
WHERE UnitPrice = (
    SELECT TOP 1 UnitPrice
    FROM Warehouse.StockItems 
    ORDER BY UnitPrice ASC
);

--3
WITH MinPrice AS (
    SELECT MIN(UnitPrice) AS MinPriceValue
    FROM Warehouse.StockItems
)
SELECT 
    StockItems.StockItemID,
    StockItems.StockItemName,
    StockItems.UnitPrice
FROM Warehouse.StockItems StockItems
CROSS JOIN MinPrice MinPrice
WHERE StockItems.UnitPrice = MinPrice.MinPriceValue;

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--1
SELECT DISTINCT Customers.CustomerID, Customers.CustomerName
FROM Sales.Customers as Customers
WHERE Customers.CustomerID IN (
    SELECT TOP 5 WITH TIES CustomerID 
    FROM Sales.CustomerTransactions
    ORDER BY TransactionAmount DESC
);

--2
WITH DistinctTopCustomers AS (
    SELECT DISTINCT TOP 5 WITH TIES
        CustomerID, TransactionAmount
    FROM Sales.CustomerTransactions
    ORDER BY TransactionAmount DESC
)
SELECT 
    Customers.CustomerID,
    Customers.CustomerName
FROM Sales.Customers Customers
WHERE Customers.CustomerID IN (SELECT CustomerID FROM DistinctTopCustomers)
ORDER BY Customers.CustomerID;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

--1
    WITH Top3MostExpensiveItems AS (
        SELECT TOP 3 WITH TIES
            StockItemID,
            StockItemName,
            UnitPrice
        FROM Warehouse.StockItems
        ORDER BY UnitPrice DESC
    ),
    CustomerAndPackedPersonTopItems AS (
        SELECT DISTINCT
            Invoices.CustomerID,
            Invoices.PackedByPersonID
        FROM Sales.Invoices as Invoices
        INNER JOIN Sales.InvoiceLines as InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
        WHERE InvoiceLines.StockItemID IN (SELECT StockItemID FROM Top3MostExpensiveItems)
    ),
    DeliveryCity AS (
        SELECT DISTINCT
            Cities.CityID,
            Cities.CityName,
            CustomerAndPackedPerson.PackedByPersonID
        FROM CustomerAndPackedPersonTopItems as CustomerAndPackedPerson
        INNER JOIN Sales.Customers as Customers ON CustomerAndPackedPerson.CustomerID = Customers.CustomerID
        INNER JOIN Application.Cities as Cities ON Customers.DeliveryCityID = Cities.CityID
    )
    SELECT 
        DeliveryCity.CityID,
        DeliveryCity.CityName,
        People.FullName
    FROM DeliveryCity as DeliveryCity
    INNER JOIN Application.People as People ON DeliveryCity.PackedByPersonID = People.PersonID
    ORDER BY DeliveryCity.CityName;

--2
SELECT DISTINCT
    Cities.CityID,
    Cities.CityName,
    People.FullName
FROM Sales.Invoices as Invoices
INNER JOIN Sales.InvoiceLines as InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
INNER JOIN Sales.Customers as Customers ON Invoices.CustomerID = Customers.CustomerID
INNER JOIN Application.Cities as Cities ON Customers.DeliveryCityID = Cities.CityID
INNER JOIN Application.People as People ON Invoices.PackedByPersonID = People.PersonID
WHERE InvoiceLines.StockItemID IN (
    SELECT TOP 3 WITH TIES StockItemID 
    FROM Warehouse.StockItems
    ORDER BY UnitPrice DESC
)
ORDER BY Cities.CityName;

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

-- --
/*
Запрос выбирает счета-фактуры с суммой > 27 000 и показывает:
ID счета, дату счета, Имя продавца (через подзапрос), Общую сумму счета (подзапрос), Сумму отобранных товаров в связанном заказе

Основная проблема, что подзапросы вывода выполняются для кажджой строки результата
*/

WITH InvoiceTotals AS (
    -- 1. Считаем суммы по счетам один раз
    SELECT 
        InvoiceId, 
        SUM(Quantity * UnitPrice) AS TotalSumm
    FROM Sales.InvoiceLines
    GROUP BY InvoiceId
    HAVING SUM(Quantity * UnitPrice) > 27000
),
OrderPickedTotals AS (
    -- 2. Считаем суммы отобранных товаров по заказам
    SELECT 
        Orders.OrderId,
        SUM(OrderLines.PickedQuantity * OrderLines.UnitPrice) AS PickedTotal
    FROM Sales.Orders as Orders
    INNER JOIN Sales.OrderLines as OrderLines ON Orders.OrderId = OrderLines.OrderId
    WHERE Orders.PickingCompletedWhen IS NOT NULL
    GROUP BY Orders.OrderId
)
-- 3. Основной запрос с JOIN вместо подзапросов
SELECT 
    Invoices.InvoiceID, 
    Invoices.InvoiceDate,
    People.FullName AS SalesPersonName,
    InvoiceTotals.TotalSumm AS TotalSummByInvoice,
    opt.PickedTotal AS TotalSummForPickedItems
FROM Sales.Invoices as Invoices
-- Главный JOIN - только счета с суммой > 27000
INNER JOIN InvoiceTotals as InvoiceTotals ON Invoices.InvoiceID = InvoiceTotals.InvoiceID
-- LEFT JOIN к продавцу (может быть NULL)
LEFT JOIN Application.People as People ON Invoices.SalespersonPersonID = People.PersonID
-- LEFT JOIN к сумме отобранных товаров (может не быть picked заказа)
LEFT JOIN OrderPickedTotals as opt ON Invoices.OrderID = opt.OrderId
ORDER BY InvoiceTotals.TotalSumm DESC;
