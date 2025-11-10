# UBS Scenario 2 - Portfolio Management - Wealth Management Client analytics
# Objective: analyzing client data for UBS Wealth Management to provide insights for relationship managers and portfolio strategists.
Tables: clients [client_id, full_name, country, city, risk_profile, client_tier, join_date]
		investment_accounts [account_id, client_id, account_type, base_currency, total_balance, opened_date, status]
		portfolio_holdings [holding_id, account_id, asset_name, asset_type,quantity,purchase_price,current_price,purchase_date]
		client_meetings [meeting_id,client_id,meeting_type, meeting_date, duration_minutes, rm_id, notes]


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

#Expected result:
account_id | full_name          | total_balance | status
-----------|-------------------|---------------|-------
201        | Dr. Michael Zhang  | 1250000       | Active
203        | Maria Rodriguez    | 2800000       | Active
205        | Sarah Chen         | 1650000       | Active
206        | Dr. Anna Kowalski  | 2200000       | Active

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

#Expected result:
ccount_id | full_name       | client_tier | holding_id | asset_name      | asset_type
-----------|----------------|-------------|------------|----------------|-----------
203        | Maria Rodriguez | Private     | 303        | Nestlé SA       | Equity
203        | Maria Rodriguez | Private     | 304        | Swiss Govt Bond | Fixed Income
206        | Dr. Anna Kowalski | Private   | 307        | Siemens AG      | Equity


#DATE FUNCTIONS
#3.👉 Calculate how many days each client has been with the bank (from join_date to today).
SELECT
client_id,
full_name,
DATEDIFF(CURDATE(),join_date) as Days_with_bank
FROM clients
ORDER BY client_id;

#Expected result:
client_id | full_name          | Days_with_bank
----------|-------------------|---------------
101       | Dr. Michael Zhang  | 435
102       | Maria Rodriguez    | 314
103       | Mr. James Wilson   | 385
104       | Sarah Chen         | 276
105       | Dr. Anna Kowalski  | 474
106       | Robert Kim         | 260


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

#Exoeted result:
full_name          | meeting_id | meeting_type    | meeting_date | duration_minutes | rm_id  | notes
-------------------|------------|----------------|-------------|-----------------|--------|----------------------
Dr. Michael Zhang  | 401        | Portfolio Review| 2024-06-15  | 60               | RM001  | Discussed rebalancing
Maria Rodriguez    | 402        | Strategy Session| 2024-06-18  | 90               | RM002  | Risk appetite confirmed
Mr. James Wilson   | 404        | Initial Planning| 2024-06-22  | 120              | RM003  | Investment plan created
Sarah Chen         | 405        | Portfolio Review| 2024-06-10  | 60               | RM002  | Added fixed income
Dr. Anna Kowalski  | 406        | Strategy Session| 2024-06-25  | 90               | RM001  | Exploring alternatives


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

#Expected resutlt:
full_name          | Title
-------------------|--------
Dr. Michael Zhang  | Dr.
Maria Rodriguez    | No title
Mr. James Wilson   | Mr
Sarah Chen         | No title
Dr. Anna Kowalski  | Dr.
Robert Kim         | No title


#6.String concatenation
#👉 Create a client summary showing "Client Name - City, Country" format for all clients.
SELECT
CONCAT(full_name, '-' ,city, ',' ,country) as client_summary
FROM clients
ORDER BY client_id ASC;

#Expected result:
client_summary
-----------------------------------
Dr. Michael Zhang-New York,USA
Maria Rodriguez-Zurich,Switzerland
Mr. James Wilson-London,UK
Sarah Chen-Singapore,Singapore
Dr. Anna Kowalski-Frankfurt,Germany
Robert Kim-San Francisco,USA


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

#Expected result:
country | premium_client_count
--------|---------------------
USA     | 2



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

