--Query:Each Riders Average Delivery Time
WITH delivery_time_taken AS (
    SELECT  
        d.rider_id AS rider_id,
        o.order_time,
        d.delivery_time,
        (
            CASE 
                WHEN d.delivery_time < o.order_time THEN 
                    DATEDIFF(SECOND, o.order_time, '23:59:59') 
                    + DATEDIFF(SECOND, '00:00:00', d.delivery_time) 
                    + 1
                ELSE 
                    DATEDIFF(SECOND, o.order_time, d.delivery_time)
            END
        ) / 60 AS time_taken
    FROM orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
)
SELECT 
    del.rider_id,
    r.rider_name,
    AVG(time_taken) AS delivery_time,
	dense_rank()over(order by avg(time_taken)) as avgperformance
FROM delivery_time_taken del
LEFT JOIN riders r ON del.rider_id = r.rider_id
GROUP BY del.rider_id, r.rider_name

--Query:Rider's total monthly earnings, assuming they earn 8% of the order amount
select d.rider_id,format(o.order_date,'MM-yy') as month,
sum(o.total_amount)*0.08 as  monthly_earning
from orders o
join deliveries d
on o.order_id=d.order_id
group by d.rider_id,format(o.order_date,'MM-yy')
order by sum(o.total_amount)*0.08 desc 


--Query:Rider Ratings Analysis Based on Delivery Time
WITH rider_time AS (
    SELECT 
        d.rider_id,
        d.delivery_time,
        o.order_time,
        -- Calculate time taken for delivery in minutes
        (CASE 
            WHEN d.delivery_time < o.order_time THEN 
                DATEDIFF(SECOND, o.order_time, '23:59:59') 
                + DATEDIFF(SECOND, '00:00:00', d.delivery_time) + 1
            ELSE 
                DATEDIFF(SECOND, o.order_time, d.delivery_time)
         END) / 60.0 AS time_taken
    FROM orders o
    LEFT JOIN deliveries d ON o.order_id = d.order_id
    WHERE d.delivery_status = 'Delivered'
),
star_ranking AS (
    SELECT 
        rider_id,
        time_taken,
        CASE 
            WHEN time_taken < 15 THEN '5 Star'
            WHEN time_taken < 20 THEN '4 Star'
            ELSE '3 Star'
        END AS rider_rating
    FROM rider_time
)
SELECT 
    rider_id,
    rider_rating,
    COUNT(*) AS total_stars
FROM star_ranking
GROUP BY rider_id, rider_rating
ORDER BY rider_id, rider_rating DESC;