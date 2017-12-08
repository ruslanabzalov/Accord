USE master
GO

USE accord
GO

-- ПРОЦЕДУРЫ

/*
Процедура №1.
Регистрация покупателя (!!!Для корректной работы нужно убрать все UNIQUE у Person и Company!!!).
1. Входные параметры: все атрибуты покупателя;
2. Результат: id покупателя и соответствующее сообщение.
Проверки: 
Новый покупатель, зачисление в соответствующую группу.
При изменении информации о покупателе указывать в поле ChangedAt дату редактирования.
*/

-- Регистрация частного лица
CREATE PROCEDURE PersonRegistration
(
@customerID int OUTPUT,
@lastName varchar(20),
@firstName varchar(20),
@middleName varchar(20),
@birthDate date,
@passportSeries int,
@passportNumber int,
@homeAddress varchar(70),
@phoneNumber varchar(20)
)
AS
BEGIN
	IF 
	(
		(@lastName IS NOT NULL)
		AND
		(@firstName IS NOT NULL)
		AND
		(@middleName IS NOT NULL)
		AND
		(@birthDate IS NOT NULL)
		AND
		(@passportSeries IS NOT NULL AND @passportSeries > 0)
		AND
		(@passportNumber IS NOT NULL AND @passportNumber > 0)
		AND
		(@homeAddress IS NOT NULL)
		AND
		(@phoneNumber IS NOT NULL)
	)
	BEGIN
		IF EXISTS (SELECT CustomerID FROM Person
		WHERE PassportSeries = @passportSeries AND PassportNumber = @passportNumber)
		BEGIN
			UPDATE Person
			SET
			LastName = @lastName,
			FirstName = @firstName,
			MiddleName = @middleName,
			BirthDate = @birthDate,
			HomeAddress = @homeAddress,
			PhoneNumber = @phoneNumber,
			ExparesAt = GETDATE()
			WHERE PassportSeries = @passportSeries AND PassportNumber = @passportNumber AND ChangedAt IS NULL

			INSERT INTO Customer 
			(CustomerType)
			VALUES
			('Частное лицо')

			SET @customerID = (SELECT MAX(CustomerID) FROM Customer)

			INSERT INTO Person
			(CustomerID, LastName, FirstName, MiddleName, BirthDate, PassportSeries, PassportNumber, HomeAddress, PhoneNumber)
			VALUES
			(@customerID, @lastName, @firstName, @middleName, @birthDate, @passportSeries, @passportNumber, @homeAddress, @phoneNumber)

			RETURN
		END
		ELSE
		BEGIN
			INSERT INTO Customer 
			(CustomerType)
			VALUES
			('Частное лицо')

			SET @customerID = (SELECT MAX(CustomerID) FROM Customer)

			INSERT INTO Person
			(CustomerID, LastName, FirstName, MiddleName, BirthDate, PassportSeries, PassportNumber, HomeAddress, PhoneNumber)
			VALUES
			(@customerID, @lastName, @firstName, @middleName, @birthDate, @passportSeries, @passportNumber, @homeAddress, @phoneNumber)

			RETURN
		END
	END
	ELSE
		PRINT 'Некорректный ввод параметров!'
END
GO

-- Регистрация юридического лица
CREATE PROCEDURE CompanyRegistration
(
@customerID int OUTPUT,
@companyName varchar(30),
@companyAddress varchar(20),
@companyPhoneNumber varchar(20),
@licenseNumber int,
@bankDetails varchar(20),
@category varchar(20)
)
AS
BEGIN
	IF 
	(
		(@companyName IS NOT NULL)
		AND
		(@companyAddress IS NOT NULL)
		AND
		(@companyPhoneNumber IS NOT NULL)
		AND
		(@licenseNumber IS NOT NULL AND @licenseNumber > 0)
		AND
		(@bankDetails IS NOT NULL)
		AND
		(@category IS NOT NULL)
	)
	BEGIN
		IF EXISTS (SELECT CustomerID FROM Company
		WHERE CompanyName = @companyName AND LicenseNumber = @licenseNumber)
		BEGIN
			SET @customerID = (SELECT CustomerID FROM Company WHERE CompanyName = @companyName AND LicenseNumber = @licenseNumber)

			UPDATE Company
			SET
			CompanyAddress = @companyAddress,
			CompanyPhoneNumber = @companyPhoneNumber,
			BankDetails = @bankDetails,
			Category = @category
			WHERE CompanyName = @companyName AND LicenseNumber = @licenseNumber

			RETURN
		END
		ELSE
		BEGIN
			INSERT INTO Customer
			(CustomerType)
			VALUES
			('Юридическое лицо')

			SET @customerID = (SELECT MAX(CustomerID) FROM Customer)

			INSERT INTO Company
			(CustomerID, CompanyName, CompanyAddress, CompanyPhoneNumber, LicenseNumber, BankDetails, Category)
			VALUES
			(@customerID, @companyName, @companyAddress, @companyPhoneNumber, @licenseNumber, @bankDetails, @category)

			RETURN
		END
	END
	ELSE
		PRINT 'Некорректный ввод параметров!'
