
use classicmodels;
show tables;

-- 1.'customers table'
describe customers;

select * from customers;
-- Checking for the total number of Unique customers.
select count(distinct customerNumber) as total_customers from customers;

-- checking for null values 
select customerNumber from customers where customerNumber is null;

-- Cheking Duplicates 

select customerNumber , count(*) as Total_Duplicates from customers
group by customerNumber
having Total_Duplicates > 1 ;

-- Checking for customers who are not assigned to any company's sales representative.

select * from customers where salesRepEmployeeNumber is null;
-- Assume that 22 customers have not placed any orders. 
-- Let's check for confirmation.

select customerNumber from orders
where customerNumber in 
   ( select customerNumber from customers where salesRepEmployeeNumber is null );

-- 2.'employees table'
describe employees;
select * from employees;

-- Checking for the total number of Unique employees.
select count(distinct employeeNumber) as Total_Employees from employees;

-- cheking the null values
select employeeNumber from employees where employeeNumber is null;

-- Cheking the duplicates

select employeeNumber , count(*) as Total_Duplicates from employees
group by employeeNumber
having Total_Duplicates > 1 ;

-- Name of the President of the company
select concat(firstName,' ',lastName) as President_Name
,email from employees
where jobTitle = 'President';

-- 3 'offices Table'

describe offices;

select * from offices;

-- Checking for the total number of Unique Offices.
select count(distinct officeCode) as Total_Offices from offices;

-- Offices by Country
select country , count(officeCode) as Total_Offices from offices 
group by country
order by Total_Offices desc;

-- 4 'Orderdetails Table'
describe Orderdetails;

select * from Orderdetails;

-- Total Number of Orders Received
select count(distinct orderNumber) as Total_Orders from orders;


-- 5 'Orders Table'
describe orders;
select * from orders;

-- Total Orders by Year and Month
select  year(orderDate) as Year,
MONTH(orderDate) AS Month,
monthname(orderDate) as Month_Name,
count(orderNumber) as Total_orders,
sum( count(orderNumber) ) over ( partition by Year(orderDate) order by MONTH(orderDate) asc) as Sum_Of_Orders
from orders
group by Year,Month,Month_Name
order by Year,Month asc;

-- Total Shipped Orders
select status, count(orderNumber) as Total_Orders 
from orders 
where status = 'Shipped';

-- 6. 'Payments Table'

describe payments;

select * from payments;
-- Total Amount Recived 
select sum(amount) Total_Amount from payments;

-- Total Amount paid by Customers
select customerNumber, sum(amount) as Total_Payment
from payments group by customerNumber;

-- Total Amount Recived by Year 
select year(paymentDate) as Year,
sum(amount) as Total_Amount,
sum(sum(amount)) over( order by Year(paymentDate)) as Sum_Of_Amount
from payments
group by Year
order by Year;

-- Total Amount Recived by Year and Month
select year(paymentDate) as Year,
monthname(paymentDate) as Month_Name,
sum(amount) as Total_Amount
from payments
group by Year,month(paymentDate),Month_Name 
order by Year,month(paymentDate),Month_Name ;

-- 7. 'Productlines Table'
describe productlines;
select  * from productlines;

-- Total Productlines
select count(distinct productLine) as total_productLine from productLines;

-- 8. 'products Table'
describe products;
select * from products;

-- Total Products
select count(distinct productCode) as Total_Products from products;

-- Total Products By Product Line
select productLine, count(productCode)as Total_Products
from products
group by productLine;

-- Quantity in stocks by Productline
select productLine , sum(quantityInStock) as Quantity_In_Stock from
products group by productLine;

-- Total Vendors 
select count(distinct productVendor) as Total_Vendors from products;


-- -------------------------------------- - Data Insights with MySQL Queries -  -----------------------------------------------------


-- Show customers grouped by credit limit status, divided into three categories.and
-- show the count of the customers in each group

create view Customer_Credit_Status as 
(

select customerNumber,creditlimit,concat(contactFirstName,contactLastName) as Full_Name,
case 
	when creditLimit < 10000 then 'Low Credit Limit'
    when  creditLimit > 10000 and creditLimit < 75000 then 'Medium Credit Limit'
    when  creditLimit > 75000 then 'High Credit Limit'
    end as Customer_Credit_Status
from customers

);

