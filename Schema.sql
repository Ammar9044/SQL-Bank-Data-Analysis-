
-- Cleaning Raw Data --

Select account_id , Count(*)
from accounts group by
account_id
having count(*) > 1;

Select * from accounts;
Select * from customers;
Select * from loans;
Select * from transactions;






With ranked as 
( Select *, row_number() over(partition by account_id order by account_id desc) as rn from 
accounts ) 
Delete from accounts
where account_id in ( select 
account_id from ranked 
where rn > 1) ;


With ranked as 
( Select *, row_number() over(partition by customer_id order by customer_id desc) as rn from 
customers ) 
Delete from customers
where customer_id in ( select 
customer_id from ranked 
where rn > 1) ;

Select customer_id , Count(*)
from customers group by
customer_id
having count(*) > 1;

Select * from customers;

Update customers
set email = null
where email = '' or ' ';

Update customers 
set phone_number = replace(phone_number, '-', ''),
phone_number = replace(replace(phone_number, ')', ''), '(', ''),
phone_number = replace(phone_number, 'x', ''),
phone_number = replace(phone_number, '+', ''),
phone_number = replace(phone_number, '.', '');


Update customers 
set phone_number = Trim(phone_number);

Update customers 
set phone_number = null
where phone_number = '' or ' ';

Update customers 
set phone_number = STR_TO_DATE(open_date, '%Y-%m-%d');

Update customers 
set income = null
where income = 0;

Select loan_id, Count(*)
from loans 
group by loan_id
having Count(*) > 1;

UPDATE loans
SET loan_id = CAST(SUBSTRING(loan_id, 2) AS UNSIGNED);



With ranked as 
( Select *, row_number() over(partition by transaction_id order by transaction_id desc) as rn from 
transactions ) 
Delete from transactions
where transaction_id in ( select 
transaction_id from ranked 
where rn > 1) ;


ALTER TABLE accounts
MODIFY COLUMN account_id INT,
MODIFY COLUMN customer_id INT,
MODIFY COLUMN account_type ENUM('Loan', 'Checking', 'Savings'),
MODIFY COLUMN balance DECIMAL(15, 2),
MODIFY COLUMN open_date DATE,
MODIFY COLUMN status ENUM('Closed', 'Inactive', 'Active'),
ADD PRIMARY KEY (account_id);

ALTER TABLE customers
MODIFY COLUMN  customer_id int,
MODIFY COLUMN first_name varchar(40),
MODIFY COLUMN last_name varchar(40),
MODIFY COLUMN gender enum('Male', 'Female'),
MODIFY COLUMN date_of_birth date, 
MODIFY COLUMN phone_number varchar(50),
MODIFY COLUMN join_date date,
MODIFY COLUMN city varchar(50),
MODIFY COLUMN state varchar(50),
MODIFY COLUMN income Decimal(15, 2),
ADD PRIMARY KEY (customer_id);

ALTER TABLE loans 
MODIFY COLUMN  loan_id int, 
MODIFY COLUMN account_id int, 
MODIFY COLUMN customer_id int, 
MODIFY COLUMN loan_amount Decimal(15, 2),
MODIFY COLUMN loan_date Date,
MODIFY COLUMN loan_status enum( 'rejected', 'pending', 'closed', 'approved'),
Add Primary Key(loan_id);

ALTER TABLE transactions
MODIFY COLUMN  transaction_id int,
MODIFY COLUMN account_id int, 
MODIFY COLUMN transaction_date date,
MODIFY COLUMN transaction_time time,
MODIFY COLUMN transaction_type enum('Deposit','Transfer','Withdrawal'),
MODIFY COLUMN amount Decimal(15, 2),
MODIFY COLUMN description text,
Add Primary Key(transaction_id);


DELETE t
FROM transactions t
LEFT JOIN accounts a ON a.account_id = t.account_id
WHERE a.account_id IS NULL;

DELETE l
FROM loans l 
LEFT JOIN customers c ON c.customer_id = l.customer_id
WHERE c.customer_id IS NULL;



Alter table accounts
Add constraint fk_cust
foreign key (customer_id)
references customers(customer_id);

Alter table loans
Add constraint fk_acc
foreign key (account_id)
references accounts(account_id);

Alter table loans
Add constraint fk_cust1
foreign key (customer_id)
references customers(customer_id);

CREATE INDEX idx_account_id ON transactions(account_id);
CREATE INDEX idx_customer_id ON accounts(customer_id);
CREATE INDEX idx_loan_account_id ON loans(account_id);

 -- Exploratory Data Analysis --
 
 -- No ofActive Accounts 
 Select Count(*)
 from accounts
 where  status = 'Active';
 
 -- Total Balance by account_type 
 Select account_type, Sum(balance) as total_balance
 from accounts 
 group by account_type
 order by Sum(balance);
 
 -- Top 10 Cities by most income 
SELECT city, SUM(income) AS total_income
FROM customers
GROUP BY city
ORDER BY total_income desc
limit 10;

