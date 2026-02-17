--------------------------------------------------------------------------
-- Start of eda_queries.sql
--------------------------------------------------------------------------

SELECT * 
FROM insurance.cust_clean
LIMIT 20;

SELECT *
FROM insurance.camp_clean
LIMIT 20;

-- I will answer 5 questions
-- 1. Which campaigns acquire the most customers?
-- 2. Which campaign has the lowest Customer Acquisition Cost (CAC)?
-- 3. Which campaigns bring the highest value customers (LTV)?
-- 4. What is the churn rate by campaign?
-- 5. Which channel delivers the best balance between CAC and LTV?

-- 1. Which campaigns acquire the most customers?
-- Use of JOIN
-- Conclusion: Eventos Corporativos (537), Partnership Bancos (529), Vida Segura Q1 2023 (526)

SELECT 
    ca.campaign_name,
    COUNT(*) AS customers_acquired
FROM insurance.cust_clean cu
JOIN insurance.camp_clean ca ON cu.acquisition_campaign_id = ca.campaign_id
WHERE cu.acquisition_campaign_id IS NOT NULL
GROUP BY ca.campaign_name
ORDER BY customers_acquired DESC
LIMIT 20;

-- 1.a Which channel acquire the most customers?
-- Use of JOIN
-- Conclusion: Digital (4557), Agentes (1987), Partners (1908), Telefónica (1548)

SELECT
    cu.acquisition_channel,
    COUNT(*) AS customers_acquired
FROM insurance.cust_clean cu
JOIN insurance.camp_clean ca ON cu.acquisition_campaign_id = ca.campaign_id
WHERE cu.acquisition_campaign_id IS NOT NULL
GROUP BY cu.acquisition_channel
ORDER BY customers_acquired DESC;


-- 2. Which campaign has the lowest Customer Acquisition Cost (CAC)?
-- USE of JOIN
-- Conclusion: Agentes Premium (52.43€), Remarketing Vida (112.15€) and Digital Boost 2024 (145.41€) acquire customer more efficiently.

WITH customers_acquired AS (
    SELECT
        cu.acquisition_campaign_id,
        COUNT(cu.acquisition_campaign_id) AS cust_acq
    FROM insurance.cust_clean cu
    GROUP BY cu.acquisition_campaign_id
)
SELECT
    ca.campaign_name,
    channel,
    ca.budget_euro,
    cust_acq,
    ROUND(ca.budget_euro / cust_acq, 2) AS cac
FROM customers_acquired
JOIN insurance.camp_clean ca ON customers_acquired.acquisition_campaign_id = ca.campaign_id
ORDER BY cac ASC;

-- 2.a Which channel has the lowest CAC?
-- Use of CTE and JOIN
-- Conclusion: Agentes (165.19€), Telefónica (198.83€), Digital (289.15€), Partners (361.99€)

WITH budget AS (
    SELECT
        channel,
        SUM(budget_euro) AS total_budget
    FROM insurance.camp_clean ca
    GROUP BY channel
),
channel_cust AS (
    SELECT
        acquisition_channel,
        COUNT(cu.customer_id) AS customers_acquired
    FROM insurance.cust_clean cu
    GROUP BY acquisition_channel
)
SELECT
    budget.channel,
    budget.total_budget,
    channel_cust.customers_acquired,
    ROUND(total_budget / customers_acquired, 2) AS cac
FROM budget
JOIN channel_cust ON budget.channel = channel_cust.acquisition_channel
ORDER BY cac ASC;


-- 3. Which campaigns bring the highest value customers (LTV)?
-- Use of JOIN
-- Conclusion: Salud Preventiva 2024 (LTV 4574.63€), Vida Segura Q1 2023 (LTV 4519.76€), Televentas Plus (4518.27€)

SELECT
    ca.campaign_name,
    ROUND(AVG(cu.total_premium_paid_euro),2) AS avg_ltv,
    ROUND(AVG(cu.claims_total_euro),2) AS avg_claim,
    ROUND(AVG(cu.total_premium_paid_euro - cu.claims_total_euro),2 ) AS avg_margin,
    ROUND(AVG(cu.total_premium_paid_euro - cu.claims_total_euro) / AVG(cu.total_premium_paid_euro) * 100, 2) AS pct_margin,
    ROUND(AVG(cu.lifetime_months),2) AS avg_lifetime
FROM insurance.camp_clean ca
JOIN insurance.cust_clean cu ON ca.campaign_id = cu.acquisition_campaign_id
GROUP BY ca.campaign_name
ORDER BY avg_ltv DESC;

