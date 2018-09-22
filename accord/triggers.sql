USE master
GO

USE accord
GO

/*
ТРИГГЕРЫ.
*/

/*
Триггер №1.
При добавлении записи в таблицу "Документ об оплате" выполнять правку
текущего количества товаров на складе, и при отсутствии хотя бы одного
товара выполнять откат транзакции с удалением отсутсвующих позиций из накладной.
*/
CREATE TRIGGER TriggerForPaymentDocument
ON PaymentDocument
FOR UPDATE
AS
BEGIN
	DECLARE @prID int, @invcID int, @docID int, @stQty int, @qty int
		
	DECLARE rowCursor CURSOR LOCAL FAST_FORWARD FOR
	SELECT Product.ProductID, Invoice.InvoiceID, PaymentDocument.DocumentID, Product.StorageQuantity, Deal.Quantity
	FROM Product INNER JOIN ProductInPriceList
	ON Product.ProductID = ProductInPriceList.ProductID 
	INNER JOIN Deal
	ON Deal.ProductInPriceID = ProductInPriceList.ProductInPriceID
	INNER JOIN Invoice
	ON Deal.InvoiceID = Invoice.InvoiceID AND Invoice.PaymentDate IS NULL AND Invoice.Canceled IS NULL
	INNER JOIN PaymentDocument
	ON Invoice.DocumentID = PaymentDocument.DocumentID

	OPEN rowCursor
	FETCH NEXT FROM rowCursor INTO @prID, @invcID, @docID, @stQty, @qty
	WHILE @@FETCH_STATUS = 0
	BEGIN

		IF @qty > @stQty 
			BEGIN
				DELETE FROM Invoice
				WHERE Invoice.InvoiceID = @invcID

				DELETE FROM PaymentDocument
				WHERE PaymentDocument.DocumentID = @docID
			END

		UPDATE Product
		SET Product.StorageQuantity = @stQty - @qty
		FROM Product INNER JOIN ProductInPriceList
		ON Product.ProductID = ProductInPriceList.ProductID INNER JOIN Deal ON Deal.ProductInPriceID = ProductInPriceList.ProductInPriceID
		WHERE Product.ProductID = @prID AND Deal.InvoiceID = @invcID

		UPDATE Invoice
		SET Invoice.PaymentDate = PaymentDocument.PaymentDate
		FROM Invoice INNER JOIN PaymentDocument
		ON Invoice.DocumentID = PaymentDocument.DocumentID AND Invoice.InvoiceID = @invcID

		FETCH NEXT FROM rowCursor INTO @prID, @invcID, @docID, @stQty, @qty

	END
	CLOSE rowCursor
	DEALLOCATE rowCursor
END
GO

DROP TRIGGER TriggerForPaymentDocument
GO

UPDATE PaymentDocument
SET PaymentDate = GETDATE()

/*
Триггер №2.
При вставке в таблицу "Накладная на отпуск товара" уменьшать
текущее количетсво товаров на складе.
*/
CREATE TRIGGER TriggerForDeal
ON Deal
FOR INSERT
AS
BEGIN
	IF @@ROWCOUNT = 0 RETURN

	UPDATE Product
	SET Product.StorageQuantity = Pr.StorageQuantity - Temp.Qty
	FROM Product Pr inner JOIN
	(
		SELECT Product.ProductID AS ID, Product.StorageQuantity AS SQty, SUM(Ins.Quantity) AS Qty
		FROM Product inner JOIN ProductInPriceList
		ON Product.ProductID = ProductInPriceList.ProductID
		inner JOIN inserted AS Ins
		ON ProductInPriceList.ProductInPriceID = Ins.ProductInPriceID
		GROUP BY Product.ProductID, Product.StorageQuantity
	) AS Temp
	ON Pr.ProductID = Temp.ID
END
GO

DROP TRIGGER TriggerForDeal
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