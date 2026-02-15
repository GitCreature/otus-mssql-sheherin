-- 
-- БАЗА ДАННЫХ: Аэропорт
-- Назначение: Учет рейсов, пассажиров, билетов и персонала
-- 

-- 1. Создание базы данных
-- -----------------------------------------------------
CREATE DATABASE AirportDB;
GO

USE AirportDB;
GO

-- 
-- 2. Создание таблиц
-- 
-- -----------------------------------------------------
-- Таблица 1: Aircraft (Самолеты)
-- -----------------------------------------------------
CREATE TABLE Aircraft (
    AircraftID INT PRIMARY KEY IDENTITY(1,1),        -- Автоинкрементный первичный ключ
    Model NVARCHAR(100) NOT NULL,                     -- Модель самолета (обязательно)
    ManufactureYear INT,                               -- Год выпуска
    Capacity INT NOT NULL,                             -- Вместимость (обязательно)
    
    -- Ограничение: год выпуска не может быть в будущем и не раньше 1900
    CONSTRAINT CHK_Aircraft_Year CHECK (ManufactureYear BETWEEN 1900 AND YEAR(GETDATE()))
);

-- -----------------------------------------------------
-- Таблица 2: Flights (Рейсы)
-- -----------------------------------------------------
CREATE TABLE Flights (
    FlightID INT PRIMARY KEY IDENTITY(1000,1),        -- Первичный ключ с начальным значением 1000
    FlightNumber NVARCHAR(20) NOT NULL,                -- Номер рейса (обязательно)
    AircraftID INT NOT NULL,                            -- Внешний ключ к самолету
    DepartureCity NVARCHAR(100) NOT NULL,               -- Город вылета
    ArrivalCity NVARCHAR(100) NOT NULL,                 -- Город назначения
    DepartureTime DATETIME NOT NULL,                    -- Дата и время вылета
    ArrivalTime DATETIME NOT NULL,                      -- Дата и время прилета
    
    -- Внешний ключ
    CONSTRAINT FK_Flights_Aircraft FOREIGN KEY (AircraftID) REFERENCES Aircraft(AircraftID),
    
    -- Ограничение: время прилета должно быть позже времени вылета
    CONSTRAINT CHK_Flights_Times CHECK (ArrivalTime > DepartureTime),
    
    -- Ограничение: города вылета и назначения не должны совпадать
    CONSTRAINT CHK_Flights_Cities CHECK (DepartureCity <> ArrivalCity)
);

-- -----------------------------------------------------
-- Таблица 3: Passengers (Пассажиры)
-- -----------------------------------------------------
CREATE TABLE Passengers (
    PassengerID INT PRIMARY KEY IDENTITY(1,1),
    FullName NVARCHAR(200) NOT NULL,
    PassportNumber NVARCHAR(50) NOT NULL UNIQUE,      -- Уникальный номер паспорта
    Phone NVARCHAR(30),
    Email NVARCHAR(100),
    
    -- Ограничение: email должен содержать @ (базовая проверка)
    CONSTRAINT CHK_Passengers_Email CHECK (Email IS NULL OR Email LIKE '%@%.%'),
    
    -- Ограничение: телефон не может быть пустым, если email не указан
    -- (хотя бы один способ связи)
    CONSTRAINT CHK_Passengers_Contact CHECK (
        Phone IS NOT NULL OR Email IS NOT NULL
    )
);

-- -----------------------------------------------------
-- Таблица 4: Employees (Сотрудники)
-- -----------------------------------------------------
CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(100,1),        -- Табельные номера с 100
    FullName NVARCHAR(200) NOT NULL,
    Position NVARCHAR(100) NOT NULL,
    HireDate DATE NOT NULL,
    
    -- Ограничение: дата приема не может быть в будущем
    CONSTRAINT CHK_Employees_HireDate CHECK (HireDate <= CAST(GETDATE() AS DATE))
);

