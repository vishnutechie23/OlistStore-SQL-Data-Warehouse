
USE OlistStore_DW;
GO

/*
===============================================================================
                    BRONZE LAYER - DATA QUALITY VALIDATION
===============================================================================

Purpose:
1. Check NULL values in important columns.
2. Identify duplicate primary and composite keys.
3. Check invalid numeric values.
4. Validate date and timestamp consistency.
5. Identify invalid or unexpected values.
6. Check data quality across all 9 Bronze tables.

Note:
- Bronze layer stores raw source data.
- NULL values in optional columns are not automatically errors.
- This script only reads data. It does not modify any table.

===============================================================================
*/


-- =============================================================================
-- 1. CUSTOMERS TABLE VALIDATION
-- =============================================================================

-- 1.1 Check total rows, unique customer IDs and NULL values

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_ids,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS null_unique_ids,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_codes,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS null_cities,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS null_states
FROM bronze.olist_customers;


-- 1.2 Check duplicate customer IDs

SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- 1.3 Check invalid customer state length

SELECT *
FROM bronze.olist_customers
WHERE customer_state IS NOT NULL
  AND LEN(customer_state) <> 2;


-- =============================================================================
-- 2. ORDERS TABLE VALIDATION
-- =============================================================================

-- 2.1 Check total rows, unique order IDs and NULL values

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_ids,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_order_status,
    SUM(CASE WHEN order_purchase_timestamp IS NULL THEN 1 ELSE 0 END) AS null_purchase_dates,
    SUM(CASE WHEN order_approved_at IS NULL THEN 1 ELSE 0 END) AS null_approval_dates,
    SUM(CASE WHEN order_delivered_customer_date IS NULL THEN 1 ELSE 0 END) AS null_delivery_dates
FROM bronze.olist_orders;


-- 2.2 Check duplicate order IDs

SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 2.3 Check invalid order statuses

SELECT
    order_status,
    COUNT(*) AS total_orders
FROM bronze.olist_orders
WHERE order_status NOT IN
(
    'delivered',
    'shipped',
    'canceled',
    'unavailable',
    'invoiced',
    'processing',
    'created',
    'approved'
)
OR order_status IS NULL
GROUP BY order_status;


-- 2.4 Check inconsistent order timestamps

SELECT *
FROM bronze.olist_orders
WHERE
    (order_approved_at IS NOT NULL
     AND order_approved_at < order_purchase_timestamp)

    OR

    (order_delivered_carrier_date IS NOT NULL
     AND order_delivered_carrier_date < order_purchase_timestamp)

    OR

    (order_delivered_customer_date IS NOT NULL
     AND order_delivered_customer_date < order_purchase_timestamp)

    OR

    (order_estimated_delivery_date IS NOT NULL
     AND order_estimated_delivery_date < order_purchase_timestamp);

--
SELECT
    SUM(CASE
        WHEN order_approved_at < order_purchase_timestamp
        THEN 1 ELSE 0
    END) AS invalid_approval_dates,

    SUM(CASE
        WHEN order_delivered_carrier_date < order_purchase_timestamp
        THEN 1 ELSE 0
    END) AS invalid_carrier_dates,

    SUM(CASE
        WHEN order_delivered_customer_date < order_purchase_timestamp
        THEN 1 ELSE 0
    END) AS invalid_customer_delivery_dates
FROM bronze.olist_orders;

-- 
SELECT
    COUNT(*) AS customer_delivery_before_carrier
FROM bronze.olist_orders
WHERE order_delivered_customer_date < order_delivered_carrier_date;

-- =============================================================================
-- 3. ORDER ITEMS TABLE VALIDATION
-- =============================================================================

-- 3.1 Check total rows, unique composite keys and NULL values

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) AS unique_item_keys,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS null_item_ids,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_ids,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_ids
FROM bronze.olist_order_items;


-- 3.2 Check duplicate composite keys

SELECT
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


-- 3.3 Check invalid item IDs and negative prices

SELECT *
FROM bronze.olist_order_items
WHERE order_item_id < 1
   OR price < 0
   OR freight_value < 0;


-- 3.4 Check NULL values in important numeric columns

SELECT
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_prices,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS null_freight_values
FROM bronze.olist_order_items;


-- =============================================================================
-- 4. ORDER PAYMENTS TABLE VALIDATION
-- =============================================================================

-- 4.1 Check total rows, unique composite keys and NULL values

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential)) AS unique_payment_keys,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) AS null_payment_sequences,
    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS null_payment_types,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS null_payment_values
FROM bronze.olist_order_payments;


-- 4.2 Check duplicate composite keys

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS duplicate_count
FROM bronze.olist_order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;


-- 4.3 Check invalid payment values

SELECT *
FROM bronze.olist_order_payments
WHERE payment_sequential < 1
   OR payment_installments < 0
   OR payment_value < 0;


-- 4.4 Check unexpected payment types

SELECT
    payment_type,
    COUNT(*) AS total_records
FROM bronze.olist_order_payments
WHERE payment_type NOT IN
(
    'credit_card',
    'boleto',
    'voucher',
    'debit_card',
    'not_defined'
)
OR payment_type IS NULL
GROUP BY payment_type;


-- =============================================================================
-- 5. ORDER REVIEWS TABLE VALIDATION
-- =============================================================================

-- 5.1 Check total rows, unique review IDs and NULL values

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id) AS unique_review_ids,
    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS null_review_ids,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS null_review_scores,
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS null_creation_dates,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS null_answer_dates
FROM bronze.olist_order_reviews;


-- 5.2 Check duplicate review IDs

SELECT
    review_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1;

-- exact duplicate 
SELECT
    COUNT(*) AS duplicate_review_id_groups,
    SUM(duplicate_count) AS rows_in_duplicate_groups,
    SUM(duplicate_count - 1) AS excess_duplicate_rows
