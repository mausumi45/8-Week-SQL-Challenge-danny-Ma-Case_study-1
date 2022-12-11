CREATE SCHEMA dannys_diner;
USE dannys_diner;


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
  
select * from sales;
select * from menu;
select * from members;
  
 -- 1. What is the total amount each customer spent at the restaurant? 
  SELECT S.customer_id,
		SUM(price) as total_amount
  FROM sales S inner join menu M
  ON S.product_id = M.product_id
  GROUP BY S.customer_id;
      
-- 2. How many days has each customer visited the restaurant?
    SELECT customer_id,
           COUNT(order_date) as number_of_days
    from sales
    GROUP BY customer_id;
     
-- 3. What was the first item from the menu purchased by each customer?
WITH first_item As
       (SELECT customer_id,order_date,M.product_name,Row_number() 
       over(partition by S.customer_id order by S.order_date asc) as occurance
        FROM Sales S inner join Menu M on S.product_id = M.product_id)
SELECT customer_id,product_name 
FROM first_item
WHERE occurance =1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name as Most_purchase_item,
       COUNT(S.product_id) as purchase_count
FROM  sales S inner join Menu M
ON S.product_id = M.product_id
GROUP BY product_name
ORDER BY Count(S.product_id) desc limit 1 ;

-- 5. Which item was the most popular for each customer?
WITH popular_item as(
     SELECT Customer_id,
            product_name,
            COUNT(S.product_id) as product_count,
            rank() over(partition by customer_id order by COUNT(s.product_id) desc) as occurance
	FROM sales S inner join menu M
    ON S.product_id = M.product_id
    GROUP BY Customer_id,product_name)
SELECT  Customer_id,
       product_name,
       occurance
FROM popular_item
WHERE occurance =1;

-- -- 6. Which item was purchased first by the customer after they became a member?
WITH CTE AS(
      SELECT M.customer_id,
             join_date,
             N.product_id,
             product_name,
             Dense_rank() Over(partition by M.customer_id order by order_date) as first_item
	FROM members M inner join sales S 
    ON M.customer_id = S.customer_id
    inner join menu N 
    ON S.product_id = N.product_id
    WHERE S.order_date >= join_date)
SELECT * 
FROM  CTE
WHERE first_item =1;

-- 7. Which item was purchased just before the customer became a member?
WITH CTE AS(
     SELECT M.customer_id,
            S.order_date,
            join_date,
            N.product_id,
            product_name,
            Dense_rank() Over(partition by M.customer_id order by order_date desc) as first_item
      FROM members M inner join sales S 
	  ON M.customer_id = S.customer_id
      inner join menu N 
      ON S.product_id = N.product_id
      WHERE S.order_date <join_date)
SELECT * 
FROM CTE
WHERE first_item =1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 
     S.customer_id,
     GROUP_CONCAT(distinct M.product_name) as total_item,
     SUM(M.price) as total_amount
FROM  menu M inner join  sales S
ON   S.product_id = M.product_id
inner join members N
ON S.customer_id = N.customer_id
WHERE S.order_date<join_date 
GROUP BY S.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select S.customer_id,
       SUM(CASE WHEN product_name = 'sushi' THEN price*20 ELSE price*10 END) as point_earned
FROM sales S inner join menu M
ON S.product_id = M.product_id
GROUP BY S.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?
WITH jan_point as (
         SELECT *,
         ADDDATE(join_date,7) as valid_date ,
         Last_day("2021-01-01") as lastday
         FROM members)
SELECT S.customer_id,
       SUM( CASE WHEN S.order_date between join_date and valid_date THEN price*20 END) as point_earned
FROM jan_point j inner join sales S
ON J.customer_id = S.customer_id
inner join menu M 
ON S.product_id = M.product_id
WHERE S.order_date<= lastday
GROUP BY S.customer_id;
