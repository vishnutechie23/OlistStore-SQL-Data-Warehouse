-- Customers -- orders
/*
Our first logical relationship is:
bronze.olist_customers
customer_id — Candidate PK
1 : 1 in this dataset
bronze.olist_orders
customer_id — Candidate FK
First, verify that customer_id is unique in Customers and that every order has a matching customer.
*/
-- Relationship: Customers (1) → Orders (1) in this dataset.
-- Technically, each order belongs to one customer, and each customer has exactly one order in this dataset.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM bronze.olist_customers;

SELECT COUNT(*) AS unmatched_orders
FROM bronze.olist_orders o
LEFT JOIN bronze.olist_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- orders -- orders_item
-- Order Items (Many)
-- One-to-Many (1:N)
-- PK: Orders.order_id → FK: Order_Items.order_id

SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM bronze.olist_orders;

SELECT
    COUNT(*) AS total_items,
    COUNT(DISTINCT order_id) AS orders_with_items,
    COUNT(DISTINCT CONCAT(order_id, '-', order_item_id)) AS unique_order_items
FROM bronze.olist_order_items;

SELECT COUNT(*) AS unmatched_order_items
FROM bronze.olist_order_items oi
LEFT JOIN bronze.olist_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Orders ↔ Order Payments
SELECT
    COUNT(*) AS total_payment_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM bronze.olist_order_payments;

SELECT COUNT(*) AS unmatched_payments
FROM bronze.olist_order_payments p
LEFT JOIN bronze.olist_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;
-- Relationship: Orders (1) → Order Payments (Many)
-- One order can have multiple payment records because of payment_sequential.

-- Orders ↔ Order Reviews
-- Relationship: Orders (1) → Order Reviews (Many)
-- Some orders have multiple reviews, so don't assume order_id is unique in Reviews
SELECT
    COUNT(*) AS total_reviews,
    COUNT(DISTINCT review_id) AS unique_reviews,
    COUNT(DISTINCT order_id) AS unique_orders
FROM bronze.olist_order_reviews;

SELECT COUNT(*) AS unmatched_reviews
FROM bronze.olist_order_reviews r
LEFT JOIN bronze.olist_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Products ↔ Order :  Items Relationship: Products (1) → Order Items (Many)
-- products.product_id (PK) → order_items.product_id (FK)
SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products
FROM bronze.olist_products;

SELECT COUNT(*) AS unmatched_products
FROM bronze.olist_order_items oi
LEFT JOIN bronze.olist_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;


-- Sellers ↔ Order Items
/*
Relationship verified
- Sellers: 3,095 unique seller_id.
- Unmatched order items: 0.
Relationship: Sellers (1) → Order Items (Many)
 sellers.seller_id (PK) → order_items.seller_id (FK)
*/
SELECT
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT seller_id) AS unique_sellers
FROM bronze.olist_sellers;

SELECT COUNT(*) AS unmatched_sellers
FROM bronze.olist_order_items oi
LEFT JOIN bronze.olist_sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;


-- Products ↔ Category Translation
SELECT
    COUNT(*) AS total_categories,
    COUNT(DISTINCT product_category_name) AS unique_categories
FROM bronze.olist_category_translation;

SELECT COUNT(*) AS unmatched_categories
FROM bronze.olist_products p
LEFT JOIN bronze.olist_category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL;

  -- identify unmatched categories
  SELECT
    p.product_category_name,
    COUNT(*) AS product_count
FROM bronze.olist_products p
LEFT JOIN bronze.olist_category_translation ct
    ON p.product_category_name = ct.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND ct.product_category_name IS NULL
GROUP BY p.product_category_name;
-- These categories are missing from the translation CSV. 
-- We'll preserve them in Silver and handle missing English translations appropriately.




-- Geolocation relationship check
-- Geolocation ZIP prefixes are not unique, so we must not treat them as a primary key.

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_prefixes
FROM bronze.olist_geolocation;

SELECT
    COUNT(*) AS total_customer_rows,
    COUNT(DISTINCT customer_zip_code_prefix) AS unique_customer_zip_prefixes
FROM bronze.olist_customers;

SELECT
    COUNT(*) AS total_seller_rows,
    COUNT(DISTINCT seller_zip_code_prefix) AS unique_seller_zip_prefixes
FROM bronze.olist_sellers;


/*
Final relationship overview
Our main relationships identified so far:
- Customers → Orders (1:1 in this dataset)
- Orders → Order Items (1:N)
- Orders → Payments (1:N)
- Orders → Reviews (1:N)
- Products → Order Items (1:N)
- Sellers → Order Items (1:N)
- Products → Category Translation (logical lookup)
- Customers/Sellers → Geolocation (ZIP-prefix lookup, non-unique)

Next, we'll record these findings in sql/bronze/identify_bronze_relationships.sql and prepare the ER diagram.
*/