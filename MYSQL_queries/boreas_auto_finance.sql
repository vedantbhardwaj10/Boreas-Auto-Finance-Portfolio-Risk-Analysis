CREATE DATABASE automotive_loans;
USE automotive_loans;

-- Verifying rows count post - ingestion.

SELECT COUNT(*) AS total_records FROM contracts;
SELECT COUNT(*) AS total_records FROM repayment;
SELECT COUNT(*) AS total_records FROM branches;
SELECT COUNT(*) AS total_records FROM brokers;
SELECT COUNT(*) AS total_records FROM dealers;
SELECT COUNT(*) AS total_records FROM executives;

-- Establishing relationship between tables.

ALTER TABLE contracts ADD CONSTRAINT pk_contracts PRIMARY KEY(loan_id);
ALTER TABLE branches ADD CONSTRAINT pk_branches PRIMARY KEY(branch_id);
ALTER TABLE dealers ADD CONSTRAINT pk_dealers PRIMARY KEY(dealer_id);
ALTER TABLE brokers ADD CONSTRAINT pk_brokers PRIMARY KEY(broker_id);
ALTER TABLE executives ADD CONSTRAINT pk_executives PRIMARY KEY(executive_id);

ALTER TABLE contracts ADD CONSTRAINT fk_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id);
ALTER TABLE contracts ADD CONSTRAINT fk_executive FOREIGN KEY (executive_id) REFERENCES executives(executive_id);
ALTER TABLE repayment ADD CONSTRAINT fk_contract FOREIGN KEY (loan_id) REFERENCES contracts(loan_id);


-- 3 Month Rolling Average of Overdue Amount.

WITH overdue_monthly AS(
SELECT 
	DATE_FORMAT(due_date,'%Y-%m') AS month,
	SUM(overdue_amount) AS total_overdue
	FROM repayment
	GROUP BY DATE_FORMAT(due_date,'%Y-%m')
)
SELECT 
	month , 
	total_overdue,
	ROUND(
	AVG(total_overdue)OVER(
	ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ),
	2) AS rolling_3m_avg_overdue
	FROM overdue_monthly
	ORDER BY month ;

/* Rolling 3 month overdue peaked in early 2024 and declined thereafter, 
indicating partial but not complete resolution of the accumulated overdue cases.*/


-- 3 Month Rolling Average of DPD Days.

