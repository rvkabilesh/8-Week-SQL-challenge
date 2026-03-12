#CREATE SCHEMA pizza_runner;
use pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  ---------------------------------
  show tables;
  ---------------------------------
  update customer_orders 
  set exclusions = null
  where exclusions = '';
  
  update customer_orders
  set extras = null
  where extras = '';
  
update runner_orders set 
pickup_time = nullif(pickup_time,'null'),
distance = nullif(distance,'null'),
duration = nullif(duration,'null'),
cancellation = NULLIF(NULLIF(cancellation, ''), 'null');

select * from runner_orders;
---------------------------------------------
-- A. Pizza Metrics
-- How many pizzas were ordered?
select count(*) total_orders from customer_orders;

-- How many unique customer orders were made?
select count(distinct customer_id) unique_cus_orders from customer_orders;

-- How many successful orders were delivered by each runner?
select runner_id,count(*) success_cnt from runner_orders
where cancellation is NULL
group by runner_id;

-- How many of each type of pizza was delivered?
select pizza_name,count(*) delivered from customer_orders join runner_orders using(order_id) join pizza_names using(pizza_id)
where cancellation is null
group by pizza_name;

-- How many Vegetarian and Meatlovers were ordered by each customer?
select pizza_name,count(*) delivered from customer_orders join runner_orders using(order_id) join pizza_names using(pizza_id)
where pizza_name in ('Meatlovers','Vegetarian')
group by pizza_name;

-- What was the maximum number of pizzas delivered in a single order?
select order_id,count(*) del from customer_orders join runner_orders using(order_id)
where cancellation is null
group by order_id
order by del desc
limit 1;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
    customer_id,
    COUNT(CASE
        WHEN exclusions IS NOT NULL OR extras IS NOT NULL THEN 1
    END) AS changes,
    COUNT(CASE
        WHEN exclusions IS NULL AND extras IS NULL THEN 0
    END) AS no_change
FROM
    customer_orders
        JOIN
    runner_orders USING (order_id)
WHERE
    cancellation IS NULL
GROUP BY customer_id;

-- How many pizzas were delivered that had both exclusions and extras?
SELECT 
    count(*)
FROM
    customer_orders
        JOIN
    runner_orders USING (order_id)
WHERE
    exclusions IS NOT NULL AND extras IS NOT NULL and cancellation is null;

-- What was the total volume of pizzas ordered for each hour of the day?
select time_format(order_time,'%H:00:00') hr,count(*) cnt from customer_orders
group by hr
order by hr;

-- What was the volume of orders for each day of the week?
select dayname(order_time) week_,count(*) cnt from customer_orders
group by week_;
-------------------------------------------------------------------------------------------
-- B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
select * from runners;
select week(registration_date) week,count(*) from runners
group by week;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select avg(timestampdiff(minute, order_time, pickup_time)) as pickup from customer_orders join runner_orders using(order_id);

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT 
    COUNT(*) no_of_pizza,
    TIMESTAMPDIFF(MINUTE,
        order_time,
        pickup_time) time_diff_in_min
FROM
    customer_orders
        JOIN
    runner_orders USING (order_id)
GROUP BY order_id , order_time , pickup_time
order by no_of_pizza desc, time_diff_in_min desc;
----------------------------------------------------
update runner_orders
set duration = replace(replace(replace(trim(duration), 'minutes',''),'mins',''),'minute','');

update runner_orders
set distance = replace(distance,'km','');

alter table runner_orders
modify duration int,
modify distance decimal(10,2);
-------------------------------------------------------------------
-- What was the average distance travelled for each customer?
select customer_id,round(avg(distance),2) dis
FROM
    customer_orders
        JOIN
    runner_orders USING (order_id)
group by customer_id
order by dis desc;

-- What was the difference between the longest and shortest delivery times for all orders?
select max(duration) - min(duration) from runner_orders;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
select order_id,runner_id,distance,duration,round(avg(distance / (duration/60) ),2) speed from runner_orders
where cancellation is null
group by order_id,runner_id,distance,duration
order by duration desc,speed desc;

-- What is the successful delivery percentage for each runner?
with cte as(
select runner_id,sum(cancellation is null) success,sum(cancellation is not null) failed from runner_orders 
group by runner_id)

select runner_id,round((success/(success+failed))*100,1) success_rate from cte;
--------------------------------------------------------------------------------------------------------
drop table if exists pizza_recipes;
CREATE TABLE pizza_recipes (
    pizza_id INT,
    toppings INT
);
INSERT INTO pizza_recipes (pizza_id, toppings) VALUES
(1, 1),
(1, 2),
(1, 3),
(1, 4),
(1, 5),
(1, 6),
(1, 8),
(1, 10),
(2, 4),
(2, 6),
(2, 7),
(2, 9),
(2, 11),
(2, 12);
------------------------------------------------------------------------
-- C. Ingredient Optimisation
-- What are the standard ingredients for each pizza?
select topping_name from pizza_recipes pr join pizza_toppings pt on pt.topping_id = pr.toppings
group by topping_id,topping_name
having count(topping_id) > 1;
-- What was the most commonly added extra?
select topping_name,count(*) cnt from customer_orders co join pizza_toppings pt on co.extras = pt.topping_id
where extras is not null
group by extras,topping_name
order by cnt desc
limit 1;
-- What was the most common exclusion?
select topping_name,count(*) cnt from customer_orders co join pizza_toppings pt on co.exclusions = pt.topping_id
where exclusions is not null
group by exclusions,topping_name
order by cnt desc
limit 1;
-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
SELECT 
    co.*,pizza_name
