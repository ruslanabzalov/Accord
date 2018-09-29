USE accord
GO

/*
Запрос, возвращающий максимальную стоимость каждого товара во всех прайс-листах,
которая больше 1000, отсортированную по убыванию.
*/
SELECT
	products_in_price_lists.product_id AS 'ID товара',
	MAX(products_in_price_lists.product_price) AS 'Максимальная стоимость среди всех прайс-листов'
FROM products_in_price_lists
GROUP BY products_in_price_lists.product_id
HAVING MAX(products_in_price_lists.product_price) > 1000
ORDER BY 2 DESC
GO

/*
Пример использования оператора UNION.
*/
SELECT
	products_in_price_lists.product_id,
	MAX(products_in_price_lists.product_price)
FROM products_in_price_lists
GROUP BY products_in_price_lists.product_id
	UNION
SELECT
	products_in_price_lists.product_id,
	MIN(products_in_price_lists.product_price)
FROM products_in_price_lists
GROUP BY products_in_price_lists.product_id
ORDER BY 1
GO

/*
Запрос, возвращающий кол-во всех товаров в разных прайс-листах.
*/
SELECT COUNT(*) AS 'Коли-во товаров в разных прайс-листах'
FROM products_in_price_lists
GROUP BY()
GO

/*
Запрос, возвращающий все идентификаторы.
*/
SELECT $identity
FROM products_in_price_lists
GO

/*
Запрос, возвращающий начальное значение и шаг.
*/
SELECT
	IDENT_SEED('products_in_price_lists') AS 'Начальное значение',
	IDENT_INCR('products_in_price_lists') AS 'Шаг'
GO