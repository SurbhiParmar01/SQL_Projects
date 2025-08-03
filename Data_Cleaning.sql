-- ----------------------------------------------
-- SQL Script: Data Cleaning for Layoffs Dataset
-- Author: Surbhi Parmar
-- Description:
--   This script performs data cleaning steps, including:
--     • Removing duplicates
--     • Handling NULLs and missing values
--     • Standardizing data
--     • Dropping irrelevant records and columns
-- ----------------------------------------------



-- ---------------------------------------------------
-- Removing Duplicate Records from the Layoffs Dataset
-- ---------------------------------------------------

/*

This SQL script demonstrates how to clean a dataset by identifying and removing duplicate records
using the ROW_NUMBER() window function. The cleaned data is stored in a new table for further analysis.

*/

-- STEP 1: Create a staging table with the same schema as the original 'layoffs' table
CREATE TABLE layoffs_staging
LIKE layoffs;

-- STEP 2: Copy all records from the original 'layoffs' table into the staging table
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- Optional: View the raw data in the staging table
SELECT * 
FROM layoffs_staging;

-- STEP 3: Use ROW_NUMBER() to identify duplicate rows
-- Duplicates are determined based on a combination of the following columns
SELECT *,
  ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
                 stage, country, funds_raised_millions
    ORDER BY company
  ) AS row_num 
FROM layoffs_staging;

-- STEP 4: Wrap the above query in a CTE to isolate duplicate records
WITH duplicate_cte AS (
  SELECT *,
    ROW_NUMBER() OVER (
      PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
                   stage, country, funds_raised_millions
      ORDER BY company
    ) AS row_num 
  FROM layoffs_staging
)

-- Preview rows that are considered duplicates (row_num > 1)
SELECT * 
FROM duplicate_cte
WHERE row_num > 1;

-- STEP 5: Create a new table to store cleaned data (only unique rows will be kept)
CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT DEFAULT NULL,
  percentage_laid_off TEXT,
  `date` TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT DEFAULT NULL,
  row_num INT
);

-- STEP 6: Insert all records into the new table with an added row_num to identify duplicates
INSERT INTO layoffs_staging2
SELECT *,
  ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`,
                 stage, country, funds_raised_millions
    ORDER BY company
  ) AS row_num 
FROM layoffs_staging;

-- STEP 7: Verify duplicate entries still exist (for deletion in next step)
SELECT * 
FROM layoffs_staging2
WHERE row_num > 1;

-- STEP 8: Delete duplicate rows (keeping only row_num = 1)
DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- The layoffs_staging2 table now contains only unique, cleaned records. 




-- -----------------------------------------------
-- Handling NULL or Missing Values (Blank Strings)
-- -----------------------------------------------

/*

This script demonstrates how to detect, standardize, and fill in missing values (particularly in the `industry` column) 
by leveraging a self-join technique. It ensures consistency and completeness in the dataset.

*/

-- STEP 1: Identify rows where `industry` is either NULL or an empty string
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = '';

-- STEP 2: Check if the same company has other rows where `industry` is populated
SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- STEP 3: Use a self-join to match rows with NULL/blank `industry` values 
-- to other rows of the same company that have the correct `industry`
SELECT t1.company, t1.industry AS missing_industry, t2.industry AS correct_industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

-- Note: Before running the UPDATE, standardize blank strings to actual NULLs
UPDATE layoffs_staging2 
SET industry = NULL
WHERE industry = '';

-- STEP 4: Now update the NULL `industry` values using the non-NULL values from other matching rows
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- STEP 5: Validate if the update worked (Airbnb should now have its industry filled in)
SELECT * 
FROM layoffs_staging2
WHERE company = 'Airbnb';

-- STEP 6: Identify any rows where the `industry` is still NULL
-- These are companies with no non-NULL counterpart to use for filling
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL;

-- Example: Bally’s still has NULL industry and cannot be updated via this method
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';




-- ------------------
-- Standardizing Data
-- ------------------

/*
This script addresses inconsistencies in text formatting, country names, industry labels, and dates. 
Standardization ensures uniformity, improves data quality, and prepares the dataset for reliable analysis.
*/

-- STEP 1: Remove extra spaces from the `company` column
SELECT company, TRIM(company) AS trimmed_company
FROM layoffs_staging2;

-- Apply the cleaned values to the table
UPDATE layoffs_staging2
SET company = TRIM(company);

-- STEP 2: Identify inconsistencies in the `industry` column
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY industry;

-- Example Fix: Standardize all entries starting with 'Crypto' to just 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- STEP 3: Clean up `country` column (e.g., removing trailing periods or duplicates like 'United States.' and 'United States')
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY country;

-- Use TRIM to remove trailing characters 
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- STEP 4: Standardize the `date` column format

-- View current state of dates
SELECT `date`
FROM layoffs_staging2;

-- Convert text dates to DATE format (without changing the column data type yet)
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Finally, convert the column datatype to proper DATE (if it’s still stored as TEXT/VARCHAR)
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- Final check to confirm standardization
SELECT *
FROM layoffs_staging2
LIMIT 10;




-- --------------------------------------
-- Remove Unnecessary Columns and Records
-- --------------------------------------

/*

This script removes rows and columns that do not contribute meaningful information to the analysis. 
Specifically, it deletes entries with no layoff data and drops redundant columns created during processing.

*/

-- STEP 1: Identify records where no layoffs were reported
SELECT *
FROM layoffs_staging2 
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- These rows do not provide any valuable information, so we delete them
DELETE FROM layoffs_staging2 
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- STEP 2: Drop the `row_num` column if it was created earlier during deduplication or staging
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Final check to confirm cleanup
SELECT *
FROM layoffs_staging2
LIMIT 10;



-- ----------------------------------------------
-- Final Output Check
-- ----------------------------------------------

SELECT *
FROM layoffs_staging2;


