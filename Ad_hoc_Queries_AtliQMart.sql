#1
/* 
List of products with base price greater than 500
in promo_type - Buy One Get one Free(BOGOF)
*/

Select 
	distinct p.product_name, 
    e.base_price,
    p.category 
from fact_events e
join dim_products p 
	using(product_code)
where base_price>500 and
	  promo_type="BOGOF";
      
#2
/*
Number of stores in each city
*/

 Select 
	city,
    sum(1) as Store_Counts
 FROM dim_stores
 group by  city
 order by Store_Counts Desc;
 
 #3
 /*
 Total revenue generated before and after promotional campaigns
 */
 
 with fact_events_with_promo_price_and_corrected_qty as 
(select 
	* ,
	case
		when promo_type = "50% off" then base_price * (1 - 0.50)
        when promo_type = "25% off" then base_price * (1 - 0.25)
        when promo_type = "bogof" then base_price * (1 - 0.50)
        when promo_type = "500 cashback" then (base_price - 500)
        when promo_type = "33% off" then base_price * (1 - 0.33)
		else base_price
    end as promo_price,
	if(promo_type = "BOGOF",2*`quantity_sold(after_promo)`, `quantity_sold(after_promo)`) as qty_after_promo 
from fact_events)
select 
	campaign_name,
   	round(sum(base_price*`quantity_sold(before_promo)`)/1000000,2) as Total_revenue_before_promo_in_Millions,
	round(sum(promo_price*qty_after_promo)/1000000,2) as Total_revenue_after_promo_in_Millions
from fact_events_with_promo_price_and_corrected_qty
join dim_campaigns c using(campaign_id)
group by campaign_id; 

#4

/*
Incremental Sold Units %(ISU%) for each category during Diwali campaign
*/

with cte1 as(select 
	p.category,
    sum(`quantity_sold(before_promo)`) as Qty_before,
    sum(qty_after_promo) as Qty_after    
from fact_events_with_promo_price_and_corrected_qty  #view 
join dim_campaigns c using(campaign_id)
join dim_products p using(product_code)
where campaign_name = "Diwali"
group by category),
cte2 as(Select 
	category,
    (Qty_after-Qty_before) as Incremental_sales,
	((Qty_after-Qty_before)*100/Qty_before) as ISU_percent
from cte1)
select
	category,
    ISU_percent,
    rank() over(order by ISU_percent desc) as rank_order
    from cte2;
    
    
   #5
   
   /*
   Top 5 products ranked by Incremental Revenue %
   */
   
with cte1 as (
	select 
	product_name,
    category,
    sum(base_price*`quantity_sold(before_promo)`) as revenue_before_promo,
	sum(promo_price*qty_after_promo) as revenue_after_promo
from fact_events_with_promo_price_and_corrected_qty
join dim_products p using(product_code)
group by product_code)
select
    product_name,
    category,
    (revenue_after_promo - revenue_before_promo)*100/revenue_before_promo as IR_percent
from cte1
order by IR_percent desc
Limit 5; 