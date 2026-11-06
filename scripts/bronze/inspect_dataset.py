
import pandas as pd
from pathlib import Path

# Dataset folder location
DATASET_PATH = Path("dataset")

# Find all CSV files
csv_files = list(DATASET_PATH.glob("*.csv"))

# Inspect each CSV
for file in csv_files:
    df = pd.read_csv(file, nrows=5)

    print("\n" + "=" * 60)
    print("FILE:", file.name)
    print("COLUMNS:", len(df.columns))
    print("COLUMN NAMES:", df.columns.tolist())
    print("DATA TYPES:")
    print(df.dtypes)
    print("=" * 60)
