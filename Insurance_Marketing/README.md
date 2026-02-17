# Insurance Customer Acquisition & Value Analysis

## Project Overview
This project analyzes customer acquisition, lifetime value and marketing efficiency for a non-existent insurance company. Using SQL for data processing and Power BI for visualization, I explored key business questions about campaign performance, channel effectiveness and customer profitability.

## Objectives
- Identify which campaigns and channels acquire the most customers
- Calculate Customer Acquisition Cost (CAC) by campaign and channel
- Analyse Customer Lifetime Value (LTV) across segments
- Measure churn rates and identify at-risk customers
- Determine the optimal balance between CAC and LTV

## Tools Used
- **PostgreSQL** - Data cleaning, transformation and KPI calculation
- **Power BI** - Dashboard creation and visualisation
- **GitHub** - Version control and project portfolio

## Dataset and Data Structure
The dataset used in this project was generated on demand by ChatGPT, therefore it contains **synthetic data**. Some records were intentionally modified to:

- Achieve more realistic business scenarios
- Introduce data quality issues (inconsistent formats, duplicates, invalid values) to simulate a real-world cleaning process

This approach allowed me to practice and demonstrate:
- **Data cleaning techniques** (handling duplicates, fixing data types, standardising formats)
- **Data transformation** using SQL (CASE statements, regex, NULL handling)
- **Exploratory analysis** on imperfect, real-world-like data

The final cleaned dataset consists of two main tables:

### `cust_clean` (Customers Table)
- **10,000+ customer records** with acquisition details, premiums, claims, and churn status
- Key fields: `customer_id`, `acquisition_channel`, `acquisition_date`, `first_product`, `total_premium_paid_euro`, `claims_total_euro`, `status`, `lifetime_months`

### `camp_clean` (Campaigns Table)
- **20 marketing campaigns** with budget, leads, and channel information
- Key fields: `campaign_id`, `campaign_name`, `channel`, `budget_euro`, `leads_generated`, `cost_per_lead`

## Key Findings

### Top Performing Campaigns
- **Eventos Corporativos**, **Partnership Bancos** and **Vida Segura Q1 2023** acquired the most customers (500+ each)
- **Agentes Premium** achieved the lowest CAC at **€52.43 per customer**
- **Salud Preventiva 2024** generated the highest LTV at **€4,574 per customer**

### Channel Efficiency
- **Agents** channel delivers the best LTV:CAC ratio (**27:1**), meaning every €1 spent returns €27 in customer value
- **Digital** channel has the highest volume but higher CAC (**€289**) and lower LTV:CAC ratio (15:1)
- **Telephone** shows strong conversion rates (**47.96%**) from leads to customers

### Product Insights
- **Auto** insurance has the highest LTV (**€7,229**) but also the highest churn rate (**25.05%**)
- **Vida** products have the lowest churn (**24.38%**), indicating better retention
- Overall conversion rate from leads to customers: **40.27%**

## Business Recommendations

1. **Increase investment in Agent channel** - With the best LTV:CAC ratio (27:1), reallocating 20% of digital budget to agents could improve overall profitability

2. **Review low-performing campaigns** - Campaigns with LTV:CAC ratio < 10:1 (Influencers 2024, Email Nutrición) should be paused or redesigned

3. **Implement retention programme for Auto customers** - Despite highest LTV, Auto has the highest churn. Create loyalty incentives before renewal dates

4. **Optimise lead conversion in Partner channel** - Partners have lowest conversion rate (33%) vs Telephone (48%). Investigate and replicate best practices

5. **Targeted cross-selling** - Customers with only one product show high propensity for second products. Use propensity scoring to prioritise outreach

## Visualizations

### Dashboard: Overview - General Performance
![Overview Dashboard](/Insurance_Marketing/Assets/Dashboard_Overview.png)

*This dashboard provides a high-level view of key metrics including total customers, conversion rates, channel distribution and top-performing campaigns.*

# Contact
Juan José García — Data Analyst | Business Analyst | E-commerce Manager

Email: juanjosegarcia@outlook.com

LinkedIn: https://www.linkedin.com/in/DA-JuanGarcia

GitHub: https://github.com/DA-JuanGarcia