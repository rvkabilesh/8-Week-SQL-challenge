/*1. Data Cleansing Steps
In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:

Convert the week_date to a DATE format

Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc

Add a month_number with the calendar month for each week_date value as the 3rd column

Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values

Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

segment	age_band
1	Young Adults
2	Middle Aged
3 or 4	Retirees
Add a new demographic column using the following mapping for the first letter in the segment values:
segment	demographic
C	Couples
F	Families
Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns

Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record*/

select * from weekly_sales;
DROP TABLE IF EXISTS clean_weekly_sales;
create table clean_weekly_sales as
select str_to_date(week_date, '%d/%m/%y') as week_date,
week(str_to_date(week_date, '%d/%m/%y'),3) as week_number,
month(str_to_date(week_date, '%d/%m/%y')) as month_number,
year(str_to_date(week_date, '%d/%m/%y')) as calendar_year,
region, platform,
COALESCE(NULLIF(segment,'null'),'unknown') AS segment,
case when segment like '%1' then 'Young Adults' 
when segment like '%2' then 'Middle Aged'
when segment like '%3' or segment like '%4' then 'Retirees'
else 'unknown'
end as age_band,
case when segment like 'C%' then 'Couples'
when segment like 'F%' then 'Families'
else 'unknown'
end as demographic,
customer_type,
transactions,
sales,
round(sales / transactions,2) as avg_transaction
from weekly_sales;

select distinct * from clean_weekly_sales;

-- 2. Data Exploration
-- What day of the week is used for each week_date value?
select dayname(week_date) dow from clean_weekly_sales
group by dow;
-- What range of week numbers are missing from the dataset?
WITH RECURSIVE weeks AS (
    SELECT 1 AS week_number
    UNION ALL
    SELECT week_number + 1
    FROM weeks
    WHERE week_number < 52
)
SELECT week_number
FROM weeks
WHERE week_number NOT IN (
    SELECT DISTINCT week_number
    FROM clean_weekly_sales
);
-- How many total transactions were there for each year in the dataset?
select calendar_year,sum(transactions) from clean_weekly_sales
group by calendar_year;
-- What is the total sales for each region for each month?
select region,monthname(week_date) month_name,sum(sales) sales from clean_weekly_sales
group by region,monthname(week_date),month_number
order by month_number;
-- What is the total count of transactions for each platform
select platform,count(transactions) from clean_weekly_sales
group by platform;
-- What is the percentage of sales for Retail vs Shopify for each month?
SELECT 
    month_number,
    platform,
    ROUND(
        SUM(sales) * 100 /
        SUM(SUM(sales)) OVER (PARTITION BY month_number),
        2
    ) AS percentage_sales
FROM clean_weekly_sales
GROUP BY month_number, platform
ORDER BY month_number, platform;
-- What is the percentage of sales by demographic for each year in the dataset?
select calendar_year,demographic,round(sum(sales)*100/sum(sum(sales)) over(partition by calendar_year),2) percentage_sales from clean_weekly_sales
group by calendar_year,demographic
order by calendar_year,demographic;
-- Which age_band and demographic values contribute the most to Retail sales?
select age_band,demographic,sum(sales) sales1 from clean_weekly_sales
where platform = 'Retail'
group by age_band,demographic
order by sales1 desc;
-- Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
select calendar_year,platform, avg(sales)  from clean_weekly_sales
group by calendar_year,platform;
----------------------------------------------------------------------------------------------
-- 3. Before & After Analysis
-- This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.
-- Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.
-- We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

-- Using this analysis approach - answer the following questions:
-- What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
with w4_bef as (select sum(sales) bef_amt from clean_weekly_sales
WHERE week_date BETWEEN subdate('2020-06-15',interval 28 day)  AND subdate('2020-06-15',interval 1 day)),
w4_aft as (select sum(sales) aft_amt from clean_weekly_sales
WHERE week_date BETWEEN '2020-06-15' AND adddate('2020-06-15',interval 27 day))
select aft_amt,bef_amt,aft_amt - bef_amt diff,(aft_amt - bef_amt)*100/bef_amt change_rate from w4_bef join w4_aft;

-- What about the entire 12 weeks before and after?
with w4_bef as (select sum(sales) bef_amt from clean_weekly_sales
WHERE week_date BETWEEN subdate('2020-06-15',interval 84 day)  AND subdate('2020-06-15',interval 1 day)),
w4_aft as (select sum(sales) aft_amt from clean_weekly_sales
WHERE week_date BETWEEN '2020-06-15' AND adddate('2020-06-15',interval 83 day))
select aft_amt,bef_amt,aft_amt - bef_amt diff,(aft_amt - bef_amt)*100/bef_amt change_rate from w4_bef join w4_aft;

-- How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
with w_num as (select distinct week_number wn from clean_weekly_sales where week_date = '2020-06-15'),
bef as (
select calendar_year,sum(sales) bef1 from clean_weekly_sales 
where week_number > (select wn from w_num) -5 and 
week_number < (select wn from w_num) 
group by calendar_year
),
aft as (
select calendar_year,sum(sales) aft1 from clean_weekly_sales 
where week_number >= (select wn from w_num) and 
week_number < (select wn from w_num) + 4
group by calendar_year
)
select bef.calendar_year,aft1 - bef1 diff, aft1,bef1,(aft1 - bef1)*100/bef1 change_rate from bef join aft using(calendar_year);
------------------------------------------------------------------------------------------------------------------------------
-- 4. Bonus Question
-- Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
create view w_num as (select distinct week_number wn from clean_weekly_sales where week_date = '2020-06-15');
create view aft_12 as (
select * from clean_weekly_sales
where week_number < (select * from w_num) + 12 and week_number >= (select * from w_num)
);
create view bef_12 as (
select * from clean_weekly_sales
where week_number < (select * from w_num) and week_number >= (select * from w_num) - 12
);
-- region
with reg_b_12 as (select region,sum(sales) b_12s from bef_12 group by region
),
reg_a_12 as (select region, sum(sales) a_12s from aft_12 group by region
)
select b.region,a_12s - b_12s diff from reg_b_12 b join reg_a_12 using(region) order by diff;

-- platform
with p_b12 as (select platform,sum(sales) b12s from bef_12 group by platform),
p_a12 as (select platform,sum(sales) a12s from aft_12 group by platform)
select b.platform, a12s - b12s diff from p_b12 b join p_a12 using(platform) order by diff;

-- age_band
with ab_a12 as (select age_band,sum(sales) a12s from aft_12 group by age_band),
ab_b12 as (select age_band,sum(Sales) b12s from bef_12 group by age_band)
select b.age_band, a12s-b12s diff from ab_a12 join ab_b12 b using(age_band) order by diff;

-- demographic
with d_a12 as (select demographic,sum(sales) a12s from aft_12 group by demographic),
d_b12 as (select demographic,sum(sales) b12s from bef_12 group by demographic)
select b.demographic, a12s - b12s diff from d_a12 join d_b12 b using(demographic) order by diff;

-- customer_type
with c_a12 as (select customer_type,sum(sales) a12s from aft_12 group by customer_type),
c_b12 as (select customer_type,sum(sales) b12s from bef_12 group by customer_type)
select b.customer_type, a12s - b12s diff from c_a12 join c_b12 b using(customer_type) order by diff;
