/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/
SET STATISTICS TIME ON
SET STATISTICS IO ON
GO

WITH SalesPerMonth AS (
    SELECT 
        YEAR(Invoices.InvoiceDate) AS Год,
        MONTH(Invoices.InvoiceDate) AS Месяц,
        SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) AS СуммаЗаМесяц
    FROM Sales.Invoices 
    INNER JOIN Sales.InvoiceLines  ON Invoices.InvoiceID = InvoiceLines.InvoiceID
    WHERE Invoices.InvoiceDate >= '2015-01-01'
    GROUP BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate)
)
SELECT 
    Invoices.InvoiceID AS id_продажи,
    Customers.CustomerName AS название_клиента,
    Invoices.InvoiceDate AS дата_продажи,
    (SELECT SUM(Quantity * UnitPrice) 
     FROM Sales.InvoiceLines 
     WHERE InvoiceLines.InvoiceID = Invoices.InvoiceID) AS сумма_продажи,
    (SELECT SUM(СуммаЗаМесяц)
     FROM SalesPerMonth
     WHERE SalesPerMonth.Год < YEAR(Invoices.InvoiceDate) 
        OR (SalesPerMonth.Год = YEAR(Invoices.InvoiceDate) AND SalesPerMonth.Месяц <= MONTH(Invoices.InvoiceDate))
    ) AS сумма_нарастающим_итогом
FROM Sales.Invoices 
INNER JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
WHERE Invoices.InvoiceDate >= '2015-01-01'
ORDER BY Invoices.InvoiceDate, Invoices.InvoiceID;
GO
/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

--напишите здесь свое решение

SELECT 
    Invoices.InvoiceID AS id_продажи,
    Customers.CustomerName AS название_клиента,
    Invoices.InvoiceDate AS дата_продажи,
    SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) AS сумма_продажи,
    SUM(SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice)) OVER (
        ORDER BY YEAR(Invoices.InvoiceDate), MONTH(Invoices.InvoiceDate)
    ) AS сумма_нарастающим_итогом
FROM Sales.Invoices 
INNER JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
JOIN Sales.InvoiceLines ON InvoiceLines.InvoiceID = Invoices.InvoiceID
WHERE Invoices.InvoiceDate >= '2015-01-01'
GROUP BY Invoices.InvoiceID, Customers.CustomerName, Invoices.InvoiceDate
ORDER BY Invoices.InvoiceDate, Invoices.InvoiceID;
GO

SET STATISTICS TIME OFF
SET STATISTICS IO OFF
GO

--(затронуто записей: 31440)
--Таблица "InvoiceLines". Сканирований 888, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 502, физических операций чтения LOB 3, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 778, операций чтения LOB страничного сервера, выполненных с упреждением 0.
--Таблица "InvoiceLines". Считано сегментов 444, пропущено 0.
--Таблица "Worktable". Сканирований 443, логических операций чтения 198223, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
--Таблица "Workfile". Сканирований 1329, логических операций чтения 155936, физических операций чтения 15505, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 140431, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
--Таблица "Invoices". Сканирований 2, логических операций чтения 22800, физических операций чтения 3, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 11388, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
--Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
--Таблица "Customers". Сканирований 1, логических операций чтения 40, физических операций чтения 1, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 31, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

-- Время работы SQL Server:
--   Время ЦП = 152344 мс, затраченное время = 325623 мс.
--Время синтаксического анализа и компиляции SQL Server: 
-- время ЦП = 62 мс, истекшее время = 84 мс.

--(затронуто записей: 31440)
--Таблица "InvoiceLines". Сканирований 2, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 161, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
--Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
--Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
--Таблица "Invoices". Сканирований 1, логических операций чтения 11400, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
--Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
--Таблица "Customers". Сканирований 1, логических операций чтения 40, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

-- Время работы SQL Server:
--   Время ЦП = 204 мс, затраченное время = 709 мс.
--Время синтаксического анализа и компиляции SQL Server: 
-- время ЦП = 0 мс, истекшее время = 0 мс.
--Второй запрос значительно быстрее

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

WITH ItemRankTB AS (
    SELECT 
        InvoiceLines.StockItemID,
        MONTH(Invoices.InvoiceDate) AS InvoiceMonth,
        SUM(InvoiceLines.Quantity) AS TotalQuantity,
        DENSE_RANK() OVER (PARTITION BY MONTH(Invoices.InvoiceDate) ORDER BY SUM(InvoiceLines.Quantity) DESC) AS rank
    FROM Sales.InvoiceLines
    JOIN Sales.Invoices ON InvoiceLines.InvoiceID = Invoices.InvoiceID
    WHERE Invoices.InvoiceDate >= '2016-01-01' AND Invoices.InvoiceDate < '2017-01-01'
    GROUP BY InvoiceLines.StockItemID, MONTH(Invoices.InvoiceDate)
)
SELECT 
    ItemRankTB.InvoiceMonth,
    ItemRankTB.rank,
    ItemRankTB.StockItemID,
    StockItems.StockItemName
FROM ItemRankTB
JOIN Warehouse.StockItems ON ItemRankTB.StockItemID = StockItems.StockItemID
WHERE ItemRankTB.rank < 3
ORDER BY ItemRankTB.InvoiceMonth, ItemRankTB.rank;

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT 
    StockItems.StockItemID,
    StockItems.StockItemName,
    StockItems.Brand,
    StockItems.UnitPrice,
    StockItems.TypicalWeightPerUnit,
    ROW_NUMBER() OVER (PARTITION BY LEFT(StockItems.StockItemName, 1) ORDER BY StockItems.StockItemName) AS RowNumberPerFirstLetter, --Нумерация записей по первой букве
    COUNT(*) OVER () AS TotalItems,     --Общее количество всех товаров
    COUNT(*) OVER (PARTITION BY LEFT(StockItems.StockItemName, 1)) AS ItemsPerFirstLetter,     --Количество товаров по первой букве
    LEAD(StockItems.StockItemID) OVER (ORDER BY StockItems.StockItemName) AS NextStockItemID,     --ID следующего товара 
    LAG(StockItems.StockItemID) OVER (ORDER BY StockItems.StockItemName) AS PreviousStockItemID,   -- ID предыдущего товара 
    COALESCE(LAG(StockItems.StockItemName, 2) OVER (ORDER BY StockItems.StockItemName), 'No items') AS ItemNameTwoRowsAgo,    --названия товара 2 строки назад
    NTILE(30) OVER (ORDER BY StockItems.TypicalWeightPerUnit) AS WeightGroupNumber     --группы по весу товара    
FROM Warehouse.StockItems 
ORDER BY StockItems.StockItemName;

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

--напишите здесь свое решение

WITH LastSales AS (
    SELECT 
        Invoices.SalespersonPersonID,
        Invoices.CustomerID,
        Invoices.InvoiceDate,
        SUM(InvoiceLines.Quantity * InvoiceLines.UnitPrice) AS TransactionAmount,
        ROW_NUMBER() OVER (PARTITION BY Invoices.SalespersonPersonID ORDER BY Invoices.InvoiceDate desc, Invoices.InvoiceID desc) As LastSaleR
    FROM Sales.Invoices
    INNER JOIN Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
    GROUP BY Invoices.SalespersonPersonID, Invoices.CustomerID, Invoices.InvoiceDate, Invoices.InvoiceID
)
SELECT 
    People.PersonID AS EmployeeID,
    People.FullName AS EmployeeName,
    Customers.CustomerID,
    Customers.CustomerName,
    LastSales.InvoiceDate AS SaleDate,
    LastSales.TransactionAmount
FROM LastSales
INNER JOIN Application.People ON LastSales.SalespersonPersonID = People.PersonID
INNER JOIN Sales.Customers ON LastSales.CustomerID = Customers.CustomerID
WHERE LastSales.LastSaleR = 1
ORDER BY People.PersonID;


/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

WITH CustomerItemPurchases AS (
    SELECT 
        Sales.Invoices.CustomerID,
        Sales.Invoices.InvoiceDate,
        Sales.InvoiceLines.StockItemID,
        Sales.InvoiceLines.UnitPrice,
        DENSE_RANK() OVER (PARTITION BY Sales.Invoices.CustomerID ORDER BY Sales.InvoiceLines.UnitPrice desc, Sales.InvoiceLines.StockItemID desc) AS PriceRank
    FROM Sales.Invoices 
    INNER JOIN Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID
)
SELECT 
    CustomerItemPurchases.CustomerID,
    Sales.Customers.CustomerName,
    CustomerItemPurchases.StockItemID,
    StockItems.StockItemName,
    CustomerItemPurchases.UnitPrice,
    CustomerItemPurchases.InvoiceDate
FROM CustomerItemPurchases
INNER JOIN Sales.Customers ON CustomerItemPurchases.CustomerID = Sales.Customers.CustomerID
INNER JOIN Warehouse.StockItems ON CustomerItemPurchases.StockItemID = StockItems.StockItemID
WHERE CustomerItemPurchases.PriceRank <= 2
ORDER BY CustomerItemPurchases.CustomerID, CustomerItemPurchases.PriceRank;

--Не совсем понятное условие, 
--я исходил из условия что нужно вывести именно 2 раличных товара, даже если большее количество товаров имеет одну из максимальных цен,
--но при этом вывести все покупки данных товаров