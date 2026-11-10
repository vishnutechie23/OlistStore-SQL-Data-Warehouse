USE OlistStore_DW;
GO

/*
    Project: OlistStore SQL Data Warehouse
    Layer: Silver
    Purpose: Data cleaning and transformation
*/

SET NOCOUNT ON;
GO

DECLARE @log_id BIGINT;

INSERT INTO audit.etl_execution_log
(
    pipeline_name,
    source_name,
    target_name,
    status
)
VALUES
(
    'Silver Customers Transformation',
    'bronze.olist_customers',
    'silver.olist_customers',
    'RUNNING'
);

SET @log_id = SCOPE_IDENTITY();

SELECT @log_id AS log_id;


-- Bronze Customers data validate 
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(*) - COUNT(customer_id) AS null_customer_ids,
    COUNT(*) - COUNT(customer_unique_id) AS null_unique_ids
FROM bronze.olist_customers;


-- Check blank values : Ab NULL ke saath empty strings bhi check karenge.
SELECT
    SUM(CASE WHEN LTRIM(RTRIM(customer_id)) = '' THEN 1 ELSE 0 END) AS blank_customer_ids,
    SUM(CASE WHEN LTRIM(RTRIM(customer_unique_id)) = '' THEN 1 ELSE 0 END) AS blank_unique_ids,
    SUM(CASE WHEN LTRIM(RTRIM(customer_city)) = '' THEN 1 ELSE 0 END) AS blank_cities,
    SUM(CASE WHEN LTRIM(RTRIM(customer_state)) = '' THEN 1 ELSE 0 END) AS blank_states
FROM bronze.olist_customers;


-- Load Silver Customers
INSERT INTO silver.olist_customers
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    LTRIM(RTRIM(customer_id)),
    LTRIM(RTRIM(customer_unique_id)),
    LTRIM(RTRIM(customer_zip_code_prefix)),
    LTRIM(RTRIM(customer_city)),
    UPPER(LTRIM(RTRIM(customer_state)))
FROM bronze.olist_customers;

SELECT @@ROWCOUNT AS rows_inserted;


/* What this does:
- Bronze se Silver mein data transfer.
- Leading/trailing spaces remove.
- State codes uppercase standardize.
- Original Bronze data unchanged rahega.
Expected
 rows_inserted = 99441*/

-- Verify silver customers
SELECT COUNT(*) AS silver_customer_rows
FROM silver.olist_customers;


-- ETL log
UPDATE audit.etl_execution_log
SET
    end_time_utc = SYSUTCDATETIME(),
    rows_read = (SELECT COUNT(*) FROM bronze.olist_customers),
    rows_inserted = (SELECT COUNT(*) FROM silver.olist_customers),
    status = 'SUCCESS'
WHERE log_id = 12;

SELECT *
FROM audit.etl_execution_log
WHERE log_id = 12;


