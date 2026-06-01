# Quant_Edge_Financial

## Project Overview
This is an end-to-end analysis for "Quant_Edge" A Financial & Digital trading platform, that offers stodk trading, porfolio analytics and investment insights. This project features the following analysis.
- Profitability Analysis
- Customer Analysis
- Trading Performanca Analysis
- Risk Management Analysis
- Customer retention Analysis

## Table of Contents
- [Data Sources](#data_sources)
- [Tools](#tools)
- [Data Cleaning](#data-cleaning)
- [Query Highlight](#query-highlight)
- [Findings](#findings)
- [References](#references)

## Data Sources
Quant_Edge_Data: The primary dataset used for this analysis is the "financial_trading_data.csv" file, containing detailed finacial information of the platform.

## Tools
- Excel - Data Cleaning
  - [Download Here](https://www.microsoft.com)
- PostgreSQL - Data Analysis
  - [Download Here](https://www.postgresql.org/download)
- PowerBi - Insight Report
  - [Download Here](https://www.microsoft.com/en-us/download/details.aspx?id=58494&msockid=2fafce07f9f165923597d8d4f8e36471)

## Data Cleaning
- Data loading and preparation
- Columns Standardisation ('M' to 'Male' etc)
- Date Transformation (yyyy-MM-dd)
- Handling Null values
- Columns Formatting
- Data Grain_level Identification 

## Query Highlight
```sql
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
```
```sql
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
```
```sql
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
```
```sql
-- platform with the highest risk of suspicious login
WITH no_of_account AS (
	SELECT
		COUNT(DISTINCT account_id) AS total_accounts
	FROM public."Quant_Financial"
)											-- They all have a close risk profile									
SELECT
	p.platform_used,
	ROUND(
	COUNT(DISTINCT p.account_id) * 100.0/ n.total_accounts ,2) AS perc_with_sus_activity
FROM public."Quant_Financial" p
CROSS JOIN no_of_account n    					
WHERE suspicious_activity_flag = 'Yes'
GROUP BY p.platform_used, n.total_accounts
ORDER BY perc_with_sus_activity DESC;

```
## Findings
- Total Portfolio size is $ 17,872,749,535.27
- Total profit made by the platfrom (fees based) is $ 362,982,620.87
- Total profit made by trader $ 1,384,492,456.04
- Crypto traders were the most profitable, contributing 96% to the total profits.They made $ 1,341,629,569.10
- Stocks is the most traded class, it was traded 6291 times.
- Risk profile analysis shows that High Risk traders are the most profitable
-  Middle_Aged Adults (age 26 - 50) are the most active on the platform 
-  [Download Full Report]()
  
## References
[Stack Overflow](https://stackoverflow.com/)


