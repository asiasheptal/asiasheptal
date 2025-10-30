# UBS Scenario 2 - Portfolio Management - Wealth Management Client analytics
# Objective: analyzing client data for UBS Wealth Management to provide insights for relationship managers and portfolio strategists.
"Tables: clients [client_id, full_name, country, city, risk_profile, client_tier, join_date]
		investment_accounts [account_id, client_id, account_type, base_currency, total_balance, opened_date, status]
		portfolio_holdings [holding_id, account_id, asset_name, asset_type,quantity,purchase_price,current_price,purchase_date]
		client_meetings [meeting_id,client_id,meeting_type, meeting_date, duration_minutes, rm_id, notes]"


#JOINS & FILTERING
#1.👉 Find all active trading accounts with balances over $1,000,000, showing client names and account details
SELECT
a.account_id,
c.full_name,
a.total_balance,
a.status
FROM clients c
INNER JOIN investment_accounts a
	ON c.client_id = a.client_id
WHERE a.account_type = 'Trading'
	AND a.total_balance > 1000000
	AND a.status='Active';

#2.👉 Show all portfolio holdings for clients in the 'Private' tier, including client names and asset details.
SELECT
a.account_id,
c.full_name,
c.client_tier,
p.holding_id,
p.asset_name,
p.asset_type
FROM clients c
INNER JOIN investment_accounts a
	ON c.client_id = a.client_id
INNER JOIN portfolio_holdings p
	ON a.account_id=p.account_id
WHERE c.client_tier = 'Private'
ORDER BY a.account_id, c.full_name ASC;


#DATE FUNCTIONS
#3.👉 Calculate how many days each client has been with the bank (from join_date to today).
SELECT
client_id,
full_name,
DATEDIFF(CURDATE(),join_date) as Days_with_bank
FROM clients
ORDER BY client_id;

#4.👉 Find all client meetings that occurred in June 2024, showing client names and meeting details.
SELECT
c.full_name,
cm.meeting_id,
cm.meeting_type,
cm.meeting_date,
cm.duration_minutes,
cm.rm_id,
cm.notes
FROM clients c
INNER JOIN client_meetings cm
ON c.client_id = cm.client_id
WHERE MONTH(cm.meeting_date)=6 and YEAR(cm.meeting_date)=2024
ORDER BY cm.meeting_date DESC;


#STRING FUNCTIONS
#5. String manipulation
#👉 Extract the title (Dr., Mr., etc.) from full_name for clients who have one. If no title, show 'No Title'.
SELECT
full_name,
CASE 
	WHEN full_name LIKE 'Dr.%' THEN 'Dr.'
	WHEN full_name LIKE 'Mr.%' THEN 'Mr'
	WHEN full_name LIKE 'Ms.%' THEN 'Ms.'
	WHEN full_name LIKE 'Mrs.%' THEN 'Mrs.'
		ELSE 'No title'
			END as Title
FROM clients;

#6.String concatenation
#👉 Create a client summary showing "Client Name - City, Country" format for all clients.
SELECT
CONCAT(full_name, '-' ,city, ',' ,country) as client_summary
FROM clients
ORDER BY client_id ASC;


#AGGREGATE FUNCTIONS
#7.GROUP BY with HAVING
#👉 Find countries with more than 1 Premium tier client.
SELECT
country,
count(client_id) as premium_client_count
from clients
where client_tier = 'Premium'
Group by country
having count(client_id) > 1;

#8. Multiple Aggregates
#👉 Calculate the total balance and average balance by client tier.
SELECT
c.client_tier,
SUM(a.total_balance) as total_balance_per_tier,
AVG(a.total_balance) as average_balance_per_tier
FROM clients c
INNER JOIN investment_accounts a
ON c.client_id=a.client_id
GROUP BY client_tier;


#SUBQUERIES
#9.Basic Subquery
#👉 Find clients who have a total portfolio value greater than the average client portfolio value.

SELECT
c.client_id,
c.full_name,
SUM(p.quantity * p.current_price) as total_portfolio_value
FROM clients c
INNER JOIN investment_accounts a
ON c.client_id=a.client_id
INNER JOIN portfolio_holdings p
on a.account_id=p.account_id
GROUP BY
c.client_id, c.full_name
Having SUM(p.quantity * p.current_price) > 
(SELECT AVG(total_portfolio_value) FROM (SELECT SUM(p.quantity * p.current_price) as total_portfolio_value 
	FROM portfolio_holdings
	GROUP BY account_id) accounts_total
);