-- Validate Bronze Orders : Ab Orders data validate karenge before transformation.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT o.order_id) AS unique_order_ids,
    SUM(CASE WHEN o.order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN o.customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_ids,
    SUM(CASE WHEN c.customer_id IS NULL THEN 1 ELSE 0 END) AS unmatched_customers
FROM bronze.olist_orders o
LEFT JOIN silver.olist_customers c
    ON o.customer_id = c.customer_id;

-- Check Blank Values
SELECT
    SUM(CASE WHEN LTRIM(RTRIM(order_id)) = '' THEN 1 ELSE 0 END) AS blank_order_ids,
    SUM(CASE WHEN LTRIM(RTRIM(customer_id)) = '' THEN 1 ELSE 0 END) AS blank_customer_ids,
    SUM(CASE WHEN LTRIM(RTRIM(order_status)) = '' THEN 1 ELSE 0 END) AS blank_order_status
FROM bronze.olist_orders;



-- Check Order Status Values Transformation se pehle available order statuses check karenge.
SELECT
    order_status,
    COUNT(*) AS total_orders
FROM bronze.olist_orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Load Silver Orders : Ab Bronze se Silver mein data transform aur load karo:
INSERT INTO silver.olist_orders
(
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
)
SELECT
    LTRIM(RTRIM(order_id)),
    LTRIM(RTRIM(customer_id)),
    LOWER(LTRIM(RTRIM(order_status))),
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM bronze.olist_orders;

SELECT @@ROWCOUNT AS rows_inserted;

/*
What this does:
- IDs ke extra spaces remove karta hai.
- Order status lowercase standardize karta hai.
- Date columns as-is preserve karta hai, including legitimate NULL values.
- Foreign Key relationship enforce karta hai.*/

-- Verify Silver Orders
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM silver.olist_orders;

-- ETL logs 
EXEC audit.usp_finish_etl_log
    @log_id = 13,
    @rows_read = 99441,
    @rows_inserted = 99441,
    @rows_updated = 0,
    @rows_rejected = 0;

UPDATE audit.etl_execution_log
SET
    end_time_utc = SYSUTCDATETIME(),
    status = 'FAILED',
    error_message = 'Incomplete duplicate logging attempt. Successful Customers load recorded under log_id 12.'
WHERE log_id IN (11, 14, 15)
  AND status = 'RUNNING';

SELECT
    log_id,
    pipeline_name,
    source_name,
    target_name,
    rows_read,
    rows_inserted,
    rows_updated,
    rows_rejected,
    status,
    start_time_utc,
    end_time_utc,
    error_message
FROM audit.etl_execution_log
ORDER BY log_id;

EXEC audit.usp_start_etl_log
    @pipeline_name = 'Silver Products Transformation',
    @source_name = 'bronze.olist_products',
    @target_name = 'silver.olist_products';


-- Validate Bronze Products
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_ids,
    COUNT(*) - COUNT(product_id) AS null_product_count
FROM bronze.olist_products;

-- Check blank values
SELECT
    SUM(CASE WHEN LTRIM(RTRIM(product_id)) = '' THEN 1 ELSE 0 END) AS blank_product_ids,
    SUM(CASE WHEN LTRIM(RTRIM(product_category_name)) = '' THEN 1 ELSE 0 END) AS blank_categories,
    SUM(CASE WHEN LTRIM(RTRIM(product_name_lenght)) = '' THEN 1 ELSE 0 END) AS blank_name_lengths
FROM bronze.olist_products;

-- Check product category translation coverage
-- We need to identify categories that don't have an English translation.

SELECT
    p.product_category_name,
    COUNT(*) AS product_count
FROM bronze.olist_products p
LEFT JOIN bronze.olist_category_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
GROUP BY p.product_category_name;

-- Check numeric columns for invalid values
SELECT
    SUM(CASE WHEN product_name_lenght < 0 THEN 1 ELSE 0 END) AS invalid_name_length,
    SUM(CASE WHEN product_description_lenght < 0 THEN 1 ELSE 0 END) AS invalid_description_length,
    SUM(CASE WHEN product_photos_qty < 0 THEN 1 ELSE 0 END) AS invalid_photos_qty,
    SUM(CASE WHEN product_weight_g < 0 THEN 1 ELSE 0 END) AS invalid_weight,
    SUM(CASE WHEN product_length_cm < 0 THEN 1 ELSE 0 END) AS invalid_length,
    SUM(CASE WHEN product_height_cm < 0 THEN 1 ELSE 0 END) AS invalid_height,
    SUM(CASE WHEN product_width_cm < 0 THEN 1 ELSE 0 END) AS invalid_width
FROM bronze.olist_products;


-- Load Silver Products 
INSERT INTO silver.olist_products
(
    product_id,
    product_category_name,
    product_category_name_english,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    LTRIM(RTRIM(p.product_id)),
    LTRIM(RTRIM(p.product_category_name)),
    LTRIM(RTRIM(t.product_category_name_english)),
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM bronze.olist_products p
LEFT JOIN bronze.olist_category_translation t
    ON p.product_category_name = t.product_category_name;

SELECT @@ROWCOUNT AS rows_inserted;

-- verify pdts
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS unique_products
FROM silver.olist_products;

SELECT * FROM silver.olist_products
WHERE product_category_name_english = 'auto'

-- Why LEFT JOIN? It preserves all 32,951 products, including the 13 without translations.

-- comlete ETL logs
EXEC audit.usp_finish_etl_log
    @log_id = 16,
    @rows_read = 32951,
    @rows_inserted = 32951,
    @rows_updated = 0,
    @rows_rejected = 0;


-- start ETL
EXEC audit.usp_start_etl_log
    @pipeline_name = 'Silver Sellers Transformation',
    @source_name = 'bronze.olist_sellers',
    @target_name = 'silver.olist_sellers';

-- Validate Bronze Sellers
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_seller_ids,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_ids,
    COUNT(*) - COUNT(seller_id) AS null_seller_count
FROM bronze.olist_sellers;

-- chcek blanks values
SELECT
    SUM(CASE WHEN LTRIM(RTRIM(seller_id)) = '' THEN 1 ELSE 0 END) AS blank_seller_ids,
    SUM(CASE WHEN LTRIM(RTRIM(seller_city)) = '' THEN 1 ELSE 0 END) AS blank_cities,
    SUM(CASE WHEN LTRIM(RTRIM(seller_state)) = '' THEN 1 ELSE 0 END) AS blank_states
FROM bronze.olist_sellers;

-- check sellers zip codes 
SELECT
    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_codes,
    SUM(CASE WHEN LTRIM(RTRIM(seller_zip_code_prefix)) = '' THEN 1 ELSE 0 END) AS blank_zip_codes,
    MIN(LEN(seller_zip_code_prefix)) AS min_zip_length,
    MAX(LEN(seller_zip_code_prefix)) AS max_zip_length
FROM bronze.olist_sellers;


-- Load Silver Sellers
INSERT INTO silver.olist_sellers
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    LTRIM(RTRIM(seller_id)),
    LTRIM(RTRIM(seller_zip_code_prefix)),
    LOWER(LTRIM(RTRIM(seller_city))),
    UPPER(LTRIM(RTRIM(seller_state)))
FROM bronze.olist_sellers;

SELECT @@ROWCOUNT AS rows_inserted;

-- verify 
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS unique_sellers
FROM silver.olist_sellers;

-- complete etl log 
EXEC audit.usp_finish_etl_log
    @log_id = 17,
    @rows_read = 3095,
    @rows_inserted = 3095,
    @rows_updated = 0,
    @rows_rejected = 0;



-- Silver Order Items Transformation

-- Start ETL log
EXEC audit.usp_start_etl_log
    @pipeline_name = 'Silver Order Items Transformation',
    @source_name = 'bronze.olist_order_items',
    @target_name = 'silver.olist_order_items';


-- Validate Bronze Order Items
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) AS unique_order_items,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN order_item_id IS NULL THEN 1 ELSE 0 END) AS null_item_ids,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_ids,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_ids
FROM bronze.olist_order_items;

-- Validate foreign key references : Check whether all orders, products, and sellers exist in Silver.
SELECT
    SUM(CASE WHEN o.order_id IS NULL THEN 1 ELSE 0 END) AS unmatched_orders,
    SUM(CASE WHEN p.product_id IS NULL THEN 1 ELSE 0 END) AS unmatched_products,
    SUM(CASE WHEN s.seller_id IS NULL THEN 1 ELSE 0 END) AS unmatched_sellers
FROM bronze.olist_order_items i
LEFT JOIN silver.olist_orders o
    ON i.order_id = o.order_id
LEFT JOIN silver.olist_products p
    ON i.product_id = p.product_id
LEFT JOIN silver.olist_sellers s
    ON i.seller_id = s.seller_id;


-- Check blank IDs
SELECT
    SUM(CASE WHEN LTRIM(RTRIM(order_id)) = '' THEN 1 ELSE 0 END) AS blank_order_ids,
    SUM(CASE WHEN LTRIM(RTRIM(product_id)) = '' THEN 1 ELSE 0 END) AS blank_product_ids,
    SUM(CASE WHEN LTRIM(RTRIM(seller_id)) = '' THEN 1 ELSE 0 END) AS blank_seller_ids
FROM bronze.olist_order_items;

-- Check price and freight values
SELECT
    SUM(CASE WHEN price < 0 THEN 1 ELSE 0 END) AS negative_prices,
    SUM(CASE WHEN freight_value < 0 THEN 1 ELSE 0 END) AS negative_freight,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_prices,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS null_freight
FROM bronze.olist_order_items;


-- Load Silver Order Items
INSERT INTO silver.olist_order_items
(
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value
)
SELECT
    LTRIM(RTRIM(order_id)),
    order_item_id,
    LTRIM(RTRIM(product_id)),
    LTRIM(RTRIM(seller_id)),
    shipping_limit_date,
    price,
    freight_value
FROM bronze.olist_order_items;

SELECT @@ROWCOUNT AS rows_inserted;


-- Verify Silver Order Items
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) AS unique_order_items
FROM silver.olist_order_items;

-- comlete etllog s
EXEC audit.usp_finish_etl_log
    @log_id = 21,
    @rows_read = 112650,
    @rows_inserted = 112650,
    @rows_updated = 0,
    @rows_rejected = 0;

-- Silver Order Payments Transformation
EXEC audit.usp_start_etl_log
    @pipeline_name = 'Silver Order Payments Transformation',
    @source_name = 'bronze.olist_order_payments',
    @target_name = 'silver.olist_order_payments';

-- Validate Bronze Order Payments
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential)) AS unique_payments,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids,
    SUM(CASE WHEN payment_sequential IS NULL THEN 1 ELSE 0 END) AS null_sequential_ids
FROM bronze.olist_order_payments;

-- Validate Order References
SELECT
    SUM(CASE WHEN o.order_id IS NULL THEN 1 ELSE 0 END) AS unmatched_orders
FROM bronze.olist_order_payments p
LEFT JOIN silver.olist_orders o
    ON p.order_id = o.order_id;

-- Check payment values
SELECT
    SUM(CASE WHEN payment_value < 0 THEN 1 ELSE 0 END) AS negative_payments,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS null_payments,
    SUM(CASE WHEN payment_installments < 0 THEN 1 ELSE 0 END) AS negative_installments,
    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS null_payment_types
FROM bronze.olist_order_payments;

-- Check payment types
SELECT
    payment_type,
    COUNT(*) AS payment_count
FROM bronze.olist_order_payments
GROUP BY payment_type
ORDER BY payment_count DESC;

-- Load Silver Order Payments
INSERT INTO silver.olist_order_payments
(
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    LTRIM(RTRIM(order_id)),
    payment_sequential,
    LOWER(LTRIM(RTRIM(payment_type))),
    payment_installments,
    payment_value
FROM bronze.olist_order_payments;

SELECT @@ROWCOUNT AS rows_inserted;

-- verify
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(order_id, '-', payment_sequential)) AS unique_payments
FROM silver.olist_order_payments;

-- comppete etl log s
EXEC audit.usp_finish_etl_log
    @log_id = 26,
    @rows_read = 103886,
    @rows_inserted = 103886,
    @rows_updated = 0,
    @rows_rejected = 0;

