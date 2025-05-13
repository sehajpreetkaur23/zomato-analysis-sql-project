# zomato-analysis-sql-project

PROJECT OVERVIEW

This project dives into the backend data of a Zomato-like food delivery platform to derive actionable business insights using advanced SQL techniques. The analysis spans across customers, orders, deliveries, riders, and restaurants to uncover behavior patterns, optimize operations, and support strategic decisions.



OBJECTIVES

Understand Customer Behavior: Analyze patterns, churn, segmentation, and preferences.

Order and Sales Performance: Explore ordering habits, peak times, and sales trends.

Restaurant Metrics: Rank restaurants, compare cancellation rates, and track growth.

Rider Efficiency: Measure delivery performance, time, and earnings.



Key Business Questions Answered

Who are the top customers and what dishes do they prefer?

Which restaurants generate the most revenue? How are they ranked city-wise?

How can we segment customers into Gold and Silver tiers?

When do users place the most orders (time slots, days, seasons)?

What are the most popular dishes per city?

Which riders are the most efficient and what are their monthly earnings?

Are there seasonal or weekend spikes in customer behavior?

What is the delivery performance and cancellation rate across years?



KEY BUSINESS INSIGHTS

1. Peak Ordering Hours
Most orders are placed between 14:00–16:00, 18:00–20:00, and 22:00–00:00.


2. High-Value Customers
Customers like Sneha Desai (807 orders, ₹333.58 AOV) are high-LTV users.


3. Orders Without Delivery
Mumbai tops with non-deliveries; Gajalee and Mahesh Lunch Home are major contributors.


4. Top Restaurants by Revenue
Britannia & Co. (Mumbai) leads with rupees 118106.


5. Most Popular Dishes by City
Paneer Butter Masala and Chicken Biryani dominate across major cities.


6. Churned Customers
Identified 9 customers active in 2023 but not in 2024.


7. Cancellation Rates (2023 vs 2024)
Perch Wine & Coffee Bar leads in 2023 cancellations (6.67%).


8. Monthly Restaurant Growth
Growth spikes in March and July, but declines in June and December.


9. Customer Segmentation
Gold customers (fewer in number) contribute a much higher revenue share.


10. Rider Monthly Earnings
Highest monthly earnings is of rider_id 1  with rupees 2262.16 in the month of jan 2023

11. Rider Ratings
Based on delivery times: <15 min (5), 15–20 min (4), >20 min (3).

Riders #9 and #14 have most 5-star deliveries.

12. Order Frequency by Day
Britannia & Co. peaks on Saturdays; Ziya and Indigo on Sundays.


13. Delivery Efficiency
Riders #7and #8 are fastest (~32 min); Riders #1 and #2 slowest (~51 min).


14. Seasonal Dish Popularity
Pasta Alfredo and Masala Dosa dominate seasonally; Chicken Biryani performs year-round.


15. City-wise Revenue Rank
Mumbai leads with ₹1.52M, followed by Bengaluru and Delhi.



DATA CLEANING CHECKS

Ensured NULL values were addressed before analysis:

-- Customers
SELECT COUNT(*) FROM customers WHERE customer_name IS NULL OR reg_date IS NULL;

-- Restaurants
SELECT COUNT(*) FROM restaurants WHERE restaurant_name IS NULL OR city IS NULL;

-- Orders
SELECT * FROM orders WHERE order_item IS NULL OR order_date IS NULL OR total_amount IS NULL;




PROJECT STRUCTURE 

Food-Delivery-SQL-Project
<br>
├── table_creation.sql            
<br>
├── data_analysis.sql          
<br>
├── customer_analysis.sql       
<br>
├── restaurant_performance.sql    
<br>
├── rider_performance.sql        
<br>
├── orders_trends.sql        





TECH STACK

Database: SQL Server

Language: SQL (T-SQL)

Tools: Power BI 


CONCLUSION

This project demonstrates expertise in SQL for solving real-world business problems in the food delivery domain. It showcases advanced querying techniques, structured problem-solving, and the ability to extract actionable insights from transactional data.