#10.Correlated Subquery
#👉 Find clients who have above-average balances for their respective risk profiles.

SELECT
c.client_id,
c.full_name,
c.risk_profile,
SUM(a.total_balance) as balance_per_risk_profile
FROM clients c
INNER JOIN investment_accounts a
ON c.client_id=a.client_id
GROUP BY c.client_id,c.full_name,c.risk_profile
Having SUM(a.total_balance) > 
(SELECT AVG(balance_per_risk_profile) FROM 
	(SELECT
c2.client_id,
c2.full_name,
c2.risk_profile,
SUM(a2.total_balance) as balance_per_risk_profile
FROM clients c2
INNER JOIN investment_accounts a2
ON c2.client_id=a2.client_id
WHERE c.risk_profile = c2.risk_profile
GROUP BY c2.client_id,c2.full_name,c2.risk_profile) totals_per_risk_profile
);

--//--//

SELECT
    c.client_id,
    c.full_name,
    c.risk_profile,
    SUM(a.total_balance) as total_balance
FROM clients c
INNER JOIN investment_accounts a ON c.client_id = a.client_id
GROUP BY c.client_id, c.full_name, c.risk_profile
HAVING SUM(a.total_balance) > (
    SELECT AVG(SUM(a2.total_balance))
    FROM clients c2 
    INNER JOIN investment_accounts a2 ON c2.client_id = a2.client_id
    WHERE c2.risk_profile = c.risk_profile
    GROUP BY c2.client_id
);


#CTEs
#11. Simple CTE
#👉 Using a CTE, calculate each client's total investment value and show clients with over $2,000,000.

WITH investment_value as
(SELECT
account_id,
SUM(quantity * current_price) as total_investment_value
FROM portfolio_holdings
Group by account_id
)
SELECT
c.client_id,
c.full_name,
iv.total_investment_value
FROM clients c
INNER JOIN investment_accounts a 
ON c.client_id = a.client_id
INNER JOIN investment_value iv
on a.account_id=iv.account_id
WHERE iv.total_investment_value > 2000000;

--//--//

SELECT
    c.client_id,
    c.full_name,
    SUM(p.quantity * p.current_price) as total_investment_value
FROM clients c
INNER JOIN investment_accounts a ON c.client_id = a.client_id
INNER JOIN portfolio_holdings p ON a.account_id = p.account_id
GROUP BY c.client_id, c.full_name
HAVING SUM(p.quantity * p.current_price) > 2000000;

#12. Multiple CTEs
#👉 Calculate each asset type's percentage of total portfolio for each client.

with total_portfolio as
(SELECT
account_id,
SUM(quantity * current_price) as total_balance_per_account
FROM portfolio_holdings p
Group by account_id
),
balance_per_asset as
(SELECT
account_id,
asset_type,
SUM(quantity * current_price) as total_balance_per_asset
FROM portfolio_holdings p
Group by account_id, asset_type
)
SELECT
c.client_id,
c.full_name,
ab.asset_type,
ROUND((total_balance_per_asset * 100.0 / total_balance_per_account),2) as percentage
FROM clients c
INNER JOIN investment_accounts a ON c.client_id=a.client_id
INNER JOIN total_portfolio tp ON a.account_id=tp.account_id
INNER JOIN balance_per_asset ab ON a.account_id=ab.account_id;


#WINDOW FUNCTIONS
#13.ROW_NUMBER for Ranking
#👉 Rank clients by total balance within each country.
SELECT
c.client_id,
c.full_name,
c.country,
SUM(a.total_balance) as total_balance,
DENSE_RANK() OVER (PARTITION BY c.country ORDER BY SUM(a.total_balance) DESC) as country_rank
FROM clients c
INNER JOIN investment_accounts a
ON c.client_id=a.client_id
GROUP BY c.client_id, c.full_name, c.country;

#14. Simple Running Total
#👉 Show a running total of account balances by opening date.
SELECT
account_id,
opened_date,
SUM(total_balance) OVER (ORDER BY opened_date ASC) as running_total
FROM investment_accounts;