-- Silver orders reviews
EXEC audit.usp_start_etl_log
    @pipeline_name = 'Silver Order Reviews Transformation',
    @source_name = 'bronze.olist_order_reviews',
    @target_name = 'silver.olist_order_reviews';

-- Validate Bronze Order Reviews
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(review_id, '-', order_id)) AS unique_reviews,
    SUM(CASE WHEN review_id IS NULL THEN 1 ELSE 0 END) AS null_review_ids,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_ids
FROM bronze.olist_order_reviews;

-- Validate Order References
SELECT
    SUM(CASE WHEN o.order_id IS NULL THEN 1 ELSE 0 END) AS unmatched_orders
FROM bronze.olist_order_reviews r
LEFT JOIN silver.olist_orders o
    ON r.order_id = o.order_id;

-- Validate Review Scores
SELECT
    MIN(review_score) AS min_score,
    MAX(review_score) AS max_score,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS null_scores,
    SUM(CASE WHEN review_score NOT BETWEEN 1 AND 5 THEN 1 ELSE 0 END) AS invalid_scores
FROM bronze.olist_order_reviews; 

-- Check review dates
SELECT
    SUM(CASE WHEN review_creation_date IS NULL THEN 1 ELSE 0 END) AS null_creation_dates,
    SUM(CASE WHEN review_answer_timestamp IS NULL THEN 1 ELSE 0 END) AS null_answer_dates,
    SUM(CASE
        WHEN review_answer_timestamp < review_creation_date THEN 1
        ELSE 0
    END) AS invalid_date_sequence
FROM bronze.olist_order_reviews;


-- Check comment NULLs We already know comments have many NULLs. Let's confirm both columns.
SELECT
    SUM(CASE WHEN review_comment_title IS NULL THEN 1 ELSE 0 END) AS null_titles,
    SUM(CASE WHEN review_comment_message IS NULL THEN 1 ELSE 0 END) AS null_messages,
    SUM(CASE WHEN LTRIM(RTRIM(review_comment_title)) = '' THEN 1 ELSE 0 END) AS blank_titles,
    SUM(CASE WHEN LTRIM(RTRIM(review_comment_message)) = '' THEN 1 ELSE 0 END) AS blank_messages
FROM bronze.olist_order_reviews;

-- Load Silver Order Reviews
SELECT
    COUNT_BIG(*) AS total_rows,
    COUNT_BIG(DISTINCT review_key) AS unique_review_keys
FROM silver.olist_order_reviews;

--
SELECT COUNT_BIG(*) AS records_to_fix
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

-- load 18 rows
UPDATE silver.olist_order_reviews
SET review_comment_message = NULL
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

SELECT @@ROWCOUNT AS rows_updated;

-- Load Silver Order Reviews
INSERT INTO silver.olist_order_reviews
(
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp
)
SELECT
    LTRIM(RTRIM(review_id)),
    LTRIM(RTRIM(order_id)),
    review_score,
    NULLIF(LTRIM(RTRIM(review_comment_title)), ''),
    NULLIF(
        LTRIM(RTRIM(
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
        )),
        ''
    ),
    review_creation_date,
    review_answer_timestamp
FROM bronze.olist_order_reviews;

SELECT @@ROWCOUNT AS rows_inserted;

-- Verify Silver Order Reviews
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_key) AS unique_review_keys,
    COUNT(DISTINCT CONCAT(review_id, '-', order_id)) AS unique_reviews
FROM silver.olist_order_reviews;


-- Silver Geolocation Transformation
-- Validate Bronze Geolocation
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CONCAT(geolocation_zip_code_prefix, '-', geolocation_lat, '-', geolocation_lng)) AS unique_location_records,
    SUM(CASE WHEN geolocation_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip_codes,
    SUM(CASE WHEN geolocation_lat IS NULL THEN 1 ELSE 0 END) AS null_latitudes,
    SUM(CASE WHEN geolocation_lng IS NULL THEN 1 ELSE 0 END) AS null_longitudes
FROM bronze.olist_geolocation;

-- Check exact duplicate records
SELECT
    COUNT(*) AS duplicate_groups,
    SUM(duplicate_count - 1) AS extra_duplicate_rows
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
) d;

-- Check coordinate ranges
SELECT
    MIN(geolocation_lat) AS min_latitude,
    MAX(geolocation_lat) AS max_latitude,
    MIN(geolocation_lng) AS min_longitude,
    MAX(geolocation_lng) AS max_longitude
FROM bronze.olist_geolocation;

-- Count coordinates outside Brazil's approximate bounds
SELECT
    SUM(CASE
        WHEN geolocation_lat NOT BETWEEN -34 AND 5.3
        THEN 1 ELSE 0
    END) AS out_of_range_latitudes,

    SUM(CASE
        WHEN geolocation_lng NOT BETWEEN -74 AND -34
        THEN 1 ELSE 0
    END) AS out_of_range_longitudes
FROM bronze.olist_geolocation;

-- View suspicious coordinates
SELECT TOP 20
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM bronze.olist_geolocation
WHERE geolocation_lat NOT BETWEEN -34 AND 5.3
   OR geolocation_lng NOT BETWEEN -74 AND -34;

