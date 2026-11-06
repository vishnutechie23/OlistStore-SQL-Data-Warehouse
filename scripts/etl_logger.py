from scripts.db_connection import get_connection


def start_log(pipeline_name, source_name, target_name):

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("""
        INSERT INTO audit.etl_execution_log
        (pipeline_name, source_name, target_name, status)
        OUTPUT INSERTED.log_id
        VALUES (?, ?, ?, 'RUNNING')
    """, pipeline_name, source_name, target_name)

    log_id = cursor.fetchone()[0]

    connection.commit()
    cursor.close()
    connection.close()

    return log_id


def finish_log(log_id, rows_read=0, rows_inserted=0,
               rows_updated=0, rows_rejected=0):

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("""
        UPDATE audit.etl_execution_log
        SET
            end_time_utc = SYSUTCDATETIME(),
            rows_read = ?,
            rows_inserted = ?,
            rows_updated = ?,
            rows_rejected = ?,
            status = 'SUCCESS'
        WHERE log_id = ?
    """, rows_read, rows_inserted, rows_updated,
         rows_rejected, log_id)

    connection.commit()
    cursor.close()
    connection.close()


def fail_log(log_id, error_message):

    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute("""
        UPDATE audit.etl_execution_log
        SET
            end_time_utc = SYSUTCDATETIME(),
            status = 'FAILED',
            error_message = ?
        WHERE log_id = ?
    """, str(error_message), log_id)

    connection.commit()
    cursor.close()
    connection.close()