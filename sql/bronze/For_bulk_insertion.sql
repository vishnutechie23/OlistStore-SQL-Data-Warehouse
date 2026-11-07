

-- For bulk insert via sql 
TRUNCATE TABLE table_name

BULK INSERT table_name
FROM 'path'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',', -- File delimiter : , ; | # "
	TABLOCK 
);  
-- QUALITY CHECK : Check that data has not shifted and is in the correct col
-- TRUNCATE : Quickly delete all rows from a table, resetting it to an empty state (first truncate then load)

-- HINT : save frequently used SQL code in stored procedures in database
-- Add prints to track execution , debug issues and understanding its flow
-- Add TRY ..CATCH : Ensures error handling, data integrity and issue logging for easier debugging
-- sql runs TRY block and if it fails it runs the CATCH block to handle errors

-- Track ETL duration : Helps to indentify bottlenecks, optimize performance, monitor trends, detect issues