-- Recheck using wider Brazil bounds
SELECT
    COUNT(*) AS invalid_coordinate_rows
FROM bronze.olist_geolocation
WHERE geolocation_lat NOT BETWEEN -34.0 AND 5.3
   OR geolocation_lng NOT BETWEEN -74.0 AND -32.0;

-- Recheck with corrected bounds
SELECT
    COUNT(*) AS suspicious_rows
FROM bronze.olist_geolocation
WHERE geolocation_lat NOT BETWEEN -34.0 AND 5.3
   OR geolocation_lng NOT BETWEEN -74.0 AND -32.5;

-- Recheck with corrected bounds
SELECT
    COUNT(*) AS suspicious_rows
FROM bronze.olist_geolocation
WHERE geolocation_lat NOT BETWEEN -34.0 AND 5.3
   OR geolocation_lng NOT BETWEEN -74.0 AND -32.5;

-- Separate latitude and longitude violations

SELECT
    SUM(CASE WHEN geolocation_lat NOT BETWEEN -34.0 AND 5.3
        THEN 1 ELSE 0 END) AS invalid_latitudes,

    SUM(CASE WHEN geolocation_lng NOT BETWEEN -74.0 AND -32.5
        THEN 1 ELSE 0 END) AS invalid_longitudes,

    SUM(CASE
        WHEN geolocation_lat NOT BETWEEN -34.0 AND 5.3
         AND geolocation_lng NOT BETWEEN -74.0 AND -32.5
        THEN 1 ELSE 0 END) AS both_invalid
FROM bronze.olist_geolocation;

-- Inspect all 42 records
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM bronze.olist_geolocation
WHERE geolocation_lat NOT BETWEEN -34.0 AND 5.3
   OR geolocation_lng NOT BETWEEN -74.0 AND -32.0
ORDER BY geolocation_state, geolocation_zip_code_prefix;

-- Check affected ZIP prefixes
WITH ZipCheck AS
(
    SELECT
        geolocation_zip_code_prefix,
        SUM(CASE
            WHEN geolocation_lat BETWEEN -34.0 AND 5.3
             AND geolocation_lng BETWEEN -74.0 AND -32.0
            THEN 1 ELSE 0
        END) AS valid_records,
        SUM(CASE
            WHEN geolocation_lat NOT BETWEEN -34.0 AND 5.3
              OR geolocation_lng NOT BETWEEN -74.0 AND -32.0
            THEN 1 ELSE 0
        END) AS invalid_records
    FROM bronze.olist_geolocation
    GROUP BY geolocation_zip_code_prefix
)
SELECT
    COUNT(*) AS affected_zip_prefixes,
    SUM(CASE WHEN valid_records > 0 THEN 1 ELSE 0 END) AS prefixes_with_valid_records,
    SUM(CASE WHEN valid_records = 0 THEN 1 ELSE 0 END) AS prefixes_with_only_invalid_records
FROM ZipCheck
WHERE invalid_records > 0;

-- Check valid records per affected ZIP
SELECT
    geolocation_zip_code_prefix,
    COUNT(*) AS valid_records
FROM bronze.olist_geolocation
WHERE geolocation_lat BETWEEN -34.0 AND 5.3
  AND geolocation_lng BETWEEN -74.0 AND -32.0
  AND geolocation_zip_code_prefix IN
  (
      SELECT DISTINCT geolocation_zip_code_prefix
      FROM bronze.olist_geolocation
      WHERE geolocation_lat NOT BETWEEN -34.0 AND 5.3
         OR geolocation_lng NOT BETWEEN -74.0 AND -32.0
  )
GROUP BY geolocation_zip_code_prefix
ORDER BY geolocation_zip_code_prefix;

WITH ZipCheck AS
(
    SELECT
        geolocation_zip_code_prefix,
        SUM(CASE
            WHEN geolocation_lat BETWEEN -34.0 AND 5.3
             AND geolocation_lng BETWEEN -74.0 AND -32.5
            THEN 1 ELSE 0
        END) AS valid_records,
        SUM(CASE
            WHEN geolocation_lat NOT BETWEEN -34.0 AND 5.3
              OR geolocation_lng NOT BETWEEN -74.0 AND -32.5
            THEN 1 ELSE 0
        END) AS invalid_records
    FROM bronze.olist_geolocation
    GROUP BY geolocation_zip_code_prefix
)
SELECT
    COUNT(*) AS affected_zip_prefixes,
    SUM(CASE WHEN valid_records > 0 THEN 1 ELSE 0 END) AS prefixes_with_valid_records,
    SUM(CASE WHEN valid_records = 0 THEN 1 ELSE 0 END) AS prefixes_with_only_invalid_records
FROM ZipCheck
WHERE invalid_records > 0;

WITH ZipCheck AS
(
    SELECT
        geolocation_zip_code_prefix
    FROM bronze.olist_geolocation
    GROUP BY geolocation_zip_code_prefix
    HAVING SUM(CASE
        WHEN geolocation_lat BETWEEN -34.0 AND 5.3
         AND geolocation_lng BETWEEN -74.0 AND -32.5
        THEN 1 ELSE 0
    END) = 0
)
SELECT DISTINCT
    g.geolocation_zip_code_prefix,
    g.geolocation_lat,
    g.geolocation_lng,
    g.geolocation_city,
    g.geolocation_state
