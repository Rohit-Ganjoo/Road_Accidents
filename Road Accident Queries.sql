-- Spatial Analysis
-- Top 10 Districts that have high accidents:
SELECT `Local_Authority_(District)`, count(*)
FROM roadrash
GROUP BY 1
ORDER BY 2 DESC
LIMIT 10;


-- Temporal Analysis:
-- Display the Month on Month change in the Accident Rate, along with that display the Current Month Accidents and Previous Month Accidents.
WITH Accident_Monthly_Comparison
AS (
	SELECT *,
			lag(`Current Month Accident`) OVER (ORDER BY `Year`,`Month Number`) AS `Previous Month Accident`
	FROM (
		SELECT month(str_to_date(`Accident Date`, '%d-%m-%Y')) AS `Month Number`
			,year(str_to_date(`Accident Date`, '%d-%m-%Y')) AS `Year`
			,monthname(str_to_date(`Accident Date`, '%d-%m-%Y')) AS Month
			,count(Accident_Index) AS `Current Month Accident`
		FROM roadrash
		GROUP BY 2,1,3
		ORDER BY 2,1
		) x
	ORDER BY `Year`,`Month Number`
	)
SELECT *,
		IFNULL(CONCAT(round(((`Current Month Accident` - `Previous Month Accident`) / `Previous Month Accident`) * 100, 2)," %"), 'No Record') AS Percentage_Increase
FROM Accident_Monthly_Comparison;



-- Number of Casualties in each Quarters of each year, and give the percentage change to the consecutive quarter:
WITH QuarterCasualties
AS (
	SELECT CONCAT (Year," Q",Quarter) AS Quarter
		  ,`Total Casualties`
		  ,lag(`Total Casualties`) OVER (ORDER BY Year,Quarter) AS Prev_Quarter
	FROM (
		SELECT year(str_to_date(`Accident Date`, '%d-%m-%Y')) AS Year
			,Quarter(str_to_date(`Accident Date`, '%d-%m-%Y')) AS Quarter
			,SUM(Number_of_Casualties) AS `Total Casualties`
		FROM roadrash
		GROUP BY year,2) x
	     )
SELECT Quarter
	,`Total Casualties`
	,Prev_Quarter
	,CONCAT (round(((`Total Casualties` - Prev_Quarter) / Prev_Quarter * 100), 2)," %") AS `Percentage Change`
FROM QuarterCasualties;


-- Side by side comparison of Total Casualties for different years Quarterwise:
SELECT 
    CONCAT(" Q", a.Quarter) AS Quarter,
    a.`Total Casualties` AS Current_Quarter,
    b.`Total Casualties` AS Prev_Year_Quarter
