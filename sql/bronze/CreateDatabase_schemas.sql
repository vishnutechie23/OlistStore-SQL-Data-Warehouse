-- Create Database
CREATE DATABASE OlistStore_DW;
GO

-- Verify 
SELECT name
FROM sys.databases
WHERE name = 'OlistStore_DW';

/*
 Create schemas
We'll organize our warehouse using three schemas:
- bronze — Raw source data.
- silver — Cleaned and transformed data.
- gold — Business-ready data for Power BI.
*/

USE OlistStore_DW;
GO

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

-- Verify
SELECT name
FROM sys.schemas
WHERE name IN ('bronze', 'silver', 'gold');