WITH dpd_monthly AS(
	SELECT 
	DATE_FORMAT(due_date,'%Y-%m') AS month,
	AVG(dpd_days) AS avg_dpd_days_in_month
	FROM repayment
	GROUP BY DATE_FORMAT(due_date,'%Y-%m')
)
SELECT 
	month, 
	avg_dpd_days_in_month,
	ROUND( AVG(avg_dpd_days_in_month) OVER (
	ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
	,2) AS rolling_3m_avg_dpd_days
	FROM dpd_monthly
	ORDER BY month;

/* Rolling average DPD days increased steadily through 2023 and continued to rise in 2024,
indicating persistence of high risk accounts even as overdue amount began to decline  */


--  3 Month Rolling Average for Amount Recovered.


WITH amt_recieved_monthly AS(
SELECT 
	DATE_FORMAT(due_date,'%Y-%m') AS month,
	SUM(amount_received) AS total_amount_recovered
	FROM repayment
	GROUP BY DATE_FORMAT(due_date,'%Y-%m')
)
SELECT 
	month , 
	total_amount_recovered,
	ROUND(
	AVG(total_amount_recovered)OVER(
	ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ),
	2) AS rolling_3m_avg_amount_recovered
	FROM amt_recieved_monthly
	ORDER BY month ;

/* Recovery improved in early 2024 and then declined thereafter,  following similar pattern as overdue amount, 
it points towards increasing collection distress.*/



-- Top 2% dealers based on Overdue Amount concentration for year 2023 and 2024.

WITH dealer_overdue AS (
SELECT 
	YEAR(r.due_date) AS year,
	d.dealer_id,
	d.dealer_name,
	SUM(r.overdue_amount) AS total_overdue
	FROM contracts c
	INNER JOIN repayment r ON c.loan_id = r.loan_id
	INNER JOIN dealers d ON c.dealer_id = d.dealer_id
	GROUP BY d.dealer_id, d.dealer_name,YEAR(r.due_date)
),
ranked_dealers AS (
SELECT *, 
	PERCENT_RANK()OVER(
    PARTITION BY year ORDER BY total_overdue DESC
    ) AS pct_rank
	FROM dealer_overdue
)
SELECT 
	year,
	dealer_id,
	dealer_name,
	total_overdue
	FROM ranked_dealers
	WHERE pct_rank <= 0.02 
	ORDER BY year ASC, total_overdue DESC ;
    


-- Top 2% brokers based on Overdue Amount concentration for year 2023 and 2024.

WITH broker_overdue AS (
SELECT 
	YEAR(r.due_date) AS year,
	b.broker_id,
	b.broker_name,
	SUM(r.overdue_amount) AS total_overdue_amount
	FROM contracts c
	INNER JOIN repayment r ON c.loan_id = r.loan_id
	INNER JOIN brokers b ON c.broker_id = b.broker_id
	GROUP BY b.broker_id, b.broker_name, YEAR(r.due_date)
),
ranked_brokers AS(
SELECT *, 
	PERCENT_RANK()OVER(
    PARTITION BY year ORDER BY total_overdue_amount DESC
    ) AS pct_rank
	FROM broker_overdue
)
SELECT
	year,
	broker_id,
	broker_name,
	total_overdue_amount
	FROM ranked_brokers
	WHERE pct_rank <= 0.02
	ORDER BY year ASC, total_overdue_amount DESC ;
    
    

--  Top 2 states with highest total amount recovered for years 2023 and 2024.

WITH state_wise_amt_recovered AS 
(
SELECT 
	b.state,  
	YEAR(r.due_date) AS year, 
	SUM(r.amount_received) AS total_amt_recovered
	FROM branches b 
	INNER JOIN contracts c ON b.branch_id = c.branch_id 
	INNER JOIN repayment r ON c.loan_id = r.loan_id
	GROUP BY YEAR(r.due_date), b.state
),
state_rank AS 
(
SELECT *, 
	DENSE_RANK()OVER(
    PARTITION BY year ORDER BY total_amt_recovered DESC
    ) AS rnk
	FROM state_wise_amt_recovered
)
SELECT 
	year, 
	state , 
    total_amt_recovered
	FROM state_rank
	WHERE rnk <= 2
	ORDER BY year ASC, total_amt_recovered DESC;



-- Branches in top 2% with highest total amount recovered for year 2023 and 2024.

WITH branch_wise AS (
SELECT 
b.branch_id,
b.branch_name,
b.state,  
	YEAR(r.due_date) AS year, 
	SUM(r.amount_received) AS total_amt_recovered
	FROM branches b 
    INNER JOIN contracts c ON b.branch_id = c.branch_id 
	INNER JOIN repayment r ON c.loan_id = r.loan_id
	GROUP BY YEAR(r.due_date), b.state, b.branch_id, b.branch_name
),
ranked_branches AS(
SELECT *, 
	PERCENT_RANK()OVER(
    PARTITION BY year ORDER BY total_amt_recovered DESC
    ) AS pct_rnk
	FROM branch_wise
)
SELECT 
	year,
	branch_id,
	branch_name,
    total_amt_recovered
    FROM ranked_branches
    WHERE pct_rnk <= 0.02
    ORDER BY year, total_amt_recovered DESC;
    

-- Date of the month(out of 5,10,15) has higher EMI bounces.

WITH emi_bounced AS(
SELECT 
	DAY(due_date) AS due_day,
	SUM(
    CASE WHEN amount_received < due_amount THEN 1 ELSE 0 END
    ) AS number_of_emi_bounced,
    COUNT(*) AS total_number_of_EMIs
	FROM repayment
	GROUP BY DAY(due_date)
	ORDER BY number_of_emi_bounced DESC
)
SELECT 
	due_day, 
    number_of_emi_bounced, 
    ROUND(
    (number_of_emi_bounced / total_number_of_EMIs),
    2) AS bounce_rate
    FROM emi_bounced
    ORDER BY bounce_rate DESC;
   
/* EMI bounce rate is higher on the 15th, including greater repayment stress later in the month */


