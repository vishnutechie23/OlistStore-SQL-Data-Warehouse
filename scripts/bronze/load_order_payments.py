
import pandas as pd
from pathlib import Path

from scripts.db_connection import get_connection
from scripts.etl_logger import start_log, finish_log, fail_log


BASE_DIR = Path(__file__).resolve().parents[2]

CSV_FILE = BASE_DIR / "dataset" / "olist_order_payments_dataset.csv"

TABLE_NAME = "bronze.olist_order_payments"

COLUMNS = [
    "order_id",
    "payment_sequential",
    "payment_type",
    "payment_installments",
    "payment_value"
]


log_id = start_log(
    pipeline_name="Order Payments Bronze Load",
    source_name="olist_order_payments_dataset.csv",
    target_name=TABLE_NAME
)

rows_read = 0
rows_inserted = 0

try:
    connection = get_connection()
    cursor = connection.cursor()
    cursor.fast_executemany = True

    column_names = ", ".join(COLUMNS)
    placeholders = ", ".join(["?"] * len(COLUMNS))

    insert_query = f"""
        INSERT INTO {TABLE_NAME} ({column_names})
        VALUES ({placeholders})
    """

    # Initial full refresh
    cursor.execute(f"TRUNCATE TABLE {TABLE_NAME}")

    for chunk in pd.read_csv(
        CSV_FILE,
        dtype=str,
        chunksize=5000
    ):

        chunk = chunk[COLUMNS].copy()

        # Transform numeric columns
        chunk["payment_sequential"] = pd.to_numeric(
            chunk["payment_sequential"], errors="coerce"
        )

        chunk["payment_installments"] = pd.to_numeric(
            chunk["payment_installments"], errors="coerce"
        )

        chunk["payment_value"] = pd.to_numeric(
            chunk["payment_value"], errors="coerce"
        )

        # Convert missing values to SQL NULL
        chunk = chunk.astype(object).where(
            pd.notna(chunk), None
        )

        records = list(
            chunk.itertuples(index=False, name=None)
        )

        cursor.executemany(insert_query, records)

        rows_read += len(records)
        rows_inserted += len(records)

    connection.commit()
    cursor.close()
    connection.close()

    finish_log(
        log_id,
        rows_read=rows_read,
        rows_inserted=rows_inserted
    )

    print("Order Payments loaded successfully!")
    print("Rows read:", rows_read)
    print("Rows inserted:", rows_inserted)

except Exception as error:

    if "connection" in locals():
        connection.rollback()
        connection.close()

    fail_log(log_id, error)

    print("Order Payments loading failed!")
    print("Error:", error)