select Customer_Credit_Status, count(customerNumber) as Total_Customers
from Customer_Credit_Status
group by Customer_Credit_Status
order by Total_Customers desc;

-- How many customers for each sales representative?

select e.employeeNumber,concat(firstName,' ',lastName) as Employee_Name,
count(c.customerNumber) as Total_Customers from employees e left join 
customers c on c.salesRepEmployeeNumber = e.employeeNumber
group by e.employeeNumber
order by Total_Customers desc;

-- Write a query to list the full name and job title of employees who are Presidents, VPs, or Managers,
-- along with the total number of employees that report to them.

select concat(e1.firstName,' ',e1.lastName) as Full_name, e1.jobTitle,
   (
	select count(*) from employees e2
    where e2.reportsTo = e1.employeeNumber 
    ) as Total_Employee
from employees e1
where jobTitle like 'President' or jobTitle like '%VP%' or jobTitle like '%Manager%' 
group by Full_name,jobTitle,Total_Employee; 


-- Write a query to list all the products purchased by "Thomas Smith"

select p.productName from products p 
inner join orderdetails od on p.productCode = od.productCode
inner join orders o on od.orderNumber = o.orderNumber
inner join customers c on c.customerNumber = o.customerNumber
where c.contactFirstName like  "Thomas%" and  c.contactLastName like 'smith%';


-- Write a query to pull the customers who bought the 2nd highest number of products.

select c.customerName, count(o.orderNumber) as Total_Orders from customers c inner join 
orders o on c.customerNumber = o.customerNumber
group by c.customerName
order by Total_Orders desc
limit 1,1;

-- Find the country with the highest number of customers.

select country , count(customerNumber) as total_customers
from customers 
group by country
order by total_customers desc
limit 1;


-- Write a query to find which product has highest number of Customers

select p.productName,count(o.customerNumber) as Total_Customers from products p
inner join orderdetails od on od.productCode = p.productCode
inner join orders o on o.orderNumber = od.orderNumber
group by p.productName
order by Total_Customers desc
limit 1;


-- Write a query to find for every year how many orders shipped 

select year(shippedDate) as Year , count(orderNumber) Total_orders
from orders
where status = 'Shipped'
group by Year
order by Year;

-- Write a query to find number of products ordered by each vendor

select p.productVendor, count(od.orderNumber) as Total_Orders from products p  
inner join orderdetails od on od.productCode = p.productCode
group by productVendor
order by Total_Orders desc;

--  Create a stored procedure that takes a customer's name as input and returns the total number of orders

delimiter $
create procedure Customer_Details(customer_name varchar(250)) 
begin
select o.customerNumber,c.customerName ,concat(e.firstName,' ',e.lastName) as Sales_Representative  ,
count(distinct o.orderNumber) as Total_Orders,
max(pd.productLine) as Product_Line
from customers c 
inner join orders o on o.customerNumber = c.customerNumber
inner join orderdetails od on od.orderNumber = o.orderNumber
inner join products pd on pd.productCode = od.productCode
inner join payments p on p.customerNumber = c.customerNumber
inner join employees e on e.employeeNumber = c.salesRepEmployeeNumber
where c.customerName = customer_name
group by o.customerNumber,c.customerName,Sales_Representative ,pd.productLine 
order by Total_Orders desc;
end $
delimiter ;

call Customer_Details('Euro+ Shopping Channel');

-- write a query to find product wise how much stock remained in the classsicmodels
with cte as ( 
select p.productcode,productname,quantityinstock,sum(quantityordered) QuantityOrdered
from products p join orderdetails od
on p.productcode=od.productcode
group by p.productcode,productname,quantityinstock
order by QuantityOrdered desc)

select productname, (quantityinstock - (quantityordered)) as Balance_Stock
from cte;

-- Write a query to find the product which is not ordered by any customer.

select * from products
where productCode not in (
select productCode from orderdetails );


-- create a store porocedure that will take Year as Input and then gives the
-- total orders by Year-> Month-> Quarter