#Expected result:
client_tier | total_balance_per_tier | average_balance_per_tier
-----------|-----------------------|------------------------
Premium    | 2900000               | 1450000
Private    | 5000000               | 2500000
Select     | 1030000               | 515000


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

#Expected result:
client_id | full_name          | total_portfolio_value
----------|-------------------|----------------------
101       | Dr. Michael Zhang  | 188500
102       | Maria Rodriguez    | 159000

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

#Expected result:
client_id | full_name          | risk_profile  | total_balance
----------|-------------------|-------------|---------------
102       | Maria Rodriguez    | Aggressive   | 2800000
105       | Dr. Anna Kowalski  | Aggressive   | 2200000
101       | Dr. Michael Zhang  | Conservative | 1600000



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

#Expected result:
client_id | full_name          | total_investment_value
----------|-------------------|-----------------------
102       | Maria Rodriguez    | 159000



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

#Expected result:
client_id | full_name          | asset_type  | percentage
----------|-------------------|------------|-----------
101       | Dr. Michael Zhang  | Equity      | 46.82
101       | Dr. Michael Zhang  | Fixed Income| 53.18
102       | Maria Rodriguez    | Equity      | 42.14
102       | Maria Rodriguez    | Fixed Income| 57.86



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

#Expected result:
client_id | full_name          | country     | total_balance | country_rank
----------|-------------------|-------------|---------------|-------------
101       | Dr. Michael Zhang  | USA         | 1600000       | 1
106       | Robert Kim         | USA         | 180000        | 2
102       | Maria Rodriguez    | Switzerland | 2800000       | 1
105       | Dr. Anna Kowalski  | Germany     | 2200000       | 1
104       | Sarah Chen         | Singapore   | 1650000       | 1
103       | Mr. James Wilson   | UK          | 850000        | 1


#14. Simple Running Total
#👉 Show a running total of account balances by opening date.
SELECT
account_id,
opened_date,
SUM(total_balance) OVER (ORDER BY opened_date ASC) as running_total
FROM investment_accounts;

#Expected result:
account_id | opened_date | running_total
-----------|-------------|--------------
201        | 2023-05-20  | 1250000
202        | 2023-05-25  | 1600000
206        | 2023-08-20  | 3800000
204        | 2023-11-15  | 4650000
203        | 2024-01-25  | 7450000
205        | 2024-03-05  | 9100000
207        | 2024-03-20  | 9280000


#15. Conditional Aggregation with CASE
#👉 Count how many clients have gains (current_value > purchase_value) vs losses by asset type.

SELECT
ph.asset_type,
CASE 
WHEN
(ph.purchase_price*ph.quantity) < (ph.current_price*ph.quantity) THEN 'gain'
WHEN (ph.purchase_price*ph.quantity) > (ph.current_price*ph.quantity) THEN 'loss'
ELSE 'equal'
END AS 'profit_analysis',
Count(DISTINCT a.client_id) as number_of_clients
FROM investment_accounts a
INNER JOIN portfolio_holdings ph
ON a.account_id = ph.account_id
GROUP BY ph.asset_type,
CASE 
WHEN
(ph.purchase_price*ph.quantity) < (ph.current_price*ph.quantity) THEN 'gain'
WHEN (ph.purchase_price*ph.quantity) > (ph.current_price*ph.quantity) THEN 'loss'
ELSE 'equal'
END;

asset_type  | profit_analysis | number_of_clients
------------|-----------------|------------------
Equity      | gain            | 4
Equity      | loss            | 1
Fixed Income| gain            | 2
REIT        | gain            | 1


#16. Date Difference Analysis
#👉 Find the average time between client join date and their first investment purchase.

WITH X as
(SELECT
c.client_id,
DATEDIFF(MIN(ph.purchase_date),c.join_date) as time_between_join_and_purchase
FROM clients c
INNER JOIN investment_accounts a
ON c.client_id=a.client_id
INNER JOIN portfolio_holdings ph
ON a.account_id=ph.account_id
GROUP BY c.client_id 
)
SELECT
AVG(time_between_join_and_purchase) as avg_time_between_join_and_purchase
FROM X;

