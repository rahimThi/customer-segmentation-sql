/* =====================================================================
   Customer Segmentation Analysis
   Step 3: Analysis queries for the findings
   Run AFTER 02_create_views.sql. Highlight one query and press F5
   to run only that one.
   Business question: which customer groups offer the highest
   spending potential relative to their income?
   ===================================================================== */


-- 1. How many rows survived cleaning, and what are the split points?
SELECT COUNT(*) AS clean_customers,
       (SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY annual_income)  OVER () FROM dbo.v_customers_clean) AS median_income,
       (SELECT TOP 1 PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY spending_score) OVER () FROM dbo.v_customers_clean) AS median_spending_score
FROM dbo.v_customers_clean;


-- 2. Segment overview: size, share and averages
SELECT *
FROM dbo.v_segment_kpis
ORDER BY avg_income DESC;


-- 3. Top 3 professions in each segment
SELECT segment,
       rank_in_segment,
       profession,
       customers
FROM dbo.v_profession_ranking
WHERE rank_in_segment <= 3
ORDER BY segment, rank_in_segment;


-- 4. Key finding: income vs. spending of Untapped Affluent compared with the rest.
--    Spending per 10,000 EUR of income shows how much of their means they use.
SELECT segment,
       CAST(AVG(annual_income * 1.0)  AS DECIMAL(10,0)) AS avg_income,
       CAST(AVG(spending_score * 1.0) AS DECIMAL(5,1))  AS avg_spending_score,
       CAST(AVG(spending_score * 10000.0 / annual_income) AS DECIMAL(6,2)) AS spending_per_10k_income
FROM dbo.v_customer_segments
GROUP BY segment
ORDER BY spending_per_10k_income;


-- 5. Age profile of each segment (share of each age group within the segment)
SELECT segment,
       age_group,
       COUNT(*) AS customers,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY segment) AS DECIMAL(5,1)) AS pct_of_segment
FROM dbo.v_customer_segments
GROUP BY segment, age_group
ORDER BY segment, age_group;


-- 6. Gender split per segment
SELECT segment,
       gender,
       COUNT(*) AS customers,
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY segment) AS DECIMAL(5,1)) AS pct_of_segment
FROM dbo.v_customer_segments
GROUP BY segment, gender
ORDER BY segment, gender;


-- 7. Target list for the marketing recommendation:
--    the 20 Untapped Affluent customers with the largest gap between
--    income rank and spending rank.
WITH ranked AS (
    SELECT customer_id,
           profession,
           age,
           annual_income,
           spending_score,
           RANK() OVER (ORDER BY annual_income DESC)  AS income_rank,
           RANK() OVER (ORDER BY spending_score DESC) AS spending_rank
    FROM dbo.v_customer_segments
    WHERE segment = 'Untapped Affluent'
)
SELECT TOP 20
       customer_id,
       profession,
       age,
       annual_income,
       spending_score,
       spending_rank - income_rank AS potential_gap
FROM ranked
ORDER BY potential_gap DESC;
