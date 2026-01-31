/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

DECLARE @xmlData XML;

SELECT @xmlData = CAST(BulkColumn AS XML)
FROM OPENROWSET(BULK 'C:\Users\pasha\Downloads\HW09_xml_json_tasks\StockItems.xml', SINGLE_BLOB) AS x;

SELECT @xmlData;

--1
DECLARE @docHandle INT;

EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlData;

DECLARE @StockItemsData TABLE (
    StockItemName NVARCHAR(200),
    SupplierID INT,
    UnitPackageID INT,
    OuterPackageID INT,
    QuantityPerOuter INT,
    TypicalWeightPerUnit DECIMAL(18,3),
    LeadTimeDays INT,
    IsChillerStock BIT,
    TaxRate DECIMAL(18,3),
    UnitPrice DECIMAL(18,2)
);

INSERT INTO @StockItemsData
SELECT 
    [Name] AS StockItemName,
    SupplierID,
    UnitPackageID,
    OuterPackageID,
    QuantityPerOuter,
    TypicalWeightPerUnit,
    LeadTimeDays,
    IsChillerStock,
    TaxRate,
    UnitPrice
FROM OPENXML(@docHandle, '/StockItems/Item', 2)
WITH (
    [Name] NVARCHAR(200) '@Name',
    SupplierID INT 'SupplierID',
    UnitPackageID INT 'Package/UnitPackageID',
    OuterPackageID INT 'Package/OuterPackageID',
    QuantityPerOuter INT 'Package/QuantityPerOuter',
    TypicalWeightPerUnit DECIMAL(18,3) 'Package/TypicalWeightPerUnit',
    LeadTimeDays INT 'LeadTimeDays',
    IsChillerStock BIT 'IsChillerStock',
    TaxRate DECIMAL(18,3) 'TaxRate',
    UnitPrice DECIMAL(18,2) 'UnitPrice'
);

SELECT * FROM @StockItemsData

EXEC sp_xml_removedocument @docHandle;

--2
GO
DECLARE @xmlData XML;

SELECT @xmlData = CAST(BulkColumn AS XML)
FROM OPENROWSET(BULK 'C:\Users\pasha\Downloads\HW09_xml_json_tasks\StockItems.xml', SINGLE_BLOB) AS x;

SELECT @xmlData;

DECLARE @StockItemsDataXQuery TABLE (
    StockItemName NVARCHAR(200),
    SupplierID INT,
    UnitPackageID INT,
    OuterPackageID INT,
    QuantityPerOuter INT,
    TypicalWeightPerUnit DECIMAL(18,3),
    LeadTimeDays INT,
    IsChillerStock BIT,
    TaxRate DECIMAL(18,3),
    UnitPrice DECIMAL(18,2)
);

INSERT INTO @StockItemsDataXQuery
SELECT 
    Item.value('(@Name)[1]', 'NVARCHAR(200)') AS StockItemName,
    Item.value('(SupplierID)[1]', 'INT') AS SupplierID,
    Item.value('(Package/UnitPackageID)[1]', 'INT') AS UnitPackageID,
    Item.value('(Package/OuterPackageID)[1]', 'INT') AS OuterPackageID,
    Item.value('(Package/QuantityPerOuter)[1]', 'INT') AS QuantityPerOuter,
    Item.value('(Package/TypicalWeightPerUnit)[1]', 'DECIMAL(18,3)') AS TypicalWeightPerUnit,
    Item.value('(LeadTimeDays)[1]', 'INT') AS LeadTimeDays,
    Item.value('(IsChillerStock)[1]', 'BIT') AS IsChillerStock,
    Item.value('(TaxRate)[1]', 'DECIMAL(18,3)') AS TaxRate,
    Item.value('(UnitPrice)[1]', 'DECIMAL(18,2)') AS UnitPrice
FROM @xmlData.nodes('/StockItems/Item') AS T(Item);

SELECT * FROM @StockItemsDataXQuery


MERGE Warehouse.StockItems AS Target
USING @StockItemsDataXQuery AS Source
ON (Target.StockItemName = Source.StockItemName)
WHEN MATCHED THEN
    UPDATE SET
        Target.SupplierID = Source.SupplierID,
        Target.UnitPackageID = Source.UnitPackageID,
        Target.OuterPackageID = Source.OuterPackageID,
        Target.QuantityPerOuter = Source.QuantityPerOuter,
        Target.TypicalWeightPerUnit = Source.TypicalWeightPerUnit,
        Target.LeadTimeDays = Source.LeadTimeDays,
        Target.IsChillerStock = Source.IsChillerStock,
        Target.TaxRate = Source.TaxRate,
        Target.UnitPrice = Source.UnitPrice,
        Target.LastEditedBy = 1
WHEN NOT MATCHED BY TARGET THEN
    INSERT (StockItemName, SupplierID, UnitPackageID, OuterPackageID, 
            QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, 
            IsChillerStock, TaxRate, UnitPrice, LastEditedBy)
    VALUES (Source.StockItemName, Source.SupplierID, Source.UnitPackageID, 
            Source.OuterPackageID, Source.QuantityPerOuter, 
            Source.TypicalWeightPerUnit, Source.LeadTimeDays, 
            Source.IsChillerStock, Source.TaxRate, Source.UnitPrice, 1);
/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

CREATE TABLE dbo.StockItemsForExport (
    XmlData XML
);

DECLARE @xmlOutput XML;

SET @xmlOutput = (
    SELECT 
        StockItemName AS [@Name],
        SupplierID AS [SupplierID],
        (
            SELECT 
                UnitPackageID AS [UnitPackageID],
                OuterPackageID AS [OuterPackageID],
                QuantityPerOuter AS [QuantityPerOuter],
                TypicalWeightPerUnit AS [TypicalWeightPerUnit]
            FOR XML PATH('Package'), TYPE
        ),
        LeadTimeDays AS [LeadTimeDays],
        IsChillerStock AS [IsChillerStock],
        TaxRate AS [TaxRate],
        UnitPrice AS [UnitPrice]
    FROM Warehouse.StockItems
    FOR XML PATH('Item'), ROOT('StockItems'), TYPE );

SELECT @xmlOutput;

INSERT INTO dbo.StockItemsForExport (XmlData)
VALUES (@xmlOutput);

SELECT XmlData FROM dbo.StockItemsForExport;

bcp "SELECT XmlData FROM WideWorldImporters.dbo.StockItemsForExport" queryout "C:\Users\pasha\Downloads\HW09_xml_json_tasks\export.xml" -T -S . -w

DROP TABLE dbo.StockItemsForExport;


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT 
    StockItems.StockItemID,
    StockItems.StockItemName,
    jsonT.CountryOfManufacture,
    jsonT.FirstTag
FROM Warehouse.StockItems as StockItems
CROSS APPLY (
    SELECT 
        JSON_VALUE(StockItems.CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture,
        JSON_VALUE(StockItems.CustomFields, '$.Tags[0]') AS FirstTag
) jsonT
WHERE StockItems.CustomFields IS NOT NULL
    AND ISJSON(StockItems.CustomFields) > 0
ORDER BY StockItems.StockItemID;


/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/


SELECT 
    StockItems.StockItemID,
    StockItems.StockItemName
FROM Warehouse.StockItems as StockItems
WHERE EXISTS (
    SELECT 1
    FROM OPENJSON(StockItems.CustomFields, '$.Tags')
    WHERE [value] = 'Vintage'
)
ORDER BY StockItems.StockItemID;