avg_time_between_join_and_first_purchase
----------------------------------------
84.7

#17. Pattern Matching
#👉 Find all clients with email addresses (not in table - assume pattern: name with @domain) or specific naming patterns.

SELECT
full_name
FROM clients
WHERE full_name LIKE '%@%'
OR full_name LIKE '%@gmail.com%'
OR full_name LIKE '%@domain.com%'

full_name
-----------------

#18. NULL Handling
#👉 Show all clients and their meetings, including clients who have never had a meeting.

SELECT
c.client_id,
c.full_name,
COALESCE(cm.meeting_type, 'No meeting') as meeting_type
FROM clients c
LEFT JOIN client_meetings cm
ON c.client_id=cm.client_id;

client_id | full_name          | meeting_type
----------|-------------------|---------------
101       | Dr. Michael Zhang  | Portfolio Review
101       | Dr. Michael Zhang  | Quarterly Update
102       | Maria Rodriguez    | Strategy Session
103       | Mr. James Wilson   | Initial Planning
104       | Sarah Chen         | Portfolio Review
105       | Dr. Anna Kowalski  | Strategy Session
106       | Robert Kim         | No meeting


#19. Multiple Window Functions
#👉 For each client, show their balance and both the rank within their country and the percentage of total country balance.

WITH Y as
(SELECT
c.client_id as client_id,
c.full_name as client_name,
c.country as country,
SUM(a.total_balance) as total_balance
FROM clients c
INNER JOIN investment_accounts a
ON c.client_id=a.client_id
GROUP BY c.client_id, c.full_name, c.country
)
 
 SELECT client_id,
 client_name,
 country,
 total_balance,
 DENSE_RANK() OVER (PARTITION BY country ORDER BY total_balance DESC) as client_rank,
 total_balance * 100.00 / SUM(total_balance) OVER (PARTITION BY country) as percentage_of_country_balance
 FROM Y;

client_id | client_name       | country     | total_balance | client_rank | percentage_of_country_balance
----------|-------------------|-------------|---------------|-------------|------------------------------
101       | Dr. Michael Zhang | USA         | 1600000       | 1           | 89.89
106       | Robert Kim        | USA         | 180000        | 2           | 10.11
102       | Maria Rodriguez   | Switzerland | 2800000       | 1           | 100.00
105       | Dr. Anna Kowalski | Germany     | 2200000       | 1           | 100.00
104       | Sarah Chen        | Singapore   | 1650000       | 1           | 100.00
103       | Mr. James Wilson  | UK          | 850000        | 1           | 100.00

#20. Complex CASE Logic
#👉 Categorize clients as 'New' (<6 months), 'Established' (6-18 months), or 'Long-term' (>18 months) based on join date.

SELECT
client_id,
full_name,
join_date,
CASE WHEN TIMESTAMPDIFF(MONTH,join_date, CURDATE()) < 6 THEN 'NEW'
WHEN TIMESTAMPDIFF(MONTH,join_date, CURDATE()) BETWEEN 6 AND 18 THEN 'Established'
WHEN TIMESTAMPDIFF(MONTH,join_date, CURDATE()) > 18 THEN 'Long-term'
ELSE 'No date'
END as Client_Category
FROM clients
ORDER BY client_id;

client_id | full_name          | join_date   | Client_Category
----------|-------------------|-------------|---------------
101       | Dr. Michael Zhang  | 2023-05-15  | Long-term
102       | Maria Rodriguez    | 2024-01-20  | Established
103       | Mr. James Wilson   | 2023-11-10  | Long-term
104       | Sarah Chen         | 2024-02-28  | Established
105       | Dr. Anna Kowalski  | 2023-08-12  | Long-term
106       | Robert Kim         | 2024-03-15  | New















