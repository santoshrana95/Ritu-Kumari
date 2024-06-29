****DATA PREPARATION AND UNDERSTANDING****

1. What is the total number of rows in each of the 3 tables in the database? 

select count(*) from e_commerce.transactions_new;

select count(*) from e_commerce.customers_new;

select count(*) from e_commerce.prod_cat_info;

2. What is the total number of transactions that have a return?

select count(*) from  e_commerce.transactions_new where total_amt < 0 ;

3.you would have noticed, the dates provided across the datasets are not in a correct format. As first steps, pls convert the date variables into valid date formats before proceeding ahead.

UPDATE e_commerce.transactions_new
SET tran_date = STR_TO_DATE(tran_date, '%d-%m-%Y')
WHERE tran_date IS NOT NULL;

ALTER TABLE e_commerce.transactions_new
MODIFY COLUMN tran_date DATE NOT NULL;


UPDATE e_commerce.customers_new
SET DOB = STR_TO_DATE(DOB, '%d-%m-%Y')
WHERE DOB IS NOT NULL;

ALTER TABLE e_commerce.customers_new
MODIFY COLUMN DOB DATE NOT NULL;

4. What is the time range of the transaction data available for analysis? Show the output in number of days, months and years simultaneously in different columns.

SELECT
    MIN(tran_date) AS trans_start_date,
    MAX(tran_date) AS tras_end_date,
    DATEDIFF(MAX(tran_date), MIN(tran_date)) AS total_trans_days,
    TIMESTAMPDIFF(MONTH, MIN(tran_date), MAX(tran_date)) AS total_trans_in_months,
    TIMESTAMPDIFF(YEAR, MIN(tran_date), MAX(tran_date)) AS total_trans_in_years
FROM
    e_commerce.transactions_new;
   
5. Which product category does the sub-category "DIY" belong to?

select prod_cat from e_commerce.prod_cat_info
where prod_subcat = 'DIY' ;
_______________________________________________________________________________________
****DATA ANALYSIS****

1. Which channel is most frequently used for transactions?

SELECT
    Store_type,
    COUNT(*) AS transaction_count
FROM
    e_commerce.transactions_new
GROUP BY
    Store_type
ORDER BY
    transaction_count DESC
LIMIT 1;

2. What is the count of Male and Female customers in the database?

SELECT
    Gender,
    COUNT(DISTINCT ï»¿customer_Id) AS customer_count
FROM
    e_commerce.customers_new
where Gender in ('M','F')
GROUP BY
    Gender;
   
3. From which city do we have the maximum number of customers and how many?

   select city_code,count(DISTINCT ï»¿customer_Id)  as total_customer 
   from e_commerce.customers_new
   group by city_code
   order by count(DISTINCT ï»¿customer_Id)  desc
   limit 1; 
   
4. How many sub-categories are there under the Books category?
   
   select count(*) from e_commerce.prod_cat_info 
   where prod_cat  = 'Books'
   
5. What is the maximum quantity of products ever ordered?
   
   select max(Qty) as maximum_quantity 
   from  e_commerce.transactions_new;   
 
6. What is the net total revenue generated in categories Electronics and Books?
   
   select round(SUM(total_amt),2) as net_revenue,prod_cat from  e_commerce.transactions_new
   join e_commerce.prod_cat_info on  e_commerce.transactions_new.prod_cat_code=
   e_commerce.prod_cat_info.prod_cat_code
   where prod_cat in ("ELECTRONICS","BOOKS") group by prod_cat;

7. How many customers have >10 transactions with us, excluding returns?

select cust_id, count(cust_id) as transactions 
from e_commerce.transactions_new where Qty>=0 group by cust_id having count(cust_id) >10;
	
8. What is the combined revenue earned from the "Electronics" & "Clothing" categories, from "Flagship stores"?

select Store_type,round(sum(total_amt),0) as net_revenue,prod_cat from e_commerce.transactions_new 
join e_commerce.prod_cat_info  on e_commerce.transactions_new. prod_subcat_code = e_commerce.prod_cat_info.prod_cat_code
where prod_cat in ("ELECTRONICS","Clothing") group by prod_cat,store_type
having store_type="Flagship store";   

9. What is the total revenue generated from "Male" customers in "Electronics" category? Output should display total revenue by prod sub-cat.

select round(sum(total_amt),0) as total_revenue,c.gender,p.prod_subcat from e_commerce.transactions_new t
join e_commerce.customers_new c
on t.cust_Id= c.ï»¿customer_Id
join e_commerce.prod_cat_info p on p.prod_cat_code= t.prod_cat_code
where gender="M" group by gender, prod_subcat;

