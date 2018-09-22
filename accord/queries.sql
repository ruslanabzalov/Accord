USE master
GO

USE accord
GO

/*
ЗАПРОСЫ.
*/

/*
Запрос №1.
Найти категории прайс-листов, которые использовались наиболее часто
(т.е. по ним оформлено максимальное кол-во накладных) за последний год.
Отчёт представить в виде:
категория прайс-листа; кол-во оформленных накладных; кол-во аннулированных накладных;
кол-во разных покупателей, оформлявших накладные (колонка A); кол-во покупателей,
которые могут использовать данную категорию прайс-листа (колонка B); доля использования категории
прайс-листа (колонка A / колонка B; в процентах).
*/
SELECT	PriceList.PriceListID AS 'ID прайс-листа',
		PriceList.PriceListCategory AS 'Категория прайс-листа',
		COUNT(DISTINCT Invoice.InvoiceID) AS 'Кол-во оформленных накладных по прайс-листам',
		COUNT(DISTINCT #Invoice.InvoiceID) AS 'Кол-во аннулированных накладных по прайс-листам',
		COUNT(DISTINCT Invoice.CustomerID) AS 'Кол-во разных покупателей оформлявших прайс-лист (A)',
		COUNT(DISTINCT CustomerInCustomersGroup.CustomerID) AS 'Кол-во разных покупателей, которые могут оформлять прайс-лист (B)',
		(CONVERT(numeric(6,2), COUNT(DISTINCT Invoice.CustomerID) / CONVERT(numeric(6,2), COUNT(DISTINCT CustomerInCustomersGroup.CustomerID)))) * 100 AS 'Доля использования категории прайс-листа (%)'
FROM PriceList LEFT OUTER JOIN CustomerInCustomersGroup
		ON PriceList.GroupID = CustomerInCustomersGroup.GroupID
		LEFT OUTER JOIN Invoice
		ON PriceList.PriceListID = Invoice.PriceNumber

		LEFT OUTER JOIN Invoice AS #Invoice
		ON Invoice.InvoiceID = #Invoice.InvoiceID AND #Invoice.Canceled = 'Аннулировано'

WHERE YEAR(Invoice.IssueDate) = YEAR(GETDATE())
GROUP BY PriceList.PriceListID, PriceList.PriceListCategory
ORDER BY COUNT(DISTINCT Invoice.InvoiceID) DESC
GO

/*
Запрос №2.
Получить информацию о самых неблагонадёжных клиентах (т.е. о клиентах, которые имеют максимальное кол-во
аннулированных накладных).
Отчёт представить в виде:
информация о клиенте; тип клиента; кол-во оформленных накладных; общая стоимость всех товаров в накладных;
(потенциальный доход); кол-во аннулированных накладных; общая стоимость товаров в аннулированных
накладных (неполученный доход); кол-во неоплаченных накладных; общая стоимость товара в неоплаченных
накладных (долг).
*/
SELECT	Customer.CustomerID AS 'ID клиента',
		Customer.CustomerType AS 'Тип документа',
		COUNT(Invoice.InvoiceID) AS 'Кол-во оформленных накладных',
		SUM(#Deal.Quantity * #ProductInPriceList.ProductPrice) AS 'Потенциальный доход',
		COUNT(#Invoice1.InvoiceID) AS 'Кол-во аннулированных накладных',
		SUM(#Deal1.Quantity * #ProductInPriceList1.ProductPrice) AS 'Неполученный доход',
		COUNT(#Invoice2.InvoiceID) AS 'Кол-во неоплаченных накладных',
		SUM(#Deal2.Quantity * #ProductInPriceList2.ProductPrice) AS 'Долг'
FROM	Customer LEFT OUTER JOIN Invoice
		ON Customer.CustomerID = Invoice.CustomerID

		LEFT OUTER JOIN
		(
			Deal AS #Deal LEFT OUTER JOIN ProductInPriceList AS #ProductInPriceList
			ON #Deal.ProductInPriceID = #ProductInPriceList.ProductInPriceID
		)
		ON #Deal.InvoiceID = Invoice.InvoiceID
		
		LEFT OUTER JOIN
		(
			Deal AS #Deal1 LEFT OUTER JOIN ProductInPriceList AS #ProductInPriceList1
			ON #Deal1.ProductInPriceID = #ProductInPriceList1.ProductInPriceID
			LEFT OUTER JOIN Invoice AS #Invoice1
			ON #Deal1.InvoiceID = #Invoice1.InvoiceID
		)
		ON #Deal.InvoiceID = #Invoice1.InvoiceID AND #Invoice1.Canceled = 'Аннулировано'
		
		LEFT OUTER JOIN
		(
			Deal AS #Deal2 LEFT OUTER JOIN ProductInPriceList AS #ProductInPriceList2
			ON #Deal2.ProductInPriceID = #ProductInPriceList2.ProductInPriceID
			LEFT OUTER JOIN Invoice AS #Invoice2
			ON #Deal2.InvoiceID = #Invoice2.InvoiceID
		)
		ON #Deal.InvoiceID = #Invoice2.InvoiceID AND #Invoice2.PaymentDate IS NULL
		
GROUP BY Customer.CustomerID, Customer.CustomerType
HAVING COUNT(Invoice.InvoiceID) != 0
ORDER BY COUNT(#Invoice1.InvoiceID) DESC
GO

/*
Запрос №3.
Сформировать отчёт о продаже товара за последние полгода в виде:
название товара; кол-во прайс-листов, в которых упоминается этот товар; средняя стоимость товара за полгода
по всем прайс-листам; общее кол-во продаж товара; доход от продаж товара; кол-во возвращённого товара;
недополученный доход.
*/

SELECT	Product.ProductID AS 'ID товара',
		Product.ProductName AS 'Название товара',
		COUNT(DISTINCT ProductInPriceList.PriceListID) AS 'Кол-во прайс-листов с этим товаром',
		AVG(ProductInPriceList.ProductPrice) AS 'Средняя стоимость товара по всем прайс-листам',
		SUM(#Deal.Quantity) AS 'Общее кол-во продаж товара',
		SUM(#PInPL.ProductPrice * #Deal.Quantity) AS 'Общий доход от продаж товара',
		SUM(#Deal1.Quantity) AS 'Кол-во возвращённого товара',
		SUM(#Deal1.Quantity * #PInPL.ProductPrice) AS 'Недополученный доход'
FROM	Product LEFT OUTER JOIN ProductInPriceList
		ON Product.ProductID = ProductInPriceList.ProductID
		
		LEFT OUTER JOIN Deal AS #Deal
		ON #Deal.ProductInPriceID = ProductInPriceList.ProductInPriceID
		
		LEFT OUTER JOIN ProductInPriceList AS #PInPL
		ON #PInPL.ProductInPriceID = #Deal.ProductInPriceID
		
		LEFT OUTER JOIN Invoice AS #Invoice
		ON #Deal.InvoiceID = #Invoice.InvoiceID
		
		LEFT OUTER JOIN
		(
			Deal AS #Deal1 LEFT OUTER JOIN Invoice AS #Invoice1
			ON #Deal1.InvoiceID = #Invoice1.InvoiceID
			LEFT OUTER JOIN ProductInPriceList AS #ProductInPriceList1
			ON #Deal1.ProductInPriceID = #ProductInPriceList1.ProductInPriceID
		)
		ON #Deal.InvoiceID = #Invoice1.InvoiceID AND #Invoice1.Canceled = 'Аннулировано'
		
WHERE	MONTH(#Invoice.IssueDate) >= (MONTH(getdate()) - 6)
GROUP BY Product.ProductID, Product.ProductName
GO

/*
Запрос №4.
Получить информацию о прайс-листах, которые не использовались ни одним клиентом за последние полгода.
Отчёт представить в виде:
информация о прайс-листе; кол-во различных видов проданных товаров из данного прайс-листа; кол-во разных клиентов,
использовавших данный прайс-лист.
*/
SELECT	PriceList.PriceListID AS 'ID прайс-листа',
		PriceList.PriceListCategory AS 'Категория прайс-листа',
		SUM(#Deal.Quantity) AS 'Кол-во различных видов проданных товаров',
		COUNT(DISTINCT #Invoice.CustomerID) AS 'Кол-во различных покупателей'
FROM	PriceList LEFT OUTER JOIN ProductInPriceList
		ON PriceList.PriceListID = ProductInPriceList.PriceListID

		LEFT OUTER JOIN Deal AS #Deal
		ON #Deal.ProductInPriceID = ProductInPriceList.ProductInPriceID AND #Deal.DealID IS NOT NULL
		
		LEFT OUTER JOIN Invoice AS #Invoice
		ON #Deal.InvoiceID = #Invoice.InvoiceID
WHERE	MONTH(#Invoice.PaymentDate) <= (MONTH(getdate()) - 6)
GROUP BY PriceList.PriceListID, PriceList.PriceListCategory
GO

/*
Запрос №5.
Получить инофрмацию о клиентах, оформивших хотя бы одну накладную, но не оплативших ни одной накладной.
Отчёт представить в виде:
информация о клиенте; общее кол-во накладных; суммарное кол-во товаров; ожидаемый доход; общее кол-во аннулированных накладных;
недополученный доход; долг.
*/
SELECT	Customer.CustomerID AS 'ID клиента',
		Customer.CustomerType AS 'Тип клиента',
		COUNT(Invoice.InvoiceID) AS 'Кол-во оформленных накладных',
		SUM(#Deal.Quantity) AS 'Суммарное кол-во товаров',
		SUM(#Deal.Quantity * #ProductInPriceList.ProductPrice) AS 'Ожидаемый доход',
		COUNT(#Invoice.InvoiceID) AS 'Общее кол-во аннулированных накладных',
		SUM(#Deal1.Quantity * #ProductInPriceList1.ProductPrice) AS 'Недополученный доход',
		SUM(#Deal1.Quantity * #ProductInPriceList1.ProductPrice) AS 'Долг'
FROM	Customer LEFT OUTER JOIN Invoice
		ON Customer.CustomerID = Invoice.CustomerID

		LEFT OUTER JOIN Deal AS #Deal
		ON Invoice.InvoiceID = #Deal.InvoiceID

		LEFT OUTER JOIN ProductInPriceList AS #ProductInPriceList
		ON #Deal.ProductInPriceID = #ProductInPriceList.ProductInPriceID

		LEFT OUTER JOIN
		(
			Deal AS #Deal1 LEFT OUTER JOIN ProductInPriceList AS #ProductInPriceList1
			ON #Deal1.ProductInPriceID = #ProductInPriceList1.ProductInPriceID
			LEFT OUTER JOIN Invoice AS #Invoice
			ON #Deal1.InvoiceID = #Invoice.InvoiceID
		)
		ON #Deal.InvoiceID = #Invoice.InvoiceID AND #Invoice.Canceled = 'Аннулировано'
GROUP BY Customer.CustomerID, Customer.CustomerType
HAVING COUNT(Invoice.InvoiceID) = COUNT(#Invoice.InvoiceID) AND COUNT(#Invoice.InvoiceID) != 0
GO