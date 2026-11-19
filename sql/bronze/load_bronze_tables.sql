
/*
========================================================
 OLIST STORE - BRONZE LAYER DATA LOADING
 Database: OlistStore_DW
 Purpose: Load raw CSV datasets into Bronze tables
========================================================
*/

-- Check BULK INSERT permission
SELECT IS_SRVROLEMEMBER('bulkadmin') AS is_bulkadmin;

USE OlistStore_DW;
GO

/*
========================================================
 1. LOAD CUSTOMERS
 Source: olist_customers_dataset.csv
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_customers;

    BULK INSERT bronze.olist_customers
    FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_customers_dataset.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        CODEPAGE = '65001',
        TABLOCK
    );

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_customers;

    IF @rows <> 99441
        THROW 50001, 'Customer row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Customers loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO


/*
========================================================
 2. LOAD ORDERS
 Source: olist_orders_dataset.csv
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_orders;

    BULK INSERT bronze.olist_orders
    FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_orders_dataset.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        CODEPAGE = '65001',
        TABLOCK
    );

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_orders;

    IF @rows <> 99441
        THROW 50001, 'Orders row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Orders loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO


/*
========================================================
 3. LOAD ORDER ITEMS
 Source: olist_order_items_dataset.csv
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_order_items;

    BULK INSERT bronze.olist_order_items
    FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_order_items_dataset.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        CODEPAGE = '65001',
        TABLOCK
    );

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_order_items;

    IF @rows <> 112650
        THROW 50001, 'Order Items row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Order Items loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO


/*
========================================================
 4. LOAD ORDER PAYMENTS
 Source: olist_order_payments_dataset.csv
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_order_payments;

    BULK INSERT bronze.olist_order_payments
    FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_order_payments_dataset.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        CODEPAGE = '65001',
        TABLOCK
    );

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_order_payments;

    IF @rows <> 103886
        THROW 50001, 'Payment row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Payments loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO


/*
========================================================
 5. LOAD REVIEWS
 Source: olist_order_reviews_dataset.csv
 Target: bronze.olist_order_reviews

 Direct CSV loading:
 - SQL Server handles quoted fields and embedded line breaks.
 - Review comments are preserved as NVARCHAR(MAX).
 - Empty fields are loaded as NULL.
 - Dates and scores are loaded directly into target types.
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_order_reviews;

    BULK INSERT bronze.olist_order_reviews
    FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_order_reviews_dataset.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0d0a',
        CODEPAGE = '65001',
        TABLOCK
    );

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_order_reviews;

    IF @rows <> 99224
        THROW 50001, 'Reviews row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Reviews loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO


/*
========================================================
 6. LOAD PRODUCTS
 Source: olist_products_dataset.csv
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_products;

    BULK INSERT bronze.olist_products
    FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_products_dataset.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        CODEPAGE = '65001',
        TABLOCK
    );

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_products;

    IF @rows <> 32951
        THROW 50001, 'Products row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Products loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO


/*
========================================================
 7. LOAD SELLERS
 Source: olist_sellers_dataset.csv
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_sellers;

    BULK INSERT bronze.olist_sellers
    FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_sellers_dataset.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        CODEPAGE = '65001',
        TABLOCK
    );

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_sellers;

    IF @rows <> 3095
        THROW 50001, 'Sellers row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Sellers loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO


/*
========================================================
 8. LOAD GEOLOCATION
 Source: olist_geolocation_dataset.csv
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_geolocation;

    BULK INSERT bronze.olist_geolocation
    FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_geolocation_dataset.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        CODEPAGE = '65001',
        TABLOCK
    );

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_geolocation;

    IF @rows <> 1000163
        THROW 50001, 'Geolocation row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Geolocation loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO


/*
========================================================
 9. LOAD CATEGORY TRANSLATION
 Source: product_category_name_translation.csv
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_category_translation;

    BULK INSERT bronze.olist_category_translation
    FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\product_category_name_translation.csv'
    WITH
    (
        FORMAT = 'CSV',
        FIRSTROW = 2,
        FIELDQUOTE = '"',
        FIELDTERMINATOR = ',',
        ROWTERMINATOR = '0x0a',
        CODEPAGE = '65001',
        TABLOCK
    );

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_category_translation;

    IF @rows <> 71
        THROW 50001, 'Category Translation row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Category Translation loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO


