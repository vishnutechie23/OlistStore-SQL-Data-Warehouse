-- =====================================================
-- Gold Layer: Final Data Validation
-- Project: Olist Store SQL Data Warehouse
-- Purpose: Validate Gold tables, row counts, keys,
--          relationships, data quality and measures
-- =====================================================

-- 1: Verify Gold Tables and Row Counts

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    SUM(p.rows) AS total_rows
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p
    ON t.object_id = p.object_id
WHERE
    s.name = 'gold'
    AND p.index_id IN (0, 1)
GROUP BY
    s.name,
    t.name
ORDER BY
    t.name;


-- 2: Verify Gold Table Column Structures

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
ORDER BY
    TABLE_NAME,
    ORDINAL_POSITION;
/*
important observations:
- dim_date mein iso_year_number correctly present hai.
- fact_order_items mein composite key ke columns order_id and order_item_id present hain.
- fact_payments mein order_id and payment_sequential present hain.
- fact_reviews mein review_id and order_id present hain.
- Optional dates aur product attributes nullable hain, which is expected.
*/

-- 3  : Verify Gold Primary Keys
SELECT
    tc.TABLE_NAME,
    kcu.COLUMN_NAME,
    tc.CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
    AND tc.TABLE_SCHEMA = kcu.TABLE_SCHEMA
WHERE
    tc.TABLE_SCHEMA = 'gold'
    AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
ORDER BY
    tc.TABLE_NAME,
    kcu.ORDINAL_POSITION;

-- 04 : Verify Gold Foreign Keys
SELECT
    fk.name AS foreign_key_name,
    tp.name AS referencing_table,
    cp.name AS referencing_column,
    tr.name AS referenced_table,
    cr.name AS referenced_column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tp
    ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.columns cp
    ON fkc.parent_object_id = cp.object_id
    AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.tables tr
    ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns cr
    ON fkc.referenced_object_id = cr.object_id
    AND fkc.referenced_column_id = cr.column_id
INNER JOIN sys.schemas s
    ON tp.schema_id = s.schema_id
WHERE s.name = 'gold'
ORDER BY
    tp.name,
    cp.name;


-- 4: Compare Silver vs Gold Row Counts
SELECT
    'dim_customers' AS table_name,
    (SELECT COUNT(*) FROM silver.olist_customers) AS silver_count,
    (SELECT COUNT(*) FROM gold.dim_customers) AS gold_count

UNION ALL

SELECT
    'dim_products',
    (SELECT COUNT(*) FROM silver.olist_products),
    (SELECT COUNT(*) FROM gold.dim_products)

UNION ALL

SELECT
    'dim_sellers',
    (SELECT COUNT(*) FROM silver.olist_sellers),
    (SELECT COUNT(*) FROM gold.dim_sellers)

UNION ALL

SELECT
    'dim_payment_type',
    (SELECT COUNT(DISTINCT payment_type)
     FROM silver.olist_order_payments),
    (SELECT COUNT(*) FROM gold.dim_payment_type)

UNION ALL

SELECT
    'dim_order_status',
    (SELECT COUNT(DISTINCT order_status)
     FROM silver.olist_orders),
    (SELECT COUNT(*) FROM gold.dim_order_status)

UNION ALL

SELECT
    'fact_orders',
    (SELECT COUNT(*) FROM silver.olist_orders),
    (SELECT COUNT(*) FROM gold.fact_orders)

UNION ALL

SELECT
    'fact_order_items',
    (SELECT COUNT(*) FROM silver.olist_order_items),
    (SELECT COUNT(*) FROM gold.fact_order_items)

UNION ALL

SELECT
    'fact_payments',
    (SELECT COUNT(*) FROM silver.olist_order_payments),
    (SELECT COUNT(*) FROM gold.fact_payments)

UNION ALL

SELECT
    'fact_reviews',
    (SELECT COUNT(*) FROM silver.olist_order_reviews),
    (SELECT COUNT(*) FROM gold.fact_reviews);

-- Note:
-- dim_date is generated as a calendar dimension, so it has no direct Silver source table.
-- Payment type and order status dimensions are compared using distinct source values.


