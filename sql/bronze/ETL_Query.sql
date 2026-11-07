
USE OlistStore_DW;
GO

CREATE SCHEMA audit;
GO

CREATE TABLE audit.etl_execution_log
(
    log_id BIGINT IDENTITY(1,1) PRIMARY KEY,

    pipeline_name NVARCHAR(150) NOT NULL,
    source_name NVARCHAR(255),
    target_name NVARCHAR(255),

    start_time_utc DATETIME2(3) NOT NULL
        DEFAULT SYSUTCDATETIME(),

    end_time_utc DATETIME2(3),

    rows_read BIGINT NOT NULL DEFAULT 0,
    rows_inserted BIGINT NOT NULL DEFAULT 0,
    rows_updated BIGINT NOT NULL DEFAULT 0,
    rows_rejected BIGINT NOT NULL DEFAULT 0,

    status VARCHAR(20) NOT NULL DEFAULT 'RUNNING'
        CHECK (status IN ('RUNNING', 'SUCCESS', 'FAILED')),

    error_message NVARCHAR(MAX),

    created_at_utc DATETIME2(3) NOT NULL
        DEFAULT SYSUTCDATETIME()
);
GO

-- Verify
SELECT *
FROM sys.tables
WHERE name = 'etl_execution_log';


USE OlistStore_DW;
GO

SELECT *
FROM audit.etl_execution_log
ORDER BY log_id DESC;


