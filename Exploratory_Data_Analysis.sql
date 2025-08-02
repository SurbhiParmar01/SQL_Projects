-- ========================================================================================
-- EXPLORATORY DATA ANALYSIS (EDA) ON WORLD LAYOFFS DATA
-- Dataset: layoffs_staging2
-- Author: Surbhi Parmar
-- Description: SQL queries used for exploring layoff patterns across companies, industries,
--              countries, and company stages. Includes charts used in portfolio visualizations.
-- ========================================================================================


-- BASIC EXPLORATION: View all records
SELECT *
FROM layoffs_staging2;



-- ========================================================================================
-- PORTFOLIO RESULTS QUERIES (Used in Dashboard/Charts)
-- ========================================================================================


-- ----------------------------------------------------------------------------------------
-- Card 1: Layoffs Trend by Funding Stages (Top 5 + Others)
-- ----------------------------------------------------------------------------------------

WITH trend_layoffs AS (
  SELECT 
    YEAR(`date`) AS years,
    stage,
    total_laid_off
  FROM layoffs_staging2
  WHERE stage IS NOT NULL AND `date` IS NOT NULL
),
top_stages AS (
  SELECT stage
  FROM trend_layoffs
  GROUP BY stage
  ORDER BY SUM(total_laid_off) DESC
  LIMIT 5
),
simplified_trend AS (
  SELECT 
    years,
    CASE 
      WHEN stage IN (SELECT stage FROM top_stages) THEN stage
      ELSE 'Others'
    END AS simplified_stage,
    total_laid_off
  FROM trend_layoffs
)
SELECT 
  simplified_stage,
  years,
  SUM(total_laid_off) AS layoffs_trend
FROM simplified_trend
GROUP BY simplified_stage, years
ORDER BY simplified_stage, years;



-- ----------------------------------------------------------------------------------------
-- Card 2: Industries Where Layoffs Are Decreasing Year-over-Year
-- ----------------------------------------------------------------------------------------

WITH industry_yearly_layoffs AS ( 
  SELECT 
    industry, 
    YEAR(`date`) AS `year`, 
    SUM(total_laid_off) AS total_layoffs
  FROM layoffs_staging2
  WHERE industry IS NOT NULL AND `date` IS NOT NULL
  GROUP BY industry, `year`
), 
industry_layoff_trend AS (
  SELECT 
    industry, 
    `year`, 
    total_layoffs AS current_year_layoffs, 
    LAG(total_layoffs) OVER(PARTITION BY industry ORDER BY `year`) AS prev_year_layoffs
  FROM industry_yearly_layoffs
), 
industry_deltas AS (
  SELECT 
    industry,
    `year`,
    current_year_layoffs,
    prev_year_layoffs,
    (current_year_layoffs - prev_year_layoffs) AS layoffs_difference
  FROM industry_layoff_trend
  WHERE prev_year_layoffs IS NOT NULL
    AND current_year_layoffs < prev_year_layoffs
), 
ranked_drops AS (
  SELECT *,
         RANK() OVER (PARTITION BY industry ORDER BY layoffs_difference ASC) AS drop_rank
  FROM industry_deltas
)
SELECT *
FROM ranked_drops
WHERE drop_rank = 1
ORDER BY layoffs_difference ASC
LIMIT 5;



-- ----------------------------------------------------------------------------------------
-- Card 3: Rolling Total of Layoffs by Year in Top 5 Countries
-- ----------------------------------------------------------------------------------------

WITH TopCountries AS (
  SELECT 
    country, 
    SUM(total_laid_off) AS total_layoffs
  FROM layoffs_staging2
  WHERE country IS NOT NULL
  GROUP BY country
  ORDER BY total_layoffs DESC
  LIMIT 5
),
Rolling_Total AS (
  SELECT 
    country,
    SUBSTRING(`date`, 1, 4) AS `year`,
    SUM(total_laid_off) AS total_off
  FROM layoffs_staging2
  WHERE SUBSTRING(`date`, 1, 4) IS NOT NULL
  GROUP BY `year`, country
)
SELECT 
  rt.`year`, 
  rt.country, 
  SUM(rt.total_off) OVER(PARTITION BY rt.country ORDER BY rt.`year`) AS rolling_total
FROM Rolling_Total rt
JOIN TopCountries tc ON rt.country = tc.country
WHERE rt.total_off IS NOT NULL
ORDER BY rt.country, rt.`year`;