FROM bronze.olist_geolocation g
INNER JOIN ZipCheck z
    ON g.geolocation_zip_code_prefix = z.geolocation_zip_code_prefix
ORDER BY g.geolocation_zip_code_prefix;

-- count
SELECT
    COUNT(*) AS total_records,
    SUM(CASE
        WHEN geolocation_lat BETWEEN -34.0 AND 5.3
         AND geolocation_lng BETWEEN -74.0 AND -32.0
        THEN 1 ELSE 0
    END) AS valid_records,
    SUM(CASE
        WHEN geolocation_lat NOT BETWEEN -34.0 AND 5.3
          OR geolocation_lng NOT BETWEEN -74.0 AND -32.0
        THEN 1 ELSE 0
    END) AS suspicious_records
FROM bronze.olist_geolocation;

-- Insert into Silver
INSERT INTO silver.olist_geolocation
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT DISTINCT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    LOWER(LTRIM(RTRIM(geolocation_city))),
    UPPER(LTRIM(RTRIM(geolocation_state)))
FROM bronze.olist_geolocation
WHERE geolocation_lat BETWEEN -34.0 AND 5.3
  AND geolocation_lng BETWEEN -74.0 AND -32.5;

-- verify
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_prefixes,
    SUM(CASE
        WHEN geolocation_lat NOT BETWEEN -34.0 AND 5.3
          OR geolocation_lng NOT BETWEEN -74.0 AND -32.5
        THEN 1 ELSE 0
    END) AS suspicious_coordinates
FROM silver.olist_geolocation;

-- Etl logs
EXEC audit.usp_finish_etl_log
    @log_id = 35,
    @rows_read = 1000163,
    @rows_inserted = 738267,
    @rows_updated = 0,
    @rows_rejected = 261896;



-- Category Translation
-- Pehle Bronze table ka data check karenge.

SELECT *
FROM bronze.olist_category_translation
ORDER BY product_category_name;

-- Check duplicate and NULL values
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_category_name) AS unique_categories,
    SUM(CASE WHEN product_category_name IS NULL
        OR LTRIM(RTRIM(product_category_name)) = ''
        THEN 1 ELSE 0 END) AS invalid_category_names,
    SUM(CASE WHEN product_category_name_english IS NULL
        OR LTRIM(RTRIM(product_category_name_english)) = ''
        THEN 1 ELSE 0 END) AS invalid_english_names
FROM bronze.olist_category_translation;

-- Insert into Silver
INSERT INTO silver.olist_category_translation
(
    product_category_name,
    product_category_name_english
)
SELECT
    LOWER(LTRIM(RTRIM(product_category_name))),
    LOWER(LTRIM(RTRIM(product_category_name_english)))
FROM bronze.olist_category_translation;

-- Verify Silver Category Translation
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_category_name) AS unique_categories,
    SUM(CASE WHEN product_category_name_english IS NULL
        THEN 1 ELSE 0 END) AS null_english_names
FROM silver.olist_category_translation;




-- 
SELECT
    COUNT_BIG(*) AS total_rows,
    COUNT_BIG(*) - COUNT_BIG(*)
        AS check_value
FROM silver.olist_geolocation;

SELECT COUNT_BIG(*) AS distinct_records
FROM
(
    SELECT DISTINCT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    FROM silver.olist_geolocation
) AS d;

DELETE FROM silver.olist_geolocation;

INSERT INTO silver.olist_geolocation
(
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
)
SELECT DISTINCT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    LOWER(LTRIM(RTRIM(geolocation_city))),
    UPPER(LTRIM(RTRIM(geolocation_state)))
FROM bronze.olist_geolocation
WHERE geolocation_lat BETWEEN -34.0 AND 5.3
  AND geolocation_lng BETWEEN -74.0 AND -32.5;



SELECT
    COUNT_BIG(*) AS total_rows,
    COUNT_BIG(*) - COUNT_BIG(DISTINCT geolocation_key) AS duplicate_keys
FROM silver.olist_geolocation;

SELECT COUNT_BIG(*) AS distinct_records
FROM
(
    SELECT DISTINCT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    FROM silver.olist_geolocation
) AS d;

SELECT
    log_id,
    rows_read,
    rows_inserted,
    rows_rejected,
    status
FROM audit.etl_execution_log
WHERE log_id = 35;

-- silver table row counts
SELECT 'customers' AS table_name, COUNT_BIG(*) AS total_rows FROM silver.olist_customers
UNION ALL
SELECT 'orders', COUNT_BIG(*) FROM silver.olist_orders
UNION ALL
SELECT 'products', COUNT_BIG(*) FROM silver.olist_products
UNION ALL
SELECT 'sellers', COUNT_BIG(*) FROM silver.olist_sellers
UNION ALL
SELECT 'order_items', COUNT_BIG(*) FROM silver.olist_order_items
UNION ALL
SELECT 'order_payments', COUNT_BIG(*) FROM silver.olist_order_payments
UNION ALL
SELECT 'order_reviews', COUNT_BIG(*) FROM silver.olist_order_reviews
UNION ALL
SELECT 'geolocation', COUNT_BIG(*) FROM silver.olist_geolocation
UNION ALL
SELECT 'category_translation', COUNT_BIG(*) FROM silver.olist_category_translation;

