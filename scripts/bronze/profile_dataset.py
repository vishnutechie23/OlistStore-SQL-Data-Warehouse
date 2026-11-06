
import pandas as pd
from pathlib import Path

DATASET_PATH = Path("dataset")

csv_files = list(DATASET_PATH.glob("*.csv"))

for file in csv_files:
    df = pd.read_csv(file)

    print("\n" + "=" * 65)
    print("FILE:", file.name)
    print("TOTAL ROWS:", len(df))
    print("TOTAL COLUMNS:", len(df.columns))
    print("DUPLICATE ROWS:", df.duplicated().sum())

    print("\nNULL VALUES:")
    null_counts = df.isnull().sum()
    print(null_counts[null_counts > 0])

    print("\nDATA TYPES:")
    print(df.dtypes)

    print("=" * 65)
