-- Sales Data Exploration with SQL
-- By Olamide Emida, Google Certified Data Analyst
-- US regional sales data was gotten from kaggle. The data contains 6 tables: customer, location, product, region, sales order,
-- and sales team. 

use `portfolio-projects`; -- To use the database portfolio-projects

-- Retrieve all rows in the sales order table to identify all columns 
SELECT 
    *
FROM
    `sales order`;

-- Total Number of transactions made
SELECT 
    COUNT(OrderNumber) AS no_of_transactions
FROM
    `sales order`;

-- Total quantity of products purchased
SELECT 
    SUM(`Order Quantity`)
FROM
    `sales order`;

-- Add a new column, TotalRevenue
alter table `sales order`
add TotalRevenue float;

-- Add a new column, TotalCost
alter table `sales order`
add TotalCost float;

-- Add a new column, Profit
alter table `sales order`
add Profit float;

-- Populate the new TotalRevenue column
UPDATE `sales order` 
SET 
    TotalRevenue = `Unit Price` * `Order Quantity`;

-- Populate the new TotalCost column
UPDATE `sales order` 
SET 
    TotalCost = `Unit Cost` * `Order Quantity`;

-- Populate the new Profit column
UPDATE `sales order` 
SET 
    Profit = TotalRevenue - TotalCost;

