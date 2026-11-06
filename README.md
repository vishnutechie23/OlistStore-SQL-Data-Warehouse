# OlistStore SQL Data Warehouse

🚧 **Project Status: In Progress**

## 📌 Project Overview

OlistStore SQL Data Warehouse is an end-to-end data warehousing project built using Microsoft SQL Server and Power BI.

The project implements the **Medallion Architecture (Bronze, Silver, and Gold)** to transform raw Brazilian e-commerce data into clean, structured, and business-ready datasets for analytical reporting.

## 🎯 Project Objectives

- Build a structured SQL Data Warehouse.
- Implement Bronze, Silver, and Gold data layers.
- Perform data cleaning and transformation using SQL.
- Develop fact and dimension tables using Star Schema.
- Perform data quality checks and validation.
- Generate business insights using SQL queries.
- Develop interactive Power BI dashboards.

## 🛠️ Technology Stack

- **Database:** Microsoft SQL Server
- **Query Language:** T-SQL
- **Visualization:** Microsoft Power BI
- **Programming:** Python (supporting tasks)
- **Version Control:** Git & GitHub

## 🏗️ Architecture

```text
Source CSV Files
       |
       v
  Bronze Layer
   (Raw Data)
       |
       v
  Silver Layer
 (Cleaned Data)
       |
       v
   Gold Layer
 (Business Data)
       |
       v
    Power BI
 (Dashboards & Insights)
```

## 📂 Dataset

**Brazilian E-Commerce Public Dataset by Olist**

Source: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

The dataset contains information about customers, orders, products, sellers, payments, reviews, and deliveries.

## 📊 Planned Analytics

- Sales Performance Analysis
- Customer Analysis
- Product & Seller Performance
- Payment Analysis
- Delivery Performance
- Customer Satisfaction Analysis

## 📁 Project Structure

```text
OlistStore-SQL-Data-Warehouse/
│
├── datasets/
├── sql/
│   ├── bronze/
│   ├── silver/
│   ├── gold/
│   └── analysis/
│
├── python/
├── powerbi/
├── docs/
├── tests/
└── README.md
```

## 🚀 Project Progress

- [x] Repository initialization
- [ ] Dataset exploration and profiling
- [ ] Bronze Layer implementation
- [ ] Silver Layer implementation
- [ ] Gold Layer implementation
- [ ] SQL Business Analysis
- [ ] Power BI Dashboard
- [ ] Documentation and final testing

---

**Note:** This project is currently under development. More details, SQL scripts, and analytical dashboards will be added as development progresses.

Dataset attribution: Olist Brazilian E-Commerce Public Dataset.