-- 3.a Which channel bring the highest value customers (LTV)?
-- Conclusion: Agentes (4471.94), Telefónica (4416.98), Digital (4361.27), Partners (4346.19)

SELECT
    ca.channel,
    ROUND(AVG(cu.total_premium_paid_euro),2) AS avg_ltv,
    ROUND(AVG(cu.claims_total_euro),2) AS avg_claim,
    ROUND(AVG(cu.total_premium_paid_euro - cu.claims_total_euro),2 ) AS avg_margin,
    ROUND(AVG(cu.total_premium_paid_euro - cu.claims_total_euro) / AVG(cu.total_premium_paid_euro) * 100, 2) AS pct_margin,
    ROUND(AVG(cu.lifetime_months),2) AS avg_lifetime
FROM insurance.camp_clean ca
JOIN insurance.cust_clean cu ON ca.campaign_id = cu.acquisition_campaign_id
GROUP BY ca.channel
ORDER BY avg_ltv DESC;

-- 3.b Which first product bring the highest value customers (LTV)?
-- Conclusion: Auto (7229.09), Hogar (5290.44), Salud (4201.17), Vida (3042.14)

SELECT
    cu.first_product,
    ROUND(AVG(cu.total_premium_paid_euro),2) AS avg_ltv,
    ROUND(AVG(cu.claims_total_euro),2) AS avg_claim,
    ROUND(AVG(cu.total_premium_paid_euro - cu.claims_total_euro),2 ) AS avg_margin,
    ROUND(AVG(cu.total_premium_paid_euro - cu.claims_total_euro) / AVG(cu.total_premium_paid_euro) * 100, 2) AS pct_margin,
    ROUND(AVG(cu.lifetime_months),2) AS avg_lifetime
FROM insurance.cust_clean cu
GROUP BY cu.first_product
ORDER BY avg_ltv DESC;


-- 4. What is the churn rate by campaign?
-- Conclusion: Highest is Cobertura Hogar 2023 (27.57%), lowest is Social Salud Joven (22.20%)

SELECT
    ca.campaign_name,
    COUNT(*) AS customers,
    SUM(CASE WHEN cu.status = 'Churned' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN cu.status = 'Churned' THEN 1 ELSE 0 END)::NUMERIC / COUNT (*) * 100, 2) AS churn_rate_pct
FROM insurance.cust_clean cu
JOIN insurance.camp_clean ca ON cu.acquisition_campaign_id = ca.campaign_id
GROUP BY ca.campaign_name
ORDER BY churn_rate_pct DESC;

-- 4.a What is the churn rate by channel?
-- Conclusion: Agentes (24.66%), Digital (24.58%), Telefónica (24.22%), Partners (24.21%)

SELECT
    cu.acquisition_channel,
    COUNT(*) AS customers,
    SUM(CASE WHEN cu.status = 'Churned' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN cu.status = 'Churned' THEN 1 ELSE 0 END)::NUMERIC / COUNT (*) * 100, 2) AS churn_rate_pct
FROM insurance.cust_clean cu
JOIN insurance.camp_clean ca ON cu.acquisition_campaign_id = ca.campaign_id
GROUP BY cu.acquisition_channel
ORDER BY churn_rate_pct DESC;

-- 4.a What is the churn rate by product?
-- Conclusion: Auto (25.05%), Hogar (24.63%), Vida (24.38%), Salud (24.24%)

SELECT
    cu.first_product,
    COUNT(*) AS customers,
    SUM(CASE WHEN cu.status = 'Churned' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN cu.status = 'Churned' THEN 1 ELSE 0 END)::NUMERIC / COUNT (*) * 100, 2) AS churn_rate_pct
FROM insurance.cust_clean cu
JOIN insurance.camp_clean ca ON cu.acquisition_campaign_id = ca.campaign_id
GROUP BY cu.first_product
ORDER BY churn_rate_pct DESC;


-- 5. Which campaigns delivers the best balance between CAC and LTV?
-- USE of CTE and subqueries
-- Conclusion: The bests are Agentes Premium (85:1), Remarketing Vida (39:1), Digital Boost 2024 (29:1)
-- Conclusion: The worsts are Influencers 2024 (9:1), Email Nutrición (10:1), SEO Seguros (11:1)

