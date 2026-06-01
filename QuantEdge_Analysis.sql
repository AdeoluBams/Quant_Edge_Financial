
SELECT * 
FROM public."Quant_Financial"

--- PROFITABILITY ANALYTICS  

-- Average Profit/loss by country
SELECT
	country,
	ROUND(
	AVG(profit_loss),2) AS avg_profitloss
FROM public."Quant_Financial"
GROUP BY country
ORDER BY avg_profitloss DESC;

-- Total Portolio size
SELECT
	SUM(portfolio_value) AS portfolio_size
FROM public."Quant_Financial";

-- Total Profit Made by traders
SELECT
	SUM(profit_loss) AS total_profit
FROM public."Quant_Financial";

-- Total Profit Made by the Platfrom (fees based)
SELECT
	SUM(platform_fee) AS total_fee
FROM public."Quant_Financial";

-- Risk profile relationship with profitability
SELECT
	risk_profile,
	SUM(profit_loss) AS total_profit
FROM public."Quant_Financial"	         -- High Risk traders made the most
GROUP BY risk_profile
ORDER BY total_profit DESC;

-- Leverage Relationship with profitability
WITH profit_loss_an AS(
	SELECT
		leverage_used,
		SUM(profit_loss) AS total_profit
	FROM public."Quant_Financial"
	WHERE leverage_used BETWEEN 1 AND 50
	GROUP BY leverage_used
),
leverage_classification AS(
	SELECT
		*,
		CASE
			WHEN leverage_used BETWEEN 1 AND 15 THEN 'Low Leverage'
			WHEN leverage_used BETWEEN 16 AND 30 THEN 'Mid Leverage'
			WHEN leverage_used BETWEEN 31 AND 50   THEN 'High Leverage'
			ELSE 'No leverage_class'
		END AS leverage_group
	FROM profit_loss_an
)
SELECT
	leverage_group,
	SUM(total_profit) AS total_profit_
FROM leverage_classification 
GROUP BY leverage_group
ORDER BY total_profit_;


--Most traded assets class
SELECT 
	asset_class,
	COUNT(trade_id) AS total_trade
FROM public."Quant_Financial"			-- Stocks is the most traded asset class   
GROUP BY asset_class
ORDER BY total_trade DESC;

-- Profit_loss by asset class
WITH total_profits AS(
	SELECT
		SUM(profit_loss) AS total_profit
	FROM public."Quant_Financial"
)										-- Crypto traders were the most profitable
SELECT									-- Made 96% of the total profit
	a.asset_class,
	SUM(a.profit_loss) AS assets_total_profit,
	ROUND(
		(SUM(a.profit_loss)*100.0/ t.total_profit)
			,2)AS assets_total_profit_pct
FROM public."Quant_Financial" a
CROSS JOIN total_profits t				
GROUP BY a.asset_class, t.total_profit
ORDER BY assets_total_profit_pct DESC;
----- THE ANALYSIS ABOVE SHOWS WHY THERE ARE DECLINING ACTIVE TRADERS


-- CUSTOMER  ANALYTICS 

-- 	NO of Inactive customers
SELECT 
	COUNT(customer_status)
FROM public."Quant_Financial"
WHERE customer_status = 'Inactive'

-- TOP 5 trader with the most trades in the past 30 days
SELECT
	customer_id,
	SUM(trades_last_30_days) AS trades_last_30_days_
FROM public."Quant_Financial"
GROUP BY customer_id
ORDER BY trades_last_30_days_ DESC
LIMIT 5;

-- What type of traders are the most inactive
SELECT
	asset_class,
	COUNT(customer_status) AS No_of_inactive_users
FROM public."Quant_Financial"
WHERE customer_status = 'Inactive'
GROUP BY asset_class
ORDER BY No_of_inactive_users DESC;

-- Age group with the most trades
WITH age_group_revenue AS(
	SELECT
		age,
		COUNT(trade_id) AS total_trades
	FROM public."Quant_Financial"
	GROUP BY age
),
age_classification AS(
	SELECT
		*,
		CASE
			WHEN age BETWEEN 1 AND  25 THEN 'Young Adults'
			WHEN age BETWEEN 26 AND 50 THEN 'Middle_Aged Adults'
			WHEN AGE >= 51 THEN 'Older Adults'
		END AS age_group
	FROM age_group_revenue
)												-- Middle_Aged Adult traded the most  
SELECT 
	age_group,
	SUM(total_trades) AS total_trades
FROM age_classification
GROUP BY age_group
ORDER BY total_trades DESC;

-- Which account types hold the highest portfolio value
SELECT
	account_type,
	SUM(portfolio_value) AS portfolio_size
FROM public."Quant_Financial"
GROUP BY account_type
ORDER BY portfolio_size DESC;

-- Customer Segment and their profitability
SELECT
	customer_segment,
	SUM(profit_loss) AS total_profit
FROM public."Quant_Financial"				-- Retail traders made the most profit	
GROUP BY customer_segment
ORDER BY total_profit DESC;

-- Distribution of customers by risk profiles
SELECT
	risk_profile,
	COUNT(DISTINCT customer_id) AS total_customers
FROM public."Quant_Financial"	         -- There are more low risk takers 
GROUP BY risk_profile					-- even though the number is relatively close
ORDER BY total_customers DESC;

-- Platform with the highest customer engagement(Desktop etc)
SELECT
	platform_used,
	COUNT(platform_used) AS engagement_count  
