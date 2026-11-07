-- FOR olist_customers
-- Verify row count
SELECT COUNT(*) AS total_customers
FROM bronze.olist_customers;

-- Verify sample records
SELECT TOP 10 *
FROM bronze.olist_customers;

-- Verify ETL execution log
SELECT TOP 5
    log_id,
    pipeline_name,
    rows_read,
    rows_inserted,
    status,
    start_time_utc,
    end_time_utc
FROM audit.etl_execution_log
ORDER BY log_id DESC;


-- FOR olist_orders
-- Verify row count
SELECT COUNT(*) AS total_orders
FROM bronze.olist_orders;

-- Verify sample records
SELECT TOP 10 *
FROM bronze.olist_orders;

-- Verify Orders ETL execution log
SELECT TOP 5
    log_id,
    pipeline_name,
    rows_read,
    rows_inserted,
    status,
    start_time_utc,
    end_time_utc
FROM audit.etl_execution_log
WHERE pipeline_name = 'Orders Bronze Load'
ORDER BY log_id DESC;


-- FOR olist_order_items
SELECT COUNT(*) AS total_order_items
FROM bronze.olist_order_items;

-- Verify Order Items ETL execution log
SELECT TOP 5
    log_id,
    pipeline_name,
    rows_read,
    rows_inserted,
    status,
    start_time_utc,
    end_time_utc
FROM audit.etl_execution_log
WHERE pipeline_name = 'Order Items Bronze Load'
ORDER BY log_id DESC;


-- FOR olist_order_payments
SELECT COUNT(*) AS total_payments
FROM bronze.olist_order_payments;

-- Verify ETL logs
SELECT TOP 5
    log_id,
    pipeline_name,
    rows_read,
    rows_inserted,
    status,
    start_time_utc,
    end_time_utc
FROM audit.etl_execution_log
WHERE pipeline_name = 'Order Payments Bronze Load'
ORDER BY log_id DESC;


-- FOR olist_order_reviews
SELECT COUNT(*) AS total_reviews
FROM bronze.olist_order_reviews;

-- ETL logs
SELECT TOP 5
    log_id,
    pipeline_name,
    rows_read,
    rows_inserted,
    status,
    start_time_utc,
    end_time_utc
FROM audit.etl_execution_log
WHERE pipeline_name = 'Order Reviews Bronze Load'
ORDER BY log_id DESC;

-- FOR olist_products
SELECT COUNT(*) AS total_products
FROM bronze.olist_products;

-- ETL logs 
SELECT
    log_id,
    pipeline_name,
    rows_read,
    rows_inserted,
    status,
    start_time_utc,
    end_time_utc
FROM audit.etl_execution_log
WHERE pipeline_name = 'Products Bronze Load'
ORDER BY log_id DESC;


-- FOR olist_sellers
SELECT COUNT(*) AS total_sellers
FROM bronze.olist_sellers;

-- ETL logs 
SELECT
    log_id,
    pipeline_name,
    rows_read,
    rows_inserted,
    status,
    start_time_utc,
    end_time_utc
FROM audit.etl_execution_log
WHERE pipeline_name = 'Sellers Bronze Load'
ORDER BY log_id DESC;

-- FOR olist_geolocation
SELECT COUNT(*) AS total_geolocation
FROM bronze.olist_geolocation;

-- ETL logs check
SELECT
    log_id,
    pipeline_name,
    rows_read,
    rows_inserted,
    status,
    start_time_utc,
    end_time_utc
FROM audit.etl_execution_log
WHERE pipeline_name = 'Geolocation Bronze Load'
ORDER BY log_id DESC;

-- FOR olist_category_translation
SELECT COUNT(*) AS total_categories
FROM bronze.olist_category_translation;

-- check all logs here 
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


-- Just check all tables (top 10 )
SELECT TOP 10 * FROM bronze.olist_customers;
SELECT TOP 10 * FROM bronze.olist_orders;
SELECT TOP 10 * FROM bronze.olist_order_items;
SELECT TOP 10 * FROM bronze.olist_order_payments;
SELECT TOP 10 * FROM bronze.olist_order_reviews;
SELECT TOP 10 * FROM bronze.olist_products;
SELECT TOP 10 * FROM bronze.olist_sellers;
SELECT TOP 10 * FROM bronze.olist_geolocation;
SELECT TOP 10 * FROM bronze.olist_category_translation;