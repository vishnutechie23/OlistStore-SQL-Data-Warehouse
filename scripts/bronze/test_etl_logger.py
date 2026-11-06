from scripts.etl_logger import start_log, finish_log

try:
    # Start ETL execution
    log_id = start_log(
        pipeline_name="ETL Logger Test",
        source_name="Python Test",
        target_name="audit.etl_execution_log"
    )

    print("ETL started. Log ID:", log_id)

    # Mark execution as successful
    finish_log(
        log_id=log_id,
        rows_read=100,
        rows_inserted=100
    )

    print("ETL completed successfully!")

except Exception as error:
    print("ETL test failed:", error)