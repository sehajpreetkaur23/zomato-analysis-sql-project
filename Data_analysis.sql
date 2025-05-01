--CUSTOMER_ANALYSIS
-- Query: Average Order Value for High-Frequency Customers (750+ Orders)

SELECT 
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(AVG(o.total_amount), 2) AS avg_order_value
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_name
HAVING COUNT(o.order_id) > 750
ORDER BY total_orders DESC;

--Query: Identify Customers Active in 2023 but Inactive in 2024

SELECT DISTINCT c.customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE DATEPART(YEAR, o.order_date) = 2023
  AND o.customer_id NOT IN (
      SELECT customer_id
      FROM orders
      WHERE DATEPART(YEAR, order_date) = 2024
  );

--Query:Segment Customers into Gold and Silver Tiers Based on Spending
WITH customer_segment AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS total_orders,
        SUM(total_amount) AS customer_spending
    FROM orders
    GROUP BY customer_id
),
overall_avg_spending AS (
    SELECT 
        SUM(total_amount) * 1.0 / COUNT(DISTINCT customer_id) AS avg_spend_per_customer
    FROM orders
)
SELECT 
    cs.customer_id,
    cs.total_orders,
    cs.customer_spending,
    oas.avg_spend_per_customer,
    CASE 
        WHEN cs.customer_spending > oas.avg_spend_per_customer THEN 'Gold'
        ELSE 'Silver'
    END AS customer_category
FROM customer_segment cs
CROSS JOIN overall_avg_spending oas;


-- Query:Estimates long-term customer value based on spending, frequency, and recency.

SELECT 
    c.customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent,
    MAX(o.order_date) AS last_order_date,
    DATEDIFF(DAY, MIN(o.order_date), MAX(o.order_date)) AS customer_lifetime_days
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_name
ORDER BY 
    total_orders DESC,
    total_spent DESC;

--Query: Top 3 Most Ordered Dishes by Top 5 Customers (Past 2 Years)

WITH top_customers AS (
    SELECT TOP 5 
        customer_id,
        COUNT(*) AS total_orders
    FROM orders
    WHERE order_date >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY customer_id
    ORDER BY total_orders DESC
),

top_dishes AS (
    SELECT 
        customer_id,
        order_item AS dish_name,
        COUNT(*) AS times_ordered,
        DENSE_RANK() OVER (
            PARTITION BY customer_id 
            ORDER BY COUNT(*) DESC
        ) AS dish_rank
    FROM orders
    WHERE customer_id IN (SELECT customer_id FROM top_customers)
      AND order_date >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY customer_id, order_item
)

SELECT 
    customer_id,
    dish_name,
    times_ordered,
    dish_rank
FROM top_dishes
WHERE dish_rank <= 3
ORDER BY customer_id, dish_rank;

-- query:Categorizes customers based on their order frequency to analyze retention.

SELECT 
    customer_id,
    COUNT(order_id) AS total_orders,
    CASE 
        WHEN COUNT(order_id) = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type
FROM orders
GROUP BY customer_id
ORDER BY customer_id;


--RESTAURANT_PERFORMANCE

-- Query: Undelivered Orders by Restaurant and City

SELECT 
    r.restaurant_name,
    r.city,
    COUNT(d.delivery_status) AS undelivered_orders
FROM orders o
LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
LEFT JOIN deliveries d ON o.order_id = d.order_id
WHERE d.delivery_status = 'Not Delivered'
GROUP BY r.restaurant_name, r.city
ORDER BY undelivered_orders DESC;

-- Query: Top 10 Restaurants by Revenue (Global & City-wise Ranking) – Last 2 Years

WITH ranking AS (
    SELECT 
        r.restaurant_name,
        r.city,
        SUM(o.total_amount) AS restaurant_revenue,
        DENSE_RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS overall_rank,
        DENSE_RANK() OVER (PARTITION BY r.city ORDER BY SUM(o.total_amount) DESC) AS city_rank
    FROM restaurants r
    RIGHT JOIN orders o ON r.restaurant_id = o.restaurant_id
    WHERE o.order_date >= DATEADD(YEAR, -2, GETDATE())
    GROUP BY r.restaurant_name, r.city
)

SELECT *
FROM ranking
WHERE overall_rank <= 10
  AND city_rank <= 10;


-- Query: Most Popular Dish by City & Top Restaurant for It Based on Number of Orders

WITH dish_ranking AS (
    SELECT 
        o.order_item,
        r.restaurant_name,
        r.city,
        COUNT(o.order_item) AS total_orders,
        
        -- Rank dishes by popularity within each city
        DENSE_RANK() OVER (PARTITION BY r.city ORDER BY COUNT(o.order_item) DESC) AS city_rank,
        
        -- Rank restaurants overall based on dish popularity
        DENSE_RANK() OVER (ORDER BY COUNT(o.order_item) DESC) AS restaurant_rank
    FROM orders o
    LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY o.order_item, r.restaurant_name, r.city
)

SELECT *
FROM dish_ranking
WHERE city_rank = 1
  AND restaurant_rank = 1;

--QUERY:Compare Order Cancellation Rates by Restaurant for 2023 vs 2024

WITH cancellation_2023 AS (
    SELECT 
        o.restaurant_id,
        r.restaurant_name,
        ROUND(
            CAST(COUNT(CASE WHEN o.order_status = 'Not Fulfilled' THEN 1 END) AS DECIMAL) / 
            CAST(COUNT(o.order_id) AS DECIMAL) * 100, 
        2) AS rate_2023
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    WHERE DATEPART(YEAR, o.order_date) = 2023
    GROUP BY o.restaurant_id, r.restaurant_name
),

