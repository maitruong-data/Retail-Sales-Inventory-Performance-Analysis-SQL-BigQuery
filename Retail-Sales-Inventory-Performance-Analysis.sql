--Q1 Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M

SELECT 
      FORMAT_DATETIME('%b %Y', o.ModifiedDate) AS period
      --EXTRACT(YEAR FROM o.ModifiedDate) AS year
      --,EXTRACT(MONTH FROM o.ModifiedDate) AS month
      ,ps.Name
      ,SUM(o.OrderQty) AS qty_item
      ,ROUND(SUM(o.LineTotal), 2) AS total_sales
      ,COUNT(DISTINCT o.SalesOrderID) AS order_cnt
FROM `adventureworks2019.Sales.SalesOrderDetail` o 
LEFT JOIN `adventureworks2019.Production.Product` p
  ON o.ProductID = p.ProductID
LEFT JOIN `adventureworks2019.Production.ProductSubcategory` ps
  ON p.ProductSubcategoryID = CAST(ps.ProductSubcategoryID AS string)

WHERE DATE(o.ModifiedDate) >=  (SELECT DATE_SUB(DATE(MAX(o.ModifiedDate)), INTERVAL 12 month)
                                FROM `adventureworks2019.Sales.SalesOrderDetail` )
GROUP BY period, Name
ORDER BY period DESC, total_sales DESC, qty_item DESC, Name;


--Q2. Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate. Can use metric: quantity_item. Round results to 2 decimal

WITH sales_quantity AS (--get sales quantity per year per subcategory
  SELECT 
    EXTRACT(YEAR FROM s.ModifiedDate) AS year
    ,ps.Name AS Name
    ,SUM(s.OrderQty) AS qty_item
    
  FROM `adventureworks2019.Sales.SalesOrderDetail` AS s
    LEFT JOIN `adventureworks2019.Production.Product` AS p 
    ON s.ProductID = p.ProductID
    LEFT JOIN `adventureworks2019.Production.ProductSubcategory` AS ps 
    ON CAST(p.ProductSubcategoryID AS int64) = ps.ProductSubcategoryID
                                  
  GROUP BY year, Name 
  ORDER BY year, Name
)

,prev_quantity AS (--compare quantity this year vs. previous year for each subcategory
  SELECT 
    Name
    ,year
    ,qty_item
    ,LAG(qty_item) OVER(PARTITION BY Name ORDER BY year) AS prv_qty
  FROM sales_quantity
)

,YoY_rate AS (--calculate YoY growth rate = qty_item / prv_qty - 1
  SELECT
    Name
    ,year
    ,qty_item
    ,prv_qty
    ,ROUND(qty_item / prv_qty - 1, 2) AS qty_diff
  FROM prev_quantity
)

,rnk AS (--get rank for qty_diff
  SELECT 
    Name
    ,year
    ,qty_item
    ,prv_qty
    ,qty_diff
    ,DENSE_RANK() OVER(ORDER BY qty_diff DESC) AS rn
  FROM YoY_rate
  )

SELECT 
  Name
  ,qty_item
  ,prv_qty
  ,qty_diff
FROM rnk
WHERE rn <= 3 --filter top 3 from ranking
ORDER BY qty_diff DESC;


--Q3. Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number

WITH count_order AS (--count order per territory ID per year
  SELECT 
      EXTRACT(YEAR FROM s.ModifiedDate) AS yr
      ,sh.TerritoryID AS TerritoryID
      ,SUM(s.OrderQty) AS order_cnt 
      
  FROM `adventureworks2019.Sales.SalesOrderDetail` AS s
  LEFT JOIN `adventureworks2019.Sales.SalesOrderHeader` AS sh 
  ON s.SalesOrderID = sh.SalesOrderID
                                  
  GROUP BY yr, TerritoryID
)

,get_rank AS (--rank the orders by territory ID
  SELECT 
    yr
    ,TerritoryID
    ,order_cnt
    ,DENSE_RANK() OVER(PARTITION BY yr ORDER BY order_cnt DESC) AS rn 
  FROM count_order
)

SELECT
  yr
  ,TerritoryID
  ,order_cnt
  ,rn
FROM get_rank
WHERE rn <= 3
ORDER BY yr DESC, rn;



--Q4. Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory

SELECT
    FORMAT_TIMESTAMP("%Y", ModifiedDate) AS year
    ,Name
    ,SUM(disc_cost) AS total_cost
FROM (
      SELECT DISTINCT o.ModifiedDate
      ,ps.Name
      ,so.DiscountPct, so.Type
      ,o.OrderQty * so.DiscountPct * UnitPrice AS disc_cost 
      FROM `adventureworks2019.Sales.SalesOrderDetail` o
      LEFT JOIN `adventureworks2019.Production.Product` p on o.ProductID = p.ProductID
      LEFT JOIN `adventureworks2019.Production.ProductSubcategory` ps ON CAST(p.ProductSubcategoryID as int) = ps.ProductSubcategoryID
      LEFT JOIN `adventureworks2019.Sales.SpecialOffer` so on o.SpecialOfferID = so.SpecialOfferID
      WHERE LOWER(so.Type) LIKE '%seasonal discount%' 
)
GROUP BY year, Name;


--Q5. Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)

