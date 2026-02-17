-- schema.sql
CREATE SCHEMA IF NOT EXISTS insurance;
SET search_path TO insurance;

DROP TABLE IF EXISTS cust_raw;
CREATE TABLE cust_raw (
  customer_id TEXT,
  acquisition_campaign_id TEXT,
  acquisition_channel TEXT,
  acquisition_date TEXT,
  first_product TEXT,
  second_product TEXT,
  initial_premium_euro TEXT,
  current_premium_euro TEXT,
  status TEXT,
  churn_date TEXT,
  churn_reason TEXT,
  total_premium_paid_euro TEXT,
  claims_count TEXT,
  claims_total_euro TEXT,
  last_renewal_date TEXT,
  next_renewal_date TEXT,
  segment TEXT,
  lifetime_months TEXT,
  customer_value_score TEXT
);

DROP TABLE IF EXISTS camp_raw;
CREATE TABLE camp_raw (
campaign_id TEXT,
campaign_name TEXT,
channel TEXT,
subchannel TEXT,
start_date TEXT,
end_date TEXT,
budget_euro TEXT,
impressions TEXT,
clicks TEXT,
leads_generated TEXT,
cost_per_click TEXT,
cost_per_lead TEXT
);
