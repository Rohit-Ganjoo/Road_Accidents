use roadaccidents;

show tables;

-- Average number of Casulaties in accidents:
select speed_limit, avg(Number_of_casualties) 
from roadrash
group by 1
order by 1;

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
			,sum(Number_of_Casualties) AS `Total Casualties`
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




