USE OlistStore_DW;
GO

CREATE OR ALTER PROCEDURE audit.usp_start_etl_log
    @pipeline_name NVARCHAR(150),
    @source_name NVARCHAR(255) = NULL,
    @target_name NVARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO audit.etl_execution_log
    (
        pipeline_name,
        source_name,
        target_name,
        status
    )
    VALUES
    (
        @pipeline_name,
        @source_name,
        @target_name,
        'RUNNING'
    );

    SELECT CAST(SCOPE_IDENTITY() AS BIGINT) AS log_id;
END;
GO


-- finish
CREATE OR ALTER PROCEDURE audit.usp_finish_etl_log
    @log_id BIGINT,
    @rows_read BIGINT = 0,
    @rows_inserted BIGINT = 0,
    @rows_updated BIGINT = 0,
    @rows_rejected BIGINT = 0
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE audit.etl_execution_log
    SET
        end_time_utc = SYSUTCDATETIME(),
        rows_read = @rows_read,
        rows_inserted = @rows_inserted,
        rows_updated = @rows_updated,
        rows_rejected = @rows_rejected,
        status = 'SUCCESS'
    WHERE log_id = @log_id
      AND status = 'RUNNING';
END;
GO

-- fail 
CREATE OR ALTER PROCEDURE audit.usp_fail_etl_log
    @log_id BIGINT,
    @error_message NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE audit.etl_execution_log
    SET
        end_time_utc = SYSUTCDATETIME(),
        status = 'FAILED',
        error_message = @error_message
    WHERE log_id = @log_id
      AND status = 'RUNNING';
END;
GO

-- test 
DECLARE @log_id BIGINT;

EXEC audit.usp_start_etl_log
    @pipeline_name = 'Silver Orders Transformation',
    @source_name = 'bronze.olist_orders',
    @target_name = 'silver.olist_orders';