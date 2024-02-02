use roadaccidents;
show tables;


-- Average number of Casulaties in accidents:



-- Check how much each Category contributes to the Total accidents. Show the Percentage Contribution for each category.

select Accident_Severity,`Accidents per Severity`,
      concat(round((`Accidents per Severity` / `Total Accidents`)*100,2)," %") as `Percent Contribution`
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
lag(`Current Month Accident`) over(order by `Month Number`) as `Previous Month Accident`
from 
(
select month(str_to_date(`Accident Date`,'%d-%m-%Y')) as `Month Number`,
	   monthname(str_to_date(`Accident Date`,'%d-%m-%Y')) as Month,
       count(Accident_Index) as `Current Month Accident`
from roadrash
group by 1,2
order by 1
)x
order by `Month Number`
)

select *,
ifnull(concat(round(((`Current Month Accident`-`Previous Month Accident`)/`Current Month Accident`) * 100,2)," %" ),'No Value') as Percentage_Increase
from Accident_Monthly_Comparison;



