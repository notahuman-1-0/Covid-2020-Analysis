select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations
--order by 3,4

--select data that we are going to be using
select Location,date, total_cases,new_cases,total_deaths,population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


--Looking at Total Cases v/s Total Deaths
-- shows the liklihood of death if u get in infected in India
select Location,date, total_cases, total_deaths,(total_deaths/total_cases)*100 as comparison
from PortfolioProject..CovidDeaths
where continent is not null and location like '%india%'
order by  5 DESC


--Looking at Total_Cases v/s Population
-- Shows what percentage of population got Covid
select Location,date,Population,total_cases,(total_cases/population)*100 as PercentagePopulation
from PortfolioProject..CovidDeaths
where continent is not null and location like '%india%'
order by 5 asc

--Highest Infection Rate (countries) compared to population
select Location,Population, MAX(total_cases) as HighestInfectionCount , (Max(total_cases)/population)*100 as PercentagePopulationInfected
from PortfolioProject..CovidDeaths
--where continent is not null and location like '%india%'
group by Location,Population
order by PercentagePopulationInfected desc


--Countries with highest death count
select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null 
group by Location
order by TotalDeathCount desc


-- Actual correct numbers for the below scenario
select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is null 
group by Location
order by TotalDeathCount desc


--Let's break things down by Continents
--Showing the continents with the highest death counts

select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null 
group by continent
order by TotalDeathCount desc


-- To visualise the previous queries with continents just replace all the queries in the select statement and the group by statements by continents and not location


-- Global Numbers
 select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths ,SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Death_Percentage -- total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
 from PortfolioProject..CovidDeaths
 --where location like '%states%'
 where continent is not null
 group by date
 order by 1,2

 --Overall Total Cases
  select  SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths ,SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Death_Percentage -- total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
 from PortfolioProject..CovidDeaths
 --where location like '%states%'
 where continent is not null
 --group by date
 order by 1,2


 --Covid Vaccinations
select *
from PortfolioProject..CovidVaccinations





-- Join Covid Vaccinations & Covid Deaths
select *
from PortfolioProject..CovidDeaths dea -- Join Table 1 (alias)
Join PortfolioProject..CovidVaccinations vac --with Table 2 (alias)
	on dea.location = vac.location --  on meeting these conditions
	and dea.date = vac.date



--Looking for Total_Population v/s Vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))  OVER (Partition by dea.location order by dea.location) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100 thus gives an error because it is an newly created column
-- sum(convert(int,vac.new_vaccinations))-- 
from PortfolioProject..CovidDeaths dea -- Join Table 1 (alias)
Join PortfolioProject..CovidVaccinations vac --with Table 2 (alias)
	on dea.location = vac.location --  on meeting these conditions
	and dea.date = vac.date
where dea.continent is not NULL
order by 2,3



--Create an CTE stands for Common Table Expression a temporary named result set that you can reference within a SELECT, INSERT, UPDATE, or DELETE statement
with PopvsVac  (continent,Location,date,Population, New_Vaccinations,RollingPeopleVaccinated) 
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int))  OVER (Partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated
-- (RollingPeopleVaccinated/population)*100
-- sum(convert(int,vac.new_vaccinations))-- 
from PortfolioProject..CovidDeaths dea -- Join Table 1 (alias)
Join PortfolioProject..CovidVaccinations vac --with Table 2 (alias)
	on dea.location = vac.location --  on meeting these conditions
	and dea.date = vac.date
where dea.continent is not NULL
--order by 2,3
)

select *
from PopvsVac

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac






-- Method 2 for Rolling Vaccinated
-- Using Temp Table to perform Calculation on Partition By in previous query
-- TEMP Table
DROP table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location,dea.Date) as
RollingPeopleVaccinated --,(RollingPeopleVaccinated)*100
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated


--Creating View to store data for later part - Visualizations

Create View PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location,dea.Date) as
RollingPeopleVaccinated --,(RollingPeopleVaccinated)*100
from PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select *
from PercentPopulationVaccinated