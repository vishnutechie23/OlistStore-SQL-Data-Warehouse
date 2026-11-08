USE OlistStore_DW;
GO

/*
    Project: OlistStore SQL Data Warehouse
    Layer: Gold
    Purpose: Create business-ready dimension and fact tables
*/

SET NOCOUNT ON;
GO
-- 01_TABLE : CREATE dim_customers

CREATE TABLE gold.dim_customers
(
    customer_key BIGINT IDENTITY(1,1) PRIMARY KEY,
    customer_id VARCHAR(50) NOT NULL,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city NVARCHAR(100),
    customer_state CHAR(2)
);
GO

-- Validate dim_customers structure 
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
  AND TABLE_NAME = 'dim_customers'
ORDER BY ORDINAL_POSITION;


-- Load Customers into Gold  :  Ab Silver se Gold mein data insert karenge.
INSERT INTO gold.dim_customers
(
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM silver.olist_customers;
GO

/*
Kya hoga?
- Silver ke 99,441 customers Gold mein load honge.
- customer_key automatically generate hoga.
- Original customer IDs preserve rahengi.*/

-- Checking insert 
SELECT
    (SELECT COUNT_BIG(*) FROM silver.olist_customers) AS silver_rows,
    (SELECT COUNT_BIG(*) FROM gold.dim_customers) AS gold_rows;

-- Check duplicate customer IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_person_ids
FROM gold.dim_customers;
-- Purpose: Verify karna ki customer IDs unique hain aur person-level IDs kitne distinct hain.

-- Check NULL values
SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN customer_unique_id IS NULL THEN 1 ELSE 0 END) AS null_unique_id,
    SUM(CASE WHEN customer_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip,
    SUM(CASE WHEN customer_city IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN customer_state IS NULL THEN 1 ELSE 0 END) AS null_state
FROM gold.dim_customers;

-- Check duplicate rows
SELECT
    customer_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

/*
DDL created
99,441 rows loaded
Row count matched
Customer IDs unique
NULL validation passed
Duplicate validation passed
*/

-- Verify Silver vs Gold data : Check karenge ki actual customer data dono layers mein same hai.
SELECT COUNT(*) AS mismatched_records
FROM silver.olist_customers s
INNER JOIN gold.dim_customers g
    ON s.customer_id = g.customer_id
WHERE
    ISNULL(s.customer_unique_id, '') <> ISNULL(g.customer_unique_id, '')
    OR ISNULL(s.customer_zip_code_prefix, '') <> ISNULL(g.customer_zip_code_prefix, '')
    OR ISNULL(s.customer_city, '') <> ISNULL(g.customer_city, '')
    OR ISNULL(s.customer_state, '') <> ISNULL(g.customer_state, '');

-- Verify customer_key : Ab surrogate key check karenge ki automatically generate hui hai aur unique hai.
SELECT
    COUNT(*) AS total_rows,
    COUNT(customer_key) AS non_null_keys,
    COUNT(DISTINCT customer_key) AS unique_keys,
    MIN(customer_key) AS first_key,
    MAX(customer_key) AS last_key
FROM gold.dim_customers;


-- 02_TABLE : Create dim_products
CREATE TABLE gold.dim_products
(
    product_key BIGINT IDENTITY(1,1) PRIMARY KEY, -- Gold : surrogate key.
    product_id VARCHAR(50) NOT NULL,              -- Silver : original product ID.
    product_category_name NVARCHAR(100),
    product_category_name_english NVARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,

    CONSTRAINT UQ_dim_products_product_id UNIQUE (product_id)
);
GO

-- Load dim_products :
INSERT INTO gold.dim_products
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
FROM silver.olist_products;
GO

-- Validate row count : Check karo Silver aur Gold mein same number of products hain ya nahi.
SELECT
    (SELECT COUNT(*) FROM silver.olist_products) AS silver_rows,
    (SELECT COUNT(*) FROM gold.dim_products) AS gold_rows;

-- Check duplicate product IDs
SELECT
    product_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Check NULL values
SELECT
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN product_category_name IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN product_category_name_english IS NULL THEN 1 ELSE 0 END) AS null_english_category,
    SUM(CASE WHEN product_weight_g IS NULL THEN 1 ELSE 0 END) AS null_weight,
    SUM(CASE WHEN product_length_cm IS NULL THEN 1 ELSE 0 END) AS null_length,
    SUM(CASE WHEN product_height_cm IS NULL THEN 1 ELSE 0 END) AS null_height,
    SUM(CASE WHEN product_width_cm IS NULL THEN 1 ELSE 0 END) AS null_width