WITH base AS (
  SELECT  
      EXTRACT(month FROM ModifiedDate) AS month_no
      ,EXTRACT(year FROM ModifiedDate) AS year_no
      ,CustomerID
      ,COUNT(DISTINCT SalesOrderID) AS order_cnt
  FROM `adventureworks2019.Sales.SalesOrderHeader`
  WHERE FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2014'
  AND Status = 5
  GROUP BY 1,2,3
  ORDER BY 3,1 
),

row_num AS (--mark row number for order month 
  SELECT 
      month_no
      ,year_no
      ,CustomerID
      ,order_cnt
      ,ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY month_no) AS row_numb
  FROM base 
), 

first_order AS (-- First month of order per customer
  SELECT 
      month_no
      ,year_no
      ,CustomerID
      ,order_cnt
  FROM row_num
  WHERE row_numb = 1
), 

month_gap AS (
  SELECT 
      b.CustomerID
      ,fo.month_no AS month_join
      ,b.month_no AS month_order
      ,b.order_cnt
      ,CONCAT('M - ',b.month_no - fo.month_no) AS month_diff
  FROM base AS b
  LEFT JOIN first_order AS fo 
  ON b.CustomerID = fo.CustomerID
  ORDER BY CustomerID,month_order
)

SELECT 
  month_join
  ,month_diff 
  ,COUNT(DISTINCT CustomerID) AS customer_cnt
FROM month_gap
GROUP BY month_join,month_diff 
ORDER BY month_join,month_diff;



--Q6. Trend of Stock level & MoM diff % by all product in 2011. If %gr rate is null then 0. Round to 1 decimal

WITH stock_qty_count AS (--count stock quantity by month, year and product in 2011
  SELECT 
    p.Name AS Name
    ,EXTRACT(MONTH FROM w.ModifiedDate) AS month
    ,EXTRACT(YEAR FROM w.ModifiedDate) AS year
    ,SUM(w.StockedQty) AS stock_qty
  FROM `adventureworks2019.Production.WorkOrder` w  
  LEFT JOIN `adventureworks2019.Production.Product` p
  ON p.ProductID = w.ProductID
  WHERE EXTRACT(YEAR FROM w.ModifiedDate) = 2011
  GROUP BY p.Name, month, year
)

,stock_prv_month AS (--get stock quantity for previous month
  SELECT 
    Name
    ,month
    ,year
    ,stock_qty
    ,LAG(stock_qty) OVER (PARTITION BY Name ORDER BY month) AS stock_prv
  FROM stock_qty_count
  GROUP BY Name, month, year, stock_qty
)

SELECT 
  Name
  ,month
  ,year
  ,stock_qty
  ,stock_prv
  ,CASE WHEN stock_prv is null then 0 
        WHEN stock_prv is not null 
          then ROUND(100 * COALESCE((stock_qty - stock_prv) / stock_prv, 0), 1) 
        END AS diff
FROM stock_prv_month
ORDER BY Name, year, month;



--Q7. Calc Ratio of Stock / Sales in 2011 by product name, by month
--Order results by month desc, ratio desc. Round Ratio to 1 decimal mom yoy

WITH stock AS (--get stock quantity per product per month
  SELECT
    EXTRACT(MONTH FROM ModifiedDate) AS month
    ,EXTRACT(YEAR FROM ModifiedDate) AS year
    ,ProductID 
    ,SUM(StockedQty) AS stock
  FROM `adventureworks2019.Production.WorkOrder` 
  WHERE EXTRACT(YEAR FROM ModifiedDate) = 2011
  GROUP BY ProductID, month, year
)

,sales AS (--get sales quantity per product per month
  SELECT 
    EXTRACT(MONTH FROM s.ModifiedDate) AS month
    ,EXTRACT(YEAR FROM s.ModifiedDate) AS year
    ,s.ProductID 
    ,p.Name
    ,SUM(s.OrderQty) AS sales
  FROM `adventureworks2019.Sales.SalesOrderDetail` s
  LEFT JOIN `adventureworks2019.Production.Product` p
  ON p.ProductID = s.ProductID
  WHERE EXTRACT(YEAR FROM s.ModifiedDate) = 2011
  GROUP BY Name, month, year, ProductID
)

SELECT 
  sa.month AS month
  ,sa.year AS year
  ,sa.ProductID AS ProductId
  ,sa.Name AS Name
  ,sa.sales AS sales
  ,st.stock AS stock
  ,ROUND(COALESCE(st.stock, 0) / sa.sales, 2) AS ratio --ratio = Stock quanity / Sales quantity
FROM stock AS st
FULL JOIN sales AS sa 
ON sa.ProductID = st.ProductID
 AND sa.year = st.year
 AND sa.month = st.month
ORDER BY month DESC, ratio DESC;




--Q8. No of order and value at Pending status in 2014

SELECT
  EXTRACT(YEAR FROM OrderDate) AS yearr
  ,Status
  ,COUNT(DISTINCT PurchaseOrderID) AS order_count
  ,ROUND(SUM(TotalDue), 2) AS value
  
FROM `adventureworks2019.Purchasing.PurchaseOrderHeader`
WHERE Status = 1 --Status = 1 means Pending
  AND EXTRACT(YEAR FROM OrderDate) = 2014
GROUP BY yearr, Status;

