# Customer Segmentation Analysis (T-SQL, Azure SQL Database)

## Business question

Which customer groups offer the highest spending potential relative to their income, and should therefore be the focus of targeted marketing?

## Data

`customers_raw.csv` contains 2,012 rows describing 2,000 customers: gender, age, annual income (EUR), spending score (1–100), profession, work experience and family size.

The dataset is **synthetic**: it was generated for practice, with typical real-world data quality problems built in.

## Approach

| Step | Script | What it does |
|---|---|---|
| 1 | `01_data_quality_checks.sql` | Row count reconciliation, duplicate and missing-value detection, outlier checks |
| 2 | `02_create_views.sql` | Cleaning and segmentation logic stored as SQL views |
| 3 | `03_analysis_queries.sql` | Segment KPIs, profession ranking, age and gender profiles, target list |

**Tools:** Azure SQL Database, T-SQL, SQL Server Management Studio (SSMS), Power BI

## Data quality findings and handling

| Issue | Rows | Handling |
|---|---|---|
| Exact duplicate rows | 12 | Removed (one row kept per customer, `ROW_NUMBER`) |
| Missing profession | 41 | Kept, labelled `Unknown` |
| Inconsistent gender spelling (`male`, `F`, extra spaces) | 60 | Standardised to `Female` / `Male` |
| Invalid age (below 18 or above 100) | 7 | Excluded |
| Spending score outside 1–100 | 4 | Excluded |

The clean dataset contains **1,989 customers**.

## Segmentation

Customers are split at the median of income (EUR 52,000) and of spending score (57):

|  | Spending ≥ median | Spending < median |
|---|---|---|
| **Income ≥ median** | Premium Spenders | Untapped Affluent |
| **Income < median** | Value Seekers | Budget Conscious |

## Key findings

| Segment | Customers | Share | Avg. income | Avg. spending score | Avg. age |
|---|---|---|---|---|---|
| Premium Spenders | 564 | 28.4% | EUR 69,014 | 71.0 | 38.9 |
| Untapped Affluent | 440 | 22.1% | EUR 73,672 | 40.6 | 45.5 |
| Value Seekers | 443 | 22.3% | EUR 35,335 | 69.3 | 34.3 |
| Budget Conscious | 542 | 27.2% | EUR 34,844 | 40.1 | 52.3 |

1. **Untapped Affluent is the main opportunity.** These customers have the highest average income of all segments, yet spend no more than Budget Conscious customers, who earn less than half as much. They use the least of their means: 5.9 spending points per EUR 10,000 of income, against 10.6 for Premium Spenders.
2. **The segment is mostly mid-career professionals.** Engineering, IT and finance are its most common professions, and most of these customers are aged 36–55.
3. **Value Seekers are young and spend heavily relative to income** (26.6 points per EUR 10,000), with many students and skilled trades workers.

## Recommendations

- Target **Untapped Affluent** with premium, quality-focused offers rather than discounts, through channels that reach working professionals.
- Retain **Premium Spenders** with loyalty programmes, since they already spend at a high level.
- Address **Value Seekers** with value-for-money bundles and student offers.

## Power BI dashboard

![Dashboard](dashboard/dashboard.png)

The dashboard connects directly to the view `v_customer_segments` in Azure SQL (Import mode), so a refresh pulls the latest data without manual exports. All KPIs are DAX measures, which means they react to the slicers.

**Visuals**

- KPI cards: customer count, average income, average spending score, Untapped Affluent share
- Scatter chart of income vs. spending score per customer, coloured by segment, with the median split lines
- Customers per segment
- Age profile per segment
- Top 5 professions in the Untapped Affluent segment
- Slicers for gender, age group and profession

**DAX measures**

```dax
Customer Count = COUNTROWS(Customers)

Avg Income = AVERAGE(Customers[annual_income])

Avg Spending Score = AVERAGE(Customers[spending_score])

Share of Customers =
DIVIDE([Customer Count], CALCULATE([Customer Count], ALL(Customers[segment])))

Untapped Affluent Share =
DIVIDE(CALCULATE([Customer Count], Customers[segment] = "Untapped Affluent"), [Customer Count])

Spending per 10k Income =
AVERAGEX(Customers, Customers[spending_score] * 10000 / Customers[annual_income])
```

## Repository structure

```
├── README.md
├── data/
│   └── customers_raw.csv
├── sql/
│   ├── 01_data_quality_checks.sql
│   ├── 02_create_views.sql
│   └── 03_analysis_queries.sql
└── dashboard/
    ├── customer_segmentation.pbix
    ├── customer_segmentation.pdf
    └── dashboard.png
```

## How to run

1. Import `data/customers_raw.csv` into Azure SQL as table `dbo.customers_raw` (SSMS → Tasks → Import Flat File).
2. Run `sql/01_data_quality_checks.sql` to review the raw data.
3. Run `sql/02_create_views.sql` once to create the four views.
4. Run the queries in `sql/03_analysis_queries.sql`.
5. Open `dashboard/customer_segmentation.pbix` in Power BI Desktop, update the data source to your server and refresh.

## Author

Md Abdur Rahim · [LinkedIn](https://linkedin.com/in/rahimthi)