FROM
(
    SELECT
        review_id,
        COUNT(*) AS duplicate_count
    FROM bronze.olist_order_reviews
    GROUP BY review_id
    HAVING COUNT(*) > 1
) AS duplicates;

-- 5.3 Check invalid review scores

SELECT *
FROM bronze.olist_order_reviews
WHERE review_score NOT BETWEEN 1 AND 5
   OR review_score IS NULL;


-- 5.4 Check inconsistent review timestamps

SELECT *
FROM bronze.olist_order_reviews
WHERE review_creation_date IS NOT NULL
  AND review_answer_timestamp IS NOT NULL
  AND review_answer_timestamp < review_creation_date;


-- =============================================================================
-- 6. PRODUCTS TABLE VALIDATION
-- =============================================================================

-- 6.1 Check total rows, unique product IDs and NULL values

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_ids,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_categories,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS null_weights,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS null_lengths,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS null_heights,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS null_widths
FROM bronze.olist_products;


-- 6.2 Check duplicate product IDs

SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_products
GROUP BY product_id
HAVING COUNT(*) > 1;


-- 6.3 Check invalid product measurements

SELECT *
FROM bronze.olist_products
WHERE product_name_lenght < 0
   OR product_description_lenght < 0
   OR product_photos_qty < 0
   OR product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;

-- 6.4 – Check zero or missing product dimensions.
SELECT
    SUM(CASE WHEN product_weight_g = 0 THEN 1 ELSE 0 END) AS zero_weights,
    SUM(CASE WHEN product_length_cm = 0 THEN 1 ELSE 0 END) AS zero_lengths,
    SUM(CASE WHEN product_height_cm = 0 THEN 1 ELSE 0 END) AS zero_heights,
    SUM(CASE WHEN product_width_cm = 0 THEN 1 ELSE 0 END) AS zero_widths
FROM bronze.olist_products;

-- 6.5 – Check product category values.
SELECT
    product_category_name,
    COUNT(*) AS product_count
FROM bronze.olist_products
GROUP BY product_category_name
ORDER BY product_count DESC;



-- =============================================================================
-- 7. SELLERS TABLE VALIDATION
-- =============================================================================

-- 7.1 Check total rows, unique seller IDs and NULL values

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_seller_ids,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_ids,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_codes,
    SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) AS null_cities,
    SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS null_states
FROM bronze.olist_sellers;


-- 7.2 Check duplicate seller IDs

SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- 7.3 Check invalid seller state length

SELECT *
FROM bronze.olist_sellers
WHERE seller_state IS NOT NULL
  AND LEN(seller_state) <> 2;


-- =============================================================================
-- 8. GEOLOCATION TABLE VALIDATION
-- =============================================================================

-- 8.1 Check total rows and NULL values

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_codes,
    SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS null_latitudes,
    SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS null_longitudes,
    SUM(CASE WHEN geolocation_city IS NULL THEN 1 ELSE 0 END) AS null_cities,
    SUM(CASE WHEN geolocation_state IS NULL THEN 1 ELSE 0 END) AS null_states
FROM bronze.olist_geolocation;


-- 8.2 Check invalid latitude and longitude values

SELECT *
FROM bronze.olist_geolocation
WHERE geolocation_lat NOT BETWEEN -90 AND 90
   OR geolocation_lng NOT BETWEEN -180 AND 180;


-- 8.3 Check duplicate geolocation records

SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS duplicate_count
FROM bronze.olist_geolocation
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1;

-- duplicate summary 
SELECT
    COUNT(*) AS duplicate_groups,
    SUM(duplicate_count) AS rows_in_duplicate_groups,
    SUM(duplicate_count - 1) AS excess_duplicate_rows
FROM
(
    SELECT COUNT(*) AS duplicate_count
    FROM bronze.olist_geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    HAVING COUNT(*) > 1
) AS duplicates;

-- =============================================================================
-- 9. CATEGORY TRANSLATION TABLE VALIDATION
-- =============================================================================

-- 9.1 Check total rows and NULL values

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_category_name) AS unique_category_names,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category_names,
    SUM(CASE WHEN product_category_name_english IS NULL THEN 1 ELSE 0 END) AS null_english_names
FROM bronze.olist_category_translation;


-- 9.2 Check duplicate category names

SELECT
    product_category_name,
    COUNT(*) AS duplicate_count
FROM bronze.olist_category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;


-- 9.3 Check missing English translations

SELECT *
FROM bronze.olist_category_translation
WHERE product_category_name_english IS NULL;


-- =============================================================================
-- 10. FINAL BRONZE LAYER ROW COUNT SUMMARY
-- =============================================================================

SELECT
    'olist_customers' AS table_name,
    COUNT(*) AS total_rows
FROM bronze.olist_customers

UNION ALL

SELECT 'olist_orders', COUNT(*)
FROM bronze.olist_orders

UNION ALL

SELECT 'olist_order_items', COUNT(*)
FROM bronze.olist_order_items

UNION ALL

SELECT 'olist_order_payments', COUNT(*)
FROM bronze.olist_order_payments

UNION ALL

SELECT 'olist_order_reviews', COUNT(*)
FROM bronze.olist_order_reviews

UNION ALL

SELECT 'olist_products', COUNT(*)
FROM bronze.olist_products

UNION ALL

SELECT 'olist_sellers', COUNT(*)
FROM bronze.olist_sellers

UNION ALL

SELECT 'olist_geolocation', COUNT(*)
FROM bronze.olist_geolocation

UNION ALL

SELECT 'olist_category_translation', COUNT(*)
FROM bronze.olist_category_translation;

GO

/*
===============================================================================
                         END OF BRONZE VALIDATION
===============================================================================
*/
