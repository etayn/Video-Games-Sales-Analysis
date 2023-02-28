/*

Queries for data visualization

*/


-- Best Selling game for each platform 

select t1.name , t1.Platform ,t1.Global_Sales
from vgsales as t1
inner join (select Platform , max(Global_Sales) as MaxSales from vgsales group by Platform) as t2
on t1.Platform = t2.Platform and t1.Global_Sales = t2.MaxSales
order by 3 desc

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


-- Faviorate platform for each publisher

with PublisherPlatform as (
select Publisher , Platform , count(*) as GamesPublisherPlatform , 
       sum(count(*)) over (partition by Publisher) as GamesPublisher
from vgsales
group by Publisher , Platform
) select *  , GamesPublisherPlatform * 100 / GamesPublisher as PublisherPlatformRatio
from PublisherPlatform
order by 1


-- What year each platform was launched

select distinct(Platform) , FIRST_VALUE(year) over(partition by Platform order by year) as LaunchDate
from vgsales
where Year is not null
order by 2

-- Genres count time series 

select Genre , Year , count(*) as NumberOfGames
from vgsales
where year is not null
group by Genre , Year
order by Year


--  top 5 best selling game globaly

select top(5) Name , sum(Global_Sales) TotalGlobalSales
from vgsales
group by Name
order by 2 desc

-- Most popular genre to make for each publisher 

with GenrePublisher as (
select Publisher , Genre , count(*) as GamesGenrePublisher , sum(count(*)) over(partition by Publisher) as GamesPublisher
from vgsales
group by Publisher , Genre
) select * , GamesGenrePublisher * 100 / GamesPublisher as GenrePublisherRatio
from GenrePublisher
where GamesPublisher > 100
order by Publisher 