-- Total Revenue and Total Profit from all transactions
SELECT 
    ROUND(SUM(TotalRevenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit
FROM
    `sales order`;

-- Distinct order dates in the sales order table. The transactions are from 2018 to 2020.
SELECT 
    COUNT(DISTINCT OrderDate) AS no_of_order_days
FROM
    `sales order`;

-- Total number of transactions made, total quantity of products ordered, total revenue and total profit per each order date
SELECT 
    OrderDate,
    COUNT(OrderDate) AS no_of_transactions,
    `Order Quantity`,
    TotalRevenue,
    Profit
FROM
    `sales order`
GROUP BY OrderDate
ORDER BY Profit DESC;

-- Total Transactions per sales channel
SELECT 
    `Sales Channel`, 
    COUNT(OrderNumber) AS no_of_transactions
FROM
    `sales order`
GROUP BY 1;

-- Retrieve all rows in the customer table to identify all columns 
SELECT 
    *
FROM
    customer;

-- Rename the customer id name in customer table
alter table customer
rename column _CustomerID to CustomerID;

-- Total number of customers
SELECT 
    COUNT(CustomerID) AS no_of_customers
FROM
    customer;

-- Retrieve all rows in the sales team table to identify all columns 
SELECT 
    *
FROM
    `sales-team`;

-- Rename a sales team id name in sales team table
alter table `sales-team`
rename column _SalesTeamID to SalesTeamID;

-- Total number of sales teams
SELECT 
    COUNT(SalesTeamID) AS no_of_SalesTeam
FROM
    `sales-team`;

-- Total number of transactions for each customer
SELECT 
    c.`Customer Names`,
    COUNT(s.OrderNumber) AS no_of_transactions
FROM
    customer c
        JOIN
    `sales order` s ON c.CustomerID = s._CustomerID
GROUP BY 1
ORDER BY 2 DESC;

-- Retrieve all rows in the location table to identify all columns 
SELECT 
    *
FROM
    location;

-- Total number of stores
SELECT 
    COUNT(DISTINCT _StoreID)
FROM
    location;

-- Retrieve all rows in the region table to identify all columns 
SELECT 
    *
FROM
    region;

-- Total number of stores in each region
SELECT 
    r.Region, 
    COUNT(l._StoreID) AS no_of_stores
FROM
    region r
        JOIN
    location l ON r.StateCode = l.StateCode
GROUP BY 1
ORDER BY 2 DESC;

-- Total number of states in each region
SELECT 
    Region, 
    COUNT(State) AS no_of_state
FROM
    region
GROUP BY 1
ORDER BY 2 DESC , 1;

-- Total number of transactions by location types
SELECT 
    l.Type, 
    COUNT(s.OrderNumber) AS no_of_transactions
FROM
    location l
        JOIN
    `sales order` s ON l._StoreID = s._StoreID
GROUP BY 1
ORDER BY 2 DESC;

-- Total Revenue and Profit in each region
SELECT 
    r.Region,
    ROUND(SUM(total_revenue), 2) AS Total_Revenue,
    ROUND(SUM(total_profit), 2) AS Total_Profit
FROM
    region r
        JOIN
    (SELECT 
        StateCode,
            SUM(TotalRevenue) AS total_revenue,
            SUM(Profit) AS total_profit
    FROM
        location l
    JOIN `sales order` s ON l._StoreID = s._StoreID
    GROUP BY 1) s2
WHERE
    r.StateCode = s2.StateCode
GROUP BY region
ORDER BY 2 DESC;

-- Change the data type of the order date column from text to date
UPDATE `sales order` 
SET 
    OrderDate = STR_TO_DATE(OrderDate, '%d/%m/%Y');

-- Change the data type of the delivery date column from text to date
UPDATE `sales order` 
SET 
    DeliveryDate = STR_TO_DATE(DeliveryDate, '%d/%m/%Y');

-- The date difference between the order date and delivery date
SELECT 
    OrderDate,
    DeliveryDate,
    DATEDIFF(DeliveryDate, OrderDate) AS date_difference
FROM
    `Sales order`
ORDER BY date_difference;

-- The maximum, the average and the minimum days between the order date and delivery date
SELECT 
    MAX(date_difference) AS max_delivery_days,
    ROUND(AVG(date_difference)) AS avg_delivery_days,
    MIN(date_difference) AS min_delivery_days
FROM
    (SELECT 
        OrderDate,
            DeliveryDate,
            DATEDIFF(DeliveryDate, OrderDate) AS date_difference
    FROM
        `Sales order`
    ORDER BY date_difference) d;

-- Performance of each sales team based on total transactions, total quantity sold and total revenue
SELECT 
    `Sales Team`,
    COUNT(OrderNumber) AS no_of_transactions,
    SUM(`Order Quantity`) AS quantity_sold,
    ROUND(SUM(TotalRevenue), 2) AS total_revenue,
    (SELECT 
            ROUND(SUM(TotalRevenue), 2)
        FROM
            `sales order`) all_revenue,
    ROUND(SUM(TotalRevenue) / (SELECT 
                    SUM(TotalRevenue)
                FROM
                    `sales order`) * 100,
            2) AS revenue_percent
FROM
    `sales-team` st
        JOIN
    `sales order` s ON st.SalesTeamID = s._SalesTeamID
GROUP BY 1
ORDER BY total_revenue DESC;

-- Retrieve all rows in the product table to identify all columns 
SELECT 
    *
FROM
    product;

-- Total number of different products offered for sale
SELECT 
    COUNT(_ProductID)
FROM
    product;

-- Most expensive products ordered by customers
SELECT 
    p.`Product Name`, 
    s.`Unit Price`
FROM
    product p
        JOIN
    `sales order` s ON p._ProductID = s._ProductID
ORDER BY 2 DESC
LIMIT 10;

-- Least expensive products ordered by customers
SELECT 
    p.`Product Name`, 
    s.`Unit Price`
FROM
    product p
        JOIN
    `sales order` s ON p._ProductID = s._ProductID
ORDER BY 2
LIMIT 10;

-- Stored Procedure to view the sales of any sales team by just calling their names
DELIMITER $$
create procedure sales_details (IN sales_team varchar(50))
BEGIN
SELECT 
    `Sales Team`,
    `Sales Channel`,
    `Product Name`,
    OrderDate,
    DeliveryDate,
    TotalRevenue,
    TotalCost,
    Profit
FROM
    `sales-team` st
        JOIN
    `sales order` s ON st.SalesTeamID = s._SalesTeamID
        JOIN
    product USING (_ProductID)
WHERE
    `Sales Team` = sales_team;
END $$
DELIMITER ;

-- View Adam Hernandez sales transactions
CALL sales_details("Adam Hernandez");