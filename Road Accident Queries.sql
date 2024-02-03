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


select distinct Road_Surface_Conditions from roadrash;