-- ----------------------------------------------------------------------------------------
-- Card 4: Top 5 Companies with Maximum Layoffs in a Single Year
-- ----------------------------------------------------------------------------------------

WITH company_yearly_layoffs AS (
  SELECT 
    company, 
    YEAR(`date`) AS layoff_year, 
    SUM(total_laid_off) AS yearly_total_layoffs
  FROM layoffs_staging2
  WHERE company IS NOT NULL AND `date` IS NOT NULL
  GROUP BY company, YEAR(`date`)
),
ranked_company_layoffs AS (
  SELECT 
    company, 
    layoff_year, 
    yearly_total_layoffs,
    RANK() OVER (PARTITION BY company ORDER BY yearly_total_layoffs DESC) AS layoff_rank
  FROM company_yearly_layoffs
)
SELECT 
  company, 
  layoff_year AS year_of_max_layoff, 
  yearly_total_layoffs AS max_layoffs_in_a_year 
FROM ranked_company_layoffs
WHERE layoff_rank = 1
ORDER BY max_layoffs_in_a_year DESC
LIMIT 5;



-- ========================================================================================
-- ADDITIONAL PRACTICE & INSIGHTS QUERIES
-- ========================================================================================


-- Companies with the Longest Duration of Layoffs
SELECT 
  company,
  MIN(`date`) AS first_layoff,
  MAX(`date`) AS last_layoff, 
  DATEDIFF(MAX(`date`), MIN(`date`)) AS duration_days
FROM layoffs_staging2
GROUP BY company
ORDER BY duration_days DESC;


-- Year-wise Top 5 Companies by Layoffs
WITH laid_off_per_year AS (
  SELECT company, YEAR(`date`) AS `year`, SUM(total_laid_off) AS total_off
  FROM layoffs_staging2
  GROUP BY company, YEAR(`date`)
),
Laid_off AS (
  SELECT 
    company,
    `year`,
    total_off,
    DENSE_RANK() OVER(PARTITION BY `year` ORDER BY total_off DESC) AS Ranking
  FROM laid_off_per_year
)
SELECT *
FROM Laid_off
WHERE Ranking <= 5
AND `year` IS NOT NULL;



-- Average Percentage of Employees Laid Off by Industry
SELECT 
  industry,
  ROUND(AVG(percentage_laid_off * 100), 2) AS Avg_percent_laid_off 
FROM layoffs_staging2
WHERE percentage_laid_off IS NOT NULL AND industry IS NOT NULL
GROUP BY industry
ORDER BY Avg_percent_laid_off DESC;



-- Month-Year with Highest Layoffs Globally
WITH Year_Month_cte AS (
  SELECT 
    total_laid_off,
    SUBSTRING(`date`, 1, 7) AS `Year_Month`
  FROM layoffs_staging2
  WHERE `date` IS NOT NULL
)
SELECT `Year_Month`, SUM(total_laid_off) AS total_laid_off
FROM Year_Month_cte
GROUP BY `Year_Month`
ORDER BY total_laid_off DESC
LIMIT 1;



-- Cumulative Layoffs by Industry Over the Years
WITH industry_cte AS (
  SELECT 
    industry,
    YEAR(`date`) AS years,
    SUM(total_laid_off) AS total_laid_off
  FROM layoffs_staging2
  GROUP BY industry, YEAR(`date`)
)
SELECT *, 
  SUM(total_laid_off) OVER(PARTITION BY industry ORDER BY years) AS cumulative_layoffs
FROM industry_cte
WHERE industry IS NOT NULL
ORDER BY industry;



-- Highest Single-Day Layoff Event
SELECT 
  company,
  `date`,
  total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL
ORDER BY total_laid_off DESC
LIMIT 1;



-- Yearly Total Layoffs (All Companies Combined)
SELECT 
  YEAR(`date`) AS `year`,
  SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE total_laid_off IS NOT NULL AND `date` IS NOT NULL
GROUP BY `year`
ORDER BY `year`;



-- Companies that Laid Off 100% of Employees
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 1;



-- Total Layoffs by Country
SELECT 
  country, 
  SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;



-- Year-wise Total Layoffs
SELECT 
  YEAR(`date`) AS `year`, 
  SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY `year`
ORDER BY `year` DESC;
