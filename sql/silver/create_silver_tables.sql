-- CREATE Tables DDL
USE OlistStore_DW;
GO
-- Create Silver Customers Table

CREATE TABLE silver.olist_customers
(
    customer_id VARCHAR(50) NOT NULL,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city NVARCHAR(100),
    customer_state CHAR(2),

    CONSTRAINT PK_silver_olist_customers
        PRIMARY KEY (customer_id)
);
GO

/* Samjho:
- customer_id — Primary Key, unique customer record identify karega.
- customer_unique_id — Same real customer ko identify karne ke liye.
- ZIP prefix VARCHAR rakha hai, taaki leading zeros preserve hon.
- NOT NULL — dono IDs mandatory hain.*/

-- Create Silver Orders Table
CREATE TABLE silver.olist_orders
(
    order_id VARCHAR(50) NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    order_status VARCHAR(30),
    order_purchase_timestamp DATETIME2(0),
    order_approved_at DATETIME2(0),
    order_delivered_carrier_date DATETIME2(0),
    order_delivered_customer_date DATETIME2(0),
    order_estimated_delivery_date DATETIME2(0),

    CONSTRAINT PK_silver_olist_orders
        PRIMARY KEY (order_id),

    CONSTRAINT FK_silver_orders_customers
        FOREIGN KEY (customer_id)
        REFERENCES silver.olist_customers(customer_id)
);
GO

/* Samjho:
- order_id → Primary Key.
- customer_id → Foreign Key referencing Silver Customers.
- DATETIME2(0) → Order timestamps store karega.
- Ek customer record ke against order relationship enforce hoga.*/


-- Create Silver Products Table
CREATE TABLE silver.olist_products
(
    product_id VARCHAR(50) NOT NULL,
    product_category_name NVARCHAR(100),
    product_category_name_english NVARCHAR(100),
    product_name_length INT,
    product_description_length INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,

    CONSTRAINT PK_silver_olist_products
        PRIMARY KEY (product_id)
);
GO

/* Important:
- product_id → Primary Key.
- English category column translation table se populate karenge.
- Dono category columns nullable rahenge, kyunki source mein missing/untranslated categories hain.
- Source column spelling product_name_lenght ko Silver mein correct karke product_name_length rakha hai.*/


-- Create Silver Sellers Table
CREATE TABLE silver.olist_sellers
(
    seller_id VARCHAR(50) NOT NULL,
    seller_zip_code_prefix VARCHAR(10),
    seller_city NVARCHAR(100),
    seller_state CHAR(2),

    CONSTRAINT PK_silver_olist_sellers
        PRIMARY KEY (seller_id)
);
GO


/* Samjho:
- seller_id → Primary Key.
- ZIP prefix VARCHAR(10) hai, leading zeros preserve karne ke liye.
- Seller details clean format mein store hongi.*/


-- Create Silver Order Items Table
CREATE TABLE silver.olist_order_items
(
    order_id VARCHAR(50) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(50) NOT NULL,
    seller_id VARCHAR(50) NOT NULL,
    shipping_limit_date DATETIME2(0),
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),

    CONSTRAINT PK_silver_olist_order_items
        PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT FK_silver_items_orders
        FOREIGN KEY (order_id)
        REFERENCES silver.olist_orders(order_id),

    CONSTRAINT FK_silver_items_products
        FOREIGN KEY (product_id)
        REFERENCES silver.olist_products(product_id),

    CONSTRAINT FK_silver_items_sellers
        FOREIGN KEY (seller_id)
        REFERENCES silver.olist_sellers(seller_id)
);
GO


/* Samjho:
- Composite Primary Key: (order_id, order_item_id).
- 3 Foreign Keys: Orders, Products aur Sellers.
- price aur freight_value decimal mein store honge.*/


-- Create Silver Order Payments Table
CREATE TABLE silver.olist_order_payments
(
    order_id VARCHAR(50) NOT NULL,
    payment_sequential INT NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10,2),

    CONSTRAINT PK_silver_olist_order_payments
        PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT FK_silver_payments_orders
        FOREIGN KEY (order_id)
        REFERENCES silver.olist_orders(order_id)
);
GO


/*Samjho:
- Composite Primary Key: (order_id, payment_sequential).
- Foreign Key: order_id → Orders.
- payment_value → Payment amount in BRL.
Important: Execute karne se pehle ek baar verify karenge ki composite key unique hai.*/

SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS duplicate_count
FROM bronze.olist_order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;


-- Create Silver Order Reviews Table
-- Pehle review_id unique nahi hai, isliye Silver mein surrogate key review_key use karenge.
SELECT
    review_id,
    order_id,
    COUNT(*) AS duplicate_count
FROM bronze.olist_order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

CREATE TABLE silver.olist_order_reviews
(
    review_key BIGINT IDENTITY(1,1) NOT NULL,
    review_id VARCHAR(50) NOT NULL,
    order_id VARCHAR(50) NOT NULL,
    review_score INT,
    review_comment_title NVARCHAR(MAX),
    review_comment_message NVARCHAR(MAX),
    review_creation_date DATETIME2(0),
    review_answer_timestamp DATETIME2(0),

    CONSTRAINT PK_silver_olist_order_reviews
        PRIMARY KEY (review_key),

    CONSTRAINT UQ_silver_reviews_review_order
        UNIQUE (review_id, order_id),

    CONSTRAINT FK_silver_reviews_orders
        FOREIGN KEY (order_id)
        REFERENCES silver.olist_orders(order_id)
);
GO

/*Samjho:
- review_key → Surrogate Primary Key.
- (review_id, order_id) → Unique combination.
- order_id → Foreign Key to Orders.*/


-- Create Silver Geolocation Table
-- Geolocation mein ZIP prefix unique nahi hai. Isliye surrogate key use karenge.

CREATE TABLE silver.olist_geolocation
(
    geolocation_key BIGINT IDENTITY(1,1) NOT NULL,
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DECIMAL(10,7),
    geolocation_lng DECIMAL(10,7),
    geolocation_city NVARCHAR(100),
    geolocation_state CHAR(2),

    CONSTRAINT PK_silver_olist_geolocation
        PRIMARY KEY (geolocation_key)
);
GO


/*Samjho:
- geolocation_key → Unique surrogate Primary Key.
- ZIP prefix par PK/FK nahi banayenge.
- Duplicate geolocation records ko Silver transformation mein investigate karenge.*/


-- Create Silver Category Translation Table
CREATE TABLE silver.olist_category_translation
(
    product_category_name NVARCHAR(100) NOT NULL,
    product_category_name_english NVARCHAR(100),

    CONSTRAINT PK_silver_category_translation
        PRIMARY KEY (product_category_name)
);
GO


/* Samjho:
- product_category_name → Primary Key.
- English category translation nullable hai.
- Products table se abhi Foreign Key nahi banayenge, kyunki 13 products ki categories translation file mein missing hain.*/


-- Verify all tables 
USE OlistStore_DW;
GO

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'silver'
ORDER BY TABLE_NAME;

