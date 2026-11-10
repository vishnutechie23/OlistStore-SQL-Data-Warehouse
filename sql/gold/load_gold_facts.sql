-- =====================================================
-- Gold Layer: Load Fact Tables
-- Project: Olist Store SQL Data Warehouse
-- Purpose: Transform and load transactional data into
--          Gold fact tables using dimension keys
-- Total Tables: 4
-- =====================================================



-- 07 : load data into gold.fact_orders

-- Load fact_orders
INSERT INTO gold.fact_orders
(
    order_id,
    customer_key,
    order_status_key,
    purchase_date_key,
    approved_date_key,
    delivered_carrier_date_key,
    delivered_customer_date_key,
    estimated_delivery_date_key,
    order_count,
    approval_hours,
    delivery_days,
    estimated_delivery_days,
    delivery_delay_days,
    is_delivered,
    is_canceled
)
SELECT
    o.order_id,
    c.customer_key,
    s.order_status_key,

    CONVERT(INT, CONVERT(CHAR(8), o.order_purchase_timestamp, 112)),
    CASE WHEN o.order_approved_at IS NOT NULL
         THEN CONVERT(INT, CONVERT(CHAR(8), o.order_approved_at, 112)) END,
    CASE WHEN o.order_delivered_carrier_date IS NOT NULL
         THEN CONVERT(INT, CONVERT(CHAR(8), o.order_delivered_carrier_date, 112)) END,
    CASE WHEN o.order_delivered_customer_date IS NOT NULL
         THEN CONVERT(INT, CONVERT(CHAR(8), o.order_delivered_customer_date, 112)) END,
    CASE WHEN o.order_estimated_delivery_date IS NOT NULL
         THEN CONVERT(INT, CONVERT(CHAR(8), o.order_estimated_delivery_date, 112)) END,

    1,

    CASE WHEN o.order_approved_at IS NOT NULL
         THEN DATEDIFF(MINUTE, o.order_purchase_timestamp, o.order_approved_at) / 60.0 END,

    CASE WHEN o.order_delivered_customer_date IS NOT NULL
         THEN DATEDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date) END,

    DATEDIFF(DAY, o.order_purchase_timestamp, o.order_estimated_delivery_date),

    CASE WHEN o.order_delivered_customer_date IS NOT NULL
         THEN DATEDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) END,

    CASE WHEN o.order_status = 'delivered' THEN 1 ELSE 0 END,
    CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END

FROM silver.olist_orders o
INNER JOIN gold.dim_customers c
    ON o.customer_id = c.customer_id
INNER JOIN gold.dim_order_status s
    ON o.order_status = s.order_status;
GO

/*
Metrics explanation:
- approval_hours: Purchase to approval time.
- delivery_days: Purchase to actual delivery.
- estimated_delivery_days: Purchase to estimated delivery.
- delivery_delay_days: Positive = late, negative = early.
- Missing actual dates remain NULL.*/

-- Validate row count and grain
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    SUM(order_count) AS total_order_count
FROM gold.fact_orders;

-- Validate NULL values
SELECT
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS null_customer,
    SUM(CASE WHEN order_status_key IS NULL THEN 1 ELSE 0 END) AS null_status,
    SUM(CASE WHEN purchase_date_key IS NULL THEN 1 ELSE 0 END) AS null_purchase_date,
    SUM(CASE WHEN approved_date_key IS NULL THEN 1 ELSE 0 END) AS null_approved_date,
    SUM(CASE WHEN delivered_carrier_date_key IS NULL THEN 1 ELSE 0 END) AS null_carrier_date,
    SUM(CASE WHEN delivered_customer_date_key IS NULL THEN 1 ELSE 0 END) AS null_delivery_date,
    SUM(CASE WHEN estimated_delivery_date_key IS NULL THEN 1 ELSE 0 END) AS null_estimated_date
FROM gold.fact_orders;


