use roadaccidents;

show tables;


-- Average number of Casulaties in accidents:



-- Check how much each Category contributes to the Total accidents. Show the Percentage for each category.

select Accident_Severity,`Accidents per Severity`,
      concat(round((`Accidents per Severity` / `Total Accidents`)*100,1)," %") as `Percent Contribution`
from (
    select Accident_Severity, count(*) as `Accidents per Severity`,
    (Select count(*) from roadrash) as `Total Accidents`
    from roadrash
    group by  1
) x
order by 2 desc;


-- Display the Month on Month change in the Accident Rate, along with that display the Current Month Accidents and Previous Month Accidents. 
with Accident_Monthly_Comparison as 
(
select *,
lag(`Current Month Accident`) over(order by `Year`,`Month Number`) as `Previous Month Accident`
from 
(
select month(str_to_date(`Accident Date`,'%d-%m-%Y')) as `Month Number`,
		year(str_to_date(`Accident Date`,'%d-%m-%Y')) as `Year`,
	   monthname(str_to_date(`Accident Date`,'%d-%m-%Y')) as Month,
       count(Accident_Index) as `Current Month Accident`
from roadrash
group by 2,1,3
order by 2,1
)x
order by `Year`,`Month Number`
)
select *,
ifnull(concat(round(((`Current Month Accident`-`Previous Month Accident`)/`Previous Month Accident`) * 100,2)," %" ),'No Record') as Percentage_Increase
from Accident_Monthly_Comparison;

-- Number of Casualties in each Quarters of each year:

select concat(Year," Q",Quarter) as Quarter,
 `Total Casualties`,
 lag(`Total Casualties`) over(order by Year,Quarter) as Prev_Quarter
 from
(
select 
year(str_to_date(`Accident Date`,'%d-%m-%Y')) as Year,
Quarter(str_to_date(`Accident Date`,'%d-%m-%Y')) as Quarter,
count(*) as `Total Casualties`
from roadrash
group by year,2
)x;


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

