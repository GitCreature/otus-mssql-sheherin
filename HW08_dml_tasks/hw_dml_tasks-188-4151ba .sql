/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO [Sales].[Customers]
           ([CustomerName]
           ,[BillToCustomerID]
           ,[CustomerCategoryID]
           ,[BuyingGroupID]
           ,[PrimaryContactPersonID]
           ,[AlternateContactPersonID]
           ,[DeliveryMethodID]
           ,[DeliveryCityID]
           ,[PostalCityID]
           ,[CreditLimit]
           ,[AccountOpenedDate]
           ,[StandardDiscountPercentage]
           ,[IsStatementSent]
           ,[IsOnCreditHold]
           ,[PaymentDays]
           ,[PhoneNumber]
           ,[FaxNumber]
           ,[DeliveryRun]
           ,[RunPosition]
           ,[WebsiteURL]
           ,[DeliveryAddressLine1]
           ,[DeliveryAddressLine2]
           ,[DeliveryPostalCode]
           ,[PostalAddressLine1]
           ,[PostalAddressLine2]
           ,[PostalPostalCode]
           ,[LastEditedBy])
VALUES
    ('Клиент 1', 1, 3, NULL, 3254, NULL, 3, 12345, 12345, 10000.00, '2024-01-15', 0.000, 0, 0, 30, '+7 (999) 111-11-11', '', NULL, NULL, '', 'Address 1', '', '101000', 'Address 1', '', '101000', 1),
    ('Клиент 2', 1, 4, NULL, 3255, NULL, 4, 12346, 12346, 15000.00, '2024-02-20', 5.000, 1, 0, 45, '+7 (999) 222-22-22', '', 'RUN1', 'A', '', 'Test St 2', 'Bld 2', '102000', 'Test St 2', 'Bld 2', '102000', 1),
    ('Клиент 3', 1, 5, 1, 3257, NULL, 3, 12347, 12347, 20000.00, '2024-03-10', 10.000, 0, 1, 60, '+7 (999) 333-33-33', '', 'RUN2', 'B', '', 'Street 3', '', '103000', 'Street 3', '', '103000', 1),
    ('Клиент 4', 1001, 3, NULL, 3259, NULL, 4, 12348, 12348, 5000.00, '2024-04-05', 2.500, 1, 0, 30, '+7 (999) 444-44-44', '', NULL, NULL, '', 'Addr 4', 'Block 4', '104000', 'Addr 4', 'Block 4', '104000', 1),
    ('Клиент 5', 1, 6, 2, 3260, NULL, 3, 12349, 12349, 30000.00, '2024-05-12', 7.500, 0, 0, 90, '+7 (999) 555-55-55', '', 'RUN3', 'C', '', 'Location 5', '', '105000', 'Location 5', '', '105000', 1);


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE FROM Sales.Customers 
WHERE CustomerName = 'Клиент 5';


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE Sales.Customers 
SET 
    BillToCustomerID = '2'
WHERE CustomerName = 'Клиент 4';

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

DECLARE @SourceData TABLE (
    CustomerID INT,
    CustomerName NVARCHAR(100),
    BillToCustomerID INT,
    CustomerCategoryID INT,
    BuyingGroupID INT,
    PrimaryContactPersonID INT,
    AlternateContactPersonID INT,
    DeliveryMethodID INT,
    DeliveryCityID INT,
    PostalCityID INT,
    CreditLimit DECIMAL(18,2),
    AccountOpenedDate DATE,
    StandardDiscountPercentage DECIMAL(18,3),
    IsStatementSent BIT,
    IsOnCreditHold BIT,
    PaymentDays INT,
    PhoneNumber NVARCHAR(20),
    FaxNumber NVARCHAR(20),
    DeliveryRun NVARCHAR(5),
    RunPosition NVARCHAR(5),
    WebsiteURL NVARCHAR(256),
    DeliveryAddressLine1 NVARCHAR(60),
    DeliveryAddressLine2 NVARCHAR(60),
    DeliveryPostalCode NVARCHAR(10),
    PostalAddressLine1 NVARCHAR(60),
    PostalAddressLine2 NVARCHAR(60),
    PostalPostalCode NVARCHAR(10),
    LastEditedBy INT
);

