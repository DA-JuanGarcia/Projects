# Introduction
This project performs a full Exploratory Data Analysis (EDA) on a Google Play Store dataset containing Android apps, their characteristics, and performance metrics (ratings, reviews, installs, size, updates, etc.).
The goal is to clean messy real-world data, prepare it for analysis using SQL (PostgreSQL), and extract meaningful insights that could support product or business decisions.

# Objective
- Clean and standardize a real-world dataset using SQL
- Apply deduplication logic
- Perform meaningful exploratory analysis
- Build a professional, well-documented EDA project suitable for a portolio and CV

# Tools Used
- **PostgreSQL:** Database system used to store and manage the data.
- **Visual Studio Code (SQL):** For querying, cleaning and analyzing data (CTE, regex, aggregations, CASE logic, etc.).
- **Power BI:** For creating interactive dashboards and visualizing key insights.
- **GitHub:** For version control and sharing SQL scripts and analysis, enabling collaboration and project tracking.

# Dataset
The dataset contains information about ~10k Android apps from the Google Play Store until 2018. Downloaded from Kaggle [[Link]](https://www.kaggle.com/datasets/lava18/google-play-store-apps/data)

It includes 13 columns (app name, category, rating, reviews, size, installs, type, price, content_rating, genres, last_updated, current_ver, android_ver)

The project uses three versions of the dataset:
1. apps_raw.csv -> original messy data
2. apps_clean.csv -> cleaned and standardized data
3. apps_final.csv -> deduplicated, analysis-ready table

# What I Did
- Imported raw CSV into PostgreSQL
- Cleaned text, numeric, and date fields using SQL 
- Removed unwanted characters and blank spaces
- Converted sizes (KB → MB) and prices to numeric
- Standardized NULL values
- Deduplicated apps by keeping the version with the highest number of reviews and most recent update
- Performed SQL-based EDA

# Data Issues Identified
- Null values
- Missing ratigns and size (~15%)
- Inconsistent size units (MB, KB)
- Currency symbols in price
- Non-numeric characters in installs
- Text values like “Varies with device”
- Duplicate app records
- Inconsistent date formats

# EDA Questions Answered
1. Which categories have the most apps?
2. How are ratings distributed and which categories have higher average ratings?
3. Do more-downloaded apps have better ratings?
4. Do Paid apps have higher ratings than Free apps? 
5. Does app size influence rating or installs?

# Key Findings
- **Data Quality**: ~15% of apps lacked valid size information, ~13% had invalid rating information
- **Market Composition**: Top 3 categories make up 40% of all apps
- **Monetization**: Free apps account for 92% of inventory but 99.2% of installs
- **Size Distribution**: 60% of apps are under 20MB
- **Correlation**: Weak relationship between installs and ratings (r=0.04)

# Business Implications
- **For Developers**: Focus on smaller app sizes (<20MB) for better adoption
- **For Product Managers**: Rating collection needs improvement (~13% missing)
- **For Marketers**: Free apps dominate installs. Consider freemium models

# Visualizations
![Category Distribution](/EDA_GooglePlay/Assets/Figure_01-Number_apps_by_category.png)
*Figure 1: Top 10 app categories by number of apps*

![Rating Distribution](/EDA_GooglePlay/Assets/Figure_03-Rating_Distribution.png)
*Figure 2: Rating distribution*

![Free vs Paid Comparison](/EDA_GooglePlay/Assets/Figure_04-Free_vs_Paid_Apps.png)
*Figure 3: Free vs Paid Comparison*

![Installs Distribution](/EDA_GooglePlay/Assets/Figure_05-Apps_Installs.png)
*Figure 4: Installs distribution*

# Interactive Dashboard
![Interactive Dashboard](/EDA_GooglePlay/Assets/Figure_08-Interactive_Dashboard.png)
*Figure 5: Designed an interactive dashboard in PowerBI

# Skills Demonstrated
- Ability to work with real-world messy data
- Strong SQL cleaning skills (regex, casting, CTEs, CASE logic, window function, buckets)
- Ability to design a robust cleaning pipeline (raw → clean → final)
- Understanding of deduplication strategy and data reliability
- Experience writing analysis-ready SQL scripts
- Ability to communicate findings clearly using EDA
- Experience with Power BI visualizations
- Production-style project structure appropriate for GitHub

# Contact
Juan José García — Data Analyst

Email: juanjosegarcia@outlook.com

LinkedIn: https://www.linkedin.com/in/juanjosegarcia-bda/

GitHub: https://github.com/DA-JuanGarcia