# Retail-Sales-Inventory-Performance-Analysis-SQL-BigQuery
This analysis focuses on sales performance, subcategory growth, territory ranking, discount costs, customer retention, inventory efficiency, and pending orders, with the goal of helping the business improve revenue growth, optimize stock planning, strengthen customer loyalty, and make better commercial decisions.

## 📑**TABLE OF CONTENTS**
I. [Project Overview](#i-project-overview) <br/>
II. [Dataset](#ii-dataset) <br/>
III. [Key Business Questions](#iii-key-business-questions) <br/>
IV. [Insights and Recommendations](#iv-insights-and-recommendations) <br/>

## I. PROJECT OVERVIEW

⚓**Business goals:** 

This project analyzes 500K+ e-commerce logs to detect conversion drop-offs, assess traffic source performance and find cross-sell opportunities, helping improve user journey and conversion rates.

❓**Business questions:**
- Which traffic sources bring the most valuable customers and revenue?
- How well do users move through the purchase funnel from product view to add-to-cart to purchase?
- How do browsing and purchasing behaviors differ between buyers and non-buyers?
- How effectively is the website converting traffic into sales and revenue?
- Which products are frequently bought together and could support cross-sell opportunities?

## II. DATASET

- **AdventureWorks** is a fictional multinational company, Adventure Works Cycles, used by Microsoft as a sample business. It manufactures and sells bicycles, parts, and accessories across multiple regions, and its business processes cover sales, production, purchasing, inventory, and customer management.
- The adventureworks2019 dataset is a relational sample database designed for transactional and analytical practice. It contains business data such as products, subcategories, customers, sales orders, discounts, territories, inventory, and shipment/order statuses, which makes it suitable for sales performance, customer retention, stock, and order pipeline analysis.

<details>
  
<summary>See data table in detailed</summary>


| Field Name | Data Type | Description |
|----------|----------|----------|
| fullVisitorId   | String   | The unique visitor ID     |
| date      | String     | The date of the session in YYYYMMDD format      |
| totals      | Record     | This section contains aggregate values across the session      |
| totals.bounces      | Integer     | Total bounces (for convenience). For a bounced session, the value is 1, otherwise it is null      |
| totals.hits      | Integer     | Total number of hits within the session      |
| totals.pageviews      | Integer     | Total number of pageviews within the session      |
| totals.visits     | Integer     | The number of sessions (for convenience). This value is 1 for sessions with interaction events. The value is null if there are no interaction events in the session      |
| totals.transactions      | Integer     | Total number of ecommerce transactions within the session      |
| trafficSource.source      | String     | The source of the traffic source. Could be the name of the search engine, the referring hostname, or a value of the utm_source URL parameter      |
| hits      | Record     | This row and nested fields are populated for any and all types of hits      |
| hits.eCommerceAction      | Record     | This section contains all of the ecommerce hits that occurred during the session. This is a repeated field and has an entry for each hit that was collected      |
| hits.eCommerceAction.action_type      | String     | The action type. Click through of product lists = 1, Product detail views = 2, Add product(s) to cart = 3, Remove product(s) from cart = 4, Check out = 5, Completed purchase = 6, Refund of purchase = 7, Checkout options = 8, Unknown = 0. Usually this action type applies to all the products in a hit, with the following exception: when hits.product.isImpression = TRUE, the corresponding product is a product impression that is seen while the product action is taking place (i.e., a "product in list view")      |
| hits.product      | Record     | This row and nested fields will be populated for each hit that contains Enhanced Ecommerce PRODUCT data      |
| hits.product.productQuantity      | Integer     | The quantity of the product purchased      |
| hits.product.productRevenue      | Integer     | The revenue of the product, expressed as the value passed to Analytics multiplied by 10^6 (e.g., 2.40 would be given as 2400000)      |
| hits.product.productSKU      | String     | Product SKU      |
| hits.product.v2ProductName      | String     | Product Name     |

</details>

## III. KEY BUSINESS QUESTIONS

This project includes 8 queries

### 🔍 Query 1. Calculate total visit, pageview, transaction for January-August 2017 (order by month).

This query is to measure total visits, page views, transactions for each month from January to August in 2017. The result identifies overall trend and growth in the site

🚀 **Query**
```sql
SELECT 
  FORMAT_DATE('%Y%m', parse_date('%Y%m%d', date)) AS month
  ,SUM(totals.visits) AS visits
  ,SUM(totals.pageviews) AS pageview
  ,SUM(totals.transactions) AS transactions
  ,ROUND(100 * SAFE_DIVIDE(SUM(totals.transactions), SUM(totals.visits)), 2) AS conversion_rate_pct

FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
GROUP BY month
ORDER BY month;
```

💡**Query result**

<img width="911" height="305" alt="image" src="https://github.com/user-attachments/assets/c93ba95c-696d-49ca-97ce-3aeb22f21db3" />

**Key-takeaway:**
May had the highest conversion rate (1.77%) while July brought peak volume (71.8k visits, 270k page views) but a relatively low conversion rate (1.49%).

## IV. INSIGHTS AND RECOMMENDATIONS

1.  **Direct and Google brought the strongest revenue contribution**, while some traffic sources generated visits but lower business value. <br/>
--> **Recommendation:** focus more on high-value channels and review lower-quality traffic sources before increasing budget.