cancellation_2024 AS (
    SELECT 
        o.restaurant_id,
        r.restaurant_name,
        ROUND(
            CAST(COUNT(CASE WHEN o.order_status = 'Not Fulfilled' THEN 1 END) AS DECIMAL) / 
            CAST(COUNT(o.order_id) AS DECIMAL) * 100, 
        2) AS rate_2024
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    WHERE DATEPART(YEAR, o.order_date) = 2024
    GROUP BY o.restaurant_id, r.restaurant_name
)

SELECT 
    a.restaurant_id,
    a.restaurant_name,
    CAST(a.rate_2023 AS DECIMAL(10,2)) AS rate_2023,
    CAST(b.rate_2024 AS DECIMAL(10,2)) AS rate_2024
FROM cancellation_2023 a
JOIN cancellation_2024 b ON a.restaurant_id = b.restaurant_id
ORDER BY rate_2023 DESC;

 --Query:Monthly Growth Ratio of Delivered Orders per Restaurant

WITH restaurant_monthly_orders AS (
    SELECT 
        o.restaurant_id AS rest_id,
        FORMAT(o.order_date, 'MM-yy') AS monthly,
        COUNT(o.order_id) AS total_orders,
        LAG(COUNT(o.order_id)) OVER (
            PARTITION BY o.restaurant_id 
            ORDER BY FORMAT(o.order_date, 'MM-yy')
        ) AS prev_order_count,
        SUM(o.total_amount) AS current_revenue,
        LAG(SUM(o.total_amount)) OVER (
            PARTITION BY o.restaurant_id 
            ORDER BY FORMAT(o.order_date, 'MM-yy')
        ) AS prev_revenue
    FROM orders o
    LEFT JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    WHERE o.order_status = 'Completed'
    GROUP BY o.restaurant_id, FORMAT(o.order_date, 'MM-yy')
)

SELECT 
    rmo.monthly,
    r.restaurant_name,
    rmo.current_revenue,
    rmo.prev_revenue,
    rmo.total_orders,
    rmo.prev_order_count,
    ROUND(
        CAST(rmo.total_orders - ISNULL(rmo.prev_order_count, 0) AS FLOAT) / 
        NULLIF(rmo.prev_order_count, 0) * 100, 
    2) AS growth_ratio
FROM restaurant_monthly_orders rmo
LEFT JOIN restaurants r ON rmo.rest_id = r.restaurant_id
ORDER BY rmo.rest_id, rmo.monthly;


--Query:Order Frequency by Day of Week: Identify Peak Day for Each Restaurant

WITH daily_order_counts AS (
    SELECT 
        r.restaurant_name,
        FORMAT(o.order_date, 'dddd') AS day_of_week,
        COUNT(o.order_id) AS total_orders,
        DENSE_RANK() OVER (
            PARTITION BY r.restaurant_name 
            ORDER BY COUNT(o.order_id) DESC
        ) AS peak_rank
    FROM orders o
    JOIN restaurants r ON o.restaurant_id = r.restaurant_id
    GROUP BY 
        r.restaurant_name,
        FORMAT(o.order_date, 'dddd')
)
SELECT 
    restaurant_name,
    day_of_week,
    total_orders
FROM daily_order_counts
WHERE peak_rank = 1
ORDER BY total_orders DESC;


--RIDER_PERFORMANCE

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


--ORDERS TRENDS
--Query: Most Popular 2-Hour Time Slots for Order Placements

SELECT 
    (DATEPART(HOUR, order_time) / 2) * 2 AS start_hour,
    (DATEPART(HOUR, order_time) / 2) * 2 + 2 AS end_hour,
    COUNT(*) AS total_orders
FROM orders
GROUP BY (DATEPART(HOUR, order_time) / 2) * 2
ORDER BY total_orders DESC;



--Query:Identifies demand spikes by season based on order item trends.

WITH seasonal_sales AS (
    SELECT 
        order_item,
        CASE 
            WHEN DATEPART(month, order_date) IN (12, 1, 2) THEN 'Winter'
            WHEN DATEPART(month, order_date) IN (3, 4) THEN 'Spring'
            WHEN DATEPART(month, order_date) BETWEEN 5 AND 7 THEN 'Summer'
            WHEN DATEPART(month, order_date) BETWEEN 8 AND 9 THEN 'Monsoon'
            WHEN DATEPART(month, order_date) BETWEEN 10 AND 11 THEN 'Autumn'
        END AS season
    FROM orders
)SELECT 
    order_item,
    COUNT(order_item) AS total_orders,
    season
FROM seasonal_sales
GROUP BY 
    order_item, 
    season
ORDER BY total_orders DESC;

-- query:Compares order volume on weekends vs weekdays by order date.

SELECT 
    order_date,
    COUNT(CASE WHEN day_type = 'Weekend' THEN order_id END) AS weekend_orders,
    COUNT(CASE WHEN day_type = 'Weekday' THEN order_id END) AS weekday_orders
FROM (
    SELECT 
        order_id,
        order_date,
        CASE 
            WHEN DATENAME(WEEKDAY, order_date) IN ('Saturday', 'Sunday') THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type
    FROM orders
) AS categorized_orders
GROUP BY order_date
ORDER BY order_date;
