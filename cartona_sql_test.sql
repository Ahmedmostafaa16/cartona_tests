-- last month

create table last_month as select created_at as last_month_column from orders
					where created_at > (select max(created_at) - interval 30 day  from orders) ; -- will be used in orders table only


-- 1.Retrieve Active Retailers in the last 30 days rolling? (Active Retailers : did at least 1 Delivered order)

select Retailer_id from orders 
where `status` = 'Delivered' and created_at > (select max(created_at) - interval 30 day from orders) ;

-- 2.Sign up Retailers in the last 30 days (Signed up within the last 30 days)

select id,full_name 
from retailers
where created_at >= (select max(created_at) - interval 30 day from retailers) ;

-- 3.New Retailers in the last 30 days (Made his first order within the last 30 days)
select Retailer_id from orders 
inner join last_month 
on last_month.last_month_column = orders.created_at 
group by 1
having count(*) = 1 ;
 
-- 4.Churned Retailers who didn't do any delivered order in the last 30 days and their total GMV lifetime is above 3000
with cte2 as (select Retailer_id,sum(GMV) AS total_gmv from orders
group by 1
having sum(GMV) > 3000
)
select t1.Retailer_id
from cte2 as t1
join orders as t2
  on t1.Retailer_id = t2.Retailer_id
where t2.created_at > (SELECT max(created_at) from orders) - INTERVAL 30 DAY
  and t2.status != 'delivered';
  
-- 5.Retailers whom their last order was between 60 days and 30 days

with last_period as (select retailer_id, max(created_at) as last_order from orders group by retailer_id)

select retailer_id 
FROM last_period
where last_order < (select max(created_at) from orders) - interval 30 day  AND last_order > (select max(created_at) from orders) - interval 60 day ;


 -- 6.Retailers who didn't create any orders
select distinct(r.id) 
from retailers as r
left join orders
on r.id = orders.Retailer_id 
where orders.Retailer_id is null;
                     
-- 7.Retailers who created orders but not delivered 
select Retailer_id
from orders
where `status` != 'delivered' ;

-- 8.Retailers who did more than 5 delivered orders in the last 30 days with their total GMV
with top_retailers as (select Retailer_id ,sum(gmv),count(*)
from orders 
join last_month
on last_month.last_month_column = orders.created_at
group by 1
having count(*) > 5 )

select Retailer_id
from top_retailers ;

-- 9.How many Retailers who were active last month and still active this month
select count(DISTINCT retailer_id) as active_both_months
from orders o
where retailer_id in (select retailer_id from orders
        where date_format(created_at, '%Y-%m') = date_format((select max(created_at) from orders), '%Y-%m')
)
AND retailer_id in (select retailer_id from orders
where date_format(created_at, '%Y-%m') = date_format (date_sub((select max(created_at) from orders), interval 1 month), '%Y-%m')
);
 

-- 10. How many orders have more than 5 Products
select count(order_id) as number_of_orders_have_more_than_5_products

from(
select order_id , sum(amount) as total 
from order_details
group by order_id
having sum(amount) > 5 ) subqurey ;




-- 11. Average of number of items in orders
with total_items as(select order_id,sum(amount) as total
from order_details
group by 1)
select avg(total) as average_number_per_order
from total_items ;





-- 12. Count of orders and retailers per Area
select  a.id as area_id, count(distinct(r.id)) as count_of_retailers ,count(o.id) as count_oforders
from orders as o
left join retailers as r
on o.Retailer_id = r.id
join areas as a
on r.Area_id = a.id
group by 1
order by 2 desc;


-- 13.Number of orders for each retailer in his first 30 days
with first_month_order_table as (select  retailer_id ,min(created_at) as first_order_date, (min(created_at)+ interval 30 day) as first_month_order_date 
from orders 
group by 1 )

select o.retailer_id ,count(*) as number_of_ordders
from orders as o
join first_month_order_table as cte 
using(retailer_id)
where o.created_at between cte.first_order_date AND cte.first_month_order_date
group by 1 ;

-- 14.Retention Rate per month in year 2020 (Retention means Retailers who were active last month and still active this month)

with cte as ( select retailer_id, year(created_at) as year, month(created_at) as month from orders
where year(created_at) = 2020 ) 

, retailers_per_month as ( select month, retailer_id from cte
group by month, retailer_id
),
retention as (
select curr.month, count(distinct curr.retailer_id) as current_active,count(distinct prev.retailer_id) as previous_active,
count(distinct case when prev.retailer_id is not null then curr.retailer_id end) as retained
from retailers_per_month curr
left join retailers_per_month prev
on curr.retailer_id = prev.retailer_id
and curr.month = prev.month + 1    -- used +1 to have month and next month in the same same row so the comparison work
group by curr.month
)
select month,
retained,previous_active,(retained * 100.0 / previous_active) as retention_rate
from retention
where month > 1
order by 1 ;


-- 15.GMV of the first order per Retailer
with first_order as (select Retailer_id,created_at,gmv , rank()over(partition by Retailer_id order by created_at asc) as rnk from  orders 
)
select Retailer_id,gmv  
from first_order
where rnk = 1;














 
 
 
 





