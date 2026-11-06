
import pyodbc

connection_string = (
    "DRIVER={ODBC Driver 18 for SQL Server};"
    r"SERVER=vishnu\SQLEXPRESS;"
    "DATABASE=OlistStore_DW;"
    "Trusted_Connection=yes;"
    "Encrypt=yes;"
    "TrustServerCertificate=yes;"
)

try:
    connection = pyodbc.connect(connection_string, timeout=5)

    cursor = connection.cursor()
    cursor.execute("SELECT DB_NAME(), SYSTEM_USER")

    result = cursor.fetchone()

    print("Connection successful!")
    print("Database:", result[0])
    print("Login:", result[1])

    connection.close()

except pyodbc.Error as error:
    print("Connection failed!")
    print(error)
