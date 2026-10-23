/* =====================================================================
   Customer Segmentation Analysis
   Step 1: Data quality checks on the raw import
   ===================================================================== */

-- 1. Row count vs. distinct customers
--    If total_rows > distinct_customers, the file contains duplicates.
SELECT COUNT(*)                                   AS total_rows,
       COUNT(DISTINCT customer_id)                AS distinct_customers,
       COUNT(*) - COUNT(DISTINCT customer_id)     AS duplicate_rows
FROM dbo.customers_raw;


-- 2. Which customers appear more than once?
SELECT customer_id,
       COUNT(*) AS occurrences
FROM dbo.customers_raw
GROUP BY customer_id
HAVING COUNT(*) > 1
ORDER BY customer_id;


-- 3. Missing values per column
--    Profession can arrive as NULL or as an empty text, so both are counted.
SELECT SUM(CASE WHEN gender IS NULL OR TRIM(gender) = ''         THEN 1 ELSE 0 END) AS missing_gender,
       SUM(CASE WHEN age IS NULL                                  THEN 1 ELSE 0 END) AS missing_age,
       SUM(CASE WHEN annual_income IS NULL                        THEN 1 ELSE 0 END) AS missing_income,
       SUM(CASE WHEN spending_score IS NULL                       THEN 1 ELSE 0 END) AS missing_spending,
       SUM(CASE WHEN profession IS NULL OR TRIM(profession) = '' THEN 1 ELSE 0 END) AS missing_profession
FROM dbo.customers_raw;


-- 4. Invalid values (outliers / data entry errors)
--    Age must be 18-100, spending score is defined on a 1-100 scale.
SELECT SUM(CASE WHEN age < 18 OR age > 100                     THEN 1 ELSE 0 END) AS invalid_age,
       SUM(CASE WHEN spending_score < 1 OR spending_score > 100 THEN 1 ELSE 0 END) AS invalid_spending_score,
       SUM(CASE WHEN annual_income <= 0                         THEN 1 ELSE 0 END) AS invalid_income
FROM dbo.customers_raw;


-- 5. Look at the invalid rows themselves
SELECT *
FROM dbo.customers_raw
WHERE age < 18 OR age > 100
   OR spending_score < 1 OR spending_score > 100
ORDER BY customer_id;


-- 6. Inconsistent spelling in the gender column
SELECT gender,
       COUNT(*) AS customers
FROM dbo.customers_raw
GROUP BY gender
ORDER BY customers DESC;


-- 7. Value ranges, for a quick plausibility check
SELECT MIN(age)            AS min_age,            MAX(age)            AS max_age,
       MIN(annual_income)  AS min_income,         MAX(annual_income)  AS max_income,
       MIN(spending_score) AS min_spending_score, MAX(spending_score) AS max_spending_score
FROM dbo.customers_raw;
