
import pyodbc

def get_connection():

    connection_string = (
        "DRIVER={ODBC Driver 18 for SQL Server};"
        r"SERVER=vishnu\SQLEXPRESS;"
        "DATABASE=OlistStore_DW;"
        "Trusted_Connection=yes;"
        "Encrypt=yes;"
        "TrustServerCertificate=yes;"
    )

    return pyodbc.connect(connection_string, timeout=5)

# Why are we doing this? : Later, our inspection, ingestion and ETL logging scripts can all reuse the same connection function.