10. What is percentage of sales and returns by product sub category; display only top 5 sub categories in terms of sales?

WITH SubcategorySales AS (
    SELECT 
        t.prod_subcat_code,
        p.prod_subcat,
        SUM(t.total_amt) AS total_sales,
        SUM(CASE WHEN t.Qty < 0 THEN t.total_amt ELSE 0 END) AS total_returns
    FROM 
        Transactions_new t
    JOIN 
       prod_cat_info  p ON t.prod_subcat_code = p.prod_sub_cat_code
    GROUP BY 
        t.prod_subcat_code, p.prod_subcat
),
TopSubcategories AS (
    SELECT 
        prod_subcat,
        total_sales,
        total_returns,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
        (total_sales / SUM(total_sales) OVER ()) * 100 AS sales_percentage,
        (total_returns / SUM(total_returns) OVER ()) * 100 AS returns_percentage
    FROM 
        SubcategorySales
)
SELECT 
    prod_subcat,
    total_sales,
    sales_percentage,
    total_returns,
    returns_percentage
FROM 
    TopSubcategories
WHERE 
    sales_rank <= 5;

   
11. For all customers aged between 25 to 35 years find what is the net total revenue generated by 
these consumers in last 30 days of transactions from max transaction date available in the  
data?

   
  WITH max_tran_date AS (
    SELECT MAX(tran_date) AS max_date
    FROM e_commerce.transactions_new
),
last_30days_sales AS (
    SELECT t.cust_id, t.tran_date, t.total_amt, m.max_date
    FROM e_commerce.transactions_new t
    CROSS JOIN max_tran_date m
    WHERE t.tran_date BETWEEN DATE_SUB(m.max_date, INTERVAL 30 DAY) AND m.max_date
),
age_btwn_2530 AS (
    SELECT c.ï»¿customer_Id, YEAR(m.max_date) - YEAR(c.DOB) AS age
    FROM e_commerce.customers_new  c
    CROSS JOIN max_tran_date m
    WHERE YEAR(m.max_date) - YEAR(c.DOB) BETWEEN 25 AND 35
),
net_rev AS (
    SELECT SUM(t.total_amt) AS net_total_revenue
    FROM last_30days_sales t
    JOIN age_btwn_2530 e ON t.cust_id = e.ï»¿customer_Id
)

SELECT net_total_revenue
FROM net_rev;

12. Which product category has seen the max value of returns in the last 3 months of transactions?

SELECT p.prod_cat, t.Qty
FROM e_commerce.prod_cat_info p
JOIN e_commerce.transactions_new t ON p.prod_cat_code = t.prod_cat_code
WHERE t.Qty < 0
AND t.tran_date >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH);

13. Which store-type sells the maximum products; by value of sales amount and by quantity sold?

SELECT 
    Store_type, 
    SUM(total_amt) AS total_amt, 
    SUM(Qty) AS total_qty
FROM 
    e_commerce.transactions_new 
GROUP BY 
    Store_type 
ORDER BY 
    SUM(total_amt) DESC, 
    SUM(Qty) DESC
LIMIT 1;    

14. What are the categories for which average revenue is above the overall average.

SELECT 
    p.prod_cat,
    AVG(t.total_amt) AS avg_cat_rev
FROM  
    e_commerce.transactions_new t
JOIN 
    e_commerce.prod_cat_info p ON t.prod_cat_code = p.prod_cat_code
GROUP BY 
    p.prod_cat
HAVING 
    AVG(t.total_amt) > (SELECT AVG(total_amt) FROM e_commerce.transactions_new);


   
15. Find the average and total revenue by each subcategory for the categories 
which are among top 5 categories in terms of quantity sold.
   
WITH TopCategories AS (
    SELECT 
        prod_cat_code,
        SUM(Qty) AS total_quantity_sold
    FROM  
        e_commerce.transactions_new
    GROUP BY 
        prod_cat_code
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 5
)
SELECT 
    p.prod_cat,
    AVG(t.total_amt) AS avg_revenue,
    SUM(t.total_amt) AS total_revenue
FROM  
    e_commerce.transactions_new t
JOIN 
    e_commerce.prod_cat_info p ON t.prod_cat_code = p.prod_cat_code
JOIN 
    TopCategories tc ON t.prod_cat_code = tc.prod_cat_code
GROUP BY 
    p.prod_cat;