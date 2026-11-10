-- FOR olist_customers

USE OlistStore_DW;
GO

/*
========================================================
 BRONZE LAYER - LOAD VERIFICATION
 Purpose:
 1. Verify total records in all Bronze tables.
 2. Verify sample records from all Bronze tables.
========================================================
*/


-- ============================================
-- 1. VERIFY CUSTOMERS
-- ============================================

-- Verify row count
SELECT COUNT(*) AS total_customers
FROM bronze.olist_customers;

-- Verify sample records
SELECT TOP 15 *
FROM bronze.olist_customers;


-- ============================================
-- 2. VERIFY ORDERS
-- ============================================

SELECT COUNT(*) AS total_orders
FROM bronze.olist_orders;

SELECT TOP 10 *
FROM bronze.olist_orders;


-- ============================================
-- 3. VERIFY ORDER ITEMS
-- ============================================

SELECT COUNT(*) AS total_order_items
FROM bronze.olist_order_items;

SELECT TOP 10 *
FROM bronze.olist_order_items;


-- ============================================
-- 4. VERIFY ORDER PAYMENTS
-- ============================================

SELECT COUNT(*) AS total_payments
FROM bronze.olist_order_payments;

SELECT TOP 10 *
FROM bronze.olist_order_payments;


-- ============================================
-- 5. VERIFY ORDER REVIEWS
-- ============================================

SELECT COUNT(*) AS total_reviews
FROM bronze.olist_order_reviews;

SELECT TOP 10 *
FROM bronze.olist_order_reviews;


-- ============================================
-- 6. VERIFY PRODUCTS
-- ============================================

SELECT COUNT(*) AS total_products
FROM bronze.olist_products;

SELECT TOP 10 *
FROM bronze.olist_products;


-- ============================================
-- 7. VERIFY SELLERS
-- ============================================

SELECT COUNT(*) AS total_sellers
FROM bronze.olist_sellers;

SELECT TOP 10 *
FROM bronze.olist_sellers;


-- ============================================
-- 8. VERIFY GEOLOCATION
-- ============================================

SELECT COUNT(*) AS total_geolocation
FROM bronze.olist_geolocation;

SELECT TOP 10 *
FROM bronze.olist_geolocation;


-- ============================================
-- 9. VERIFY CATEGORY TRANSLATION
-- ============================================

SELECT COUNT(*) AS total_categories
FROM bronze.olist_category_translation;

SELECT TOP 10 *
FROM bronze.olist_category_translation;


-- ============================================
-- 10. VERIFY ALL BRONZE TABLE ROW COUNTS
-- ============================================

SELECT 'olist_customers' AS table_name, COUNT(*) AS total_rows
FROM bronze.olist_customers

UNION ALL

SELECT 'olist_orders', COUNT(*)
FROM bronze.olist_orders

UNION ALL

SELECT 'olist_order_items', COUNT(*)
FROM bronze.olist_order_items

UNION ALL

SELECT 'olist_order_payments', COUNT(*)
FROM bronze.olist_order_payments

UNION ALL

SELECT 'olist_order_reviews', COUNT(*)
FROM bronze.olist_order_reviews

UNION ALL

SELECT 'olist_products', COUNT(*)
FROM bronze.olist_products

UNION ALL

SELECT 'olist_sellers', COUNT(*)
FROM bronze.olist_sellers

UNION ALL

SELECT 'olist_geolocation', COUNT(*)
FROM bronze.olist_geolocation

UNION ALL

SELECT 'olist_category_translation', COUNT(*)
FROM bronze.olist_category_translation;

