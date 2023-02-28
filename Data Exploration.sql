/* 

Data Exploration

skill used: Aggregate Functions, Updating tables, Case when, CTE, Unpivot, Joins, Windows Functions
*/


/* 
Checking Platform count to see misspellings. Result - No misspellings, all platforms are unique, but i gonna change
 2600 into atari
*/

select Platform , count(Platform) as CountPlatform
from vgsales
group by Platform
order by CountPlatform desc

update vgsales
set Platform = case when Platform = '2600' then 'Atari'
					else Platform end 	

-- Checking genre count to see misspellings. Result - No misspellings, all genres are unique

select Genre , count(Genre) as CountGenre
from vgsales
group by Genre
order by CountGenre desc


-- Checking publisher count to see misspellings. Result - we have N/A and unknown, so i will combine them

select Publisher , count(Publisher) as CountPublisher
from vgsales
group by Publisher
order by CountPublisher desc

-- Combining N/A and unknown

update vgsales
set Publisher = case when Publisher = 'N/A' then 'Unknown'
				else Publisher end 

-- Global analysis
--Number of games, sum of global sales and average of global sales per platfrom

select Platform ,  count(*) as NumberofGames , round(SUM(Global_Sales),2) as SumSales , 
round(avg(Global_Sales),2 )  as AverageSales 
from vgsales
group by Platform
order by 3 desc

--Number of games, sum of global sales and average of global sales per genre

select Genre ,  count(*) as NumberofGames , round(SUM(Global_Sales),2) as SumSales , 
round(avg(Global_Sales),2) as AverageSales
from vgsales
group by Genre
order by 3 desc

--Number of games, sum of global sales and average of global sales per Publisher

select Publisher ,  count(*) as NumberofGames , round(SUM(Global_Sales),2) as SumSales , 
round(avg(Global_Sales),2) as AverageSales
from vgsales
group by Publisher
order by 3 desc

/*
Number of games, sum of global sales and average of global sales per year. Note - There are over 200 rows with year as
NULL with no some rule applied to them, the games are from different years
*/

select Year ,  count(*) as NumberofGames , round(SUM(Global_Sales),2) as SumSales , 
round(avg(Global_Sales),2) as AverageSales
from vgsales
where year is not null
group by Year
order by 3 desc


-- Lets  move to cross analysis between categorical features

-- Most popular genre to make for each publisher 

with GenrePublisher as (
select Publisher , Genre , count(*) as GamesGenrePublisher , sum(count(*)) over(partition by Publisher) as GamesPublisher
from vgsales
group by Publisher , Genre
) select * , GamesGenrePublisher * 100 / GamesPublisher as GenrePublisherRatio
from GenrePublisher
where GamesPublisher > 100
order by Publisher 


-- Genres count time series 

select Genre , Year , count(*) as NumberOfGames
from vgsales
where year is not null
group by Genre , Year
order by Year

-- What year each publisher first published a game

select distinct(Publisher) , FIRST_VALUE(year) over(partition by Publisher order by year) as FirstGame
from vgsales
where year is not null
order by 2

-- Number of published game per publisher for each year time series

select Publisher , Year , count(*) as NumberOfGames
from vgsales
where Year is not null
group by Publisher , Year
order by 1 


-- What year each platform was launched

select distinct(Platform) , FIRST_VALUE(year) over(partition by Platform order by year) as LaunchDate
from vgsales
where Year is not null
order by 2

-- Number of published game per platform for each year time series

select Platform , Year , count(*) as NumberOfGames
from vgsales
where Year is not null
group by Platform , Year
order by 1 


-- Faviorate platform for each publisher

with PublisherPlatform as (
select Publisher , Platform , count(*) as GamesPublisherPlatform , 
       sum(count(*)) over (partition by Publisher) as GamesPublisher
from vgsales
group by Publisher , Platform
) select *  , GamesPublisherPlatform * 100 / GamesPublisher as PublisherPlatformRatio
from PublisherPlatform
order by 1

-- number of exlusive games per platform

with GamesExlusiveFilter as (
select Name , COUNT(Name) as GameCount
from vgsales
group by Name
having COUNT(Name) = 1
) select Platform , COUNT(*) as ExlusivesCount
from vgsales 
where Name in (select Name from GamesExlusiveFilter)
group by Platform
order by 2 desc

-- Lets move to specific games

-- Best selling games globaly

select Name , sum(Global_Sales) TotalGlobalSales
from vgsales
group by Name
order by 2 desc

-- Best Selling game for each region using CTE and UNPIVOT

with maxsellinggames as (
select Name , Region , Sales 
from vgsales
unpivot (sales for region in (NA_Sales , EU_Sales , JP_Sales , Other_Sales , Global_Sales)) as unpvt
), regionmaxsales as ( select region, max(sales) as MaxSales 
from maxsellinggames
group by region
)
 select Name , maxsellinggames.region , sales
from maxsellinggames
join regionmaxsales
on maxsellinggames.region = regionmaxsales.region and maxsellinggames.sales = regionmaxsales.MaxSales
order by 3 desc


-- Best Selling game for each platform using INNER JOIN

select t1.name , t1.Platform ,t1.Global_Sales
from vgsales as t1
inner join (select Platform , max(Global_Sales) as MaxSales from vgsales group by Platform) as t2
on t1.Platform = t2.Platform and t1.Global_Sales = t2.MaxSales
order by 3 desc

