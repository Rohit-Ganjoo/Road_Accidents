use roadaccidents;
show tables;
select `Accident Date` from roadrash;
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
concat(round(((`Current Month Accident`-`Previous Month Accident`)/ `Current Month Accident`) * 100,2)," %" )as Percentage_Increase
 from Accident_Monthly_Comparison;




