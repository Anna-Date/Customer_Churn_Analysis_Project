
CREATE SCHEMA dw;

-- Dimensionen: 

-- Kunden-Dimension
CREATE TABLE dw.dim_customer (
    customer_id INTEGER PRIMARY KEY,
    signup_date DATE NOT NULL,
    region TEXT,
    gender TEXT,
    age INTEGER
);


-- Vertrags-Dimension
CREATE TABLE dw.dim_contract (
    contract_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES dw.dim_customer(customer_id),
    subscription_type TEXT,
    contract_length TEXT,
    start_date DATE,
    end_date DATE
);

-- Produkt-Dimension
CREATE TABLE dw.dim_product (
    product_id INTEGER PRIMARY KEY
);

-- Zahlungsstatus-Dimension
CREATE TABLE dw.dim_payment_status (
    payment_status_id SERIAL PRIMARY KEY,
    status_name TEXT
);

-- Datum-Dimension
CREATE TABLE dw.dim_date (
    date_id SERIAL PRIMARY KEY,
    date DATE NOT NULL,
    day INTEGER,
    month INTEGER,
    quarter INTEGER,
    year INTEGER,
    weekday TEXT
);

-- ============================================
-- Faktentabellen


-- Fakt: Transaktionen
CREATE TABLE dw.fact_transaction (
    transaction_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES dw.dim_customer(customer_id),
    product_id INTEGER NOT NULL REFERENCES dw.dim_product(product_id),
    contract_id INTEGER REFERENCES dw.dim_contract(contract_id),
    date_id INTEGER REFERENCES dw.dim_date(date_id),
    revenue DECIMAL(10,2)
);

-- Fakt: Zahlungen
CREATE TABLE dw.fact_payment (
    payment_id INTEGER PRIMARY KEY,
    transaction_id INTEGER NOT NULL REFERENCES dw.fact_transaction(transaction_id),
    customer_id INTEGER NOT NULL REFERENCES dw.dim_customer(customer_id),
    date_id INTEGER REFERENCES dw.dim_date(date_id),
    payment_delay_days INTEGER,
    payment_status_id INTEGER REFERENCES dw.dim_payment_status(payment_status_id)
);
-- Fakt: Kundenaktivität
CREATE TABLE dw.fact_customer_activity (
    activity_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES dw.dim_customer(customer_id),
    date_id INTEGER REFERENCES dw.dim_date(date_id),
    logins INTEGER,
    support_calls INTEGER
);

-- Fakt: Churn
CREATE TABLE dw.fact_churn (
    customer_id INTEGER PRIMARY KEY REFERENCES dw.dim_customer(customer_id),
    date_id INTEGER REFERENCES dw.dim_date(date_id),
    churn_reason TEXT
);

-- ============================================
--Dimensionen befüllen

--dim_customer
INSERT INTO dw.dim_customer (customer_id, signup_date, region, gender, age)
SELECT
    customer_id,
    signup_date,
    region,
    gender,
    age
FROM public."Customers";

--dim_contract
INSERT INTO dw.dim_contract
SELECT contract_id, customer_id, subscription_type, contract_length, start_date, end_date
FROM public.contract;

--dim_payment_status
INSERT INTO dw.dim_payment_status (status_name)
SELECT DISTINCT payment_status
FROM public.payments;

--dim_product
INSERT INTO dw.dim_product  (product_id)
SELECT DISTINCT product_id
FROM public.transactions;

--dim_date
INSERT INTO dw.dim_date (date, day, month, quarter, year, weekday)
SELECT DISTINCT
    d AS date,
    EXTRACT(day FROM d),
    EXTRACT(month FROM d),
    EXTRACT(quarter FROM d),
    EXTRACT(year FROM d),
    TO_CHAR(d, 'Day')
FROM (
    SELECT signup_date AS d FROM public."Customers"
    UNION
    SELECT start_date FROM public.contract
    UNION
    SELECT end_date FROM public.contract
    UNION
    SELECT transaction_date FROM public.transactions
    UNION
    SELECT churn_date FROM public.churn_events
    UNION
    SELECT (activity_month || '-01')::date FROM public.customer_activity
) dates
WHERE d IS NOT NULL;

-- ============================================
--Fakt. befüllen

--fact_transaction
INSERT INTO dw.fact_transaction
SELECT
    t.transaction_id,
    t.customer_id,
    t.product_id,
    c.contract_id,
    d.date_id,
    t.revenue
FROM public.transactions t
LEFT JOIN dw.dim_contract c
       ON t.customer_id = c.customer_id
LEFT JOIN dw.dim_date d
       ON t.transaction_date = d.date;

--fact_payment
INSERT INTO dw.fact_payment (
    payment_id,
    transaction_id,
    customer_id,
    date_id,
    payment_delay_days,
    payment_status_id
)
SELECT
    p.payment_id,
    p.transaction_id,
    t.customer_id,
    d.date_id,
    p.payment_delay_days,
    s.payment_status_id
FROM public.payments p
JOIN public.transactions t ON p.transaction_id = t.transaction_id
JOIN dw.dim_payment_status s ON p.payment_status = s.status_name
LEFT JOIN dw.dim_date d ON t.transaction_date = d.date;

