-- 1.What is the total amount each customer spent at the restaurant?
-- Her müşterinin restoranda harcadığı toplam tutar nedir?

select
	customer_id,
	sum(price)
from sales as t1
left join menu as t2 on t1.product_id=t2.product_id 
group by 1

-- 2.How many days has each customer visited the restaurant?
-- Her müşteri restoranı kaç gün ziyaret etti?
	
select
	t2.customer_id,
	count(distinct order_date) as toplam_ziyaret
from members as t1
right join sales as t2 on t1.customer_id=t2.customer_id
group by 1

-- 3.What was the first item from the menu purchased by each customer?
-- Her müşterinin satın aldığı menüden ilk ürün neydi?
with siparis as (
select
	customer_id,
	order_date,
	product_name,
	row_number()over (partition by customer_id order by order_date),
	rank() over(partition by customer_id order by order_date) as rn,-- bu örnekte rank ile sıralamamız gerekiyor.
	dense_rank() over(partition by customer_id order by order_date)	
from sales as t1
join menu as t2 on t1.product_id=t2.product_id
)
	select 
		customer_id,
		order_date,
		product_name
	from siparis
	where rn=1

-- 4.What is the most purchased item on the menu and how many times was it purchased by all customers?
-- Menüde en çok satın alınan ürün hangisidir ve tüm müşteriler tarafından kaç kez satın alınmıştır?

select
	product_name,
	count(t1.product_id)
from sales as t1 
join menu as t2 on t2.product_id= t1.product_id 
group by 1
order by 2 desc
limit 1

-- 5.Which item was the most popular for each customer?
-- Her müşteri için en popüler ürün hangisiydi?

with tablo as (
select
	customer_id,
	product_name,
	count(order_date),
	rank() over(partition by customer_id order by count(order_date) desc)
from sales as t1 
join menu as t2 on t2.product_id= t1.product_id 
group by 1,2
)
	select
		customer_id,
		product_name
	from tablo
	where rank=1
-- 6.Which item was purchased first by the customer after they became a member?
-- Müşteri üye olduktan sonra ilk olarak hangi ürünü satın aldı?
	
with raw_data as(
select
	t1.customer_id,
	join_date,
	order_date,
	product_name,
	rank() over(partition by t1.customer_id order by order_date) as rn
from members as t1
join sales as t2 on t1.customer_id=t2.customer_id
join menu as t3 on t2.product_id=t3.product_id
where order_date>=join_date 
)
	select
		customer_id,
		product_name
	from raw_data
	where rn=1

-- 7.Which item was purchased just before the customer became a member?
-- Müşteri üye olmadan hemen önce hangi ürün satın alındı?
with raw_data as(
select
	t1.customer_id,
	join_date,
	order_date,
	product_name,
	rank() over(partition by t1.customer_id order by order_date desc) as rn
from members as t1
join sales as t2 on t1.customer_id=t2.customer_id
join menu as t3 on t2.product_id=t3.product_id
where order_date<join_date 
)
select
	customer_id,
	product_name
from raw_data 
where rn=1

-- 8.What is the total items and amount spent for each member before they became a member?
-- Her üyenin üye olmadan önce harcadığı toplam kalem ve tutar nedir?

with raw_data as(
select
	t1.customer_id,
	join_date,
	order_date,
	product_name,
	price
from members as t1
join sales as t2 on t1.customer_id=t2.customer_id
join menu as t3 on t2.product_id=t3.product_id
where order_date<join_date 
)
	select
		customer_id,
		count(*) as total_amount,
		sum(price)
	from raw_data
	group by 1
	
-- 9.If each $1 spent equates to 10 points and sushi has a 2x points multiplier 
-- 	- how many points would each customer have?
-- Harcanan her 1 dolar 10 puana eşitse ve suşi 2 kat puan çarpanına sahipse, her müşterinin kaç puanı olur?
with raw_data as(
select
	t2.customer_id,
	product_name,
	price
from members as t1
right join sales as t2 on t1.customer_id=t2.customer_id
join menu as t3 on t2.product_id=t3.product_id
)
	select 
    customer_id, 
    sum(case 
            when product_name = 'sushi' then price * 10 * 2  -- Suşi için 2 kat puan
            else price * 10                        -- Diğer ürünler için normal puan
        end) as total_point
from raw_data
group by 1;

-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- 	- how many points do customer A and B have at the end of January?
-- Bir müşteri programa katıldıktan sonraki ilk haftada (katılma tarihi dahil) yalnızca suşide değil, tüm yiyeceklerde 2 kat puan kazanır 
-- 	- A ve B müşterisi Ocak ayının sonunda kaç puana sahip olur?
with raw_data as(
select
	t1.customer_id,
	join_date,
	order_date,
	product_name,
	price
from members as t1
join sales as t2 on t1.customer_id=t2.customer_id
join menu as t3 on t2.product_id=t3.product_id
where order_date >= join_date  -- Sipariş tarihi üye olma tarihinden sonra
	AND order_date < join_date + INTERVAL '7 days' -- İlk haftaya kadar
)
select 
    customer_id, 
    sum(price *2*10) as total_point
from raw_data
group by 1;
