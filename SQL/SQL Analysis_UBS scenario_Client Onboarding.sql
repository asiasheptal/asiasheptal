#SQL analysis scenarios
#Scenario 1 - Client Onboarding Efficiency

#Task 1 - Find all clients onboarded in July 2025 with risk_level = 'High'
SELECT
client_id
, full_name
FROM clients
where onboard_date BETWEEN '2025-07-01' AND '2025-07-01'
and risk_level = 'High';

--//--

SELECT
client_id
, full_name
FROM clients
EXTRACT(YEAR_MONTH from onboard_date) = 202507
and risk_level = 'High';

#Task 2.Joins
#👉 Show a list of clients with their account types and balances, including those who don’t have an account yet.

SELECT
Client_ID
,full_name
,account_type
,balance
FROM clients c
LEFT JOIN accounts a
ON c.client_id = a.client_id
ORDER BY c.client_id, a.account_id;


#Task 3 . Aggregate Functions
# 👉 Count how many clients were onboarded per country, and calculate the average balance per country.
SELECT
country
, count(Distinct c.full_name) as client_count
, avg(a.balance) as avg_balance
FROM clients c
LEFT JOIN accounts a
ON c.client_id=a.client_id
Group by c.country;

#Task 4. Subqueries / CTEs
#👉 Find clients whose total balance is above the average balance of all clients

WITH total_balance as
(SELECT client_ID,
sum(balance) as t_balance
from accounts
Group by client_id
),
average_balance as
(SELECT
avg(t_balance) as avg_balance
from accounts
)

SELECT
distinct c.Client_ID
, c.full_name
, tb.t_balance
, ab.avg_balance

FROM clients c
LEFT JOIN total_balance tb on tb.client_id=c.client_id
CROSS JOIN average_balance ab

WHERE tb.t_balance > ab.avg_balance

--//--

WITH client_balances AS (
    SELECT 
        client_id,
        SUM(balance) as total_balance
    FROM accounts
    GROUP BY client_id
)
SELECT 
    c.client_id,
    c.full_name,
    cb.total_balance,
    (SELECT AVG(total_balance) FROM client_balances) as avg_balance
FROM clients c
JOIN client_balances cb ON c.client_id = cb.client_id
WHERE cb.total_balance > (SELECT AVG(total_balance) FROM client_balances);


#Task 5. Case and Conditional logic.
#👉 Create a field called kyc_delay_category that shows:

#•	'Fast' if approval was within 2 days,
#•	'Medium' if 3–5 days,
#•	'Slow' if more than 5 days,
#•	'Pending' if not yet approved.

SELECT
client_id,
submitted_date,
approved_date, 
status,
CASE 
when status = 'aproved' and DATEDIFF(approved_date, submitted_date)<= 2 then 'Fast'
when status = 'aproved' and DATEDIFF(approved_date, submitted_date) BETWEEN 3 and 5 then 'Medium'
when status = 'aproved' and DATEDIFF(approved_date, submitted_date) > 5 then 'Slow'
else 'Pending'
end as kyc_delay_category
FROM kyc_checks;


#Task 6.String Functions
#👉 Extract the last name of each client from full_name.

SELECT
full_name,
substring_index(full_name,' ',-1) as last_name
FROM clients;


#7.	Date Functions
#👉 Calculate the number of days taken to onboard each client (approved_date - submitted_date).


select
client_id,
submitted_date,
approved_date,
DATEDIFF(approved_date,submitted_date) as days_of_onboarding
from kyc_checks;


#8.	Window Functions
#👉 Rank clients by balance within each country.


SELECT
c.client_id,
c.full_name,
c.country,
COALESCE(SUM(a.balance),0) as total_balance,
DENSE_RANK() OVER (PARTITION BY c.country ORDER BY COALESCE(SUM(a.balance),0) DESC) as Rank_per_country
FROM clients c
LEFT JOIN accounts a
ON c.client_id=a.client_ID
GROUP by c.client_id, c.full_name, c.country
ORDER BY c.country, Rank_per_country;



















