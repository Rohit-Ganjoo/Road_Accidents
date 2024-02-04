
# Road Accidents Analysis:
-- Use the database 
``` sql
USE roadaccidents;
```
## Spatial Analysis
### 1. Top 10 Districts that have high accidents:
``` sql
SELECT `Local_Authority_(District)`, COUNT(*)
FROM roadrash
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;
```
## Temporal Analysis:
### 1. Display the Month on Month change in the Accident Rate, along with that display the Current Month Accidents and Previous Month Accidents.
``` sql 
WITH Accident_Monthly_Comparison
AS (
    SELECT *,
        LAG(`Current Month Accident`) OVER (ORDER BY `Year`,`Month Number`) AS `Previous Month Accident`
    FROM (
        SELECT 
            MONTH(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS `Month Number`,
            YEAR(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS `Year`,
            MONTHNAME(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Month,
            COUNT(Accident_Index) AS `Current Month Accident`
        FROM roadrash
        GROUP BY 2, 1, 3
        ORDER BY 2, 1
    ) x
    ORDER BY `Year`, `Month Number`
)
SELECT *,
    IFNULL(CONCAT(ROUND(((`Current Month Accident` - `Previous Month Accident`) / `Previous Month Accident`) * 100, 2), " %"), 'No Record') AS Percentage_Increase
FROM Accident_Monthly_Comparison;
```
###  2. Number of Casualties in each Quarters of each year, and give the percentage change to the consecutive quarter:
``` sql WITH QuarterCasualties
AS (
    SELECT CONCAT (Year," Q",Quarter) AS Quarter,
          `Total Casualties`,
          LAG(`Total Casualties`) OVER (ORDER BY Year,Quarter) AS Prev_Quarter
    FROM (
        SELECT 
            YEAR(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Year,
            QUARTER(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Quarter,
            SUM(Number_of_Casualties) AS `Total Casualties`
        FROM roadrash
        GROUP BY Year, 2
    ) x
)
SELECT Quarter,
    `Total Casualties`,
    Prev_Quarter,
    CONCAT (ROUND(((`Total Casualties` - Prev_Quarter) / Prev_Quarter * 100), 2), " %") AS `Percentage Change`
FROM QuarterCasualties;
```
### 3. Side by side comparison of Total Casualties for different years Quarter wise:
``` sql
SELECT 
    CONCAT(" Q", a.Quarter) AS Quarter,
    a.`Total Casualties` AS Current_Quarter,
    b.`Total Casualties` AS Prev_Year_Quarter
FROM (
    SELECT 
        YEAR(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Year,
        QUARTER(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Quarter,
        COUNT(*) AS `Total Casualties`
    FROM roadrash
    GROUP BY Year, Quarter
) a
INNER JOIN (
    SELECT 
        YEAR(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Year,
        QUARTER(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Quarter,
        COUNT(*) AS `Total Casualties`
    FROM roadrash
    GROUP BY Year, Quarter
) b ON a.Quarter = b.Quarter AND a.Year = b.Year + 1
ORDER BY a.Year, a.Quarter;
```
## Severity Analysis
### 1. Check how much each severity contributes to the total accident, also display how much percent each severity accounts for total accidents.
``` sql 
SELECT 
    Accident_Severity,
    `Accidents per Severity`,
    CONCAT(ROUND(( `accidents per severity` / `total accidents` ) * 100, 1), " %") AS `Percent Contribution`
FROM (
    SELECT 
        accident_severity,
        COUNT(*) AS `Accidents per Severity`,
        (SELECT COUNT(*) FROM roadrash) AS `Total Accidents`
    FROM roadrash
    GROUP BY 1
) x
ORDER BY 2 DESC; 
```
### 2. Display which Road types contribute to a greater number of accidents.
``` sql
SELECT 
    Road_type,
    `Accidents per roadtype`,
    CONCAT(ROUND((`accidents per roadtype`/ `total accidents` ) * 100, 1), " %") AS `Percent Contribution`
FROM (
    SELECT 
        Road_type,
        COUNT(*) AS `Accidents per roadtype`,
        (SELECT COUNT(*) FROM roadrash) AS `Total Accidents`
    FROM roadrash
    GROUP BY 1
) x
ORDER BY 2 DESC; 
```
### 3. Display which Road surface condition contributes to more number of accidents:
``` sql
SELECT 
    Road_Surface_Conditions,
    `Accidents per Surface condition`,
    CONCAT(ROUND((`accidents per Surface condition`/ `total accidents` ) * 100, 1), " %") AS `Percent Contribution`
FROM (
    SELECT 
        Road_Surface_Conditions,
        COUNT(*) AS `Accidents per Surface condition`,
        (SELECT COUNT(*) FROM roadrash) AS `Total Accidents`
    FROM roadrash
    GROUP BY 1
) x
ORDER BY 2 DESC; 
```
## Junction Analysis:
### 1. Using the pivot, make a table with Junction detail as index (Row) and Junction Control as Column and value is the Number of Accidents.
``` sql
SELECT 
    Junction_Detail,
    SUM(CASE WHEN Junction_Control = 'Authorised Person' THEN `Number of Accidents` ELSE 0 END) AS 'Authorised Person',
    SUM(CASE WHEN Junction_Control = 'Auto traffic signal' THEN `Number of Accidents` ELSE 0 END) AS 'Auto Traffic Signal',
    SUM(CASE WHEN Junction_Control = 'Data missing or out of range' THEN `Number of Accidents` ELSE 0 END) AS 'Data Missing',
    SUM(CASE WHEN Junction_Control = 'Give way or uncontrolled' THEN `Number of Accidents` ELSE 0 END) AS 'Give way or uncontrolled',
    SUM(CASE WHEN Junction_Control = 'Not at junction or within 20 metres' THEN `Number of Accidents` ELSE 0 END) AS 'Not at junction nearby',
    SUM(CASE WHEN Junction_Control = 'Stop sign' THEN `Number of Accidents` ELSE 0 END) AS 'Stop Sign'
FROM (
    SELECT  
        Junction_Control, 
        Junction_Detail, 
        COUNT(*) as `Number of Accidents` 
    FROM roadrash
    GROUP BY 1,2
    ORDER BY 1
) x
GROUP BY 1;
```
## Road Surface Conditions VS Vehicle Types:
### 1. Display the Pivot Table that shows the index 
``` sql
SELECT 
    Vehicle_Type,
    SUM(CASE WHEN Road_Surface_Conditions = 'Dry' THEN `Total Casualties` ELSE 0 END) AS 'Dry',
    SUM(CASE WHEN Road_Surface_Conditions = 'Wet' THEN `Total Casualties` ELSE 0 END) AS 'Wet',
    SUM(CASE WHEN Road_Surface_Conditions = 'Frosty' THEN `Total Casualties` ELSE 0 END) AS 'Frosty',
    SUM(CASE WHEN Road_Surface_Conditions = 'Snowy' THEN `Total Casualties` ELSE 0 END) AS 'Snowy',
    SUM(CASE WHEN Road_Surface_Conditions = 'Damp' THEN `Total Casualties` ELSE 0 END) AS 'Damp',
    SUM(CASE WHEN Road_Surface_Conditions = 'Other' THEN `Total Casualties` ELSE 0 END) AS 'Other'
FROM (
    SELECT DISTINCT 
        Road_Surface_Conditions,
        Vehicle_Type,
        SUM(Number_of_Casualties) AS `Total Casualties` 
    FROM roadrash
    GROUP BY 1,2
    ORDER BY 1
) x
GROUP BY 1;
```
## Weather Impact
### 1. Check if the weather condition has an impact on the accident rates and which weather condition is associated with higher accident numbers
``` sql
SELECT 
    Weather_Conditions,
    COUNT(*) as `Total Accidents`,
    SUM(Number_of_Casualties) as `Total Casualties`
FROM roadrash
GROUP BY 1
ORDER BY 2 DESC;
```
### 1. Display the Day-wise total accidents happening in Rural and Urban areas: 
``` sql
SELECT 
    `No`, 
    Day,
    SUM(CASE WHEN Urban_or_Rural_Area = 'Urban' THEN `Total Accidents` ELSE 0 END) as 'Urban',
    SUM(CASE WHEN Urban_or_Rural_Area = 'Rural' THEN `Total Accidents` ELSE 0 END) as 'Rural'
FROM (
    SELECT
        CASE 
            WHEN Day_of_Week='Sunday' THEN 1
            WHEN Day_of_Week='Monday' THEN 2
            WHEN Day_of_Week='Tuesday' THEN 3
            WHEN Day_of_Week='Wednesday' THEN 4
            WHEN Day_of_Week='Thursday' THEN 5
            WHEN Day_of_Week='Friday' THEN 6
            WHEN Day_of_Week='Saturday' THEN 7
        END as `No`,
        Urban_or_Rural_Area, 
        Day_of_Week as `Day`,
        COUNT(*) AS `Total Accidents`
    FROM roadrash
    GROUP BY 1, 2, 3
    ORDER BY 2, 1
) day_area
GROUP BY 1,2
ORDER BY 1;
```
## Window Function Ranking:
### 1. Rank the top 3 police forces with the highest average number of casualties per accident.
``` sql
SELECT 
    Police_Rank as `Police Ranking`, 
    `Police Force`, 
    `Number of Casualties`
FROM (
    SELECT 
        police_force AS `Police Force`,
        SUM(Number_of_Casualties) AS `Number of Casualties`,
        ROW_NUMBER() OVER (ORDER BY SUM(Number_of_Casualties) DESC) AS Police_Rank
    FROM roadrash
    GROUP BY 1
    ORDER BY 3
) x
WHERE Police_Rank <= 3
ORDER BY Police_Rank;
```



