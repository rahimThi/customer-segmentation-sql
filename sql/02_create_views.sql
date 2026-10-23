/* =====================================================================
   Customer Segmentation Analysis
   Step 2: Cleaning and segmentation logic, stored as views
   ===================================================================== */

/* ---------------------------------------------------------------------
   View 1: v_customers_clean
   - removes duplicate rows (customer_id)
   - standardises gender spelling
   - replaces missing profession with 'Unknown'
   - excludes invalid ages and spending scores
   - adds an age group
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_customers_clean AS
WITH deduplicated AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS row_num
    FROM dbo.customers_raw
)
SELECT customer_id,
       CASE UPPER(LEFT(TRIM(gender), 1))
            WHEN 'F' THEN 'Female'
            WHEN 'M' THEN 'Male'
            ELSE 'Unknown'
       END                                              AS gender,
       age,
       CASE
            WHEN age <= 25 THEN '18-25'
            WHEN age <= 35 THEN '26-35'
            WHEN age <= 45 THEN '36-45'
            WHEN age <= 55 THEN '46-55'
            ELSE '56+'
       END                                              AS age_group,
       annual_income,
       spending_score,
       COALESCE(NULLIF(TRIM(profession), ''), 'Unknown') AS profession,
       work_experience,
       family_size
FROM deduplicated
WHERE row_num = 1
  AND age BETWEEN 18 AND 100
  AND spending_score BETWEEN 1 AND 100;
GO


/* ---------------------------------------------------------------------
   View 2: v_customer_segments
   Income-versus-spending segmentation. The split uses the MEDIAN of
   income and of spending score, so the thresholds adapt to the data.

                         spending >= median   spending < median
   income >= median      Premium Spenders     Untapped Affluent
   income <  median      Value Seekers        Budget Conscious
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_customer_segments AS
WITH with_medians AS (
    SELECT *,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income)  OVER () AS median_income,
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY spending_score) OVER () AS median_spending
    FROM dbo.v_customers_clean
)
SELECT customer_id,
       gender,
       age,
       age_group,
       annual_income,
       spending_score,
       profession,
       work_experience,
       family_size,
       CASE
            WHEN annual_income >= median_income AND spending_score >= median_spending THEN 'Premium Spenders'
            WHEN annual_income >= median_income                                       THEN 'Untapped Affluent'
            WHEN spending_score >= median_spending                                    THEN 'Value Seekers'
            ELSE 'Budget Conscious'
       END AS segment
FROM with_medians;
GO


/* ---------------------------------------------------------------------
   View 3: v_segment_kpis
   One row per segment with its KPIs. share_pct uses a window function
   over the grouped result: SUM(COUNT(*)) OVER () = all customers.
   AVG is calculated on decimals, because AVG on whole numbers would
   cut off the decimals in T-SQL.
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_segment_kpis AS
SELECT segment,
       COUNT(*)                                                       AS customers,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS share_pct,
       CAST(AVG(annual_income * 1.0)  AS DECIMAL(10,0))               AS avg_income,
       CAST(AVG(spending_score * 1.0) AS DECIMAL(5,1))                AS avg_spending_score,
       CAST(AVG(age * 1.0)            AS DECIMAL(5,1))                AS avg_age,
       CAST(AVG(family_size * 1.0)    AS DECIMAL(4,1))                AS avg_family_size
FROM dbo.v_customer_segments
GROUP BY segment;
GO


/* ---------------------------------------------------------------------
   View 4: v_profession_ranking
   How many customers of each profession are in each segment, and the
   profession's rank within its segment (1 = most common).
   --------------------------------------------------------------------- */
CREATE OR ALTER VIEW dbo.v_profession_ranking AS
WITH counts AS (
    SELECT segment,
           profession,
           COUNT(*) AS customers
    FROM dbo.v_customer_segments
    GROUP BY segment, profession
)
SELECT segment,
       profession,
       customers,
       RANK() OVER (PARTITION BY segment ORDER BY customers DESC) AS rank_in_segment
FROM counts;
GO