-- 5: Duplicate Primary Key Validation
SELECT 'dim_customers' AS table_name, COUNT(*) AS duplicate_groups
FROM (
    SELECT customer_key
    FROM gold.dim_customers
    GROUP BY customer_key
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'dim_products', COUNT(*)
FROM (
    SELECT product_key
    FROM gold.dim_products
    GROUP BY product_key
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'dim_sellers', COUNT(*)
FROM (
    SELECT seller_key
    FROM gold.dim_sellers
    GROUP BY seller_key
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM (
    SELECT date_key
    FROM gold.dim_date
    GROUP BY date_key
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'dim_payment_type', COUNT(*)
FROM (
    SELECT payment_type_key
    FROM gold.dim_payment_type
    GROUP BY payment_type_key
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'dim_order_status', COUNT(*)
FROM (
    SELECT order_status_key
    FROM gold.dim_order_status
    GROUP BY order_status_key
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'fact_orders', COUNT(*)
FROM (
    SELECT order_id
    FROM gold.fact_orders
    GROUP BY order_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'fact_order_items', COUNT(*)
FROM (
    SELECT order_id, order_item_id
    FROM gold.fact_order_items
    GROUP BY order_id, order_item_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'fact_payments', COUNT(*)
FROM (
    SELECT order_id, payment_sequential
    FROM gold.fact_payments
    GROUP BY order_id, payment_sequential
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT 'fact_reviews', COUNT(*)
FROM (
    SELECT review_id, order_id
    FROM gold.fact_reviews
    GROUP BY review_id, order_id
    HAVING COUNT(*) > 1
) d;



-- 5 : Gold NULL Value Validation

DECLARE @sql NVARCHAR(MAX);

SELECT @sql = STRING_AGG(
    CAST(
        'SELECT ' +
        '''' + t.name + ''' AS table_name, ' +
        '''' + c.name + ''' AS column_name, ' +
        'COUNT_BIG(*) AS null_count ' +
        'FROM gold.' + QUOTENAME(t.name) +
        ' WHERE ' + QUOTENAME(c.name) + ' IS NULL'
        AS NVARCHAR(MAX)
    ),
    ' UNION ALL '
)
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.columns c
    ON t.object_id = c.object_id
WHERE
    s.name = 'gold'
    AND c.is_nullable = 1;

EXEC sp_executesql @sql;

/*
What this does:
- Automatically identifies nullable columns across all Gold tables.
- Counts NULL values in each column.
- Shows only columns where NULL is permitted by the table structure.
Important: NULL count zero hona compulsory nahi hai. For example,
optional delivery dates and product attributes may legitimately contain NULL values.
*/

-- 5C: Validate NULLs in NOT NULL Columns
DECLARE @sql NVARCHAR(MAX);

SELECT @sql = STRING_AGG(
    CAST(
        'SELECT ' +
        '''' + t.name + ''' AS table_name, ' +
        '''' + c.name + ''' AS column_name, ' +
        'COUNT_BIG(*) AS null_count ' +
        'FROM gold.' + QUOTENAME(t.name) +
        ' WHERE ' + QUOTENAME(c.name) + ' IS NULL'
        AS NVARCHAR(MAX)
    ),
    ' UNION ALL '
)
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.columns c
    ON t.object_id = c.object_id
WHERE
    s.name = 'gold'
    AND c.is_nullable = 0;

EXEC sp_executesql @sql;

-- 6 A : Validate fact_orders
SELECT
    COUNT(*) AS total_rows,
    SUM(order_count) AS total_orders,
    SUM(CAST(is_delivered AS INT)) AS delivered_orders,
    SUM(CAST(is_canceled AS INT)) AS canceled_orders,
    SUM(CASE
            WHEN is_delivered = 1 AND is_canceled = 1
            THEN 1 ELSE 0
        END) AS conflicting_flags,
    SUM(CASE
            WHEN delivery_days IS NOT NULL
             AND estimated_delivery_days IS NOT NULL
            THEN 1 ELSE 0
        END) AS orders_with_delivery_metrics
FROM gold.fact_orders;
-- Purpose: Check total orders, delivered/canceled counts, conflicting flags, and availability of delivery metrics.

-- B . Validate fact_order_items
SELECT
    COUNT(*) AS total_rows,
    SUM(item_count) AS total_items,
    SUM(price) AS total_price,
    SUM(freight_value) AS total_freight,
    SUM(item_total_value) AS total_item_value,
    SUM(CASE
            WHEN item_total_value <> price + freight_value
            THEN 1 ELSE 0
        END) AS calculation_mismatches
FROM gold.fact_order_items;

-- This checks item counts, sales value, freight, and the calculation of item_total_value.


-- C . Validate fact_payments
SELECT
    COUNT(*) AS total_rows,
    SUM(payment_count) AS total_payments,
    SUM(payment_value) AS total_payment_value,
    SUM(payment_installments) AS total_installments
FROM gold.fact_payments;

-- D . Validate fact_reviews
SELECT
    COUNT(*) AS total_rows,
    SUM(review_count) AS total_reviews,
    SUM(review_score) AS total_review_score,
    AVG(CAST(review_score AS DECIMAL(10,2))) AS average_review_score,
    MIN(review_score) AS minimum_score,
    MAX(review_score) AS maximum_score,
    SUM(CASE
            WHEN review_score NOT BETWEEN 1 AND 5
            THEN 1 ELSE 0
        END) AS invalid_scores
FROM gold.fact_reviews;

-- 6 E — Validate dimension data : Ab dimensions ke records aur unique business keys check karenge.
SELECT 'dim_customers' AS table_name,
       COUNT(*) AS total_rows,
       COUNT(DISTINCT customer_id) AS unique_business_keys
FROM gold.dim_customers

UNION ALL

SELECT 'dim_products',
       COUNT(*),
       COUNT(DISTINCT product_id)
FROM gold.dim_products

UNION ALL

SELECT 'dim_sellers',
       COUNT(*),
       COUNT(DISTINCT seller_id)
FROM gold.dim_sellers

UNION ALL

SELECT 'dim_payment_type',
       COUNT(*),
       COUNT(DISTINCT payment_type)
FROM gold.dim_payment_type

UNION ALL

SELECT 'dim_order_status',
       COUNT(*),
       COUNT(DISTINCT order_status)
FROM gold.dim_order_status;
-- Purpose: Check that each dimension has unique business keys and no unexpected duplicates.



-- 7 — Validate Star Schema relationships
-- Ab check karenge ki fact tables ke foreign keys correctly map ho rahe hain to their dimension tables.
SELECT
    'fact_orders -> dim_customers' AS relationship,
    COUNT(*) AS unmatched_records
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers d
    ON f.customer_key = d.customer_key
WHERE d.customer_key IS NULL

UNION ALL

SELECT
    'fact_orders -> dim_order_status',
    COUNT(*)
FROM gold.fact_orders f
LEFT JOIN gold.dim_order_status d
    ON f.order_status_key = d.order_status_key
WHERE d.order_status_key IS NULL

UNION ALL

SELECT
    'fact_order_items -> dim_products',
    COUNT(*)
FROM gold.fact_order_items f
LEFT JOIN gold.dim_products d
    ON f.product_key = d.product_key
WHERE d.product_key IS NULL

UNION ALL

SELECT
    'fact_order_items -> dim_sellers',
    COUNT(*)
FROM gold.fact_order_items f
LEFT JOIN gold.dim_sellers d
    ON f.seller_key = d.seller_key
WHERE d.seller_key IS NULL

UNION ALL

SELECT
    'fact_payments -> dim_payment_type',
    COUNT(*)
FROM gold.fact_payments f
LEFT JOIN gold.dim_payment_type d
    ON f.payment_type_key = d.payment_type_key
WHERE d.payment_type_key IS NULL;


-- 7B — Validate remaining customer and date relationships
SELECT
    'fact_order_items -> dim_customers' AS relationship,
    COUNT(*) AS unmatched_records
FROM gold.fact_order_items f
LEFT JOIN gold.dim_customers d
    ON f.customer_key = d.customer_key
WHERE d.customer_key IS NULL

UNION ALL

SELECT
    'fact_payments -> dim_customers',
    COUNT(*)
FROM gold.fact_payments f
LEFT JOIN gold.dim_customers d
    ON f.customer_key = d.customer_key
WHERE d.customer_key IS NULL

UNION ALL

SELECT
    'fact_reviews -> dim_customers',
    COUNT(*)
FROM gold.fact_reviews f
LEFT JOIN gold.dim_customers d
    ON f.customer_key = d.customer_key
WHERE d.customer_key IS NULL

UNION ALL

SELECT
    'fact_orders -> dim_date (purchase)',
    COUNT(*)
FROM gold.fact_orders f
LEFT JOIN gold.dim_date d
    ON f.purchase_date_key = d.date_key
WHERE d.date_key IS NULL

UNION ALL

SELECT
    'fact_order_items -> dim_date (purchase)',
    COUNT(*)
FROM gold.fact_order_items f
LEFT JOIN gold.dim_date d
    ON f.purchase_date_key = d.date_key
WHERE d.date_key IS NULL

UNION ALL

SELECT
    'fact_payments -> dim_date (purchase)',
    COUNT(*)
FROM gold.fact_payments f
LEFT JOIN gold.dim_date d
    ON f.purchase_date_key = d.date_key
WHERE d.date_key IS NULL;
-- This checks customer mappings and purchase-date mappings across the fact tables.

-- 7C — Validate remaining date relationships
-- Check optional date keys too. NULL date keys are allowed, but non-NULL keys must match dim_date.
SELECT
    'fact_orders -> approved_date' AS relationship,
    COUNT(*) AS unmatched_records
FROM gold.fact_orders f
LEFT JOIN gold.dim_date d
    ON f.approved_date_key = d.date_key
WHERE f.approved_date_key IS NOT NULL
  AND d.date_key IS NULL

UNION ALL

SELECT
    'fact_orders -> delivered_carrier_date',
    COUNT(*)
FROM gold.fact_orders f
LEFT JOIN gold.dim_date d
    ON f.delivered_carrier_date_key = d.date_key
WHERE f.delivered_carrier_date_key IS NOT NULL
  AND d.date_key IS NULL

UNION ALL

SELECT
    'fact_orders -> delivered_customer_date',
    COUNT(*)
FROM gold.fact_orders f
LEFT JOIN gold.dim_date d
    ON f.delivered_customer_date_key = d.date_key
WHERE f.delivered_customer_date_key IS NOT NULL
  AND d.date_key IS NULL

UNION ALL

SELECT
    'fact_orders -> estimated_delivery_date',
    COUNT(*)
FROM gold.fact_orders f
LEFT JOIN gold.dim_date d
    ON f.estimated_delivery_date_key = d.date_key
WHERE f.estimated_delivery_date_key IS NOT NULL
  AND d.date_key IS NULL

UNION ALL

SELECT
    'fact_order_items -> shipping_limit_date',
    COUNT(*)
FROM gold.fact_order_items f
LEFT JOIN gold.dim_date d
    ON f.shipping_limit_date_key = d.date_key
WHERE f.shipping_limit_date_key IS NOT NULL
  AND d.date_key IS NULL

UNION ALL

SELECT
    'fact_reviews -> review_creation_date',
    COUNT(*)
FROM gold.fact_reviews f
LEFT JOIN gold.dim_date d
    ON f.review_creation_date_key = d.date_key
WHERE f.review_creation_date_key IS NOT NULL
  AND d.date_key IS NULL

UNION ALL

SELECT
    'fact_reviews -> review_answer_date',
    COUNT(*)
FROM gold.fact_reviews f
LEFT JOIN gold.dim_date d
    ON f.review_answer_date_key = d.date_key
WHERE f.review_answer_date_key IS NOT NULL
  AND d.date_key IS NULL;

-- All non-NULL date keys should map to dim_date

-- Final Gold validation report Before preparing the final report, let's capture the final Gold table counts in one query.
SELECT
    t.name AS table_name,
    SUM(p.rows) AS total_rows
FROM sys.tables t
INNER JOIN sys.schemas s
    ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p
    ON t.object_id = p.object_id
WHERE
    s.name = 'gold'
    AND p.index_id IN (0, 1)
GROUP BY t.name
ORDER BY t.name;