-- -----------------------------------------------------
-- Таблица 5: Tickets (Билеты)
-- -----------------------------------------------------
CREATE TABLE Tickets (
    TicketID INT PRIMARY KEY IDENTITY(10000,1),       -- Номера билетов с 10000
    PassengerID INT NOT NULL,
    FlightID INT NOT NULL,
    SeatNumber NVARCHAR(10),
    Price DECIMAL(10,2) NOT NULL,
    SaleDate DATETIME NOT NULL DEFAULT GETDATE(),      -- По умолчанию текущая дата
    
    -- Внешние ключи
    CONSTRAINT FK_Tickets_Passengers FOREIGN KEY (PassengerID) REFERENCES Passengers(PassengerID),
    CONSTRAINT FK_Tickets_Flights FOREIGN KEY (FlightID) REFERENCES Flights(FlightID),
    
    -- Ограничение: цена должна быть положительной
    CONSTRAINT CHK_Tickets_Price CHECK (Price > 0),
    
    -- Ограничение: место должно быть указано (для простоты - не пустое)
    CONSTRAINT CHK_Tickets_Seat CHECK (SeatNumber IS NOT NULL AND SeatNumber <> '')
);

-- -----------------------------------------------------
-- Таблица 6: CrewAssignments (Назначение экипажа)
-- -----------------------------------------------------
CREATE TABLE CrewAssignments (
    AssignmentID INT PRIMARY KEY IDENTITY(1,1),
    EmployeeID INT NOT NULL,
    AircraftID INT NOT NULL,
    StartDate DATE NOT NULL,
    EndDate DATE NULL,
    RoleOnBoard NVARCHAR(100),
    
    -- Внешние ключи
    CONSTRAINT FK_CrewAssignments_Employees FOREIGN KEY (EmployeeID) REFERENCES Employees(EmployeeID),
    CONSTRAINT FK_CrewAssignments_Aircraft FOREIGN KEY (AircraftID) REFERENCES Aircraft(AircraftID),
    
    -- Уникальность: один сотрудник не может иметь два назначения с одной датой начала
    CONSTRAINT UQ_CrewAssignments_Employee_Start UNIQUE (EmployeeID, StartDate),
    
    -- Ограничение: дата окончания, если указана, должна быть >= даты начала
    CONSTRAINT CHK_CrewAssignments_Dates CHECK (EndDate IS NULL OR EndDate >= StartDate),
    
    -- Роль на борту не может быть пустой
    CONSTRAINT CHK_CrewAssignments_Role CHECK (RoleOnBoard IS NOT NULL AND RoleOnBoard <> '')
);

--
-- 3. Создание индексов
--

-- Индекс 1: Для ускорения поиска рейсов по направлению и дате
CREATE INDEX IX_Flights_Route ON Flights(DepartureCity, ArrivalCity, DepartureTime);

-- Индекс 2: Для ускорения поиска билетов по пассажиру
CREATE INDEX IX_Tickets_Passenger ON Tickets(PassengerID);

-- Индекс 3: Для ускорения поиска текущих назначений экипажа
CREATE INDEX IX_CrewAssignments_Current ON CrewAssignments(AircraftID, EndDate) WHERE EndDate IS NULL;

-- 
-- 4. Дополнительные ограничения (ALTER TABLE)
--

-- Добавим ограничение на уникальность номера рейса + времени
-- (один и тот же рейс не может вылетать дважды в одно время)
ALTER TABLE Flights
ADD CONSTRAINT UQ_Flights_Number_Time UNIQUE (FlightNumber, DepartureTime);

-- Добавим ограничение на уникальность места в рейсе
-- (на одно место в рейсе не может быть два билета)
ALTER TABLE Tickets
ADD CONSTRAINT UQ_Tickets_Flight_Seat UNIQUE (FlightID, SeatNumber);

-- 
-- 5. Проверка создания (информационные запросы)
-- 

-- Показать все созданные таблицы
SELECT 
    TABLE_NAME,
    TABLE_TYPE
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE';

-- Показать все ограничения
SELECT 
    tc.TABLE_NAME,
    tc.CONSTRAINT_NAME,
    tc.CONSTRAINT_TYPE
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE;