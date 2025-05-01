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

--Query:Compare Order Cancellation Rates by Restaurant for 2023 vs 2024

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
