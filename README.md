# SQL_Projects
# SQL Project: Tech Layoffs – Data Cleaning & Exploratory Analysis

## Introduction
This project focuses on cleaning and analyzing global tech layoff data to uncover key trends, patterns, and insights. Using structured SQL queries, the dataset was first cleaned for consistency and completeness, followed by exploratory analysis to identify industry impacts, country-wise layoffs, and company-specific events. The findings aim to support data-driven understanding of workforce shifts and broader economic impacts.

---

## Dataset
The dataset includes global tech layoff records from 2020 onward, with attributes such as:
- Company name
- Location
- Industry
- Number of employees laid off
- Percentage of workforce laid off
- Date of layoff
- Company stage
- Country
- Funds raised
  
  

---

## Part 1: Data Cleaning (SQL)

###  Objectives:
- Remove duplicate records
- Handle missing or null values
- Standardize text data (e.g., lowercase, trim spaces)
- Correct inconsistent entries (e.g., stage, industry labels)
- Prepare the data for accurate analysis

### Key SQL Concepts Used:
- Common Table Expressions (CTEs)
- `ROW_NUMBER()` for de-duplication
- String functions: `TRIM()`, `LOWER()`
- UPDATE, DELETE, ALTER, DROP columns and tables
- STR_TO_DATE()
- Conditional logic using `CASE`

 [View data cleaning SQL script](./Data_Cleaning.sql)

---

## Part 2: Exploratory Data Analysis (EDA)

### Key Questions Explored:
- Which companies had the highest layoffs in a single year?
- In which industries the layoffs are decreasing over time?
- What are the rolling totals by year in top five countries?
- What countries were most affected?
- Which companies laid of 100% of their employees?
- Which is the highest single day layoff event?
- How do layoff trends differ by funding stage?
- What is the cumulative layoffs by industry over the years?
- What was the month and year with the highest layoffs globally?

### Techniques Used:
- Common Table Expressions (CTEs)
- Window functions (`RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LAG()`, `SUM() OVER`), PARTITION BY
- Rolling totals
- JOINS
- Aggregations and `GROUP BY`, `ORDER BY`
- Date and string manipulation
- CASE 
- Scalar date function like DATEDIF()

 [View EDA SQL script](./Exploratory_Data_Analysis.sql)

---

## Tools & Environment
- SQL (MySQL)
- Visualizations built using Excel for portfolio charts
- GitHub for version control

---

## Contact
If you'd like to discuss this project or similar work, feel free to reach out via [LinkedIn](https://www.linkedin.com/in/surbhiparmar/) or email me at surbhiparmar1609@gmail.com.

---
