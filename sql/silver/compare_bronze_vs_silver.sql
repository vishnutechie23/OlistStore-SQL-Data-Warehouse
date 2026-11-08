-- compare
SELECT
    'Customers' AS table_name,
    (SELECT COUNT_BIG(*) FROM bronze.olist_customers) AS bronze_rows,
    (SELECT COUNT_BIG(*) FROM silver.olist_customers) AS silver_rows

UNION ALL

SELECT 'Orders',
    (SELECT COUNT_BIG(*) FROM bronze.olist_orders),
    (SELECT COUNT_BIG(*) FROM silver.olist_orders)

UNION ALL

SELECT 'Products',
    (SELECT COUNT_BIG(*) FROM bronze.olist_products),
    (SELECT COUNT_BIG(*) FROM silver.olist_products)

UNION ALL

SELECT 'Sellers',
    (SELECT COUNT_BIG(*) FROM bronze.olist_sellers),
    (SELECT COUNT_BIG(*) FROM silver.olist_sellers)

UNION ALL

SELECT 'Order Items',
    (SELECT COUNT_BIG(*) FROM bronze.olist_order_items),
    (SELECT COUNT_BIG(*) FROM silver.olist_order_items)

UNION ALL

SELECT 'Payments',
    (SELECT COUNT_BIG(*) FROM bronze.olist_order_payments),
    (SELECT COUNT_BIG(*) FROM silver.olist_order_payments)

UNION ALL

SELECT 'Reviews',
    (SELECT COUNT_BIG(*) FROM bronze.olist_order_reviews),
    (SELECT COUNT_BIG(*) FROM silver.olist_order_reviews)

UNION ALL

SELECT 'Geolocation',
    (SELECT COUNT_BIG(*) FROM bronze.olist_geolocation),
    (SELECT COUNT_BIG(*) FROM silver.olist_geolocation)

UNION ALL

SELECT 'Category Translation',
    (SELECT COUNT_BIG(*) FROM bronze.olist_category_translation),
    (SELECT COUNT_BIG(*) FROM silver.olist_category_translation);


-- 
SELECT TOP 20
    b.customer_id AS bronze_customer_id,
    s.customer_id AS silver_customer_id,

    b.customer_city AS bronze_city,
    s.customer_city AS silver_city,

    b.customer_state AS bronze_state,
    s.customer_state AS silver_state

FROM bronze.olist_customers b
INNER JOIN silver.olist_customers s
    ON LTRIM(RTRIM(b.customer_id)) = s.customer_id

WHERE
    b.customer_id <> s.customer_id
    OR b.customer_city <> s.customer_city
    OR b.customer_state <> s.customer_state;

-- 
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH AS max_length
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'bronze'
  AND TABLE_NAME = 'olist_customers'

UNION ALL

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'silver'
  AND TABLE_NAME = 'olist_customers'

ORDER BY COLUMN_NAME;

-- Check Reviews table Yahan actual cleaning hui thi — blank comments ko NULL mein convert kiya tha.
SELECT
    'Bronze' AS layer,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS null_titles,
    SUM(CASE WHEN LTRIM(RTRIM(review_comment_title)) = ''
        THEN 1 ELSE 0 END) AS blank_titles,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_messages,
    SUM(CASE WHEN LTRIM(RTRIM(review_comment_message)) = ''
        THEN 1 ELSE 0 END) AS blank_messages
FROM bronze.olist_order_reviews

UNION ALL

SELECT
    'Silver',
    COUNT(*),
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN LTRIM(RTRIM(review_comment_title)) = ''
        THEN 1 ELSE 0 END),
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN LTRIM(RTRIM(review_comment_message)) = ''
        THEN 1 ELSE 0 END)
FROM silver.olist_order_reviews;

-- Products table comparison Products mein category translation aur column renaming hua tha.
SELECT
    b.product_category_name AS bronze_category,
    s.product_category_name AS silver_category,
    s.product_category_name_english AS english_category,
    COUNT(*) AS product_count
FROM bronze.olist_products b
INNER JOIN silver.olist_products s
    ON b.product_id = s.product_id
WHERE
    b.product_category_name IS NOT NULL
GROUP BY
    b.product_category_name,
    s.product_category_name,
    s.product_category_name_english
ORDER BY product_count DESC;