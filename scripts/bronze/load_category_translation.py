import pandas as pd
from pathlib import Path

from scripts.db_connection import get_connection
from scripts.etl_logger import start_log, finish_log, fail_log


BASE_DIR = Path(__file__).resolve().parents[2]

CSV_FILE = BASE_DIR / "dataset" / "product_category_name_translation.csv"

TABLE_NAME = "bronze.olist_category_translation"

COLUMNS = [
    "product_category_name",
    "product_category_name_english"
]


log_id = start_log(
    pipeline_name="Category Translation Bronze Load",
    source_name="product_category_name_translation.csv",
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

    cursor.execute(f"TRUNCATE TABLE {TABLE_NAME}")

    for chunk in pd.read_csv(
        CSV_FILE,
        dtype=str,
        chunksize=5000
    ):

        chunk = chunk[COLUMNS].copy()

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

    print("Category Translation loaded successfully!")
    print("Rows read:", rows_read)
    print("Rows inserted:", rows_inserted)

except Exception as error:

    if "connection" in locals():
        connection.rollback()
        connection.close()

    fail_log(log_id, error)

    print("Category Translation loading failed!")
    print("Error:", error)

# What this does: Reads the translation CSV in chunks, preserves missing values,
# and inserts both category-name columns into the Bronze table while recording the ETL execution.