
import pandas as pd
from pathlib import Path

from scripts.db_connection import get_connection
from scripts.etl_logger import start_log, finish_log, fail_log


BASE_DIR = Path(__file__).resolve().parents[2]

CSV_FILE = BASE_DIR / "dataset" / "olist_order_reviews_dataset.csv"

TABLE_NAME = "bronze.olist_order_reviews"

COLUMNS = [
    "review_id",
    "order_id",
    "review_score",
    "review_comment_title",
    "review_comment_message",
    "review_creation_date",
    "review_answer_timestamp"
]

DATE_COLUMNS = [
    "review_creation_date",
    "review_answer_timestamp"
]


log_id = start_log(
    pipeline_name="Order Reviews Bronze Load",
    source_name="olist_order_reviews_dataset.csv",
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

        # Convert date columns
        for col in DATE_COLUMNS:
            parsed = pd.to_datetime(
                chunk[col], errors="coerce"
            )
            chunk[col] = parsed.apply(
                lambda value: value.to_pydatetime()
                if pd.notna(value) else None
            )

        # Convert review score to integer
        chunk["review_score"] = pd.to_numeric(
            chunk["review_score"], errors="coerce"
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

    print("Order Reviews loaded successfully!")
    print("Rows read:", rows_read)
    print("Rows inserted:", rows_inserted)

except Exception as error:

    if "connection" in locals():
        connection.rollback()
        connection.close()

    fail_log(log_id, error)

    print("Order Reviews loading failed!")
    print("Error:", error)