delimiter $
create procedure Sales_by_Year(year_num int)
begin 
select year(orderDate) as Year ,
monthname(orderDate) as Month_Name,
quarter(orderDate) as Quarter,
count(orderNumber)as  Total_Orders ,
sum( count(orderNumber) ) over( partition by year(orderDate) order by month(orderDate) ) as Cumulative_Total_Orders
from orders
where year(orderDate) = year_num
group by Year,month(orderDate),Month_Name,Quarter 
order by Year,month(orderDate) ,Month_Name ,Quarter asc ;
end $
delimiter ;

call Sales_by_Year(2004);


-- create store procedure which takes Product Code name as input and 
-- gives the total orders -> Total Amount 

delimiter $
create procedure Order_By_Product_code(ProductCode varchar(20))
begin
select pd.productCode ,pd.productName, count(distinct od.orderNumber) as Total_Orders,
round( sum(od.quantityOrdered * od.priceEach) / 1000,2) as Total_Amount
from products pd 
inner join orderdetails od on pd.productCode = od.productCode
inner join orders o on o.orderNumber = od.orderNumber
where pd.productCode  = ProductCode
group by pd.productCode,pd.productName;
end $
delimiter ;

call Order_By_Product_code('S18_3232');


-- find each year detailed customer,product and price details of all orders

select od.ordernumber,o.Customernumber,Customername,country,
year(orderdate) year,count(productcode) Total_products,sum(quantityordered) Total_Quantity_of_Products,
sum(quantityordered*priceeach) Total_price
from orderdetails od join orders o
on od.ordernumber=o.ordernumber
join customers c on c.customernumber=o.customernumber
group by o.Customernumber,Customername,country,od.ordernumber
order by year asc,total_price desc;


-- Write to query to find the profit margin for each product


SELECT od.productCode,p.productName,sum(od.quantityOrdered) as Total_Quanitity_Orderd,
avg(p.buyPrice) as Avg_Buy_Pice,
avg(od.priceEach)as Avg_selling_price,
sum(quantityOrdered * priceEach ) as Total_sales,
sum(quantityOrdered * buyPrice) as Total_Cost,
( sum(quantityOrdered * priceEach ) - sum(quantityOrdered * buyPrice) ) as Total_Profit,
concat(round(( ( sum(quantityOrdered * priceEach ) - sum(quantityOrdered * buyPrice) ) / sum(quantityOrdered * priceEach )) * 100,2),' %') as Profit_Margin
FROM orderdetails od
inner join products p on od.productCode = p.productCode
group by od.productCode,p.productName
order by Profit_Margin desc;


-- Write to query to find the profit margin for each productline

select productLine ,
sum(quantityInStock) as Quantity_in_Stock,
sum(quantityOrdered) as Quantity_Orderd,
( (sum(quantityInStock)) - (sum(quantityOrdered)) ) as Quantity_in_Balace,
avg(buyPrice) avg_buy_price,
avg(priceEach) as avg_selling_price,
sum(quantityOrdered * priceEach ) as Total_Sales,
sum(quantityOrdered * buyPrice ) as Total_Cost,
( sum(quantityOrdered * priceEach ) - sum(quantityOrdered * buyPrice) )  as Total_Profit,
concat(round(( ( sum(quantityOrdered * priceEach ) - sum(quantityOrdered * buyPrice) ) / sum(quantityOrdered * priceEach )) * 100,2),' %') as Profit_Margin
from products p 
inner join orderdetails od on od.productCode = p.productCode
group by productLine 
order by Profit_Margin desc;


-- find status wise orders and thieir price

select status,
count(distinct od.orderNumber) as Total_Orders ,
sum(quantityOrdered) as Total_Units,
sum(priceEach*quantityOrdered) as Total_Proce
from orders o
inner join orderdetails od on od.orderNumber = o.orderNumber
group by status
order by Total_Orders desc;

-- Write a query to show the percetage of orders are shipped or cancelled
SELECT
    status,
concat( round( (COUNT( distinct orderNumber) * 100.0) / (SELECT COUNT(distinct orderNumber) FROM orders),2),' %')
 AS Percentage
FROM
    orders
GROUP BY
    status
order by  Percentage desc;


-- Create a stored procedure that takes a customer's name as input and returns the following information:
-- Customer Name
-- Sales Representative Number
-- Total Bill
-- Amount Paid by the Customer
-- Payment Status (Amount Paid or Pending)
-- Pending Amount
-- The procedure should provide details about the customer's financial transactions, 
-- including their payment status and pending amount."


