USE master
GO

DROP DATABASE accord
GO

CREATE DATABASE accord
GO

USE accord
GO

/*
СОЗДАНИЕ ТАБЛИЦ.
*/

-- Таблица "Покупатели".
CREATE TABLE customers (
	id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	customers_type NVARCHAR(16) NOT NULL,
	
	CHECK(customers_type IN (N'Частное лицо', N'Юридическое лицо'))
)
GO

-- Таблица "Частные лица".
CREATE TABLE persons (
	id INT NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES customers(id) ON DELETE CASCADE,
	last_name NVARCHAR(30) NOT NULL,
	first_name NVARCHAR(30) NOT NULL,
	patronymic NVARCHAR(30) NOT NULL DEFAULT N'Не указано',
	date_of_birth DATE NOT NULL,
	passport_series VARCHAR(5) NOT NULL,
	passport_id VARCHAR(6) NOT NULL,
	home_address NVARCHAR(60) NOT NULL,
	phone_number VARCHAR(16) NOT NULL,
	edited DATETIME NULL,

	CHECK(passport_series LIKE '[0-9][0-9] [0-9][0-9]'),
	CHECK(passport_id LIKE '[0-9][0-9][0-9][0-9][0-9][0-9]'),
	CHECK(phone_number LIKE '+7([0-9][0-9][0-9])[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),

	CONSTRAINT uq_persons UNIQUE(passport_series, passport_id)
)
GO

-- Таблица "Юридические лица".
CREATE TABLE companies (
	id INT NOT NULL PRIMARY KEY FOREIGN KEY REFERENCES customers(id) ON DELETE CASCADE,
	company_name NVARCHAR(40) NOT NULL,
	company_address NVARCHAR(40) NOT NULL,
	phone_number VARCHAR(16) NOT NULL,
	license_id VARCHAR(20) NOT NULL,
	bank_details NVARCHAR(40) NOT NULL,
	category NVARCHAR(30) NOT NULL,
	edited DATETIME NULL,

	CHECK(phone_number LIKE '+7([0-9][0-9][0-9])[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]'),
	CHECK(license_id > 0),

	CONSTRAINT uq_companies UNIQUE(company_name, license_id)
)
GO

-- Таблица "Группы покупателей".
CREATE TABLE customers_groups (
	id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	group_name NVARCHAR(40) NOT NULL UNIQUE
)
GO

-- Таблица "Покупатели в группах покупателей".
CREATE TABLE customers_in_customers_group (
	customer_id INT NOT NULL FOREIGN KEY REFERENCES customers(id) ON DELETE CASCADE,
	group_id INT NOT NULL FOREIGN KEY REFERENCES customers_groups(id) ON DELETE CASCADE,

	CONSTRAINT pk_customer_in_customers_group PRIMARY KEY(customer_id, group_id)
)
GO

-- Таблица "Товары".
CREATE TABLE products (
	id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	product_name NVARCHAR(40) NOT NULL,
	vendor_code INT NOT NULL,
	certificate_number INT NOT NULL,
	packaging NVARCHAR(18) NOT NULL,
	manufacturer NVARCHAR(40) NOT NULL,
	storage_quantity INT NOT NULL,

	CHECK(certificate_number > 0 AND storage_quantity >= 0),
	CHECK(packaging IN (N'Большая упаковка', N'Маленькая упаковка'))
)
GO

-- Таблица "Прайс-листы".
CREATE TABLE price_lists (
	id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	group_id INT NOT NULL FOREIGN KEY REFERENCES customers_groups(id) ON DELETE CASCADE,
	creation_date DATE NOT NULL,
	category NVARCHAR(40) NOT NULL
)
GO

-- Таблица "Товары в прайс-листах".
CREATE TABLE products_in_price_lists (
	id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	price_list_id INT NOT NULL FOREIGN KEY REFERENCES price_lists(id) ON DELETE CASCADE,
	product_id INT NOT NULL FOREIGN KEY REFERENCES products(id) ON DELETE CASCADE,
	product_price SMALLMONEY NOT NULL
)
GO

-- Таблица "Платёжные документы".
CREATE TABLE payment_documents (
	id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	document_type NVARCHAR(30) NOT NULL,
	payment_date DATETIME NULL,
	payment_amount DECIMAL(9, 2) NOT NULL,

	CHECK(document_type IN (N'Банковское платёжное поручение', N'Приходной кассовый ордер')),
	CHECK(payment_amount > 0)
)
GO

-- Таблица "Накладные".
CREATE TABLE invoices (
	id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	customer_id INT NOT NULL FOREIGN KEY REFERENCES customers(id) ON DELETE CASCADE,
	document_id INT NOT NULL FOREIGN KEY REFERENCES payment_documents(id) ON DELETE CASCADE,
	price_number INT NOT NULL,
	issue_date DATETIME NOT NULL,
	payment_date DATETIME NULL,
	export_time DATETIME NOT NULL,
	invoice_status NVARCHAR(30) NOT NULL DEFAULT N'Активна',

	CHECK(price_number > 0)
)
GO

-- Таблица "Сделки".
CREATE TABLE deals (
	id INT NOT NULL PRIMARY KEY IDENTITY(1, 1),
	invoice_id INT NOT NULL FOREIGN KEY REFERENCES invoices(id) ON DELETE CASCADE,
	product_in_price_id INT NOT NULL FOREIGN KEY REFERENCES products_in_price_lists(id) ON DELETE CASCADE,
	quantity INT NOT NULL,

	CHECK(quantity > 0)
)
GO

/*
ЗАПОЛНЕНИЕ ТАБЛИЦ ДАННЫМИ.
*/

-- Вставка данных в таблицу "Покупатели".
INSERT INTO customers
VALUES
	(N'Частное лицо'),
	(N'Частное лицо'),
	(N'Юридическое лицо'),
	(N'Юридическое лицо'),
	(N'Частное лицо'),
	(N'Юридическое лицо'),
	(N'Частное лицо'),
	(N'Частное лицо')
GO

-- Вставка данных в таблицу "Частные лица".
INSERT INTO persons
VALUES
	(1, N'Иванов', N'Иван', N'Иванович', '1985-03-05', '45 26', '325896', N'Октябрьская улица, 57', '+7(999)965-87-36', NULL),
	(2, N'Сидоров', N'Алексей', DEFAULT, '1971-10-26', '45 49', '269824', N'Пролетарская улица, 2', '+7(916)268-16-43', NULL),
	(5, N'Стасов', N'Михаил', DEFAULT, '1964-07-11', '45 82', '731946', N'Советская улица, 13', '+7(985)753-14-74', NULL),
	(7, N'Михайлов', N'Олег', N'Николаевич', '1984-08-14', '45 81', '349885', N'Пролетарская улица, 7', '+7(916)368-82-12', NULL),
	(8, N'Куприянов', N'Владимир', N'Владимирович', '1993-09-06', '45 16', '965245', N'Советская улица, 29', '+7(985)346-28-43', NULL)
GO

-- Вставка данных в таблицу "Юридические лица".
INSERT INTO companies
VALUES
	(3, N'ГорГаз', N'Московская улица, 66', '+7(915)846-96-32', '852963741', N'Сбербанк России', N'Государственное предприятие', NULL),
	(4, N'ГорСтрой', N'Ленинградская улица, 29/3', '+7(999)264-49-21', '159753456', N'Сбербанк России', N'Государственное предприятие', NULL),
	(6, 'Dirty Monk Inc.', N'Международный проспект, 3', '+7(915)846-96-32', '789654123', N'Рокетбанк', N'Частная организация', NULL)
GO

-- Вставка данных в таблицу "Группы покупателей".
INSERT INTO customers_groups
VALUES
	(N'Новый клиент'),
	(N'Постоянный клиент'),
	(N'Льготник')
GO

-- Вставка данных в таблицу "Покупатели в группах покупателях".
INSERT INTO customers_in_customers_group
VALUES
	(1, 1),
	(2, 2),
	(3, 2),
	(4, 1),
	(5, 3),
	(6, 2),
	(7, 1),
	(8, 2)
GO

-- Вставка данных в таблицу "Товары".
INSERT INTO products
VALUES
	(N'Молоток', 123, 456, N'Большая упаковка', N'Твой инструмент', 20),
	(N'Отвёртка', 465, 934, N'Большая упаковка', N'Твой инструмент', 3),
	(N'Топор', 348, 753, N'Большая упаковка', N'Твой инструмент', 30),
	(N'Дрель', 357, 942, N'Большая упаковка', N'Твой инструмент', 15),
	(N'Пила', 495, 639, N'Большая упаковка', N'Твой инструмент', 19),
	(N'Сверло', 987, 888, N'Маленькая упаковка', N'Твой инструмент', 9)
GO

-- Вставка данных в таблицу "Прайс-листы".
INSERT INTO price_lists
VALUES
	(1, '2000-01-01', N'Основной'),
	(2, '2001-01-01', N'Скидочный'),
	(3, '2001-01-01', N'Скидочный+')
GO

-- Вставка данных в таблицу "Товары в прайс-листах".
INSERT INTO products_in_price_lists
VALUES
	(1, 1, 1000),
	(1, 2, 500),
	(1, 3, 1200),
	(1, 4, 3000),
	(1, 5, 2200),
	(1, 6, 50),
	(2, 1, 900),
	(2, 2, 400),
	(2, 3, 1100),
	(2, 4, 2800),
	(2, 5, 2100),
	(2, 6, 45),
	(3, 1, 800),
	(3, 2, 300),
	(3, 3, 1000),
	(3, 4, 2600),
	(3, 5, 2000),
	(3, 6, 40)
GO

-- Вставка данных в таблицу "Платёжные документы".
INSERT INTO payment_documents
VALUES
	(N'Приходной кассовый ордер', NULL, 3000),
	(N'Приходной кассовый ордер', NULL, 1800),
	(N'Банковское платёжное поручение', NULL, 1100),
	(N'Приходной кассовый ордер', NULL, 1200),
	(N'Банковское платёжное поручение', NULL, 2800),
	(N'Банковское платёжное поручение', NULL, 450),
	(N'Приходной кассовый ордер', NULL, 4200),
	(N'Приходной кассовый ордер', NULL, 1000),
	(N'Банковское платёжное поручение', NULL, 3300)
GO

-- Вставка данных в таблицу "Накладные".
INSERT INTO invoices
VALUES
	(1, 1, 1, '2016-02-04', NULL, '2016-02-04', DEFAULT),
	(2, 2, 2, '2016-10-16', NULL, '2016-10-16', DEFAULT),
	(3, 3, 2, '2016-11-22', NULL, '2016-11-22', DEFAULT),
	(5, 4, 3, '2016-02-07', NULL, '2016-02-07', DEFAULT),
	(3, 5, 2, '2016-09-24', NULL, '2016-09-24', DEFAULT),
	(3, 6, 2, '2016-08-11', NULL, '2016-08-11', DEFAULT),
	(2, 7, 2, '2016-12-08', NULL, '2016-12-08', DEFAULT),
	(7, 8, 1, '2016-02-11', NULL, '2016-02-11', DEFAULT),
	(6, 9, 2, '2016-12-12', NULL, '2016-12-12', DEFAULT)
GO

-- Вставка данных в таблицу "Сделки".
INSERT INTO deals
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

/*
ВЫБОРКА ВСЕХ ДАННЫХ ИЗ ВСЕХ ТАБЛИЦ.
*/

-- Выборка всех данных из таблицы "Покупатели".
SELECT 
	customers.id AS 'Идентификатор',
	customers.customers_type AS 'Тип покупателя'
FROM customers
GO

-- Выборка всех данных из таблицы "Частные лица".
SELECT
	persons.id AS 'Идентификатор',
	persons.last_name AS 'Фамилия',
	persons.first_name AS 'Имя',
	persons.patronymic AS 'Отчество',
	persons.date_of_birth AS 'Дата рождения',
	persons.passport_series AS 'Серия паспорта',
	persons.passport_id AS 'Номер паспорта',
	persons.home_address AS 'Домашний адрес',
	persons.phone_number AS 'Номер телефона',
	persons.edited AS 'Дата изменения'
FROM persons
GO

-- Выборка всех данных из таблицы "Юридические лица".
SELECT
	companies.id AS 'Идентификатор',
	companies.company_name AS 'Название компании',
	companies.company_address AS 'Адрес комании',
	companies.phone_number AS 'Номер телефона',
	companies.license_id AS 'Номер лицензии',
	companies.bank_details AS 'Информация о банке',
	companies.category AS 'Категория',
	companies.edited AS 'Дата изменения'
FROM companies
GO

-- Выборка всех данных из таблицы "Группы покупателей".
SELECT
	customers_groups.id AS 'Идентификатор',
	customers_groups.group_name AS 'Название группы покупателей'
FROM customers_groups
GO

-- Выборка всех данных из таблицы "Покупатели в группах покупателей".
SELECT
	customers_in_customers_group.customer_id AS 'Идентификатор покупателя',
	customers_in_customers_group.group_id AS 'Идентификатор группы покупателей'
FROM customers_in_customers_group
GO

-- Выборка всех данных из таблицы "Товары".
SELECT
	products.id AS 'Идентификатор',
	products.product_name AS 'Название товара',
	products.vendor_code AS 'Артикул',
	products.certificate_number AS 'Номер сертификата',
	products.packaging AS 'Упаковка',
	products.manufacturer AS 'Производитель',
	products.storage_quantity AS 'Кол-во на складе'
FROM products
GO

-- Выборка всех данных из таблицы "Прайс-листы".
SELECT
	price_lists.id AS 'Идентификатор',
	price_lists.group_id AS 'Идентификатор группы покупателей',
	price_lists.creation_date AS 'Дата создания',
	price_lists.category AS 'Категория'
FROM price_lists
GO

-- Выборка всех данных из таблицы "Товары в прайс-листах".
SELECT
	products_in_price_lists.id AS 'Идентификатор',
	products_in_price_lists.price_list_id AS 'Идентификатор прайс-листа',
	products_in_price_lists.product_id AS 'Идентификатор товара',
	products_in_price_lists.product_price AS 'Стоимость'
FROM products_in_price_lists
GO

-- Выборка всех данных из таблицы "Платёжные документы".
SELECT
	payment_documents.id AS 'Идентификатор',
	payment_documents.document_type AS 'Тип документа',
	payment_documents.payment_date AS 'Дата оплаты',
	payment_documents.payment_amount AS 'К оплате'
FROM payment_documents
GO

-- Выборка всех данных из таблицы "Накладные".
SELECT
	invoices.id AS 'Идентификатор',
	invoices.customer_id AS 'Идентификатор покупателя',
	invoices.document_id AS 'Идентификатор платёжного документа',
	invoices.price_number AS 'Номер прайс-листа',
	invoices.issue_date AS 'Дата выпуска (?)',
	invoices.payment_date AS 'Дата оплаты',
	invoices.export_time AS 'Время экспорта (?)',
	invoices.invoice_status AS 'Статус'
FROM invoices
GO

-- Выборка всех данных из таблицы "Сделки".
SELECT
	deals.id AS 'Идентификатор',
	deals.invoice_id AS 'Идентификатор накладной',
	deals.product_in_price_id AS 'Идентификатор товара в прайс-листе',
	deals.quantity AS 'Количество'
FROM deals
GO