--fact_customer_activity
INSERT INTO dw.fact_customer_activity
SELECT
    a.activity_id,
    a.customer_id,
    d.date_id,
    a.logins,
    a.support_calls
FROM public.customer_activity a
LEFT JOIN dw.dim_date d
     ON (a.activity_month || '-01')::date = d.date;

--fact_churn
INSERT INTO dw.fact_churn
SELECT
    c.customer_id,
    d.date_id,
    c.churn_reason
FROM public.churn_events c
LEFT JOIN dw.dim_date d
     ON c.churn_date = d.date;


-- ============================================================================
-- 1. Gesamtumsatz nach Jahr & Monat

SELECT
    d.year,
    d.month,
    SUM(f.revenue) AS total_revenue
FROM dw.fact_transaction f
JOIN dw.dim_date d ON f.date_id = d.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;
-- # im decemner war die Revenue am großten 

--2. Umsatz nach Region 
SELECT
    c.region,
    SUM(f.revenue) AS total_revenue
FROM dw.fact_transaction f
JOIN dw.dim_customer c ON f.customer_id = c.customer_id
GROUP BY c.region
ORDER BY total_revenue DESC;

--# Top 5 : Ontario, Quebec, Br. Columbia, Alberta, Manitoba

-- 3. Umsatz nach Subscription-Typ
SELECT
    con.subscription_type,
    SUM(f.revenue) AS revenue
FROM dw.fact_transaction f
JOIN dw.dim_contract con ON f.contract_id = con.contract_id
GROUP BY con.subscription_type;
--# Premium: 501, Basic: 490, Standart: 479.

-- 4. Durchschnittlicher Umsatz pro Kunde
SELECT
    AVG(customer_revenue) AS arpu
FROM (
    SELECT
        customer_id,
        SUM(revenue) AS customer_revenue
    FROM dw.fact_transaction
    GROUP BY customer_id
) t;
--# Avg Umsatz/Kunde = 465.2460183428209994

-- 5. Churn-Rate pro Monat
SELECT
    d.year,
    d.month,
    COUNT(c.customer_id) 
FROM dw.dim_customer cu
LEFT JOIN dw.fact_churn c
       ON cu.customer_id = c.customer_id
LEFT JOIN dw.dim_date d
       ON c.date_id = d.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;
--# 2024: Dec: 261; Jan.: 59; Mart: 33; April: 24; Now.: 24;   

-- 6. Churn-Gründe
SELECT
    churn_reason,
    COUNT(*) AS churn_count
FROM dw.fact_churn
GROUP BY churn_reason
ORDER BY churn_count DESC;

--# Top5: 1.Better offer from competitor, 2.No longer need service, 
--  3.Technical problems, 4.Price too high, 5.Billing issues;

-- 7. Avg Support Calls vs. Churn
SELECT
    CASE
        WHEN c.customer_id IS NOT NULL THEN 'Churned'
        ELSE 'Active'
    END AS customer_status,
    AVG(a.support_calls) AS avg_support_calls
FROM dw.fact_customer_activity a
LEFT JOIN dw.fact_churn c
       ON a.customer_id = c.customer_id
GROUP BY customer_status;

--# active: 0.372; churnrrd: 0.458; 

-- 8. Durchschnittliche Logins pro Monat
SELECT
    d.year,
    d.month,
    AVG(a.logins) AS avg_logins
FROM dw.fact_customer_activity a
JOIN dw.dim_date d ON a.date_id = d.date_id
GROUP BY d.year, d.month
ORDER BY d.year, d.month;

-- 9. Anteil verspäteter Zahlungen (länger als 7 Tagen)
SELECT
    COUNT(*) FILTER (WHERE payment_delay_days > 7) * 100.0 / COUNT(*) 
        AS late_payment_percentage
FROM dw.fact_payment;
--# cirka 67% 

--10. Durchschnittlicher Umsatz pro Kunde
 SELECT
    AVG(customer_revenue) AS avg_unsatz
FROM (
    SELECT
        customer_id,
        SUM(revenue) AS customer_revenue
    FROM dw.fact_transaction
    GROUP BY customer_id
) t;
--# 465.2460

-- Churn-Risiko Score 
WITH customer_metrics AS (
    SELECT
        c.customer_id,
        AVG(a.logins) AS avg_logins,
        AVG(a.support_calls) AS avg_support_calls,
        AVG(p.payment_delay_days) AS avg_payment_delay,
        con.contract_length
    FROM dw.dim_customer c
    LEFT JOIN dw.fact_customer_activity a
           ON c.customer_id = a.customer_id
    LEFT JOIN dw.fact_payment p
           ON c.customer_id = p.customer_id
    LEFT JOIN dw.dim_contract con
           ON c.customer_id = con.customer_id
    GROUP BY
        c.customer_id,
        con.contract_length
)
SELECT
    customer_id,
    avg_logins,
    avg_support_calls,
    avg_payment_delay,
    contract_length,

    (CASE WHEN avg_logins < 3 THEN 1 ELSE 0 END +
     CASE WHEN avg_support_calls > 5 THEN 1 ELSE 0 END +
     CASE WHEN avg_payment_delay > 7 THEN 1 ELSE 0 END +
     CASE WHEN contract_length = 'monthly' THEN 1 ELSE 0 END
    ) AS churn_risk_score
FROM customer_metrics
ORDER BY churn_risk_score DESC;
