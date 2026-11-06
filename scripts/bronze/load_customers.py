import pandas as pd

from pathlib import Path
from scripts.db_connection import get_connection
from scripts.etl_logger import start_log, finish_log, fail_log


# File and table details
BASE_DIR = Path(__file__).resolve().parents[2]

CSV_FILE = BASE_DIR / "dataset" / "olist_customers_dataset.csv"

TABLE_NAME = "bronze.olist_customers"

COLUMNS = [
    "customer_id",
    "customer_unique_id",
    "customer_zip_code_prefix",
    "customer_city",
    "customer_state"
]


# Start ETL logging
log_id = start_log(
    pipeline_name="Customers Bronze Load",
    source_name="olist_customers_dataset.csv",
    target_name=TABLE_NAME
)

rows_read = 0
rows_inserted = 0

try:
    connection = get_connection()
    cursor = connection.cursor()

    cursor.fast_executemany = True

    # Prepare INSERT statement
    column_names = ", ".join(COLUMNS)
    placeholders = ", ".join(["?"] * len(COLUMNS))

    insert_query = f"""
        INSERT INTO {TABLE_NAME} ({column_names})
        VALUES ({placeholders})
    """

    # Full refresh for this initial load
    cursor.execute(f"TRUNCATE TABLE {TABLE_NAME}")

    # Read CSV in chunks
    for chunk in pd.read_csv(
        CSV_FILE,
        dtype=str,
        chunksize=5000
    ):

        chunk = chunk[COLUMNS]

        # Convert missing values to Python None (SQL NULL)
        chunk = chunk.astype(object).where(pd.notna(chunk), None)

        records = list(chunk.itertuples(index=False, name=None))

        cursor.executemany(insert_query, records)

        rows_read += len(records)
        rows_inserted += len(records)

    connection.commit()

    cursor.close()
    connection.close()

    # Mark ETL as successful
    finish_log(
        log_id,
        rows_read=rows_read,
        rows_inserted=rows_inserted
    )

    print("Customers loaded successfully!")
    print("Rows read:", rows_read)
    print("Rows inserted:", rows_inserted)

except Exception as error:

    if "connection" in locals():
        connection.rollback()
        connection.close()

    fail_log(log_id, error)

    print("Customers loading failed!")
    print("Error:", error)