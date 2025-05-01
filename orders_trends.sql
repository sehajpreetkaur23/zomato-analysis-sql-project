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
