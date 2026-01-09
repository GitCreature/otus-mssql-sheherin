/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/
DECLARE @ClientColumns NVARCHAR(MAX) = ''
DECLARE @ClientColumnsNull NVARCHAR(MAX) = ''
DECLARE @SQL NVARCHAR(MAX) = ''

SELECT @ClientColumns = 
    STRING_AGG(CAST(QUOTENAME(CustomerName) AS NVARCHAR(MAX)), ',') 
    WITHIN GROUP (ORDER BY CustomerName)
FROM Sales.Customers

-- Формируем список столбцов с ISNULL для замены NULL на 0
SELECT @ClientColumnsNull = 
    STRING_AGG(CAST('ISNULL(' + QUOTENAME(CustomerName) + ', 0) AS ' + QUOTENAME(CustomerName) AS NVARCHAR(MAX)), ',') 
    WITHIN GROUP (ORDER BY CustomerName)
FROM Sales.Customers

SET @SQL = 'WITH SalesData AS (
    SELECT 
        DATEADD(day, 1, EOMONTH(Invoices.InvoiceDate, -1)) AS InvoiceMonth,
        Customers.CustomerName,
        COUNT(*) AS PurchaseCount
    FROM Sales.Customers as Customers
    JOIN Sales.Invoices as Invoices ON Customers.CustomerID = Invoices.CustomerID   
    GROUP BY 
        DATEADD(day, 1, EOMONTH(Invoices.InvoiceDate, -1)),
        Customers.CustomerName
)
SELECT 
    FORMAT(InvoiceMonth, ''dd.MM.yyyy'') AS InvoiceMonthStr,
    InvoiceMonth,
    ' + @ClientColumnsNull + '
FROM SalesData
PIVOT (
    SUM(PurchaseCount)
    FOR CustomerName IN (' + @ClientColumns + ')
) AS pvt
ORDER BY InvoiceMonth'

print @SQL 

EXEC sp_executesql @SQL