INSERT INTO @SourceData VALUES
(1001, 'Клиент 1 Обновленный', 1, 4, NULL, 3260, NULL, 4, 12350, 12350, 15000.00, '2024-06-01', 10.000, 1, 0, 45, '+7 (999) 111-99-99', '', 'RUN4', 'D', '', 'New Address 1', '', '101001', 'New Address 1', '', '101001', 1),
(1006, 'Клиент 6 Новый', 1, 3, NULL, 3261, NULL, 3, 12351, 12351, 12000.00, '2024-06-15', 3.000, 0, 0, 30, '+7 (999) 666-66-66', '', NULL, NULL, '', 'Address 6', '', '106000', 'Address 6', '', '106000', 1),
(1002, 'Клиент 2 Обновленный', 1, 5, 2, 3255, 3256, 4, 12352, 12352, 25000.00, '2024-06-10', 8.000, 1, 1, 60, '+7 (999) 222-99-99', '+7 (999) 222-99-98', 'RUN5', 'E', '', 'Updated St 2', 'Bld 3', '102001', 'Updated St 2', 'Bld 3', '102001', 1);

MERGE [Sales].[Customers] AS Target
USING @SourceData AS Source
ON (Target.CustomerID = Source.CustomerID)
WHEN MATCHED THEN
    UPDATE SET
        Target.CustomerName = Source.CustomerName,
        Target.CustomerCategoryID = Source.CustomerCategoryID,
        Target.BillToCustomerID = Source.BillToCustomerID,
        Target.PrimaryContactPersonID = Source.PrimaryContactPersonID,
        Target.DeliveryMethodID = Source.DeliveryMethodID,
        Target.DeliveryCityID = Source.DeliveryCityID,
        Target.PostalCityID = Source.PostalCityID,
        Target.CreditLimit = Source.CreditLimit,
        Target.StandardDiscountPercentage = Source.StandardDiscountPercentage,
        Target.IsStatementSent = Source.IsStatementSent,
        Target.IsOnCreditHold = Source.IsOnCreditHold,
        Target.PaymentDays = Source.PaymentDays,
        Target.PhoneNumber = Source.PhoneNumber,
        Target.FaxNumber = Source.FaxNumber,
        Target.DeliveryRun = Source.DeliveryRun,
        Target.RunPosition = Source.RunPosition,
        Target.WebsiteURL = Source.WebsiteURL,
        Target.DeliveryAddressLine1 = Source.DeliveryAddressLine1,
        Target.DeliveryAddressLine2 = Source.DeliveryAddressLine2,
        Target.DeliveryPostalCode = Source.DeliveryPostalCode,
        Target.PostalAddressLine1 = Source.PostalAddressLine1,
        Target.PostalAddressLine2 = Source.PostalAddressLine2,
        Target.PostalPostalCode = Source.PostalPostalCode,
        Target.LastEditedBy = Source.LastEditedBy
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([CustomerID], [CustomerName], [BillToCustomerID], [CustomerCategoryID], [BuyingGroupID], 
            [PrimaryContactPersonID], [AlternateContactPersonID], [DeliveryMethodID], [DeliveryCityID], 
            [PostalCityID], [CreditLimit], [AccountOpenedDate], [StandardDiscountPercentage], 
            [IsStatementSent], [IsOnCreditHold], [PaymentDays], [PhoneNumber], [FaxNumber], 
            [DeliveryRun], [RunPosition], [WebsiteURL], [DeliveryAddressLine1], [DeliveryAddressLine2], 
            [DeliveryPostalCode], [PostalAddressLine1], [PostalAddressLine2], 
            [PostalPostalCode], [LastEditedBy])
    VALUES (Source.CustomerID, Source.CustomerName, Source.BillToCustomerID, Source.CustomerCategoryID, 
            Source.BuyingGroupID, Source.PrimaryContactPersonID, Source.AlternateContactPersonID, 
            Source.DeliveryMethodID, Source.DeliveryCityID, Source.PostalCityID, Source.CreditLimit, 
            Source.AccountOpenedDate, Source.StandardDiscountPercentage, Source.IsStatementSent, 
            Source.IsOnCreditHold, Source.PaymentDays, Source.PhoneNumber, Source.FaxNumber, 
            Source.DeliveryRun, Source.RunPosition, Source.WebsiteURL, Source.DeliveryAddressLine1, 
            Source.DeliveryAddressLine2, Source.DeliveryPostalCode,  
            Source.PostalAddressLine1, Source.PostalAddressLine2, Source.PostalPostalCode, 
            Source.LastEditedBy);
/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

bcp WideWorldImporters.Sales.Customers out "D:\customers.txt" -c -T -S . -t "|" -r "\n"
*/

DROP TABLE IF EXISTS Sales.Customers_Import;

SELECT TOP 0 * INTO Sales.Customers_Import FROM Sales.Customers;

BULK INSERT Sales.Customers_Import
FROM 'D:\customers.txt'
WITH (
    FIELDTERMINATOR = '|', 
    ROWTERMINATOR = '\n',  
    FIRSTROW = 1,           
    TABLOCK                
);