END
GO

/*
Процедура №2.
В таблицу "Накладная на отпуск товара" добавить колонку Canceled.
Процедура должна найти все неоплаченные накладные (< текущей даты),
выполнить для них "возврат товара на склад" и отметить накладные в поле Canceled как аннулированные.
*/

CREATE PROCEDURE Сancellation
AS
BEGIN
	IF EXISTS (SELECT * FROM Invoice)
	BEGIN	
		IF EXISTS (SELECT InvoiceID FROM Invoice WHERE IssueDate < GETDATE() AND PaymentDate IS NULL)
			BEGIN
				DECLARE @canceledInvoiceID int

				UPDATE Invoice
				SET Canceled = 'Аннулировано'
				WHERE IssueDate < GETDATE() AND PaymentDate IS NULL

				-- Создание локального курсора
				DECLARE rowCursor CURSOR LOCAL FAST_FORWARD FOR 
				SELECT InvoiceID FROM Invoice WHERE IssueDate < GETDATE() AND PaymentDate IS NULL

				OPEN rowCursor
				FETCH NEXT FROM rowCursor INTO @canceledInvoiceID
				WHILE @@FETCH_STATUS = 0
				BEGIN
					DECLARE
					@idDeal int,
					@productQuantity int,
					@idPInP int

					SET @idDeal = (SELECT ProductInPriceID FROM Deal WHERE InvoiceID = @canceledInvoiceID)
					SET @productQuantity = (SELECT Quantity FROM Deal WHERE InvoiceID = @canceledInvoiceID)
					SET @idPInP = (SELECT ProductID FROM ProductInPriceList WHERE ProductInPriceID = @idDeal)

					UPDATE Product
					SET StorageQuantity = StorageQuantity + @productQuantity
					WHERE ProductID = @idPInP
					
					FETCH NEXT FROM rowCursor INTO @canceledInvoiceID
				END
				CLOSE rowCursor
				DEALLOCATE rowCursor
			END
		ELSE
			PRINT 'Неоплаченные накладные отсутствуют!'
	END
	ELSE
		PRINT 'В базе данных отсутствуют накладные!'
END
GO

-- ВЫЗОВ ПРОЦЕДУР

-- Вызов процедуры регистрации частного лица
DECLARE @customerID int 

EXECUTE PersonRegistration
@customerID OUTPUT,

@lastName = 'Иванов',
@firstName = 'Иван',
@middleName = 'Иванович',
@birthDate = '01/01/1990',
@passportSeries = 123,
@passportNumber = 456,
@homeAddress = 'Кековский проезд, 666',
@phoneNumber = '+7(800)555-35-35'

PRINT 'Добавлено\обновлено частное лицо с id:'
PRINT @customerID
GO

-- Вызов процедуры регистрации юридического лица
DECLARE @customerID int 

EXECUTE CompanyRegistration
@customerID OUTPUT,

@companyName = 'Lulz Inc.',
@companyAddress = 'Уличная улица, 0',
@companyPhoneNumber = '+7(888)777-66-55',
@licenseNumber = 1488,
@bankDetails = 'ВорБанк',
@category = 'Бузинесс'

PRINT 'Добавлено\обновлено юридическое лицо с id:'
PRINT @customerID
GO

-- Вызов процедуры аннулирования накладных
EXECUTE Сancellation
GO

-- СБРОС ПРОЦЕДУР

DROP PROCEDURE PersonRegistration
GO

DROP PROCEDURE CompanyRegistration
GO

DROP PROCEDURE Сancellation
GO