WITH camp_budget AS (
    SELECT
        ca.campaign_name,
        ca.campaign_id,
        SUM(ca.budget_euro) AS total_budget
    FROM insurance.camp_clean ca
    GROUP BY ca.campaign_id
),
metrics AS (
    SELECT
        cu.acquisition_campaign_id,
        ROUND(AVG(cu.total_premium_paid_euro), 2) AS avg_ltv,
        COUNT(cu.customer_id) AS customers_acquired 
    FROM insurance.cust_clean cu
    GROUP BY cu.acquisition_campaign_id
),
final_cac AS (
    SELECT
        camp_budget.campaign_name,
        metrics.acquisition_campaign_id,
        ROUND(total_budget / customers_acquired, 2) AS cac
    FROM camp_budget
    JOIN metrics ON camp_budget.campaign_id = metrics.acquisition_campaign_id
)
SELECT
    final_cac.campaign_name,
    ROUND(avg_ltv / cac, 2) AS ltv_cac_ratio
FROM final_cac
JOIN metrics ON final_cac.acquisition_campaign_id = metrics.acquisition_campaign_id
ORDER BY ltv_cac_ratio DESC;

-- 5.a Which channel delivers the best balance between CAC and LTV?
-- Conclusion: Agentes (27:1), Telefónica (22:1), Digital (15:1), Partners (12:1)

WITH camp_budget AS (
    SELECT
        ca.channel,
        SUM(ca.budget_euro) AS total_budget
    FROM insurance.camp_clean ca
    GROUP BY ca.channel
),
metrics AS (
    SELECT
        cu.acquisition_channel,
        ROUND(AVG(cu.total_premium_paid_euro), 2) AS avg_ltv, 
        COUNT(cu.customer_id) AS customers_acquired
    FROM insurance.cust_clean cu
    GROUP BY cu.acquisition_channel
),
final_cac AS (
    SELECT
        metrics.acquisition_channel,
        ROUND(total_budget / customers_acquired, 2) AS cac
    FROM camp_budget
    JOIN metrics ON camp_budget.channel = metrics.acquisition_channel
)
SELECT
    final_cac.acquisition_channel,
    ROUND(avg_ltv / cac, 2) AS ltv_cac_ratio
FROM final_cac
JOIN metrics ON final_cac.acquisition_channel = metrics.acquisition_channel;


---------------------------------
-- Other insights
---------------------------------

-- Conversion rate from all campaign leads
-- Use of CTE
-- Conclusion: 40.27%

WITH metrics AS (
    SELECT 
        (SELECT SUM(ca.leads_generated) 
        FROM insurance.camp_clean ca) AS total_leads,
        (SELECT COUNT(DISTINCT cu.customer_id) 
        FROM insurance.cust_clean cu) AS total_customers
)
SELECT 
    total_leads,
    total_customers,
    ROUND(total_customers * 100.0 / total_leads, 2) AS conversion_rate_percent,
    total_leads - total_customers AS leads_not_converted
FROM metrics;


-- Conversion rate from leads by channel
-- Use of CTE
-- Conclusion: Telefónica (47.96%), Digital (42.39%), Agentes (39.38%), Partners (32.85%) 

WITH campaign_leads AS (
    SELECT 
        channel,
        SUM(leads_generated) AS total_leads
    FROM insurance.camp_clean
    GROUP BY channel
),
campaign_customers AS (
    SELECT DISTINCT
        ca.channel,
        cu.customer_id
    FROM insurance.camp_clean ca
    INNER JOIN insurance.cust_clean cu ON ca.campaign_id = cu.acquisition_campaign_id
)
SELECT 
    cl.channel,
    cl.total_leads,
    COUNT(cc.customer_id) AS total_customers,
    ROUND(COUNT(cc.customer_id) * 100.0 / cl.total_leads, 2) AS conversion_rate
FROM campaign_leads cl
LEFT JOIN campaign_customers cc ON cl.channel = cc.channel
GROUP BY cl.channel, cl.total_leads
ORDER BY conversion_rate DESC;


-- Customer claim amount vs channel average
-- Use of WINDOW function to compare each customer claim amount to the average of the acquisition channel
SELECT 
    cu.customer_id,
    cu.acquisition_channel,
    cu.claims_total_euro,
    ROUND(AVG(cu.claims_total_euro) OVER (PARTITION BY cu.acquisition_channel), 2) AS avg_claim_per_channel
FROM insurance.cust_clean cu
WHERE cu.claims_total_euro <> '0'
ORDER BY cu.claims_total_euro DESC;


-- Customer claim amount vs first product average
-- Use of WINDOW function to compare each customer claim amount to the average of the first product
SELECT 
    cu.customer_id,
    cu.first_product,
    cu.acquisition_channel,
    cu.claims_total_euro,
    ROUND(AVG(cu.claims_total_euro) OVER (PARTITION BY cu.first_product), 2) AS avg_claim_per_first_product
FROM insurance.cust_clean cu
WHERE cu.claims_total_euro <> '0'
ORDER BY cu.claims_total_euro DESC;















