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


SELECT COUNT(*) AS total_orders
FROM bronze.olist_orders;

SELECT TOP 10 *
FROM bronze.olist_orders;