FROM
    customer_orders co
        left JOIN
    pizza_names USING (pizza_id)
       left JOIN
    pizza_toppings exc ON co.exclusions = exc.topping_id
       left JOIN
    pizza_toppings ext ON co.extras = ext.topping_id;
    
-- Meat Lovers - Exclude Beef
SELECT 
    co.*,concat(pizza_name," - Exclude ",exc.topping_name) exclude
FROM
    customer_orders co
        left JOIN
    pizza_names USING (pizza_id)
       left JOIN
    pizza_toppings exc ON co.exclusions = exc.topping_id
       left JOIN
    pizza_toppings ext ON co.extras = ext.topping_id;
-- Meat Lovers - Extra Bacon
SELECT 
    co.*,concat(pizza_name," - Extra ",ext.topping_name) extra
FROM
    customer_orders co
        left JOIN
    pizza_names USING (pizza_id)
       left JOIN
    pizza_toppings exc ON co.exclusions = exc.topping_id
       left JOIN
    pizza_toppings ext ON co.extras = ext.topping_id;
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT 
    co.*,concat(pizza_name," - Exclude ",exc.topping_name," - Extra ",ext.topping_name) pizz_ext_exc
FROM
    customer_orders co
        left JOIN
    pizza_names USING (pizza_id)
       left JOIN
    pizza_toppings exc ON co.exclusions = exc.topping_id
       left JOIN
    pizza_toppings ext ON co.extras = ext.topping_id;
-- Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
with cte as (
SELECT 
     order_id, customer_id, pizza_name, exc.topping_name exc,ext.topping_name ext,order_time, res.topping_name recipe
FROM
    customer_orders co
        LEFT JOIN
    pizza_names USING (pizza_id)
        LEFT JOIN
    pizza_toppings exc ON co.exclusions = exc.topping_id
        LEFT JOIN
    pizza_toppings ext ON co.extras = ext.topping_id
        LEFT JOIN
    pizza_recipes USING (pizza_id)
        JOIN
    pizza_toppings res ON toppings = res.topping_id
    ),p1 as (
    select order_id, customer_id, pizza_name, exc,ext, order_time, recipe
    from cte
    union all
    select order_id, customer_id, pizza_name, exc,ext, order_time, ext from cte
    where ext is not null
    group by order_id, customer_id, pizza_name, exc,ext, order_time, ext
    )
    select order_id, customer_id, pizza_name, exc,ext, order_time, group_concat(recipe) from p1
    group by order_id, customer_id, pizza_name, exc,ext, order_time;

-- What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
select topping_name,count(topping_name) cnt from customer_orders join pizza_recipes using(pizza_id) join pizza_toppings on toppings = topping_id
group by topping_name
order by cnt desc;
---------------------------------------------------------------------------------------------------------------
-- D. Pricing and Ratings
-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
with cte as (
select *,
case 
when pizza_id = 1 then 12 
when pizza_id = 2 then 10 
end price
from customer_orders join pizza_names using(pizza_id))
select pizza_name,sum(price) price_$ from cte
group by pizza_name; 
-- What if there was an additional $1 charge for any pizza extras?
-- Add cheese is $1 extra
with cte as (
select *,
case 
when pizza_id = 1 then 12 
when pizza_id = 2 then 10 
end price
from customer_orders join pizza_names using(pizza_id)
)
select *,case when extras is not null then price+1 end price_w_extras
from cte;
-- The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
drop table if exists runner_rating;
create table runner_rating (
runner_id int references runners(runner_id) ,
order_id int references customer_orders(order_id),
rating int);
-- Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
-- customer_id
-- order_id
-- runner_id
-- rating
-- order_time
-- pickup_time
-- Time between order and pickup
-- Delivery duration
-- Average speed
-- Total number of pizzas
use pizza_runner;
show tables;
SELECT 
    customer_id,
    order_id,
    rr.runner_id,
    rating,
    order_time,
    pickup_time,
    TIMEDIFF(pickup_time, order_time) Time_between_order_and_pickup,
    duration Delivery_duration,
    ROUND(distance / (duration / 60)) Average_speed,
    COUNT(*) Total_number_of_pizzas
FROM
    customer_orders
        LEFT JOIN
    runner_orders ro USING (order_id)
        left JOIN
    runner_rating rr USING (order_id)
GROUP BY customer_id , order_id , rr.runner_id , rating , order_time , pickup_time , Time_between_order_and_pickup , Delivery_duration , Average_speed;
-- If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
with cte as (
select *,
case 
when pizza_id = 1 then 12 
when pizza_id = 2 then 10 
end price
from customer_orders join pizza_names using(pizza_id)), tot_amt as (
select sum(price) tot_amt from cte), tvl_amt as (
select sum(distance*0.3) tvl_amt  from runner_orders)
select tot_amt - tvl_amt profit from tot_amt join tvl_amt;

