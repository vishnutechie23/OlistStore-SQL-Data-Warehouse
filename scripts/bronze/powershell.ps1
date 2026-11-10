# 1. PowerShell code — CSV to TSV conversion
# Ye code olist_order_reviews_normalized.tsv file create karta hai.
$source = "C:\OlistStore-SQL-Data-Warehouse\dataset\olist_order_reviews_dataset.csv"

$output = "C:\OlistStore-SQL-Data-Warehouse\dataset\olist_order_reviews_normalized.tsv"

$data = Import-Csv -LiteralPath $source

$writer = [System.IO.StreamWriter]::new(
    $output,
    $false,
    [System.Text.UTF8Encoding]::new($false)
)

try {
    foreach ($row in $data) {

        $values = @(
            $row.review_id
            $row.order_id
            $row.review_score
            $row.review_comment_title
            $row.review_comment_message
            $row.review_creation_date
            $row.review_answer_timestamp
        )

        $values = $values | ForEach-Object {
            ([string]$_) -replace '[\r\n\t]+', ' '
        }

        $writer.WriteLine(($values -join "`t"))
    }
}
finally {
    $writer.Close()
}

Write-Host "Records:" $data.Count
Write-Host "TSV file created successfully!"


# 2. SQL Server code — Staging table creation
# Ye load_bronze_tables.sql mein rahega.
IF OBJECT_ID('dbo.review_bulk_test', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.review_bulk_test
    (
        review_id NVARCHAR(100),
        order_id NVARCHAR(100),
        review_score NVARCHAR(20),
        review_comment_title NVARCHAR(500),
        review_comment_message NVARCHAR(1000),
        review_creation_date NVARCHAR(50),
        review_answer_timestamp NVARCHAR(50)
    );
END;
GO


# Dono ka difference:
# Tool	Work
# PowerShell	CSV ko TSV mein convert karta hai
# SQL Server	dbo.review_bulk_test staging table create karta hai
# SQL Server	TSV ko staging table mein load karta hai
# SQL Server	Staging se Bronze mein insert karta hai

