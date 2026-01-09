/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

WITH SalesData AS (
    SELECT 
        DATEADD(day, 1, EOMONTH(Invoices.InvoiceDate, -1)) AS InvoiceMonth,
        Customers.CustomerID,
        CL.CustomerLocation,
        COUNT(*) AS PurchaseCount
    FROM Sales.Customers as Customers
    JOIN Sales.Invoices as Invoices ON Customers.CustomerID = Invoices.CustomerID
    CROSS APPLY (
        SELECT 
            TRIM(SUBSTRING(
                Customers.CustomerName, 
                CHARINDEX('(', Customers.CustomerName) + 1, 
                CHARINDEX(')', Customers.CustomerName) - CHARINDEX('(', Customers.CustomerName) - 1
            )) AS CustomerLocation
    ) CL
    WHERE Customers.CustomerID BETWEEN 2 AND 6
    GROUP BY 
        DATEADD(day, 1, EOMONTH(Invoices.InvoiceDate, -1)),
        Customers.CustomerID,
        CL.CustomerLocation
)
SELECT 
    FORMAT(InvoiceMonth, 'dd.MM.yyyy') AS InvoiceMonthStr,
    InvoiceMonth,
    SUM(ISNULL([Gasport, NY], 0)) AS [Gasport, NY],
    SUM(ISNULL([Jessie, ND], 0)) AS [Jessie, ND],
    SUM(ISNULL([Medicine Lodge, KS], 0)) AS [Medicine Lodge, KS],
    SUM(ISNULL([Peeples Valley, AZ], 0)) AS [Peeples Valley, AZ],
    SUM(ISNULL([Sylvanite, MT], 0)) AS [Sylvanite, MT]
FROM SalesData
PIVOT (
    SUM(PurchaseCount)
    FOR CustomerLocation IN (
        [Gasport, NY],
        [Jessie, ND],
        [Medicine Lodge, KS],
        [Peeples Valley, AZ],
        [Sylvanite, MT]
    )
) AS pvt
group by FORMAT(InvoiceMonth, 'dd.MM.yyyy'), InvoiceMonth
ORDER BY InvoiceMonth
;

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/


SELECT 
    CustomerName,
    unpvt.AddressLine
FROM Sales.Customers as Customers
UNPIVOT (
    AddressLine 
    FOR AddressType IN (
        DeliveryAddressLine1,
        DeliveryAddressLine2,
        PostalAddressLine1,
        PostalAddressLine2
    )
) AS unpvt
WHERE CustomerName LIKE '%Tailspin Toys%'
ORDER BY CustomerName, 
    CASE unpvt.AddressType
        WHEN 'DeliveryAddressLine1' THEN 1
        WHEN 'DeliveryAddressLine2' THEN 2
        WHEN 'PostalAddressLine1' THEN 3
        WHEN 'PostalAddressLine2' THEN 4
    END;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT 
    Countries.CountryID,
    Countries.CountryName,
    CA.Code
FROM Application.Countries 
CROSS APPLY (
    VALUES 
        (1, Countries.IsoAlpha3Code),
        (2, CAST(Countries.IsoNumericCode AS NVARCHAR(3)))
) AS CA(SortOrder, Code)
ORDER BY Countries.CountryID, CA.SortOrder;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT 
    Customers.CustomerID,
    Customers.CustomerName,
    CA.StockItemID,
    StockItems.StockItemName,
    CA.UnitPrice,
    CA.InvoiceDate,
    CA.PriceRank
FROM Sales.Customers 
CROSS APPLY (
    SELECT 
        Invoices.CustomerID,
        Invoices.InvoiceDate,
        InvoiceLines.StockItemID,
        InvoiceLines.UnitPrice,
        DENSE_RANK() OVER (
            ORDER BY InvoiceLines.UnitPrice DESC, InvoiceLines.StockItemID DESC
        ) AS PriceRank
    FROM Sales.Invoices 
    INNER JOIN Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
    WHERE Invoices.CustomerID = Customers.CustomerID
) CA
INNER JOIN Warehouse.StockItems ON CA.StockItemID = StockItems.StockItemID
WHERE CA.PriceRank <= 2
ORDER BY Customers.CustomerID, CA.PriceRank;