FROM gold.dim_products;

/*
Column	                            NULL rows	Status
product_id	                                0	Passed
product_category_name	                  610	Expected
product_category_name_english	          623	Expected
product_weight_g	                        2	Expected
product_length_cm	                        2	Expected
product_height_cm	                        2	Expected
product_width_cm	                        2	Expected
*/

-- Check Silver vs Gold mismatches
SELECT COUNT(*) AS mismatched_records
FROM silver.olist_products s
INNER JOIN gold.dim_products g
    ON s.product_id = g.product_id
WHERE
    ISNULL(s.product_category_name, '') <> ISNULL(g.product_category_name, '')
    OR ISNULL(s.product_category_name_english, '') <> ISNULL(g.product_category_name_english, '')
    OR ISNULL(s.product_name_length, -1) <> ISNULL(g.product_name_length, -1)
    OR ISNULL(s.product_description_length, -1) <> ISNULL(g.product_description_length, -1)
    OR ISNULL(s.product_photos_qty, -1) <> ISNULL(g.product_photos_qty, -1)
    OR ISNULL(s.product_weight_g, -1) <> ISNULL(g.product_weight_g, -1)
    OR ISNULL(s.product_length_cm, -1) <> ISNULL(g.product_length_cm, -1)
    OR ISNULL(s.product_height_cm, -1) <> ISNULL(g.product_height_cm, -1)
    OR ISNULL(s.product_width_cm, -1) <> ISNULL(g.product_width_cm, -1);

-- Validate surrogate key
SELECT
    COUNT(*) AS total_rows,
    COUNT(product_key) AS non_null_keys,
    COUNT(DISTINCT product_key) AS unique_keys,
    MIN(product_key) AS first_key,
    MAX(product_key) AS last_key
FROM gold.dim_products;



-- 03_TABLE : Create gold.dim_sellers
CREATE TABLE gold.dim_sellers
(
    seller_key BIGINT IDENTITY(1,1) PRIMARY KEY, -- Gold surrogate key.
    seller_id VARCHAR(50) NOT NULL,              -- Original seller identifier
    seller_zip_code_prefix VARCHAR(10),
    seller_city NVARCHAR(100),
    seller_state CHAR(2),

    CONSTRAINT UQ_dim_sellers_seller_id UNIQUE (seller_id)
);
GO