-- final 
SELECT
    'customers' AS table_name,
    COUNT_BIG(*) - COUNT_BIG(DISTINCT customer_id) AS duplicate_keys
FROM silver.olist_customers

UNION ALL
SELECT 'orders',
    COUNT_BIG(*) - COUNT_BIG(DISTINCT order_id)
FROM silver.olist_orders

UNION ALL
SELECT 'products',
    COUNT_BIG(*) - COUNT_BIG(DISTINCT product_id)
FROM silver.olist_products

UNION ALL
SELECT 'sellers',
    COUNT_BIG(*) - COUNT_BIG(DISTINCT seller_id)
FROM silver.olist_sellers

UNION ALL
SELECT 'order_items',
    COUNT_BIG(*) - COUNT_BIG(DISTINCT CONCAT(order_id, '-', order_item_id))
FROM silver.olist_order_items

UNION ALL
SELECT 'order_payments',
    COUNT_BIG(*) - COUNT_BIG(DISTINCT CONCAT(order_id, '-', payment_sequential))
FROM silver.olist_order_payments

UNION ALL
SELECT 'order_reviews',
    COUNT_BIG(*) - COUNT_BIG(DISTINCT CONCAT(review_id, '-', order_id))
FROM silver.olist_order_reviews

UNION ALL
SELECT 'category_translation',
    COUNT_BIG(*) - COUNT_BIG(DISTINCT product_category_name)
FROM silver.olist_category_translation;

-- foreign key validation

SELECT 'orders -> customers' AS relationship,
       COUNT_BIG(*) AS unmatched_rows
FROM silver.olist_orders o
LEFT JOIN silver.olist_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL

UNION ALL

SELECT 'order_items -> orders',
       COUNT_BIG(*)
FROM silver.olist_order_items i
LEFT JOIN silver.olist_orders o
    ON i.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'order_items -> products',
       COUNT_BIG(*)
FROM silver.olist_order_items i
LEFT JOIN silver.olist_products p
    ON i.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT 'order_items -> sellers',
       COUNT_BIG(*)
FROM silver.olist_order_items i
LEFT JOIN silver.olist_sellers s
    ON i.seller_id = s.seller_id
WHERE s.seller_id IS NULL

UNION ALL

SELECT 'payments -> orders',
       COUNT_BIG(*)
FROM silver.olist_order_payments p
LEFT JOIN silver.olist_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 'reviews -> orders',
       COUNT_BIG(*)
FROM silver.olist_order_reviews r
LEFT JOIN silver.olist_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- NULL and blank value validation We'll check required columns across Silver tables.
SELECT 'customers.customer_id' AS column_name,
       COUNT_BIG(*) AS null_count
FROM silver.olist_customers
WHERE customer_id IS NULL

UNION ALL
SELECT 'orders.order_id', COUNT_BIG(*)
FROM silver.olist_orders
WHERE order_id IS NULL

UNION ALL
SELECT 'order_items.order_id', COUNT_BIG(*)
FROM silver.olist_order_items
WHERE order_id IS NULL

UNION ALL
SELECT 'order_items.product_id', COUNT_BIG(*)
FROM silver.olist_order_items
WHERE product_id IS NULL

UNION ALL
SELECT 'order_items.seller_id', COUNT_BIG(*)
FROM silver.olist_order_items
WHERE seller_id IS NULL

UNION ALL
SELECT 'payments.order_id', COUNT_BIG(*)
FROM silver.olist_order_payments
WHERE order_id IS NULL

UNION ALL
SELECT 'reviews.order_id', COUNT_BIG(*)
FROM silver.olist_order_reviews
WHERE order_id IS NULL

UNION ALL
SELECT 'products.product_id', COUNT_BIG(*)
FROM silver.olist_products
WHERE product_id IS NULL

UNION ALL
SELECT 'sellers.seller_id', COUNT_BIG(*)
FROM silver.olist_sellers
WHERE seller_id IS NULL;


-- Check transaction table IDs
SELECT 'order_items' AS table_name,
       SUM(CASE WHEN order_id IS NULL OR product_id IS NULL OR seller_id IS NULL
                THEN 1 ELSE 0 END) AS invalid_rows
FROM silver.olist_order_items

UNION ALL
SELECT 'order_payments',
       SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)
FROM silver.olist_order_payments

UNION ALL
SELECT 'order_reviews',
       SUM(CASE WHEN review_id IS NULL OR order_id IS NULL
                THEN 1 ELSE 0 END)
FROM silver.olist_order_reviews

UNION ALL
SELECT 'category_translation',
       SUM(CASE WHEN product_category_name IS NULL
                  OR product_category_name_english IS NULL
                THEN 1 ELSE 0 END)