-- Income by Gender 
Select gender, SUM(Income) as total_income 
from customers 
group by gender 
order by 2 desc;

-- Total amount of loan disbursed to approved customers 
Select SUM(loan_amount) as total_loan_disbursed, count(*) as no_of_cus from loans
where loan_status = 'approved';

-- Total amount by Transaction_type 
Select transaction_type, SUM(amount) as total_amount
from transactions 
group by transaction_type
order by SUm(amount) desc;

-- Maximum amount Withdrawn 
Select  Max(amount) as max_amount
from transactions 
where transaction_type= 'Withdrawal';

-- Highest amount deposited and Respective date 
Select transaction_date, amount 
from transactions
where amount in ( Select Max(amount) from transactions where transaction_type = 'Deposit' );


-- No of transaction by account type 
Select a.account_type, Count(t.transaction_id) as no_of_transactions 
from 
accounts as a join 
transactions as t 
on a.account_id=t.account_id
group by a.account_type
order by Count(t.transaction_id) desc;

-- Customers with high loan to income ratio 
SELECT 
  c.customer_id, 
  c.first_name, 
  c.last_name,
  SUM(income) AS total_income,
  SUM(loan_amount) AS total_loan, 
  ROUND((SUM(loan_amount) / SUM(income)) * 100, 2) AS loan_to_income_ratio
FROM customers c
JOIN loans l ON c.customer_id = l.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING SUM(income) > 0 AND loan_to_income_ratio > 100
ORDER BY loan_to_income_ratio DESC;

-- Total Loan by city 
Select city, SUM(loan_amount) as total_amount
from loans as l 
join customers as c 
on l.customer_id=c.customer_id
group by city 
order by SUM(loan_amount) desc;

-- Average Transactions per account ID
With transactions_1 as (
Select a.account_id, (Count(transaction_id)) as trans
from accounts as a join transactions as t
on t.account_id=a.account_id
group by a.account_id
order by avg(transaction_id) desc ) 
Select account_id, Avg(trans) as avg_transactions 
from transactions_1 group by account_id
order by avg_transactions desc;

--  Customers With Multiple Rejected Loans 

Select c.customer_id, c.first_name, c.last_name, l.loan_status, Count(*)
from customers c 
join loans l on c.customer_id=l.customer_id
where loan_status='rejected'
group by c.customer_id, c.first_name, c.last_name
having Count(*) > 1
order by Count(*) desc;

-- Accounts with large withdrawals and low balance

SELECT 
  a.account_id, 
  t.transaction_type, 
  t.amount, 
  a.balance,
  (SELECT AVG(amount) FROM transactions) AS avg_withdrawal,
  (SELECT AVG(balance) FROM accounts) AS avg_balance
FROM accounts a
JOIN transactions t ON a.account_id = t.account_id
WHERE 
  t.transaction_type = 'Withdrawal'
  AND t.amount > (SELECT AVG(amount) FROM transactions)
  AND a.balance < (SELECT AVG(balance) FROM accounts)
ORDER BY t.amount DESC;

ALTER TABLE loans
ADD COLUMN loan_to_income_ratio DECIMAL(10,2);

UPDATE loans l
JOIN customers c ON l.customer_id = c.customer_id
SET l.loan_to_income_ratio = ROUND(
    IFNULL(l.loan_amount, 0) / NULLIF(c.income, 0) * 100,
    2
);


-- Loan approval rate by city

SELECT 
  c.city,
  COUNT(CASE WHEN l.loan_status = 'approved' THEN 1 END) AS approved_loans,
  COUNT(*) AS total_loans,
  ROUND(
    COUNT(CASE WHEN l.loan_status = 'approved' THEN 1 END) / COUNT(*) * 100,
    2
  ) AS approval_rate
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
GROUP BY c.city
ORDER BY approval_rate DESC;

-- Time between account creation and first transaction 

SELECT 
  a.account_id, 
  a.open_date, 
  MIN(t.transaction_date) AS first_transaction,
  DATEDIFF(MIN(t.transaction_date), a.open_date) AS difference
FROM accounts a
JOIN transactions t ON a.account_id = t.account_id
GROUP BY a.account_id, a.open_date;
-- Accounts with delayed first transaction

SELECT * 
FROM (
  SELECT 
    a.account_id, 
    a.open_date, 
    MIN(t.transaction_date) AS first_transaction,
    DATEDIFF(MIN(t.transaction_date), a.open_date) AS delay_days
  FROM accounts a
  JOIN transactions t ON a.account_id = t.account_id
  GROUP BY a.account_id, a.open_date
) sub
WHERE delay_days > 7
ORDER BY delay_days DESC;

-- Running Transactions by month 

SELECT 
  month,
  total_transactions,
  SUM(total_transactions) OVER (ORDER BY month) AS running_transactions
FROM (
  SELECT 
    MONTH(transaction_date) AS month,
    SUM(amount) AS total_transactions
  FROM transactions
  GROUP BY MONTH(transaction_date)
) AS monthly_totals;





























































 
 


































