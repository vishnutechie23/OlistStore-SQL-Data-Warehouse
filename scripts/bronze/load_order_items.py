
import pandas as pd
from pathlib import Path

from scripts.db_connection import get_connection
from scripts.etl_logger import start_log, finish_log, fail_log


BASE_DIR = Path(__file__).resolve().parents[2]

CSV_FILE = BASE_DIR / "dataset" / "olist_order_items_dataset.csv"

TABLE_NAME = "bronze.olist_order_items"

COLUMNS = [
    "order_id",
    "order_item_id",
    "product_id",
    "seller_id",
    "shipping_limit_date",
    "price",
    "freight_value"
]


log_id = start_log(
    pipeline_name="Order Items Bronze Load",
    source_name="olist_order_items_dataset.csv",
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

        # Transform data types
        chunk["order_item_id"] = pd.to_numeric(
            chunk["order_item_id"], errors="coerce"
        )

        chunk["shipping_limit_date"] = pd.to_datetime(
            chunk["shipping_limit_date"], errors="coerce"
        )

        chunk["price"] = pd.to_numeric(
            chunk["price"], errors="coerce"
        )

        chunk["freight_value"] = pd.to_numeric(
            chunk["freight_value"], errors="coerce"
        )

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

    print("Order Items loaded successfully!")
    print("Rows read:", rows_read)
    print("Rows inserted:", rows_inserted)

except Exception as error:

    if "connection" in locals():
        connection.rollback()
        connection.close()

    fail_log(log_id, error)

    print("Order Items loading failed!")
    print("Error:", error)
