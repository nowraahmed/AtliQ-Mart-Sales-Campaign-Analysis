# ****Store Performance Analysis****

#Top 10 stores in terms of increment revenue generated during promotions

select
	s.city,
    s.store_id,
    round((sum(revenue_after_promo)-sum(revenue_before_promo))/1000000,2) as IR_in_Millions
from fact_events_with_revenue_details #view
join dim_stores s using(store_id)
group by store_id
order by IR_in_Millions Desc
limit 10;

#Bottom 10 stores in terms of Incremental Sold Units

select
	s.city,
    s.store_id,
    sum(qty_after_promo) - sum(`quantity_sold(before_promo)`) as ISU
from fact_events_with_promo_price_and_corrected_qty #view
join dim_stores s using(store_id)
group by store_id
order by ISU
limit 10;

#****Promotion Type Analysis****

#Top 2 promotion type in terms of Incremental Revenue

select
	promo_type,
    round((sum(revenue_after_promo)-sum(revenue_before_promo))/1000000,2) as IR_in_Millions
from fact_events_with_revenue_details #view
group by promo_type
order by IR_in_Millions Desc
limit 2;

#Bottom 2 promotion type in terms of Incremental Sold Units

select
	promo_type,
	sum(qty_after_promo) - sum(`quantity_sold(before_promo)`) as ISU
from fact_events_with_promo_price_and_corrected_qty #view
group by promo_type
order by ISU
limit 2;

# Comparison of promotion types

with cte1 as(
	select
		promo_type,
        round(sum(revenue_after_promo)/1000000,2) as total_revenue_promotion_Millions,
        round((sum(revenue_after_promo)-sum(revenue_before_promo))/1000000,2) as IR_in_Millions,
        sum(qty_after_promo) - sum(`quantity_sold(before_promo)`) as ISU,
        round(sum((case
			when promo_type = "50% off" then base_price* 0.50
            when promo_type = "25% off" then base_price* 0.25
            when promo_type = "bogof" then base_price* 0.50
            when promo_type = "500 cashback" then 500
            when promo_type = "33% off" then base_price* 0.33
            else base_price
            
        end)*qty_after_promo)/1000000,2) as lost_revenue_Millions
from fact_events_with_revenue_details
group by promo_type
)
select 
	*,
    IR_in_Millions - lost_revenue_Millions as Net_Revenue_Millions
from cte1
order by Net_Revenue_Millions desc;

        
#****Product and Category Analysis****

# Lift in sales of Product category 

select
	category,
    ((sum(qty_after_promo) - sum(`quantity_sold(before_promo)`))*100/sum(`quantity_sold(before_promo)`)) as ISU_percent
from fact_events_with_promo_price_and_corrected_qty #view
join dim_products using(product_code)
group by category
order by ISU_percent desc;

# Top 5 products that showed exceptional lift in sales in Diwali sales
select
	product_name
	category,
    ((sum(qty_after_promo) - sum(`quantity_sold(before_promo)`))*100/sum(`quantity_sold(before_promo)`)) as ISU_percent
from fact_events_with_promo_price_and_corrected_qty #view
join dim_products using(product_code)
where campaign_id = "CAMP_DIW_01"
group by product_code
order by ISU_percent desc
limit 5;

# Bottom 5 products that showed least lift in sales in Sankrati Sales
select
	product_name
	category,
    ((sum(qty_after_promo) - sum(`quantity_sold(before_promo)`))*100/sum(`quantity_sold(before_promo)`)) as ISU_percent
from fact_events_with_promo_price_and_corrected_qty #view
join dim_products using(product_code)
where campaign_id = "CAMP_SAN_01"
group by product_code
order by ISU_percent 
limit 5;