FROM silver.olist_category_translation;

-- Numeric data quality checks We'll check negative prices, freight, payment values, review scores and product dimensions.
SELECT 'order_items_invalid' AS check_name, COUNT_BIG(*) AS invalid_rows
FROM silver.olist_order_items
WHERE price < 0 OR freight_value < 0

UNION ALL
SELECT 'payments_invalid', COUNT_BIG(*)
FROM silver.olist_order_payments
WHERE payment_value < 0 OR payment_installments < 0

UNION ALL
SELECT 'reviews_invalid', COUNT_BIG(*)
FROM silver.olist_order_reviews
WHERE review_score NOT BETWEEN 1 AND 5

UNION ALL
SELECT 'products_invalid', COUNT_BIG(*)
FROM silver.olist_products
WHERE product_name_length < 0
   OR product_description_length < 0
   OR product_photos_qty < 0
   OR product_weight_g < 0
   OR product_length_cm < 0
   OR product_height_cm < 0
   OR product_width_cm < 0;

-- Date validation We'll check whether order dates have an invalid sequence.
SELECT
    COUNT_BIG(*) AS invalid_date_sequences
FROM silver.olist_orders
WHERE
    (order_approved_at < order_purchase_timestamp)
    OR (order_delivered_carrier_date < order_purchase_timestamp)
    OR (order_delivered_customer_date < order_delivered_carrier_date)
    OR (order_estimated_delivery_date < order_purchase_timestamp);

-- Inspect problematic orders
SELECT TOP 20
    order_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    CASE WHEN order_approved_at < order_purchase_timestamp
         THEN 1 ELSE 0 END AS approval_issue,
    CASE WHEN order_delivered_carrier_date < order_purchase_timestamp
         THEN 1 ELSE 0 END AS carrier_issue,
    CASE WHEN order_delivered_customer_date < order_delivered_carrier_date
         THEN 1 ELSE 0 END AS delivery_issue,
    CASE WHEN order_estimated_delivery_date < order_purchase_timestamp
         THEN 1 ELSE 0 END AS estimate_issue
FROM silver.olist_orders
WHERE
    order_approved_at < order_purchase_timestamp
    OR order_delivered_carrier_date < order_purchase_timestamp
    OR order_delivered_customer_date < order_delivered_carrier_date
    OR order_estimated_delivery_date < order_purchase_timestamp;

-- Count each issue separately
SELECT
    SUM(CASE WHEN order_approved_at < order_purchase_timestamp
        THEN 1 ELSE 0 END) AS approval_issues,

    SUM(CASE WHEN order_delivered_carrier_date < order_purchase_timestamp
        THEN 1 ELSE 0 END) AS carrier_issues,

    SUM(CASE WHEN order_delivered_customer_date < order_delivered_carrier_date
        THEN 1 ELSE 0 END) AS delivery_issues,

    SUM(CASE WHEN order_estimated_delivery_date < order_purchase_timestamp
        THEN 1 ELSE 0 END) AS estimate_issues

FROM silver.olist_orders;

-- Check order status vs delivery dates
SELECT
    order_status,
    COUNT_BIG(*) AS total_orders,
    SUM(CASE WHEN order_delivered_customer_date IS NOT NULL
        THEN 1 ELSE 0 END) AS delivered_date_present,
    SUM(CASE WHEN order_delivered_customer_date IS NULL
        THEN 1 ELSE 0 END) AS delivered_date_missing
FROM silver.olist_orders
GROUP BY order_status
ORDER BY order_status;

-- Investigate the 8 delivered orders with missing delivery dates.
SELECT
    order_id,
    order_status,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date
FROM silver.olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- Check canceled orders with delivery dates
SELECT
    order_id,
    order_purchase_timestamp,
    order_delivered_carrier_date,
    order_delivered_customer_date
FROM silver.olist_orders
WHERE order_status = 'canceled'
  AND (
      order_delivered_carrier_date IS NOT NULL
      OR order_delivered_customer_date IS NOT NULL
  );

-- Verify the exact counts
SELECT
    COUNT_BIG(*) AS canceled_orders_with_carrier_date,
    SUM(CASE
        WHEN order_delivered_customer_date IS NOT NULL
        THEN 1 ELSE 0
    END) AS canceled_orders_with_customer_delivery_date
FROM silver.olist_orders
WHERE order_status = 'canceled'
  AND (
      order_delivered_carrier_date IS NOT NULL
      OR order_delivered_customer_date IS NOT NULL
  ); 


-- 
SELECT
    COUNT_BIG(*) AS delivered_orders_missing_delivery_date
FROM silver.olist_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- Canceled orders mein delivery dates check karo.
SELECT
    COUNT_BIG(*) AS canceled_orders_with_carrier_date,
    SUM(CASE
        WHEN order_delivered_customer_date IS NOT NULL
        THEN 1 ELSE 0
    END) AS canceled_orders_with_customer_delivery_date
FROM silver.olist_orders
WHERE order_status = 'canceled'
  AND (
      order_delivered_carrier_date IS NOT NULL
      OR order_delivered_customer_date IS NOT NULL
  );