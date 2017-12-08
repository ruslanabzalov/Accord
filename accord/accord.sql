USE master
GO

DROP DATABASE accord
GO

CREATE DATABASE accord
GO

USE accord
GO

-- Таблица "Покупатели"
CREATE TABLE Customer
(
	CustomerID int NOT NULL PRIMARY KEY IDENTITY(1,1),
	CustomerType varchar(20) NOT NULL,
	CHECK(CustomerType IN ('Частное лицо','Юридическое лицо'))
)
GO

-- Таблица "Частные лица"
CREATE TABLE Person
(
	CustomerID int NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES Customer(CustomerID) ON DELETE CASCADE,
	LastName varchar(20) NOT NULL,
	FirstName varchar(20) NOT NULL,
	MiddleName varchar(20) NULL DEFAULT 'Не указано',
	BirthDate date NOT NULL,
	PassportSeries int NOT NULL,
	PassportNumber int NOT NULL,
	HomeAddress varchar(60) NOT NULL,
	PhoneNumber varchar(20) NOT NULL,
	ChangedAt datetime NULL,
	CHECK(PassportSeries > 0 AND PassportNumber > 0),
	CHECK(phoneNumber LIKE '+7([0-9][0-9][0-9])[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
	CONSTRAINT UQ_Person UNIQUE(PassportSeries, PassportNumber)
)
GO

-- Таблица "Юридические лица"
CREATE TABLE Company
(
	CustomerID int NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES Customer(CustomerID) ON DELETE CASCADE,
	CompanyName varchar(40) NOT NULL,
	CompanyAddress varchar(40) NOT NULL,
	CompanyPhoneNumber varchar(20) NOT NULL,
	LicenseNumber int NOT NULL,
	BankDetails varchar(40) NOT NULL,
	CateGOry varchar(40) NOT NULL,
	ChangedAt datetime NULL,
	CHECK(CompanyPhoneNumber LIKE '+7([0-9][0-9][0-9])[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
	CHECK(LicenseNumber > 0),
	CONSTRAINT UQ_Company UNIQUE(CompanyName, LicenseNumber)
)
GO

-- Таблица "Группы покупателей"
CREATE TABLE CustomersGroup
(
	GroupID int NOT NULL PRIMARY KEY IDENTITY(1,1),
	GroupName varchar(20) NOT NULL UNIQUE
)
GO

-- Таблица "Покупатели в группах покупателей"
CREATE TABLE CustomerInCustomersGroup
(
	CustomerID int NOT NULL FOREIGN KEY REFERENCES Customer(CustomerID) ON DELETE CASCADE,
	GroupID int NOT NULL FOREIGN KEY REFERENCES CustomersGroup(GroupID) ON DELETE CASCADE,
	CONSTRAINT PK_CustomerInCustomersGroup PRIMARY KEY(CustomerID, GroupID)
)
GO

-- Таблица "Товары"
CREATE TABLE Product
(
	ProductID int NOT NULL PRIMARY KEY IDENTITY(1,1),
	ProductName varchar(25) NOT NULL,
	VendorCode int NOT NULL,
	CertificateNumber int NOT NULL,
	Packing varchar(20) NOT NULL,
	Manufacturer varchar(20) NOT NULL,
	StorageQuantity integer NOT NULL,
	CHECK(CertificateNumber > 0 AND StorageQuantity >= 0),
	CHECK(Packing IN ('Большая упаковка','Маленькая упаковка'))
)
GO

-- Таблица "Прайс-листы"
CREATE TABLE PriceList
(
	PriceListID int NOT NULL PRIMARY KEY IDENTITY(1,1),
	GroupID integer NOT NULL FOREIGN KEY REFERENCES CustomersGroup(GroupID) ON DELETE CASCADE,
	PriceListDate date NOT NULL,
	PriceListCateGOry varchar(30) NOT NULL
)
GO

-- Таблица "Товары в прайс-листах"
CREATE TABLE ProductInPriceList
(
	ProductInPriceID integer IDENTITY(1,1) NOT NULL,
	PriceListID integer NOT NULL,
	ProductID integer NOT NULL,
	ProductPrice smallmoney NOT NULL,

	CONSTRAINT PK_ProductInPriceList PRIMARY KEY(ProductInPriceID),
	CONSTRAINT FK_ProductInPriceList_PriceList FOREIGN KEY(PriceListID) REFERENCES PriceList(PriceListID) ON DELETE CASCADE,
	CONSTRAINT FK_ProductInPriceList_Product FOREIGN KEY(ProductID) REFERENCES Product(ProductID) ON DELETE CASCADE
)
GO

-- Таблица "Платёжные документы"
CREATE TABLE PaymentDocument
(
	DocumentID int IDENTITY(1,1) NOT NULL,
	DocumentType varchar(35)  NOT NULL,
	PaymentDate datetime NULL,
	PaymentAmount decimal(9,2) NOT NULL,

	CONSTRAINT PK_DocumentID PRIMARY KEY(DocumentID),
	CONSTRAINT CHK_PaymentDocument_DocumentType CHECK(DocumentType IN ('Банковское платёжное поручение','Приходной кассовый ордер')),
	CONSTRAINT CHK_PaymentDocument_PaymentAmount CHECK(PaymentAmount > 0)
)
GO

-- Таблица "Накладные"
CREATE TABLE Invoice
(
	InvoiceID int IDENTITY(1,1) NOT NULL,
	CustomerID int NOT NULL,
	DocumentID int NOT NULL,
	PriceNumber int NOT NULL,
	IssueDate datetime NOT NULL,
	PaymentDate datetime NULL,
	ExportTime datetime NOT NULL,
	Canceled varchar(30) NULL,

	CONSTRAINT PK_Invoice PRIMARY KEY(InvoiceID),
	CONSTRAINT FK_Invoice_Customer FOREIGN KEY(CustomerID) REFERENCES Customer(CustomerID) ON DELETE CASCADE,
	CONSTRAINT FK_Invoice_PaymentDocument FOREIGN KEY(DocumentID) REFERENCES PaymentDocument(DocumentID) ON DELETE CASCADE,
	CONSTRAINT CHK_Invoice_PriceNumber CHECK(PriceNumber > 0)
)
GO

-- Таблица "Сделки"
CREATE TABLE Deal
(
	DealID int IDENTITY(1,1) NOT NULL,
	InvoiceID int NOT NULL,
	ProductInPriceID int NOT NULL,
	Quantity int NOT NULL,

	CONSTRAINT PK_Deal PRIMARY KEY(DealID),
	CONSTRAINT FK_Deal_Invoice FOREIGN KEY(InvoiceID) REFERENCES Invoice(InvoiceID) ON DELETE CASCADE,
	CONSTRAINT FK_Deal_ProductInPrice FOREIGN KEY(ProductInPriceID) REFERENCES ProductInPriceList(ProductInPriceID) ON DELETE CASCADE
)
GO

-- ЗАПОЛНЕНИЕ ТАБЛИЦ ДАННЫМИ

INSERT INTO Customer
(CustomerType)
VALUES
('Частное лицо'),
('Частное лицо'),
('Юридическое лицо'),
('Юридическое лицо'),
('Частное лицо'),
('Юридическое лицо'),
('Частное лицо'),
('Частное лицо')
GO

INSERT INTO Person
(CustomerID, LastName, FirstName, MiddleName, BirthDate, PassportSeries, PassportNumber, HomeAddress, PhoneNumber)
VALUES
(1,'Иванов','Иван','Иванович','05/03/1985',4526,325896,'Октябрьская улица, 57','+7(999)965-87-36'),
(2,'Сидоров','Алексей','Николаевич','26/10/1971',4549,269824,'Пролетарская улица, 2','+7(916)268-16-43'),
(5,'Стасов','Михаил','Михайлович','11/07/1964',4582,731946,'Советская улица, 13','+7(985)753-14-74'),
(7,'Михайлов','Олег','Николаевич','14/08/1984',4581,349885,'Пролетарская улица, 7','+7(916)368-82-12'),
(8,'Куприянов','Владимир','Владимирович','06/09/1993',4516,965245,'Советская улица, 29','+7(985)346-28-43')
GO

INSERT INTO Company
(CustomerID, CompanyName, CompanyAddress, CompanyPhoneNumber, LicenseNumber, BankDetails, CateGOry)
VALUES
(3,'ГорГаз','Московская улица, 66','+7(915)846-96-32',852963741,'Сбербанк России','Государственное предприятие'),
(4,'ГорСтрой','Ленинградская улица, 29/3','+7(999)264-49-21',159753456,'Сбербанк России','Государственное предприятие'),
(6,'Dirty Monk Inc.','Международный проспект, 3','+7(915)846-96-32',789654123,'Рокетбанк','Частная организация')
GO

INSERT INTO CustomersGroup
(GroupName)
VALUES
('Новый клиент'),
('Постоянный клиент'),
('Льготник')
GO

INSERT INTO CustomerInCustomersGroup
(CustomerID, GroupID)
VALUES
(1,1),
(2,2),
(3,2),
(4,1),
(5,3),
(6,2),
(7,1),
(8,2)
GO

INSERT INTO Product
(ProductName, VendorCode, CertificateNumber, Packing, Manufacturer, StorageQuantity)
VALUES
('Молоток',123,456,'Большая упаковка','Твой инструмент',20),
('Отвёртка',465,934,'Большая упаковка','Твой инструмент',3),
('Топор',348,753,'Большая упаковка','Твой инструмент',30),
('Дрель',357,942,'Большая упаковка','Твой инструмент',15),
('Пила',495,639,'Большая упаковка','Твой инструмент',19),
('Сверло',987,888,'Маленькая упаковка','Твой инструмент',9)
GO

INSERT INTO PriceList
(GroupID, PriceListDate, PriceListCateGOry)
VALUES
(1,'01/01/2000','Основной'),
(2,'01/01/2001','Скидочный'),
(3,'01/01/2001','Скидочный+')
GO

INSERT INTO ProductInPriceList
(PriceListID, ProductID, ProductPrice)
VALUES
(1,1,1000),
(1,2,500),
(1,3,1200),
(1,4,3000),
(1,5,2200),
(1,6,50),
(2,1,900),
(2,2,400),
(2,3,1100),
(2,4,2800),
(2,5,2100),
(2,6,45),
(3,1,800),
(3,2,300),
(3,3,1000),
(3,4,2600),
(3,5,2000),
(3,6,40)
GO

INSERT INTO PaymentDocument
(DocumentType, PaymentDate, PaymentAmount)
VALUES
('Приходной кассовый ордер',NULL,3000),
('Приходной кассовый ордер',NULL,1800),
('Банковское платёжное поручение',NULL,1100),
('Приходной кассовый ордер',NULL,1200),
('Банковское платёжное поручение',NULL,2800),
('Банковское платёжное поручение',NULL,450),
('Приходной кассовый ордер',NULL,4200),
('Приходной кассовый ордер',NULL,1000),
('Банковское платёжное поручение',NULL,3300)
/*
('Приходной кассовый ордер','04/02/2016',3000),
('Приходной кассовый ордер',NULL,1800),
('Банковское платёжное поручение','22/11/2016',1100),
('Приходной кассовый ордер','07/02/2016',1200),
('Банковское платёжное поручение','24/09/2016',2800),
('Банковское платёжное поручение',NULL,450),
('Приходной кассовый ордер','08/12/2016',4200),
('Приходной кассовый ордер','01/02/2016',1000),
('Банковское платёжное поручение',NULL,3300)
*/
GO

INSERT INTO Invoice
(CustomerID, DocumentID, PriceNumber, IssueDate, PaymentDate, ExportTime, Canceled)
VALUES
(1,1,1,'04/02/2016',NULL,'04/02/2016',DEFAULT),
(2,2,2,'16/10/2016',NULL,'16/10/2016',DEFAULT),
(3,3,2,'22/11/2016',NULL,'22/11/2016',DEFAULT),
(5,4,3,'07/02/2016',NULL,'07/02/2016',DEFAULT),
(3,5,2,'24/09/2016',NULL,'24/09/2016',DEFAULT),
(3,6,2,'11/08/2016',NULL,'11/08/2016',DEFAULT),
(2,7,2,'08/12/2016',NULL,'08/12/2016',DEFAULT),
(7,8,1,'01/02/2016',NULL,'01/02/2016',DEFAULT),
(6,9,2,'12/12/2016',NULL,'12/12/2016',DEFAULT)
/*
(1,1,1,'04/02/2016','04/02/2016','04/02/2016',DEFAULT),
(2,2,2,'16/10/2016',NULL,'16/10/2016','Аннулировано'),
(3,3,2,'22/11/2016','22/11/2016','22/11/2016',DEFAULT),
(5,4,3,'07/02/2016','07/02/2016','07/02/2016',DEFAULT),
(3,5,2,'24/09/2016','24/09/2016','24/09/2016',DEFAULT),
(3,6,2,'11/08/2016',NULL,'11/08/2016','Аннулировано'),
(2,7,2,'08/12/2016','08/12/2016','08/12/2016',DEFAULT),
(7,8,1,'01/02/2016','01/02/2016','01/02/2016',DEFAULT),
(6,9,2,'12/12/2016',NULL,'12/12/2016','Аннулировано')
*/
GO

INSERT INTO Deal
(InvoiceID, ProductInPriceID, Quantity)
VALUES
(1, 4, 1),
(2, 7, 2),
(3, 9, 1),
(4, 14, 4),
(5, 10, 1),
(6, 12, 10),
(7, 11, 2),
(8, 1, 1),
(9, 9, 3)
GO

-- ВЫБОРКА ДАННЫХ ИЗ ТАБЛИЦ

SELECT * FROM Customer
GO

SELECT * FROM Person
GO

SELECT * FROM Company
GO

SELECT * FROM CustomersGroup
GO

SELECT * FROM CustomerInCustomersGroup
GO

SELECT * FROM Product
GO

SELECT * FROM PriceList
GO

SELECT * FROM ProductInPriceList
GO

SELECT * FROM PaymentDocument
GO

SELECT * FROM Invoice
GO

SELECT * FROM Deal
GO