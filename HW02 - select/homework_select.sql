/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT 
    StockItems.StockItemID,
    StockItems.StockItemName
FROM Warehouse.StockItems AS StockItems
WHERE StockItems.StockItemName LIKE '%urgent%' OR StockItems.StockItemName LIKE 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT 
    Suppliers.SupplierID,
    Suppliers.SupplierName
FROM Purchasing.Suppliers AS Suppliers
LEFT JOIN Purchasing.PurchaseOrders AS PurchaseOrders  
    ON Suppliers.SupplierID = PurchaseOrders.SupplierID
WHERE PurchaseOrders.PurchaseOrderID IS NULL;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT 
    Orders.OrderID,
    FORMAT(Orders.OrderDate, 'dd.MM.yyyy') AS OrderDateFormatted,
    DATENAME(month, Orders.OrderDate) AS MonthName,
    DATEPART(quarter, Orders.OrderDate) AS Quarter,
    CEILING(MONTH(Orders.OrderDate) / 4) AS ThirdOfYear,
    Customers.CustomerName
FROM Sales.Orders as Orders
INNER JOIN Sales.OrderLines as OrderLines 
    ON Orders.OrderID = OrderLines.OrderID
INNER JOIN Sales.Customers as Customers 
    ON Orders.CustomerID = Customers.CustomerID
WHERE Orders.PickingCompletedWhen IS NOT NULL
  AND (OrderLines.UnitPrice > 100 OR OrderLines.Quantity > 20)
GROUP BY Orders.OrderID, Orders.OrderDate, Customers.CustomerName
ORDER BY 
    DATEPART(quarter, Orders.OrderDate),
    CEILING(MONTH(Orders.OrderDate) / 4),
    Orders.OrderDate
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select
    DeliveryMethods.DeliveryMethodName as DeliveryMethodName,
    PurchaseOrders.ExpectedDeliveryDate as ExpectedDeliveryDate,
    Suppliers.SupplierName as SupplierName,
    People.FullName as ContactPerson
FROM Purchasing.PurchaseOrders as PurchaseOrders
INNER JOIN Application.DeliveryMethods as DeliveryMethods
    ON PurchaseOrders.DeliveryMethodID = DeliveryMethods.DeliveryMethodID
INNER JOIN Purchasing.Suppliers as Suppliers
    ON PurchaseOrders.SupplierID = Suppliers.SupplierID
INNER JOIN Application.People as People 
    ON PurchaseOrders.ContactPersonID = People.PersonID
Where
    PurchaseOrders.IsOrderFinalized = 1 
    AND PurchaseOrders.ExpectedDeliveryDate >= '2013-01-01' 
    AND PurchaseOrders.ExpectedDeliveryDate < '2013-02-01'
    AND (DeliveryMethods.DeliveryMethodName = 'Air Freight' or DeliveryMethods.DeliveryMethodName = 'Refrigerated Air Freight')
    
/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10
    Orders.OrderID,
    Customers.CustomerName,
    People.FullName AS SalespersonPerson
FROM Sales.Orders as Orders
INNER JOIN Sales.Customers as Customers 
    ON Orders.CustomerID = Customers.CustomerID
INNER JOIN Application.People as People 
    ON Orders.SalespersonPersonID = People.PersonID
ORDER BY Orders.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT
    Customers.CustomerID,
    Customers.CustomerName,
    Customers.PhoneNumber
FROM Sales.Customers as Customers
INNER JOIN Sales.Orders as Orders 
    ON Customers.CustomerID = Orders.CustomerID
INNER JOIN Sales.OrderLines as OrderLines 
    ON Orders.OrderID = OrderLines.OrderID
INNER JOIN Warehouse.StockItems as StockItems 
    ON OrderLines.StockItemID = StockItems.StockItemID
WHERE StockItems.StockItemName = 'Chocolate frogs 250g';
