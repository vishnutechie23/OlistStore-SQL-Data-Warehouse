-- =====================================================
-- Gold Layer: Table Creation
-- Project: Olist Store SQL Data Warehouse
-- Purpose: Create Gold dimension and fact tables
--          with primary keys, foreign keys and constraints
-- Total Tables: 10 (6 Dimensions + 4 Facts)
-- =====================================================


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

ALTER TABLE gold.dim_customers
ADD CONSTRAINT UQ_dim_customers_customer_id
UNIQUE (customer_id);

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



-- 05_TABLE : Create gold.dim_payment_type
CREATE TABLE gold.dim_payment_type
(
    payment_type_key INT IDENTITY(1,1) PRIMARY KEY,  -- payment_type_key: Surrogate key.
    payment_type VARCHAR(30) NOT NULL,               -- payment_type: Payment method, e.g. credit_card, boleto, voucher, debit_card.

    CONSTRAINT UQ_dim_payment_type UNIQUE (payment_type) -- Unique constraint: Duplicate payment types prevent karega.

);
GO



-- 06_TABLE : Create gold.dim_order_status
CREATE TABLE gold.dim_order_status
(
    order_status_key INT IDENTITY(1,1) PRIMARY KEY, -- order_status_key: Surrogate key.
    order_status VARCHAR(30) NOT NULL,              -- order_status: Order lifecycle status, e.g. delivered, shipped, canceled, processing.

    CONSTRAINT UQ_dim_order_status UNIQUE (order_status)    -- Unique constraint: Duplicate statuses prevent karega.
);
GO




-- 07_TABLE : Create gold.fact_orders
/*
Important columns:
- order_id: One unique order.
- Date keys: Connect the same date dimension for different order events.
- approval_hours: Time taken for approval.
- delivery_days: Purchase to actual customer delivery.
- delivery_delay_days: Actual delivery date minus estimated delivery date.
- is_delivered / is_canceled: Business analysis flags.
*/
CREATE TABLE gold.fact_orders
(
    order_id VARCHAR(50) NOT NULL PRIMARY KEY,

    customer_key BIGINT NOT NULL,
    order_status_key INT NOT NULL,

    purchase_date_key INT NOT NULL,
    approved_date_key INT,
    delivered_carrier_date_key INT,
    delivered_customer_date_key INT,
    estimated_delivery_date_key INT,

    order_count TINYINT NOT NULL DEFAULT 1,

    approval_hours DECIMAL(10,2),
    delivery_days INT,
    estimated_delivery_days INT,
    delivery_delay_days INT,

    is_delivered BIT NOT NULL,
    is_canceled BIT NOT NULL,

    CONSTRAINT FK_fact_orders_customers
        FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customers(customer_key),

    CONSTRAINT FK_fact_orders_status
        FOREIGN KEY (order_status_key)
        REFERENCES gold.dim_order_status(order_status_key),

    CONSTRAINT FK_fact_orders_purchase_date
        FOREIGN KEY (purchase_date_key)
        REFERENCES gold.dim_date(date_key),

    CONSTRAINT FK_fact_orders_approved_date
        FOREIGN KEY (approved_date_key)
        REFERENCES gold.dim_date(date_key),

    CONSTRAINT FK_fact_orders_carrier_date
        FOREIGN KEY (delivered_carrier_date_key)
        REFERENCES gold.dim_date(date_key),

    CONSTRAINT FK_fact_orders_customer_delivery_date
        FOREIGN KEY (delivered_customer_date_key)
        REFERENCES gold.dim_date(date_key),

    CONSTRAINT FK_fact_orders_estimated_date
        FOREIGN KEY (estimated_delivery_date_key)
        REFERENCES gold.dim_date(date_key)
);
GO

-- Verify fact_orders structure
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
  AND TABLE_NAME = 'fact_orders'
ORDER BY ORDINAL_POSITION;



-- 08_TABLE : Create gold.fact_order_items
-- Grain: One row per order item line (order_id + order_item_id)
CREATE TABLE gold.fact_order_items
(
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,

    customer_key BIGINT NOT NULL,
    product_key BIGINT NOT NULL,
    seller_key BIGINT NOT NULL,

    purchase_date_key INT NOT NULL,
    shipping_limit_date_key INT,

    item_count TINYINT NOT NULL DEFAULT 1,

    price DECIMAL(10,2) NOT NULL,
    freight_value DECIMAL(10,2) NOT NULL,
    item_total_value DECIMAL(10,2) NOT NULL,

    CONSTRAINT PK_fact_order_items
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT FK_fact_order_items_customers
        FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customers(customer_key),

    CONSTRAINT FK_fact_order_items_products
        FOREIGN KEY (product_key)
        REFERENCES gold.dim_products(product_key),

    CONSTRAINT FK_fact_order_items_sellers
        FOREIGN KEY (seller_key)
        REFERENCES gold.dim_sellers(seller_key),

    CONSTRAINT FK_fact_order_items_purchase_date
        FOREIGN KEY (purchase_date_key)
        REFERENCES gold.dim_date(date_key),

    CONSTRAINT FK_fact_order_items_shipping_date
        FOREIGN KEY (shipping_limit_date_key)
        REFERENCES gold.dim_date(date_key)
);
GO

/*
Key points:
- Composite primary key ensures each order item line is unique.
- item_total_value = price + freight_value.
- order_id is retained for traceability; no fact-to-fact foreign key is created.
- Customer, product and seller keys support analysis.*/





-- 09_TABLE : Create gold.fact_payments – Step 1
-- Grain: One row per payment transaction (order_id + payment_sequential).

CREATE TABLE gold.fact_payments
(
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,

    customer_key BIGINT NOT NULL,
    payment_type_key INT NOT NULL,
    purchase_date_key INT NOT NULL,

    payment_count TINYINT NOT NULL DEFAULT 1,

    payment_installments INT,
    payment_value DECIMAL(10,2) NOT NULL,

    CONSTRAINT PK_fact_payments
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT FK_fact_payments_customers
        FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customers(customer_key),

    CONSTRAINT FK_fact_payments_type
        FOREIGN KEY (payment_type_key)
        REFERENCES gold.dim_payment_type(payment_type_key),

    CONSTRAINT FK_fact_payments_date
        FOREIGN KEY (purchase_date_key)
        REFERENCES gold.dim_date(date_key)
);
GO
-- This stores payment amount, type, installments and customer/date keys.




-- 10_TABLE : Create fact_reviews One row per review record.
CREATE TABLE gold.fact_reviews
(
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,

    customer_key BIGINT NOT NULL,

    review_creation_date_key INT,
    review_answer_date_key INT,

    review_count TINYINT NOT NULL DEFAULT 1,
    review_score TINYINT NOT NULL,

    CONSTRAINT PK_fact_reviews
        PRIMARY KEY (review_id, order_id),

    CONSTRAINT FK_fact_reviews_customers
        FOREIGN KEY (customer_key)
        REFERENCES gold.dim_customers(customer_key),

    CONSTRAINT FK_fact_reviews_creation_date
        FOREIGN KEY (review_creation_date_key)
        REFERENCES gold.dim_date(date_key),

    CONSTRAINT FK_fact_reviews_answer_date
        FOREIGN KEY (review_answer_date_key)
        REFERENCES gold.dim_date(date_key),

    CONSTRAINT CK_fact_reviews_score
        CHECK (review_score BETWEEN 1 AND 5)
);
GO

/*
Important:
- Composite Primary Key: review_id + order_id.
- review_score stores ratings from 1 to 5.
- Review creation and answer dates are separate date relationships.
- order_id is retained for traceability.*/