-- Load dim_seller
INSERT INTO gold.dim_sellers
(
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM silver.olist_sellers;
GO

-- Validate row count
SELECT
    (SELECT COUNT(*) FROM silver.olist_sellers) AS silver_rows,
    (SELECT COUNT(*) FROM gold.dim_sellers) AS gold_rows;

-- Check duplicate seller IDs
SELECT
    seller_id,
    COUNT(*) AS duplicate_count
FROM gold.dim_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- Check NULL values
SELECT
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS null_seller_id,
    SUM(CASE WHEN seller_zip_code_prefix IS NULL THEN 1 ELSE 0 END) AS null_zip,
    SUM(CASE WHEN seller_city IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN seller_state IS NULL THEN 1 ELSE 0 END) AS null_state
FROM gold.dim_sellers;

-- Silver vs Gold mismatch check
SELECT COUNT(*) AS mismatched_records
FROM silver.olist_sellers s
INNER JOIN gold.dim_sellers g
    ON s.seller_id = g.seller_id
WHERE
    ISNULL(s.seller_zip_code_prefix, '') <> ISNULL(g.seller_zip_code_prefix, '')
    OR ISNULL(s.seller_city, '') <> ISNULL(g.seller_city, '')
    OR ISNULL(s.seller_state, '') <> ISNULL(g.seller_state, '');

-- Validate surrogate key
SELECT
    COUNT(*) AS total_rows,
    COUNT(seller_key) AS non_null_keys,
    COUNT(DISTINCT seller_key) AS unique_keys,
    MIN(seller_key) AS first_key,
    MAX(seller_key) AS last_key
FROM gold.dim_sellers;



-- 04_TABLE : Create gold.dim_date
-- Date dimension thoda different hoga. Isme source table se direct records copy nahi karenge; calendar dates generate karenge.
CREATE TABLE gold.dim_date
(
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    day_number TINYINT NOT NULL,
    month_number TINYINT NOT NULL,
    month_name NVARCHAR(20) NOT NULL,
    quarter_number TINYINT NOT NULL,
    year_number SMALLINT NOT NULL,
    week_number TINYINT NOT NULL,
    day_of_week TINYINT NOT NULL,
    day_name NVARCHAR(20) NOT NULL,
    is_weekend BIT NOT NULL
);
GO

/*
Important:
- date_key: Format YYYYMMDD, e.g. 20170115.
- full_date: Actual calendar date.
- quarter_number: 1–4.
- is_weekend: 1 = Saturday/Sunday, 0 = weekday.*/


-- Populate dim_date : Hum calendar range 1 Jan 2016 – 31 Dec 2018 rakhenge, taaki Olist dataset ke saare relevant dates cover ho sakein.

SET LANGUAGE us_english;
GO

WITH DateSeries AS
(
    SELECT CAST('2016-01-01' AS DATE) AS calendar_date

    UNION ALL

    SELECT DATEADD(DAY, 1, calendar_date)
    FROM DateSeries
    WHERE calendar_date < '2018-12-31'
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
    is_weekend
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), calendar_date, 112)),
    calendar_date,
    DAY(calendar_date),
    MONTH(calendar_date),
    DATENAME(MONTH, calendar_date),
    DATEPART(QUARTER, calendar_date),
    YEAR(calendar_date),
    DATEPART(ISO_WEEK, calendar_date),
    (DATEDIFF(DAY, '19000101', calendar_date) % 7) + 1,
    DATENAME(WEEKDAY, calendar_date),
    CASE
        WHEN (DATEDIFF(DAY, '19000101', calendar_date) % 7) + 1 IN (6, 7)
        THEN 1
        ELSE 0
    END
FROM DateSeries
OPTION (MAXRECURSION 0);
GO

/*
What this does:
- Recursive CTE generates every calendar date.
- date_key creates YYYYMMDD format.
- day_of_week: Monday = 1, Sunday = 7.
- week_number: ISO week number.
- is_weekend: Saturday/Sunday = 1.*/

SELECT COUNT(*) AS total_rows
FROM gold.dim_date;

-- Validate date range and duplicates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT date_key) AS unique_date_keys,
    COUNT(DISTINCT full_date) AS unique_dates,
    MIN(full_date) AS first_date,
    MAX(full_date) AS last_date
FROM gold.dim_date;

-- Validate date attributes
-- Ab check karenge ki month, quarter, weekday aur weekend correctly calculate hue hain.
SELECT TOP 15
    full_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number,
    week_number,
    day_of_week,
    day_name,
    is_weekend
FROM gold.dim_date
ORDER BY full_date;

-- 
ALTER TABLE gold.dim_date
ADD iso_year_number SMALLINT NULL;
GO

UPDATE gold.dim_date
SET iso_year_number =
    YEAR(
        DATEADD(
            DAY,
            4 - day_of_week,
            full_date
        )
    );