FROM public."Quant_Financial"						-- Web version is the most used
GROUP BY platform_used
ORDER BY engagement_count DESC;

-- customer segment with the highest trading volume
WITH volume_size AS(
	SELECT
		SUM(quantity) AS trade_volume
	FROM public."Quant_Financial"	
)									-- Retail traders traded 69% of the total volume
SELECT
	c.customer_segment,
	ROUND(
		SUM(quantity) * 100.0 / v.trade_volume
			,2) AS trade_volume_perc
FROM public."Quant_Financial" c
CROSS JOIN volume_size v
GROUP BY c.customer_segment, v.trade_volume
ORDER BY trade_volume_perc DESC






--- RISK MANAGEMENT
-- Account types and associated risk behaviour
SELECT
	account_type,
	risk_profile,
	COUNT(risk_profile) AS risk_profile_count
FROM public."Quant_Financial"	
GROUP BY account_type, risk_profile
ORDER BY account_type ASC, risk_profile_count DESC;

-- Countries with the highest Margin call rate

WITH m_call_count AS (
	SELECT 
		COUNT(margin_call_flag) AS margin_call_count
	FROM public."Quant_Financial"
	WHERE margin_call_flag = 'Yes'
),													-- Nigeria topped with 28%
country_margin_call_rate AS(
	SELECT
		c.country,
		ROUND(
		(COUNT(c.margin_call_flag)* 100.0 / m.margin_call_count)
			,2)AS margin_call_rate
	FROM Public."Quant_Financial" c
	CROSS JOIN m_call_count m
	WHERE c.margin_call_flag = 'Yes'
	GROUP BY c.country, m.margin_call_count
)
SELECT
	country,
	margin_call_rate
FROM country_margin_call_rate
GROUP BY country, margin_call_rate
ORDER BY margin_call_rate DESC;

-- Percentage of traders that uses excessive leverage
WITH total_traders AS(
	SELECT
		COUNT(DISTINCT customer_id) AS traders_count
	FROM Public."Quant_Financial"
)
SELECT
	ROUND(
		(COUNT(DISTINCT c.customer_id) * 100.0/ t.traders_count)
			,2) AS traders_perc
FROM Public."Quant_Financial" c				-- 29% of the traders use excessive leverage
CROSS JOIN total_traders t
WHERE leverage_used >= 35 
GROUP BY t.traders_count;

-- Leverage correlation with margin_call 
WITH leverage_classification AS(
	SELECT
		CASE
			WHEN leverage_used BETWEEN 1 AND 15 THEN 'Low Leverage'
			WHEN leverage_used BETWEEN 16 AND 30 THEN 'Mid Leverage'
			WHEN leverage_used BETWEEN 31 AND 50   THEN 'High Leverage'
			ELSE 'No leverage_class'
		END AS leverage_group
	FROM public."Quant_Financial"
),
margin_call AS(
	SELECT 
		l.leverage_group,
		COUNT(m.margin_call_flag) AS margin_call_count
	FROM public."Quant_Financial" m
	CROSS JOIN leverage_classification l
	WHERE margin_call_flag = 'Yes'
	GROUP BY l.leverage_group
)
SELECT 
	leverage_group,
	margin_call_count
FROM margin_call 
GROUP BY leverage_group, margin_call_count;

-- Asset class with the most margin call risk
SELECT
	asset_class,
	COUNT(margin_call_flag) AS margin_call			
FROM public."Quant_Financial"					-- Asset_class has the most margin call risk
WHERE margin_call_flag = 'Yes'
GROUP BY asset_class
ORDER BY margin_call DESC;


--- FRAUD ANALYTICS

-- Percentage of Account with suspicious activity
WITH no_of_account AS (
	SELECT
		COUNT(DISTINCT account_id) AS total_accounts
	FROM public."Quant_Financial"
)												-- 50% was suspected for suspicious activity
SELECT
	ROUND(
	COUNT(DISTINCT a.account_id) * 100.0/ n.total_accounts
	,2) AS perc_with_sus_activity
FROM public."Quant_Financial" a
CROSS JOIN no_of_account n
WHERE suspicious_activity_flag = 'Yes'
GROUP BY n.total_accounts

-- ip region with the highest suspicious activity rate
WITH no_of_account AS (
	SELECT
		COUNT(DISTINCT account_id) AS total_accounts
	FROM public."Quant_Financial"
)												
SELECT
	a.ip_region,
	ROUND(
	COUNT(DISTINCT a.account_id) * 100.0/ n.total_accounts
	,2) AS perc_with_sus_activity
FROM public."Quant_Financial" a
CROSS JOIN no_of_account n    					-- Europe had the most suspicious activity rate
WHERE suspicious_activity_flag = 'Yes'
GROUP BY a.ip_region, n.total_accounts
ORDER BY perc_with_sus_activity DESC;

-- platform with the highest risk of suspicious login
WITH no_of_account AS (
	SELECT
		COUNT(DISTINCT account_id) AS total_accounts
	FROM public."Quant_Financial"
)											-- They all have a close risk profile									
SELECT
	p.platform_used,
	ROUND(
	COUNT(DISTINCT p.account_id) * 100.0/ n.total_accounts
	,2) AS perc_with_sus_activity
FROM public."Quant_Financial" p
CROSS JOIN no_of_account n    					
WHERE suspicious_activity_flag = 'Yes'
GROUP BY p.platform_used, n.total_accounts
ORDER BY perc_with_sus_activity DESC;


