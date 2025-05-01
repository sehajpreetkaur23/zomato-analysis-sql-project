
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

-- Query: Top 3 Most Ordered Dishes by Top 5 Customers (Past 2 Years)

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