-- Create table DDL
/*
Explanation
- CREATE TABLE: Creates the Orders table inside the Bronze schema.
- VARCHAR: Stores IDs and status as text.
- DATETIME2(0): Stores timestamps with seconds precision.
- No primary key or NOT NULL constraints yet. Bronze should preserve source records, while we'll validate data quality in Silver.
*/

USE OlistStore_DW;
GO
-- olist_orders
CREATE TABLE bronze.olist_orders
(
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME2(0),
    order_approved_at DATETIME2(0),
    order_delivered_carrier_date DATETIME2(0),
    order_delivered_customer_date DATETIME2(0),
    order_estimated_delivery_date DATETIME2(0)
);
GO

/*
IDs: VARCHAR(50) because they are identifiers, not numbers.
ZIP prefix: VARCHAR(10) to preserve leading zeros.
City: NVARCHAR(100) supports Unicode text.
State: CHAR(2) because state codes have two characters.
*/


USE OlistStore_DW;
GO
-- olist_customers
CREATE TABLE bronze.olist_customers
(
    customer_id VARCHAR(50),
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city NVARCHAR(100),
    customer_state CHAR(2)
);
GO


/*
Data types:
- IDs → VARCHAR(50)
- Item number → INT
- Shipping date → DATETIME2(0)
- Price and freight → DECIMAL(10,2) for monetary values.
*/

-- olist_order_items

CREATE TABLE bronze.olist_order_items
(
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME2(0),
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
);
GO

/*
order_id → Text identifier
payment_sequential → Payment sequence number
payment_type → Payment method.
payment_installments → Number of installments.
payment_value → Monetary value with 2 decimal places.
*/

-- olist_order_payments
CREATE TABLE bronze.olist_order_payments
(
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2)
);
GO


/*
IDs → VARCHAR(50)
review_score → INT
Review comments → NVARCHAR(MAX) because text length varies
Review dates → DATETIME2(0)
Missing review comments and timestamps can be stored as NULL.
*/

-- olist_order_reviews
CREATE TABLE bronze.olist_order_reviews
(
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title NVARCHAR(MAX),
    review_comment_message NVARCHAR(MAX),
    review_creation_date DATETIME2(0),
    review_answer_timestamp DATETIME2(0)
);
GO

/*
Data types:
- product_id → VARCHAR(50)
- product_category_name → NVARCHAR(100)
- Length, quantity, weight and dimensions → INT.
- Nullable product attributes will accept NULL.
Note: We are preserving the original source column spelling lenght.
*/

-- olist_products
CREATE TABLE bronze.olist_products
(
    product_id VARCHAR(50),
    product_category_name NVARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);
GO

/*
Seller ID → VARCHAR(50)
ZIP prefix → VARCHAR(10) to preserve leading zeros.
City → NVARCHAR(100)
State → CHAR(2)
*/

-- olist_sellers
CREATE TABLE bronze.olist_sellers
(
    seller_id VARCHAR(50),
    seller_zip_code_prefix VARCHAR(10),
    seller_city NVARCHAR(100),
    seller_state CHAR(2)
);
GO

/*
Data types:
- ZIP prefix → VARCHAR(10) to preserve leading zeros.
- Latitude/Longitude → DECIMAL(10,7) for geographic precision.
- City → NVARCHAR(100).
- State → CHAR(2).
*/

CREATE TABLE bronze.olist_geolocation
(
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DECIMAL(10,7),
    geolocation_lng DECIMAL(10,7),
    geolocation_city NVARCHAR(100),
    geolocation_state CHAR(2)
);
GO

-- NVARCHAR(100)? : Category names may contain Portuguese characters and accents, so Unicode support is useful.
-- olist_category_translation
CREATE TABLE bronze.olist_category_translation
(
    product_category_name NVARCHAR(100),
    product_category_name_english NVARCHAR(100)
);
GO

-- verify 
SELECT TABLE_SCHEMA, TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'bronze'
ORDER BY TABLE_NAME;

