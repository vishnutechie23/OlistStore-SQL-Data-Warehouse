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

--
SELECT
    SUM(CASE
        WHEN b.review_comment_message IS NULL
         AND s.review_comment_message IS NOT NULL
        THEN 1 ELSE 0
    END) AS bronze_null_silver_not_null,

    SUM(CASE
        WHEN b.review_comment_message IS NOT NULL
         AND s.review_comment_message IS NULL
        THEN 1 ELSE 0
    END) AS bronze_not_null_silver_null

FROM bronze.olist_order_reviews b
INNER JOIN silver.olist_order_reviews s
    ON b.review_id = s.review_id
   AND b.order_id = s.order_id;

--18 records inspect karo:
SELECT
    b.review_id,
    b.order_id,
    b.review_comment_message AS bronze_message,
    s.review_comment_message AS silver_message
FROM bronze.olist_order_reviews b
INNER JOIN silver.olist_order_reviews s
    ON b.review_id = s.review_id
   AND b.order_id = s.order_id
WHERE b.review_comment_message IS NULL
  AND s.review_comment_message IS NOT NULL;

--
SELECT
    review_id,
    CASE
        WHEN review_comment_message IS NULL THEN 'NULL'
        WHEN LTRIM(RTRIM(review_comment_message)) = '' THEN 'BLANK'
        ELSE 'HAS VALUE'
    END AS value_status,
    LEN(review_comment_message) AS value_length,
    DATALENGTH(review_comment_message) AS storage_bytes,
    '[' + review_comment_message + ']' AS inspected_value
FROM silver.olist_order_reviews
WHERE review_id IN (
    '007c08c01178c42ff829560cc24dd0d6',
    '00b385c367ca681c5800956f540f62b8',
    '052150c42f7cc01bad8bd1b3d760f2df'
);

--
SELECT COUNT_BIG(*) AS whitespace_only_messages
FROM silver.olist_order_reviews
WHERE review_comment_message IS NOT NULL
  AND LTRIM(RTRIM(
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(review_comment_message, CHAR(9), ''),
                    CHAR(10), ''
                ),
                CHAR(13), ''
            ),
            CHAR(160), ''
        )
      )) = '';


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

/*
Silver layer status
Ab tak:
- [x] Row count comparison
- [x] Customer schema comparison
- [x] Reviews cleaning comparison and correction
- [x] Product category translation comparison
- [x] Row counts, NULL, numeric, FK and date validations
*/

-- Duplicate Primary / Composite Keys
-- =============================================
-- FINAL VALIDATION: DUPLICATE KEYS IN SILVER
-- =============================================

SELECT 'customers' AS table_name,
       'customer_id' AS key_columns,
       COUNT_BIG(*) AS duplicate_groups
FROM (
    SELECT customer_id
    FROM silver.olist_customers
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT 'orders', 'order_id', COUNT_BIG(*)
FROM (
    SELECT order_id
    FROM silver.olist_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT 'products', 'product_id', COUNT_BIG(*)
FROM (
    SELECT product_id
    FROM silver.olist_products
    GROUP BY product_id
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT 'sellers', 'seller_id', COUNT_BIG(*)
FROM (
    SELECT seller_id
    FROM silver.olist_sellers
    GROUP BY seller_id
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT 'order_items', 'order_id + order_item_id', COUNT_BIG(*)
FROM (
    SELECT order_id, order_item_id
    FROM silver.olist_order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT 'order_payments', 'order_id + payment_sequential', COUNT_BIG(*)
FROM (
    SELECT order_id, payment_sequential
    FROM silver.olist_order_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT 'order_reviews', 'review_id + order_id', COUNT_BIG(*)
FROM (
    SELECT review_id, order_id
    FROM silver.olist_order_reviews
    GROUP BY review_id, order_id
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT 'order_reviews', 'review_key', COUNT_BIG(*)
FROM (
    SELECT review_key
    FROM silver.olist_order_reviews
    GROUP BY review_key
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT 'geolocation', 'geolocation_key', COUNT_BIG(*)
FROM (
    SELECT geolocation_key
    FROM silver.olist_geolocation
    GROUP BY geolocation_key
    HAVING COUNT(*) > 1
) AS d

UNION ALL

SELECT 'category_translation', 'product_category_name', COUNT_BIG(*)
FROM (
    SELECT product_category_name
    FROM silver.olist_category_translation
    GROUP BY product_category_name
    HAVING COUNT(*) > 1
) AS d;