
import pandas as pd
from pathlib import Path

from scripts.db_connection import get_connection
from scripts.etl_logger import start_log, finish_log, fail_log


BASE_DIR = Path(__file__).resolve().parents[2]

CSV_FILE = BASE_DIR / "dataset" / "olist_orders_dataset.csv"

TABLE_NAME = "bronze.olist_orders"

COLUMNS = [
    "order_id",
    "customer_id",
    "order_status",
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]

DATE_COLUMNS = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date"
]


log_id = start_log(
    pipeline_name="Orders Bronze Load",
    source_name="olist_orders_dataset.csv",
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

    # Full refresh for initial load
    cursor.execute(f"TRUNCATE TABLE {TABLE_NAME}")

    for chunk in pd.read_csv(
        CSV_FILE,
        dtype=str,
        chunksize=5000
    ):
        chunk = chunk[COLUMNS]

        # Convert date strings to Python datetime values
        for col in DATE_COLUMNS:
            chunk[col] = pd.to_datetime(
                chunk[col],
                errors="coerce"
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

    print("Orders loaded successfully!")
    print("Rows read:", rows_read)
    print("Rows inserted:", rows_inserted)

except Exception as error:

    if "connection" in locals():
        connection.rollback()
        connection.close()

    fail_log(log_id, error)

    print("Orders loading failed!")
    print("Error:", error)


# Important concepts
# - pd.to_datetime() converts CSV date strings into datetime values.
# - errors="coerce" converts invalid or missing dates to NaT, which we then convert to SQL NULL.
# - chunksize=5000 processes data in batches.
# - TRUNCATE TABLE supports a clean full reload.