## Temporal Window Function:
### 1. Calculate Monthly Rolling Average of Casualties, Segregated by Year
``` sql
WITH MonthCasualties AS (
    SELECT
        MONTH(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS `No`,
        MONTHNAME(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS `Month`,
        YEAR(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS `Year`,
        SUM(Number_of_Casualties) AS `Casualties`
    FROM roadrash
    GROUP BY 1, 2, 3
    ORDER BY 3, 1
)
SELECT
    `Month`,
    `Year`,
    `Casualties`,
    AVG(`Casualties`) OVER (PARTITION BY `Year` ORDER BY `Year` ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS `Running Average`
FROM MonthCasualties
ORDER BY 2, `No`;
```
## Categorical Analysis:

### 1. Display number of accidents happen in Urban and Rural region separately at different periods in a day.
``` sql
SELECT 
    Urban_or_Rural_Area as 'Region',
    SUM(CASE WHEN Time > '00:00' AND Time < '12:00' THEN `Number of Accidents` ELSE 0 END) as 'Morning Time',
    SUM(CASE WHEN Time >= '12:00' AND Time < '17:00' THEN `Number of Accidents` ELSE 0 END) as 'Afternoon Time',
    SUM(CASE WHEN Time >= '17:00' AND Time <= '23:59' THEN `Number of Accidents` ELSE 0 END) as 'Evening Time'
FROM (
    SELECT 
        Time, 
        Urban_or_Rural_Area, 
        COUNT(*) AS `Number of Accidents`
    FROM roadrash
    GROUP BY 1,2
    ORDER BY 1
) x
GROUP BY 1;
```
 ### 2. Categorizing the Accident Type based on Accident Severity, Number of Casualties, and Number of Vehicles:
``` sql
SELECT 
    `Accident Intensity`, 
    COUNT(*) AS `Accidents`,
    carriageway_Hazards,
    SUM(Number_of_Casualties) AS `Casualties`,
    SUM(Number_of_Vehicles) AS `Vehicles involved`
FROM (
    SELECT 
        Accident_Severity,
        Number_of_Casualties,
        Number_of_Vehicles,
        carriageway_Hazards,
        CASE
            WHEN Number_of_Casualties BETWEEN 0 AND 0 AND Number_of_Vehicles BETWEEN 1 AND 2 THEN 'Minor Incidents'
            WHEN Number_of_Casualties BETWEEN 0 AND 1 AND Number_of_Vehicles BETWEEN 2 AND 3 THEN 'Moderate Collisions'
            WHEN Number_of_Casualties BETWEEN 1 AND 2 AND Number_of_Vehicles BETWEEN 1 AND 3 THEN 'Severe Crashes'
            WHEN Number_of_Casualties BETWEEN 3 AND 8 AND Number_of_Vehicles BETWEEN 1 AND 6 THEN 'Fatal Accidents'
            WHEN Number_of_Casualties BETWEEN 5 AND 15 AND Number_of_Vehicles BETWEEN 3 AND 10 THEN 'Multi-Vehicle Collisions'
            WHEN Number_of_Casualties BETWEEN 0 AND 2 AND Number_of_Vehicles BETWEEN 1 AND 2 THEN 'Single-Vehicle Incidents'
            WHEN Number_of_Casualties BETWEEN 0 AND 1 AND Number_of_Vehicles BETWEEN 1 AND 5 THEN 'Property Damage Only'
            WHEN Number_of_Casualties BETWEEN 0 AND 2 AND Number_of_Vehicles BETWEEN 3 AND 7 THEN 'Major Traffic Incidents'
            WHEN Number_of_Casualties BETWEEN 0 AND 6 AND Number_of_Vehicles BETWEEN 2 AND 8 THEN 'Intersection Accidents'
            WHEN Number_of_Casualties BETWEEN 2 AND 12 AND Number_of_Vehicles BETWEEN 2 AND 10 THEN 'Highway Crashes'
            WHEN Number_of_Casualties BETWEEN 8 AND 21 AND Number_of_Vehicles BETWEEN 3 AND 12 THEN 'High Casualty Intersection'
            WHEN Number_of_Casualties BETWEEN 15 AND 27 AND Number_of_Vehicles BETWEEN 8 AND 19 THEN 'Major Highway Carnage'
            WHEN Number_of_Casualties >= 27 AND Number_of_Vehicles >= 19 THEN 'Massive Pileup'
            WHEN Number_of_Casualties BETWEEN 10 AND 27 AND Number_of_Vehicles BETWEEN 4 AND 9 THEN 'Pedestrian Disaster'
            WHEN Number_of_Casualties BETWEEN 15 AND 27 AND Number_of_Vehicles BETWEEN 13 AND 19 THEN 'Catastrophic Rollover'
            WHEN Number_of_Casualties BETWEEN 24 AND 27 AND Number_of_Vehicles BETWEEN 8 AND 12 THEN 'Bus Catastrophe'
            WHEN Number_of_Casualties BETWEEN 19 AND 27 AND Number_of_Vehicles BETWEEN 1 AND 4 THEN 'Train Collision'
            ELSE 'Unknown Intensity'
        END AS `Accident Intensity`
    FROM roadrash
) x
GROUP BY 1,3
ORDER BY 2 DESC;
```


```