FROM
(
    SELECT 
        YEAR(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Year,
        QUARTER(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Quarter,
        COUNT(*) AS `Total Casualties`
    FROM roadrash
    GROUP BY Year, Quarter
) a
INNER JOIN
(
    SELECT 
        YEAR(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Year,
        QUARTER(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS Quarter,
        COUNT(*) AS `Total Casualties`
    FROM roadrash
    GROUP BY Year, Quarter
) b ON a.Quarter = b.Quarter AND a.Year = b.Year + 1
ORDER BY a.Year, a.Quarter;


--Severity Analysis
-- Check how much each severity contribute to the total accident, also display the how much percent each severity accounts for total accidents.

SELECT Accident_Severity,
       `Accidents per Severity`,
       Concat(Round(( `accidents per severity` / `total accidents` ) * 100, 1)," %") AS `Percent Contribution`
FROM   (SELECT accident_severity,
               Count(*) AS `Accidents per Severity`,
               (SELECT Count(*)
                FROM   roadrash) AS `Total Accidents`
        FROM   roadrash
        GROUP  BY 1) x
ORDER  BY 2 DESC; 


-- Display which Road_types contributes to more number of accidents
SELECT Road_type,
       `Accidents per roadtype`,
       Concat(Round((`accidents per roadtype`/ `total accidents` ) * 100, 1)," %") AS `Percent Contribution`
FROM   (SELECT Road_type,
               Count(*) AS `Accidents per roadtype`,
               (SELECT Count(*)
                FROM   roadrash) AS `Total Accidents`
        FROM   roadrash
        GROUP  BY 1) x
ORDER  BY 2 DESC; 

-- Display which Road surface condition contributes to more number of accidents:
SELECT Road_Surface_Conditions,
       `Accidents per Surface condition`,
       Concat(Round((`accidents per Surface condition`/ `total accidents` ) * 100, 1)," %") AS `Percent Contribution`
FROM   (SELECT Road_Surface_Conditions,
               Count(*) AS `Accidents per Surface condition`,
               (SELECT Count(*)
                FROM   roadrash) AS `Total Accidents`
        FROM   roadrash
        GROUP  BY 1) x
ORDER  BY 2 DESC; 


--Junction Analysis:
-- using the pivot, make a table with Junction detail as index(Row) and Junction Control as Column and value is the Number of Accidents.

SELECT Junction_Detail,
SUM(case when Junction_Control = 'Authorised Person' THEN `Number of Accidents` ELSE 0 END) AS 'Authorised Person',
SUM(case when Junction_Control = 'Auto traffic signal' THEN `Number of Accidents` ELSE 0 END) AS 'Auto Traffic Signal',
SUM(case when Junction_Control = 'Data missing or out of range' THEN `Number of Accidents` ELSE 0 END) AS 'Data Missing',
SUM(case when Junction_Control = 'Give way or uncontrolled' THEN `Number of Accidents` ELSE 0 END) AS 'Give way or uncontrolled',
SUM(case when Junction_Control = 'Not at junction or within 20 metres' THEN `Number of Accidents` ELSE 0 END) AS 'Not at junction nearby',
SUM(case when Junction_Control = 'Stop sign' THEN `Number of Accidents` ELSE 0 END) AS 'Stop Sign'
FROM
(
SELECT  Junction_Control, Junction_Detail,count(*) as `Number of Accidents` 
FROM roadrash
GROUP BY 1,2
ORDER BY 1
)x
group by 1;

-- Road Surface Conditions VS Vehicle Types :
-- Display the Pivot Table, that shows the index 
SELECT Vehicle_Type,
SUM(case when Road_Surface_Conditions = 'Dry' THEN `Total Casualties` ELSE 0 END) AS 'Dry',
SUM(case when Road_Surface_Conditions = 'Wet' THEN `Total Casualties` ELSE 0 END) AS 'Wet',
SUM(case when Road_Surface_Conditions = 'Frosty' THEN `Total Casualties` ELSE 0 END) AS 'Frosty',
SUM(case when Road_Surface_Conditions = 'Snowy' THEN `Total Casualties` ELSE 0 END) AS 'Snowy',
SUM(case when Road_Surface_Conditions = 'Damp' THEN `Total Casualties` ELSE 0 END) AS 'Damp',
SUM(case when Road_Surface_Conditions = 'Other' THEN `Total Casualties` ELSE 0 END) AS 'Other'
FROM
(
select distinct Road_Surface_Conditions,Vehicle_Type,sum(Number_of_Casualties) as `Total Casualties` 
from roadrash
group by 1,2
order by 1
)x
GROUP BY 1;

-- Weather Impact
-- Check if the weather condition has impact on the accident rates and which weather condition associated with higher accidents numbers
SELECT Weather_Conditions,
       count(*) as `Total Accidents`,
       sum(Number_of_Casualties) as `Total Casualties`
FROM roadrash
group by 1
order by 2 DESC;


-- Display the Day-wise total accidents happen in Rural and Urban area: 
SELECT `No`, 
        Day,
        SUM(case when Urban_or_Rural_Area = 'Urban' THEN `Total Accidents` Else 0 END) as 'Urban',
        SUM(case when Urban_or_Rural_Area = 'Rural' THEN `Total Accidents` Else 0 END)as 'Rural'
from 
(
SELECT
    CASE WHEN Day_of_Week='Sunday' THEN 1
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
FROM
    roadrash
GROUP BY
    1, 2,3
ORDER BY 2,1
) day_area
group by 1,2
order by 1;


-- Window Function Ranking:
-- Rank the top 3 police forces with the highest number of casualties per accident.

SELECT Police_Rank AS `Police Ranking`, `Police Force`, `Casualties per Accident`
FROM
(
SELECT 
    police_force AS `Police Force`,
    SUM(Number_of_Casualties)/COUNT(*) AS `Casualties per Accident`,
    ROW_NUMBER() OVER (ORDER BY SUM(Number_of_Casualties)/COUNT(*) DESC) AS Police_Rank
FROM roadrash
GROUP BY 1
ORDER BY 3
)x
WHERE Police_Rank <= 3
ORDER BY Police_Rank;





-- Regular Expression Filtering:
-- Extract and analyze accidents occurring in urban areas during the evening (5 PM to 8 PM).

Select Urban_or_Rural_Area as 'Region',
sum(case when Time > '00:00' and Time < '12:00' then `Number of Accidents` else 0 end) as 'Morning Time',
sum(case when Time >= '12:00' and Time < '17:00' then `Number of Accidents` else 0 end) as 'Afternoon Time',
sum(case when Time >= '17:00' and Time <= '23:59' then `Number of Accidents` else 0 end) as 'Evening Time'
from
(
select Time, Urban_or_Rural_Area, count(*) as `Number of Accidents`
from roadrash
group by 1,2
order by 1)x
Group by 1;



-- Temporal Window Function:
-- Calculate Monthly Rolling Average of Casualties, Segregated by Year
    WITH MonthCasualties AS (
    SELECT
        MONTH(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS `No`,
        MONTHNAME(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS `Month`,
        YEAR(STR_TO_DATE(`Accident Date`, '%d-%m-%Y')) AS `Year`,
        SUM(Number_of_Casualties) AS `Casualties`
    FROM
        roadrash
    GROUP BY
        1, 2, 3
    ORDER BY
        3, 1
)
SELECT
    `Month`,
    `Year`,
    `Casualties`,
    AVG(`Casualties`) OVER (Partition by `Year` ORDER BY `Year` ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS `Running Average`
FROM
    MonthCasualties
ORDER BY
    2, `No`;


-- Catagorising the Accident Type on the basis of Accident Severity, Number of Casualties, and Number of Vehicles:
select `Accident Intensity`, count(*) as `Accidents`,
        sum(Number_of_Casualties) as  `Casualties`,
        sum(Number_of_Vehicles) as `Vehicles involved`
from
(
SELECT 
    Accident_Severity,
    Number_of_Casualties,
    Number_of_Vehicles,
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
)x
Group by 1
order by 2 desc;