-- Validate foreign key relationships : Check karenge ki fact table ke dimension keys actually dimensions mein exist karte hain.
SELECT
    SUM(CASE WHEN c.customer_key IS NULL THEN 1 ELSE 0 END) AS unmatched_customers,
    SUM(CASE WHEN s.order_status_key IS NULL THEN 1 ELSE 0 END) AS unmatched_statuses,
    SUM(CASE WHEN p.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_purchase_dates
FROM gold.fact_orders f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_order_status s
    ON f.order_status_key = s.order_status_key
LEFT JOIN gold.dim_date p
    ON f.purchase_date_key = p.date_key;


-- Validate remaining date relationships
-- Ab nullable date keys bhi check karenge. NULL values allowed hain, lekin jo keys present hain woh dim_date mein exist honi chahiye.
SELECT
    SUM(CASE WHEN f.approved_date_key IS NOT NULL
              AND a.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_approved_dates,

    SUM(CASE WHEN f.delivered_carrier_date_key IS NOT NULL
              AND c.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_carrier_dates,

    SUM(CASE WHEN f.delivered_customer_date_key IS NOT NULL
              AND d.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_delivery_dates,

    SUM(CASE WHEN f.estimated_delivery_date_key IS NOT NULL
              AND e.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_estimated_dates
FROM gold.fact_orders f
LEFT JOIN gold.dim_date a
    ON f.approved_date_key = a.date_key
LEFT JOIN gold.dim_date c
    ON f.delivered_carrier_date_key = c.date_key
LEFT JOIN gold.dim_date d
    ON f.delivered_customer_date_key = d.date_key
LEFT JOIN gold.dim_date e
    ON f.estimated_delivery_date_key = e.date_key;


-- Validate delivery flags
-- heck karenge ki delivered aur canceled flags correct hain.
SELECT
    SUM(CASE WHEN is_delivered = 1 THEN 1 ELSE 0 END) AS delivered_orders,
    SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS canceled_orders,
    SUM(CASE WHEN is_delivered = 1 AND is_canceled = 1 THEN 1 ELSE 0 END) AS conflicting_flags
FROM gold.fact_orders;

-- Validate duration calculations
-- Check karenge ki calculated durations mein negative values kitni hain.
SELECT
    SUM(CASE WHEN approval_hours < 0 THEN 1 ELSE 0 END) AS negative_approval_hours,
    SUM(CASE WHEN delivery_days < 0 THEN 1 ELSE 0 END) AS negative_delivery_days,
    SUM(CASE WHEN estimated_delivery_days < 0 THEN 1 ELSE 0 END) AS negative_estimated_days,
    SUM(CASE WHEN delivery_delay_days < 0 THEN 1 ELSE 0 END) AS early_deliveries,
    SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END) AS late_deliveries
FROM gold.fact_orders;

-- Check complete delivery distribution
SELECT
    SUM(CASE WHEN delivery_delay_days < 0 THEN 1 ELSE 0 END) AS early,
    SUM(CASE WHEN delivery_delay_days = 0 THEN 1 ELSE 0 END) AS on_time,
    SUM(CASE WHEN delivery_delay_days > 0 THEN 1 ELSE 0 END) AS late,
    SUM(CASE WHEN delivery_delay_days IS NULL THEN 1 ELSE 0 END) AS no_delivery_date
FROM gold.fact_orders;

-- Validate status flags against order status
SELECT COUNT(*) AS incorrect_flags
FROM gold.fact_orders f
JOIN gold.dim_order_status s
    ON f.order_status_key = s.order_status_key
WHERE
    f.is_delivered <> CASE WHEN s.order_status = 'delivered' THEN 1 ELSE 0 END
    OR
    f.is_canceled <> CASE WHEN s.order_status = 'canceled' THEN 1 ELSE 0 END;

-- Validate calculated durations against Silver
-- Ab check karenge ki Gold mein calculated durations Silver timestamps se correctly match karte hain.
SELECT
    COUNT(*) AS mismatched_records
FROM silver.olist_orders s
INNER JOIN gold.fact_orders g
    ON s.order_id = g.order_id
WHERE
    ISNULL(g.approval_hours, -999999) <>
        ISNULL(DATEDIFF(MINUTE, s.order_purchase_timestamp, s.order_approved_at) / 60.0, -999999)

    OR ISNULL(g.delivery_days, -999999) <>
        ISNULL(DATEDIFF(DAY, s.order_purchase_timestamp, s.order_delivered_customer_date), -999999)

    OR ISNULL(g.estimated_delivery_days, -999999) <>
        ISNULL(DATEDIFF(DAY, s.order_purchase_timestamp, s.order_estimated_delivery_date), -999999)

    OR ISNULL(g.delivery_delay_days, -999999) <>
        ISNULL(DATEDIFF(DAY, s.order_estimated_delivery_date, s.order_delivered_customer_date), -999999);

-- Identify which metric is mismatching Ye diagnostic query execute karo:
SELECT
    SUM(CASE
        WHEN ISNULL(g.approval_hours, -999999) <>
             ISNULL(CAST(DATEDIFF(MINUTE,
                 s.order_purchase_timestamp,
                 s.order_approved_at) / 60.0 AS DECIMAL(10,2)), -999999)
        THEN 1 ELSE 0 END) AS approval_mismatches,

    SUM(CASE
        WHEN ISNULL(g.delivery_days, -999999) <>
             ISNULL(DATEDIFF(DAY,
                 s.order_purchase_timestamp,
                 s.order_delivered_customer_date), -999999)
        THEN 1 ELSE 0 END) AS delivery_mismatches,

    SUM(CASE
        WHEN ISNULL(g.estimated_delivery_days, -999999) <>
             ISNULL(DATEDIFF(DAY,
                 s.order_purchase_timestamp,
                 s.order_estimated_delivery_date), -999999)
        THEN 1 ELSE 0 END) AS estimated_mismatches,

    SUM(CASE
        WHEN ISNULL(g.delivery_delay_days, -999999) <>
             ISNULL(DATEDIFF(DAY,
                 s.order_estimated_delivery_date,
                 s.order_delivered_customer_date), -999999)
        THEN 1 ELSE 0 END) AS delay_mismatches

FROM silver.olist_orders s
INNER JOIN gold.fact_orders g
    ON s.order_id = g.order_id;

-- Check order status distribution
SELECT
    s.order_status,
    COUNT(*) AS total_orders,
    SUM(f.order_count) AS order_count
FROM gold.fact_orders f
INNER JOIN gold.dim_order_status s
    ON f.order_status_key = s.order_status_key
GROUP BY s.order_status
ORDER BY total_orders DESC;




-- 08 : load data into gold.fact_order_items

-- Load data into gold.fact_order_items.
INSERT INTO gold.fact_order_items
(
    order_id,
    order_item_id,
    customer_key,
    product_key,
    seller_key,
    purchase_date_key,
    shipping_limit_date_key,
    item_count,
    price,
    freight_value,
    item_total_value
)
SELECT
    oi.order_id,
    oi.order_item_id,
    c.customer_key,
    p.product_key,
    s.seller_key,
    CONVERT(INT, CONVERT(CHAR(8), o.order_purchase_timestamp, 112)),
    CASE
        WHEN oi.shipping_limit_date IS NOT NULL
        THEN CONVERT(INT, CONVERT(CHAR(8), oi.shipping_limit_date, 112))
    END,
    1,
    oi.price,
    oi.freight_value,
    oi.price + oi.freight_value
FROM silver.olist_order_items oi
INNER JOIN silver.olist_orders o
    ON oi.order_id = o.order_id
INNER JOIN gold.dim_customers c
    ON o.customer_id = c.customer_id
INNER JOIN gold.dim_products p
    ON oi.product_id = p.product_id
INNER JOIN gold.dim_sellers s
    ON oi.seller_id = s.seller_id;
GO

-- This maps each item to its customer, product, seller and purchase date. item_total_value includes both item price and freight.

SELECT
    MIN(shipping_limit_date) AS min_shipping_date,
    MAX(shipping_limit_date) AS max_shipping_date,
    SUM(CASE
        WHEN shipping_limit_date IS NOT NULL
         AND CONVERT(INT, CONVERT(CHAR(8), shipping_limit_date, 112))
             NOT IN (SELECT date_key FROM gold.dim_date)
        THEN 1 ELSE 0
    END) AS unmatched_dates
FROM silver.olist_order_items;

SELECT
    MIN(oi.shipping_limit_date) AS min_shipping_date,
    MAX(oi.shipping_limit_date) AS max_shipping_date,
    COUNT(*) AS unmatched_dates
FROM silver.olist_order_items oi
WHERE oi.shipping_limit_date IS NOT NULL
AND NOT EXISTS
(
    SELECT 1
    FROM gold.dim_date d
    WHERE d.full_date = CAST(oi.shipping_limit_date AS DATE)
);


SELECT MAX(date_value) AS max_date
FROM
(
    SELECT CAST(order_purchase_timestamp AS DATE) AS date_value
    FROM silver.olist_orders

    UNION ALL

    SELECT CAST(shipping_limit_date AS DATE)
    FROM silver.olist_order_items
) dates;


-- 
SET LANGUAGE us_english;

WITH DateSeries AS
(
    SELECT DATEADD(DAY, 1, MAX(full_date)) AS full_date
    FROM gold.dim_date

    UNION ALL

    SELECT DATEADD(DAY, 1, full_date)
    FROM DateSeries
    WHERE full_date < '2020-04-09'
)
INSERT INTO gold.dim_date
(
    date_key,
    full_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number,
    week_number,
    day_of_week,
    day_name,
    is_weekend,
    iso_year_number
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), full_date, 112)),
    full_date,
    DAY(full_date),
    MONTH(full_date),
    DATENAME(MONTH, full_date),
    DATEPART(QUARTER, full_date),
    YEAR(full_date),
    DATEPART(ISO_WEEK, full_date),
    DATEDIFF(DAY, '19000101', full_date) % 7 + 1,
    DATENAME(WEEKDAY, full_date),
    CASE WHEN DATEDIFF(DAY, '19000101', full_date) % 7 IN (5, 6)
         THEN 1 ELSE 0 END,
    YEAR(DATEADD(DAY, 4 - (DATEDIFF(DAY, '19000101', full_date) % 7 + 1), full_date))
FROM DateSeries
OPTION (MAXRECURSION 0);
GO


-- Verify the date dimension.

SELECT
    COUNT(*) AS total_dates,
    MIN(full_date) AS min_date,
    MAX(full_date) AS max_date,
    COUNT(DISTINCT date_key) AS unique_date_keys,
    COUNT(DISTINCT full_date) AS unique_dates,
    SUM(CASE WHEN iso_year_number IS NULL THEN 1 ELSE 0 END) AS null_iso_years
FROM gold.dim_date;


-- Validate row count and grain of gold.fact_order_items.
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id + '-' + CAST(order_item_id AS VARCHAR(10))) AS unique_item_lines,
    SUM(item_count) AS total_item_count
FROM gold.fact_order_items;

-- Check NULL values in important columns
SELECT
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS null_customers,
    SUM(CASE WHEN product_key IS NULL THEN 1 ELSE 0 END) AS null_products,
    SUM(CASE WHEN seller_key IS NULL THEN 1 ELSE 0 END) AS null_sellers,
    SUM(CASE WHEN purchase_date_key IS NULL THEN 1 ELSE 0 END) AS null_purchase_dates,
    SUM(CASE WHEN shipping_limit_date_key IS NULL THEN 1 ELSE 0 END) AS null_shipping_dates,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_prices,
    SUM(CASE WHEN freight_value IS NULL THEN 1 ELSE 0 END) AS null_freight
FROM gold.fact_order_items;


-- Check duplicate item lines.
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- Validate Foreign Key mappings.
SELECT
    SUM(CASE WHEN c.customer_key IS NULL THEN 1 ELSE 0 END) AS unmatched_customers,
    SUM(CASE WHEN p.product_key IS NULL THEN 1 ELSE 0 END) AS unmatched_products,
    SUM(CASE WHEN s.seller_key IS NULL THEN 1 ELSE 0 END) AS unmatched_sellers,
    SUM(CASE WHEN pd.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_purchase_dates,
    SUM(CASE WHEN sd.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_shipping_dates
FROM gold.fact_order_items f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
LEFT JOIN gold.dim_sellers s
    ON f.seller_key = s.seller_key
LEFT JOIN gold.dim_date pd
    ON f.purchase_date_key = pd.date_key
LEFT JOIN gold.dim_date sd
    ON f.shipping_limit_date_key = sd.date_key;


-- Validate item_total_value calculation.
-- Check whether price + freight_value = item_total_value for every row.
SELECT COUNT(*) AS calculation_mismatches
FROM gold.fact_order_items
WHERE item_total_value <> price + freight_value;


-- Validate Silver vs Gold totals.
SELECT
    (SELECT COUNT(*) FROM silver.olist_order_items) AS silver_rows,
    (SELECT COUNT(*) FROM gold.fact_order_items) AS gold_rows,

    (SELECT SUM(price) FROM silver.olist_order_items) AS silver_price,
    (SELECT SUM(price) FROM gold.fact_order_items) AS gold_price,

    (SELECT SUM(freight_value) FROM silver.olist_order_items) AS silver_freight,
    (SELECT SUM(freight_value) FROM gold.fact_order_items) AS gold_freight;



-- 09 : load data into gold.fact_payments

-- Load data
INSERT INTO gold.fact_payments
(
    order_id,
    payment_sequential,
    customer_key,
    payment_type_key,
    purchase_date_key,
    payment_count,
    payment_installments,
    payment_value
)
SELECT
    pay.order_id,
    pay.payment_sequential,
    c.customer_key,
    pt.payment_type_key,
    CONVERT(INT, CONVERT(CHAR(8), o.order_purchase_timestamp, 112)),
    1,
    pay.payment_installments,
    pay.payment_value
FROM silver.olist_order_payments pay
INNER JOIN silver.olist_orders o
    ON pay.order_id = o.order_id
INNER JOIN gold.dim_customers c
    ON o.customer_id = c.customer_id
INNER JOIN gold.dim_payment_type pt
    ON pay.payment_type = pt.payment_type;
GO
-- This maps each payment to its customer, payment type and order purchase date.

-- Validate row count and grain
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id + '-' + CAST(payment_sequential AS VARCHAR(10))) AS unique_payments,
    SUM(payment_count) AS total_payment_count
FROM gold.fact_payments;

-- Check NULL values
SELECT
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS null_customers,
    SUM(CASE WHEN payment_type_key IS NULL THEN 1 ELSE 0 END) AS null_payment_types,
    SUM(CASE WHEN purchase_date_key IS NULL THEN 1 ELSE 0 END) AS null_purchase_dates,
    SUM(CASE WHEN payment_installments IS NULL THEN 1 ELSE 0 END) AS null_installments,
    SUM(CASE WHEN payment_value IS NULL THEN 1 ELSE 0 END) AS null_payment_values
FROM gold.fact_payments;

-- Check duplicate payment records
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS duplicate_count
FROM gold.fact_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- Validate Foreign Key mappings
SELECT
    SUM(CASE WHEN c.customer_key IS NULL THEN 1 ELSE 0 END) AS unmatched_customers,
    SUM(CASE WHEN pt.payment_type_key IS NULL THEN 1 ELSE 0 END) AS unmatched_payment_types,
    SUM(CASE WHEN d.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_purchase_dates
FROM gold.fact_payments f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_payment_type pt
    ON f.payment_type_key = pt.payment_type_key
LEFT JOIN gold.dim_date d
    ON f.purchase_date_key = d.date_key;

-- Validate Silver vs Gold totals
SELECT
    (SELECT COUNT(*) FROM silver.olist_order_payments) AS silver_rows,
    (SELECT COUNT(*) FROM gold.fact_payments) AS gold_rows,

    (SELECT SUM(payment_value) FROM silver.olist_order_payments) AS silver_payment_total,
    (SELECT SUM(payment_value) FROM gold.fact_payments) AS gold_payment_total,

    (SELECT SUM(payment_installments) FROM silver.olist_order_payments) AS silver_installments,
    (SELECT SUM(payment_installments) FROM gold.fact_payments) AS gold_installments;


-- This checks row counts, total payment value and total installments


-- 10 : load data into gold.fact_reviews

-- Load data
INSERT INTO gold.fact_reviews
(
    review_id,
    order_id,
    customer_key,
    review_creation_date_key,
    review_answer_date_key,
    review_count,
    review_score
)
SELECT
    r.review_id,
    r.order_id,
    c.customer_key,

    CASE
        WHEN r.review_creation_date IS NOT NULL
        THEN CONVERT(INT, CONVERT(CHAR(8), r.review_creation_date, 112))
    END,

    CASE
        WHEN r.review_answer_timestamp IS NOT NULL
        THEN CONVERT(INT, CONVERT(CHAR(8), r.review_answer_timestamp, 112))
    END,

    1,
    r.review_score

FROM silver.olist_order_reviews r
INNER JOIN silver.olist_orders o
    ON r.order_id = o.order_id
INNER JOIN gold.dim_customers c
    ON o.customer_id = c.customer_id;
GO
-- This maps each review to its customer and converts review timestamps into date keys.


-- Validate row count and grain
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT review_id + '-' + order_id) AS unique_reviews,
    SUM(review_count) AS total_review_count
FROM gold.fact_reviews;


-- Check NULL values
SELECT
    SUM(CASE WHEN customer_key IS NULL THEN 1 ELSE 0 END) AS null_customers,
    SUM(CASE WHEN review_creation_date_key IS NULL THEN 1 ELSE 0 END) AS null_creation_dates,
    SUM(CASE WHEN review_answer_date_key IS NULL THEN 1 ELSE 0 END) AS null_answer_dates,
    SUM(CASE WHEN review_score IS NULL THEN 1 ELSE 0 END) AS null_scores
FROM gold.fact_reviews;


-- Check duplicate review records
SELECT
    review_id,
    order_id,
    COUNT(*) AS duplicate_count
FROM gold.fact_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

-- Validate Foreign Key mappings
SELECT
    SUM(CASE WHEN c.customer_key IS NULL THEN 1 ELSE 0 END) AS unmatched_customers,
    SUM(CASE WHEN cd.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_creation_dates,
    SUM(CASE WHEN ad.date_key IS NULL THEN 1 ELSE 0 END) AS unmatched_answer_dates
FROM gold.fact_reviews f
LEFT JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
LEFT JOIN gold.dim_date cd
    ON f.review_creation_date_key = cd.date_key
LEFT JOIN gold.dim_date ad
    ON f.review_answer_date_key = ad.date_key;


-- Validate review score range
-- Check that all ratings are between 1 and 5.

SELECT
    MIN(review_score) AS minimum_score,
    MAX(review_score) AS maximum_score,
    COUNT(CASE
        WHEN review_score NOT BETWEEN 1 AND 5
        THEN 1
    END) AS invalid_scores
FROM gold.fact_reviews;
-- Expected: minimum 1, maximum 5, invalid scores 0.


-- Validate Silver vs Gold totals
SELECT
    (SELECT COUNT(*) FROM silver.olist_order_reviews) AS silver_rows,
    (SELECT COUNT(*) FROM gold.fact_reviews) AS gold_rows,

    (SELECT SUM(review_score) FROM silver.olist_order_reviews) AS silver_score_total,
    (SELECT SUM(review_score) FROM gold.fact_reviews) AS gold_score_total,

    (SELECT AVG(CAST(review_score AS DECIMAL(10,2)))
     FROM silver.olist_order_reviews) AS silver_avg_score,

    (SELECT AVG(CAST(review_score AS DECIMAL(10,2)))
     FROM gold.fact_reviews) AS gold_avg_score;