GO

ALTER TABLE gold.dim_date
ALTER COLUMN iso_year_number SMALLINT NOT NULL;
GO

-- check ISO year
SELECT
    full_date,
    year_number,
    week_number,
    iso_year_number,
    day_name
FROM gold.dim_date
WHERE full_date BETWEEN '2015-12-28' AND '2016-01-04'
ORDER BY full_date;

-- Validate weekend counts
SELECT
    is_weekend,
    COUNT(*) AS total_days
FROM gold.dim_date
GROUP BY is_weekend;

-- Validate date key consistency : Check karenge ki date_key aur full_date match karte hain.
SELECT COUNT(*) AS invalid_date_keys
FROM gold.dim_date
WHERE date_key <> CONVERT(INT, CONVERT(CHAR(8), full_date, 112));



-- 05_TABLE : Create gold.dim_payment_type
CREATE TABLE gold.dim_payment_type
(
    payment_type_key INT IDENTITY(1,1) PRIMARY KEY,  -- payment_type_key: Surrogate key.
    payment_type VARCHAR(30) NOT NULL,               -- payment_type: Payment method, e.g. credit_card, boleto, voucher, debit_card.

    CONSTRAINT UQ_dim_payment_type UNIQUE (payment_type) -- Unique constraint: Duplicate payment types prevent karega.

);
GO

-- Load dim_payment_type
INSERT INTO gold.dim_payment_type (payment_type)
SELECT DISTINCT payment_type
FROM silver.olist_order_payments
WHERE payment_type IS NOT NULL;
GO

-- Check payment types
SELECT
    payment_type_key,
    payment_type
FROM gold.dim_payment_type
ORDER BY payment_type_key;

-- Validate duplicates and NULLs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT payment_type) AS unique_types,
    SUM(CASE WHEN payment_type IS NULL THEN 1 ELSE 0 END) AS null_types
FROM gold.dim_payment_type;

-- Validate against Silver
SELECT COUNT(DISTINCT payment_type) AS silver_types
FROM silver.olist_order_payments
WHERE payment_type IS NOT NULL;

SELECT COUNT(*) AS unmatched_types
FROM
(
    SELECT DISTINCT payment_type
    FROM silver.olist_order_payments
    WHERE payment_type IS NOT NULL
) s
LEFT JOIN gold.dim_payment_type g
    ON s.payment_type = g.payment_type
WHERE g.payment_type IS NULL;


-- 06_TABLE : Create gold.dim_order_status
CREATE TABLE gold.dim_order_status
(
    order_status_key INT IDENTITY(1,1) PRIMARY KEY, -- order_status_key: Surrogate key.
    order_status VARCHAR(30) NOT NULL,              -- order_status: Order lifecycle status, e.g. delivered, shipped, canceled, processing.

    CONSTRAINT UQ_dim_order_status UNIQUE (order_status)    -- Unique constraint: Duplicate statuses prevent karega.
);
GO

-- Load dim_order_status
INSERT INTO gold.dim_order_status (order_status)
SELECT DISTINCT order_status
FROM silver.olist_orders
WHERE order_status IS NOT NULL;
GO

-- Check loaded order statuses
SELECT
    order_status_key,
    order_status
FROM gold.dim_order_status
ORDER BY order_status_key;

-- Validate duplicates and NULLs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_status) AS unique_statuses,
    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END) AS null_statuses
FROM gold.dim_order_status;

-- Validate against Silver
SELECT COUNT(DISTINCT order_status) AS silver_statuses
FROM silver.olist_orders
WHERE order_status IS NOT NULL;

SELECT COUNT(*) AS unmatched_statuses
FROM
(
    SELECT DISTINCT order_status
    FROM silver.olist_orders
    WHERE order_status IS NOT NULL
) s
LEFT JOIN gold.dim_order_status g
    ON s.order_status = g.order_status
WHERE g.order_status IS NULL;


