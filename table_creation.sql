--create database
create database zomato_db

---- Create customers table
if exists(select * from information_schema.tables where table_name='customers')
begin
     drop table customers
end
else
begin
    CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(25) NOT NULL,
    reg_date DATE
)
end

-- Create restaurants table

if exists(select * from information_schema.tables where table_name='restaurants')
begin
   drop table restaurants
end

else
begin
     CREATE TABLE restaurants (
    restaurant_id INT PRIMARY KEY,
    restaurant_name VARCHAR(60) NOT NULL,
    city VARCHAR(20),
    opening_hours VARCHAR(60))
end

-- Create Orders table
if exists(select * from information_schema.tables where table_name='orders')
begin
   drop table orders
end

else
begin
   CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    order_item VARCHAR(100),
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    order_status VARCHAR(60) DEFAULT 'Pending',
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
)
end

-- Create riders table
if exists(select * from information_schema.tables where table_name='riders')
begin
   drop table riders
end

else
begin
   CREATE TABLE riders (
    rider_id INT PRIMARY KEY,
    rider_name VARCHAR(60) NOT NULL,
    sign_up DATE
)
end

-- Create deliveries table
if exists(select * from information_schema.tables where table_name='deliveries')
begin
   drop table deliveries
end

else
begin
   CREATE TABLE deliveries (
    delivery_id INT PRIMARY KEY,
    order_id INT,
    delivery_status VARCHAR(20) DEFAULT 'Pending',
    delivery_time TIME,
    rider_id INT,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (rider_id) REFERENCES riders(rider_id)
)
end