CREATE SCHEMA dannys_diner;
use dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  show tables;
  
  select * from sales;
  select * from menu;
  select * from members;
  ---------------------------------------------------------------------------------------------------------------
  -- 1. What is the total amount each customer spent at the restaurant?
  select s.customer_id,sum(price) from sales s join menu m using(product_id)
  group by s.customer_id;
  
  -- 2. How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?
select customer_id,product_name from
(select *,row_number() over( partition by customer_id order by order_date) req
from sales s inner join menu m using (product_id)) tab where req = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name,count(*) cnt from sales s inner join menu m using(product_id) 
group by product_name
order by cnt desc
limit 1;

-- 5. Which item was the most popular for each customer?

with product_sales as
(select customer_id,product_name, rank() over(partition by customer_id order by count(*) desc) rn from sales s join menu m using(product_id)
group by customer_id,product_name
order by customer_id)  
select customer_id,product_name from product_sales 
where rn =1;

-- 6. Which item was purchased first by the customer after they became a member?
with product_sales_member as 
(select *,rank() over(partition by customer_id order by order_date) rnk from members mb join sales s using (customer_id) join menu mn using(product_id)
where order_date > join_date)

select customer_id,product_name from product_sales_member
where rnk = 1;

select * from members join sales on join_date < order_date;

#waq to print no of orders after becoming member

-- 7. Which item was purchased just before the customer became a member?
with product_sales_member as 
(select *,rank() over(partition by customer_id order by order_date desc) rnk from members mb join sales s using (customer_id) join menu mn using(product_id)
where order_date < join_date)

select customer_id,product_name from product_sales_member
where rnk = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
with product_sales_member as 
(select * from members mb right join sales s using (customer_id) join menu mn using(product_id)
where order_date < join_date or join_date is null)

select customer_id,count(product_name),sum(PRICE) from product_sales_member
group by customer_id
order by customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with CTE as 
(SELECT 
    customer_id,product_name,SUM(price),
    CASE
        WHEN product_name = 'sushi' THEN SUM(price) * 10 * 2
        ELSE SUM(price) * 10
    END AS points
FROM
    sales s
        JOIN
    menu m 
USING (product_id)
GROUP BY customer_id , product_name)

select customer_id,sum(points) from cte
group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT 
    customer_id,
    SUM(CASE
        WHEN product_name = 'sushi' THEN (price) * 10 * 2
        WHEN order_date BETWEEN join_date AND DATE_ADD(join_date, INTERVAL 6 DAY) THEN price * 10 * 2
        ELSE (price) * 10
    END) AS points
FROM
    sales s
        JOIN
    menu m USING (product_id)
        JOIN
    members USING (customer_id)
WHERE
    order_date < '2021-02-01'
GROUP BY customer_id
ORDER BY customer_id;

