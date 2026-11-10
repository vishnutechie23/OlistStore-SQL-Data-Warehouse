
/*
========================================================
 OLIST STORE - BRONZE LAYER DATA LOADING
 Database: OlistStore_DW
 Purpose: Load raw CSV/TSV datasets into Bronze tables
========================================================
*/

-- Start 
SELECT
    IS_SRVROLEMEMBER('bulkadmin') AS is_bulkadmin;

-- check file access >
SELECT *
FROM OPENROWSET(
    BULK 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_customers_dataset.csv',
    SINGLE_CLOB
) AS csv_file;

SELECT *
FROM OPENROWSET(
    BULK 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_customers_dataset.csv',
    SINGLE_CLOB
) AS csv_file;

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

    -- Remove existing data before reloading
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

    -- Validate expected row count
    IF @rows <> 99441
        THROW 50001, 'Customer row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Customers loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

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
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

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
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

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
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO


/*
========================================================
 5. REVIEWS - CREATE STAGING TABLE
 Purpose:
 - Temporary raw landing area for normalized review data.
 - Store incoming TSV values as NVARCHAR.
 - Conditional creation prevents table-exists errors.
========================================================
*/

IF OBJECT_ID('dbo.review_bulk_test', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.review_bulk_test
    (
        review_id NVARCHAR(100),
        order_id NVARCHAR(100),
        review_score NVARCHAR(20),
        review_comment_title NVARCHAR(500),
        review_comment_message NVARCHAR(1000),
        review_creation_date NVARCHAR(50),
        review_answer_timestamp NVARCHAR(50)
    );

    PRINT 'Reviews staging table created successfully!';
END
ELSE
BEGIN
    PRINT 'Reviews staging table already exists!';
END;
GO


/*
========================================================
 6. REVIEWS - LOAD TSV INTO STAGING TABLE
 Source: olist_order_reviews_normalized.tsv

 Why TSV?
 Original review CSV has multiline/formatting issues.
 PowerShell normalized it into one record per line.
 Tab delimiter avoids conflicts with commas in comments.
========================================================
*/

-- Clear previous staging data before every reload
TRUNCATE TABLE dbo.review_bulk_test;

-- Load normalized TSV into staging
BULK INSERT dbo.review_bulk_test
FROM 'C:\OlistStore-SQL-Data-Warehouse\dataset\olist_order_reviews_normalized.tsv'
WITH
(
    FIELDTERMINATOR = '0x09',  -- Tab delimiter
    ROWTERMINATOR = '0x0a',
    CODEPAGE = '65001',
    TABLOCK
);

-- Validate staging row count
DECLARE @staging_rows INT;

SELECT @staging_rows = COUNT(*)
FROM dbo.review_bulk_test;

IF @staging_rows <> 99224
    THROW 50001, 'Reviews staging row count mismatch!', 1;

PRINT 'Reviews staging loaded successfully!';
PRINT 'Staging rows: ' + CAST(@staging_rows AS VARCHAR(20));
GO


/*
========================================================
 7. REVIEWS - TRANSFORM AND LOAD INTO BRONZE
 Source: dbo.review_bulk_test
 Target: bronze.olist_order_reviews

 Transformations:
 - Convert review_score into INT.
 - Convert empty comment fields into NULL.
 - Remove CHAR(13) carriage return from date fields.
 - Convert date strings into DATETIME2.
========================================================
*/

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    TRUNCATE TABLE bronze.olist_order_reviews;

    INSERT INTO bronze.olist_order_reviews
    (
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp
    )
    SELECT
        review_id,
        order_id,
        CONVERT(INT, NULLIF(review_score, '')),
        NULLIF(review_comment_title, ''),
        NULLIF(review_comment_message, ''),
        TRY_CONVERT(
            DATETIME2(0),
            NULLIF(REPLACE(review_creation_date, CHAR(13), ''), '')
        ),
        TRY_CONVERT(
            DATETIME2(0),
            NULLIF(REPLACE(review_answer_timestamp, CHAR(13), ''), '')
        )
    FROM dbo.review_bulk_test;

    DECLARE @rows INT;

    SELECT @rows = COUNT(*)
    FROM bronze.olist_order_reviews;

    IF @rows <> 99224
        THROW 50001, 'Reviews Bronze row count mismatch!', 1;

    COMMIT TRANSACTION;

    PRINT 'Reviews loaded successfully!';
    PRINT 'Total rows: ' + CAST(@rows AS VARCHAR(20));

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO


/*
========================================================
 8. LOAD PRODUCTS
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
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO


/*
========================================================
 9. LOAD SELLERS
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
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO


/*
========================================================
 10. LOAD GEOLOCATION
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
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO


/*
========================================================
 11. LOAD CATEGORY TRANSLATION
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
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;
GO

/*
Original Reviews CSV

PowerShell normalization ke through TSV file bani


Normalized TSV

olist_order_reviews_normalized.tsv


Staging Table

dbo.review_bulk_test — raw NVARCHAR values


Bronze Reviews Table
99,224 rows
Converted dates, integer score, cleaned empty values
*/