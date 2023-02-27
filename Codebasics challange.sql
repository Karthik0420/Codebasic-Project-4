##1.Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

select DISTINCT market 
FROM gdb023.dim_customer
where customer= 'Atliq Exclusive' and REGION= 'APAC' ;

##2.What is the percentage of unique product increase in 2021 vs. 2020?##

with unique_products_2020_count  as 
(select count(distinct product_code) as unique_products_2020 from fact_sales_monthly
where fiscal_year= '2020' ),
unique_products_2021_count as
(select count(distinct product_code) as unique_products_2021 from fact_sales_monthly
where fiscal_year= '2021' )

 select A.unique_products_2020 ,B.unique_products_2021, 
 round(((B.unique_products_2021 - A.unique_products_2020)/ (A.unique_products_2020 )),2) as percentage_chg
 from unique_products_2020_count as A
 cross join unique_products_2021_count as B

## 3.Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.

select segment , count(distinct product_code) as prod_count
from dim_product 
group by segment 
order by prod_count desc;

##4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, segment ,product_count_2020, product_count_2021, difference

WITH uniq_prod_2020 AS (
    SELECT a.segment, COUNT(DISTINCT a.product_code) AS unique_product_2020
    FROM fact_sales_monthly b
    JOIN dim_product a ON
    b.product_code = a.product_code 
    WHERE b.fiscal_year = 2020
    GROUP BY a.segment),
    
uniq_prod_2021 AS (
    SELECT a.segment, COUNT(DISTINCT a.product_code) AS unique_product_2021
    FROM fact_sales_monthly b
    JOIN dim_product a ON
    b.product_code = a.product_code 
    WHERE b.fiscal_year = 2021
    GROUP BY a.segment)
    
SELECT A.segment,unique_product_2020,unique_product_2021,
      (unique_product_2021 - unique_product_2020) AS difference 
       FROM uniq_prod_2020 A
       JOIN uniq_prod_2021 B ON
       A.segment = B.segment
       GROUP BY B.segment
       ORDER BY difference DESC;

##5. Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, product_code, product, manufacturing_cost

select a.product_code , a.product , b.manufacturing_cost
from dim_product a 
inner join fact_manufacturing_cost b
on a.product_code = b.product_code 
where b.manufacturing_cost = (select max(manufacturing_cost) from fact_manufacturing_cost)
or b.manufacturing_cost = (select min(manufacturing_cost) from fact_manufacturing_cost);

##6. Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.The final output contains these fields, customer_code ,customer, average_discount_percentage

select a.customer_code, b.customer, a.pre_invoice_discount_pct
from  fact_pre_invoice_deductions a 
inner join dim_customer b
on a.customer_code= b.customer_code
where a.pre_invoice_discount_pct > (select avg(pre_invoice_discount_pct) from 
fact_pre_invoice_deductions where fiscal_year = 2021 and market= 'India')
order by a.pre_invoice_discount_pct desc
limit 5;

##7. Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month ,Year, Gross sales Amount

select month(b.date) as month, year(b.date) as year , sum(round( b.sold_quantity*a.gross_price)) as gross_sale
from fact_gross_price a 
inner join fact_sales_monthly b
on a.product_code = b.product_code 
inner join dim_customer c 
on b.customer_code =c.customer_code
where c.customer = 'Atliq Exclusive'
group by 1,2
order by 2


##8. In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, Quarter total_sold_quantity##




select case 
   when month(date) in (9,10,11) then "Quarter 1"
    when month(date) in (12,1,2) then "Quarter 2"
     when month(date) in (3,4,5) then "Quarter 3"
      when month(date) in (6,7,8) then "Quarter 4"
      end as Qtr,
      sum(sold_quantity) as total_sales_quantity
      from fact_sales_monthly 
      where fiscal_year = 2020
      group by Qtr
      order by total_sales_quantity desc;
      
##9. Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel, gross_sales_mln, percentage
       
with cte as 
(select a.channel, round(sum( (b.sold_quantity* c.gross_price)/1000000),2) as gross_sales_mln 
from dim_customer a 
inner join fact_sales_monthly b 
on a.customer_code = b.customer_code 
inner join fact_gross_price c 
on b.product_code = c.product_code
where c.fiscal_year = 2021 
group by 1 )
select * ,  gross_sales_mln*100/SUM(gross_sales_mln) over() as percentage
from cte 
order by percentage desc;



##10. Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields, division ,product_code, product ,total_sold_quantity, rank_orde
 
with cte as (select a.division,a.product_code , a.product, sum(b.sold_quantity) total_sold_quantity 
from dim_product a    
inner join fact_sales_monthly b
on a.product_code = b.product_code  
where b.fiscal_year = 2021 
group by 1,2,3),
rnk as (select * , dense_rank ()over (partition by division order by total_sold_quantity ) as rank_order
from cte )
select * from rnk 
where rank_order < 4;
      
      
      
      













