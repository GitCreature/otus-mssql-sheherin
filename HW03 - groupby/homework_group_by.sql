/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
    YEAR(Invoices.InvoiceDate) as 'Год продажи',
    MONTH(Invoices.InvoiceDate) as 'Месяц продажи',
    AVG(InvoiceLines.UnitPrice) as 'Средняя цена за месяц',
    SUM(InvoiceLines.UnitPrice * InvoiceLines.Quantity) as 'Общая сумма продаж за месяц'
FROM Sales.Invoices as Invoices
LEFT JOIN Sales.InvoiceLines as InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
GROUP BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate)
ORDER BY YEAR(Invoices.InvoiceDate) , MONTH(Invoices.InvoiceDate);

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
    YEAR(Invoices.InvoiceDate) AS 'Год продажи',
    MONTH(Invoices.InvoiceDate) AS 'Месяц продажи',
    SUM(InvoiceLines.UnitPrice * InvoiceLines.Quantity) AS 'Общая сумма продаж'
FROM Sales.Invoices As Invoices
JOIN Sales.InvoiceLines as InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
GROUP BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate)
HAVING SUM(InvoiceLines.UnitPrice * InvoiceLines.Quantity) > 4600000
ORDER BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate);

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
SELECT 
    YEAR(Invoices.InvoiceDate) AS 'Год продажи',
    MONTH(Invoices.InvoiceDate) AS 'Месяц продажи',
    StockItems.StockItemName AS 'Наименование товара',
    SUM(InvoiceLines.UnitPrice * InvoiceLines.Quantity) AS 'Сумма продаж',
    MIN(Invoices.InvoiceDate) AS 'Дата первой продажи',
    SUM(InvoiceLines.Quantity) AS 'Количество проданного'
FROM Sales.Invoices AS Invoices
LEFT JOIN Sales.InvoiceLines AS InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
LEFT JOIN Warehouse.StockItems AS StockItems ON InvoiceLines.StockItemID = StockItems.StockItemID
GROUP BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate), StockItems.StockItemName
HAVING SUM(InvoiceLines.Quantity) < 50
ORDER BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate);

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
WITH Calendar AS (
    select CAST(yy.value AS INT) as yearD, CAST(mm.value AS INT)  as monthD
    from 
    (select value from string_split('1 2 3 4 5 6 7 8 9 10 11 12', ' ')) mm
    cross join (select value from string_split('2013 2014 2015 2016', ' ')) yy
),
SalesInvByMonth as (SELECT 
    YEAR(Invoices.InvoiceDate) AS yearD,
    MONTH(Invoices.InvoiceDate) AS monthD,
    SUM(InvoiceLines.UnitPrice * InvoiceLines.Quantity) AS sumbymonth
FROM Sales.Invoices As Invoices
JOIN Sales.InvoiceLines as InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
GROUP BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate)
HAVING SUM(InvoiceLines.UnitPrice * InvoiceLines.Quantity) > 4600000

)
SELECT 
    Calendar.yearD AS 'Год продажи',
    Calendar.monthD AS 'Месяц продажи',
    COALESCE(SalesInvByMonth.sumbymonth, 0) AS 'Общая сумма продаж'
FROM Calendar as Calendar
LEFT JOIN SalesInvByMonth AS SalesInvByMonth ON Calendar.yearD = SalesInvByMonth.yearD AND Calendar.monthD = SalesInvByMonth.monthD
ORDER BY Calendar.yearD, Calendar.monthD;

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
WITH Calendar AS (
    select CAST(yy.value AS INT) as yearD, CAST(mm.value AS INT)  as monthD
    from 
    (select value from string_split('1 2 3 4 5 6 7 8 9 10 11 12', ' ')) mm
    cross join (select value from string_split('2013 2014 2015 2016', ' ')) yy
),
SalesInvByMonth as (SELECT 
    YEAR(Invoices.InvoiceDate) AS yearD,
    MONTH(Invoices.InvoiceDate) AS monthD,
    StockItems.StockItemName AS StockItemName,
    SUM(InvoiceLines.UnitPrice * InvoiceLines.Quantity) AS sumSales,
    MIN(Invoices.InvoiceDate) AS datefirstsales,
    SUM(InvoiceLines.Quantity) AS Quantity
FROM Sales.Invoices AS Invoices
LEFT JOIN Sales.InvoiceLines AS InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
LEFT JOIN Warehouse.StockItems AS StockItems ON InvoiceLines.StockItemID = StockItems.StockItemID
GROUP BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate), StockItems.StockItemName
HAVING SUM(InvoiceLines.Quantity) < 50)

SELECT 
    Calendar.yearD AS 'Год продажи',
    Calendar.monthD AS 'Месяц продажи',
    COALESCE(SalesInvByMonth.StockItemName, '0 Sales') AS 'Наименование товара',
    COALESCE(SalesInvByMonth.sumSales, 0) AS 'Сумма продаж',
    SalesInvByMonth.datefirstsales AS 'Дата первой продажи',
    COALESCE(SalesInvByMonth.Quantity, 0) AS 'Количество проданного'
FROM Calendar as Calendar
LEFT JOIN SalesInvByMonth AS SalesInvByMonth ON Calendar.yearD = SalesInvByMonth.yearD AND Calendar.monthD = SalesInvByMonth.monthD
ORDER BY Calendar.yearD, Calendar.monthD;
