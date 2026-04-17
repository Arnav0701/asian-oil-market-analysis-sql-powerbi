											#handling of datatypes.

create database global_oil_price;

use global_oil_price;


# imported tables using table data import wizard.

# [1] CLEANING AND DATATYPE ADJUSTMENT of asia_fuel_prices_detailed
show tables;

select * from asia_fuel_prices_detailed;

describe asia_fuel_prices_detailed;


update asia_fuel_prices_detailed
set price_date = str_to_date(price_date, '%Y-%m-%d');

alter table asia_fuel_prices_detailed
modify column price_date date;

alter table asia_fuel_prices_detailed
modify column country varchar(255);

alter table asia_fuel_prices_detailed
modify column sub_region varchar(255);

alter table asia_fuel_prices_detailed
modify column iso3 varchar(255);

select sum(case when country is null then 1 else 0 end) as country,
	sum(case when sub_region is null then 1 else 0 end) as sub_region,
    sum(case when iso3 is null then 1 else 0 end) as iso3,
    sum(case when gasoline_usd_per_liter is null then 1 else 0 end) as gasoline_usd_per_liter,
    sum(case when diesel_usd_per_liter is null then 1 else 0 end) as diesel_usd_per_liter,
    sum(case when lpg_usd_per_kg is null then 1 else 0 end) as lpg_usd_per_kg,
    sum(case when avg_monthly_income_usd is null then 1 else 0 end) as avg_monthly_income_usd,
    sum(case when fuel_affordability_index is null then 1 else 0 end) as fuel_affordability_index,
    sum(case when oil_import_dependency_pct is null then 1 else 0 end) as oil_import_dependency_pct,
    sum(case when refinery_capacity_kbpd is null then 1 else 0 end) as refinery_capacity_kbpd,
    sum(case when ev_adoption_pct is null then 1 else 0 end) as ev_adoption_pct,
    sum(case when fuel_subsidy_active is null then 1 else 0 end) as fuel_subsidy_active,
    sum(case when subsidy_cost_bn_usd is null then 1 else 0 end) as subsidy_cost_bn_usd,
    sum(case when co2_transport_mt is null then 1 else 0 end) as co2_transport_mt,
    sum(case when price_date is null then 1 else 0 end) as price_date,
    sum(case when gasoline_pct_daily_wage is null then 1 else 0 end) as gasoline_pct_daily_wage
from asia_fuel_prices_detailed;

describe asia_fuel_prices_detailed;

alter table asia_fuel_prices_detailed
modify column gasoline_usd_per_liter decimal(10,2);

alter table asia_fuel_prices_detailed
modify column diesel_usd_per_liter decimal(10,2),
modify column lpg_usd_per_kg decimal(10,2),
modify column avg_monthly_income_usd decimal(10,2),
modify column fuel_affordability_index decimal(10,2),
modify column oil_import_dependency_pct int,
modify column refinery_capacity_kbpd int,
modify column ev_adoption_pct decimal(10,2),
#modify column fuel_subsidy_active decimal,
modify column subsidy_cost_bn_usd decimal(10,2),
modify column co2_transport_mt decimal(10,2),
modify column gasoline_pct_daily_wage decimal(10,2)
;

alter table asia_fuel_prices_detailed
modify column fuel_subsidy_active varchar(20);

select distinct fuel_subsidy_active from asia_fuel_prices_detailed;

update asia_fuel_prices_detailed
set fuel_subsidy_active = case when fuel_subsidy_active = 'True' then 1
								when fuel_subsidy_active = 'False' then 0
							end;
                            
alter table asia_fuel_prices_detailed
modify column fuel_subsidy_active tinyint(1);


alter table asia_subsidy_tracker
modify column country varchar(255),
modify column iso3 varchar(255),
#gasoline_subsidized
#diesel_subsidized
#subsidy type
modify column annual_subsidy_cost_bn_usd decimal(10,2),
modify column subsidy_pct_gdp decimal(10,2),
modify column subsidy_description varchar(500),
modify column last_price_change varchar(255),
modify column pricing_mechanism varchar(300),
modify column regulator varchar(255);

alter table asia_fuel_prices_detailed
rename column sub_region to region;

# [2] CLEANING AND DATATYPE ADJUSTMENT of asia_subsidy_tracker

select * from asia_subsidy_tracker;

describe asia_subsidy_tracker;

update asia_subsidy_tracker
set last_price_change = str_to_date(last_price_change,'%Y-%m-%d');

alter table asia_subsidy_tracker
modify column last_price_change date;

alter table asia_subsidy_tracker
modify column annual_subsidy_cost_bn_usd decimal(10,2);

alter table asia_subsidy_tracker
modify column subsidy_pct_gdp decimal(10,2);

update asia_subsidy_tracker
set gasoline_subsidized = case when gasoline_subsidized = "True" then 1
								when gasoline_subsidized = "False" then 0 end;
                                
alter table asia_subsidy_tracker modify column gasoline_subsidized tinyint(1);

update asia_subsidy_tracker
set diesel_subsidized = case when diesel_subsidized = "True" then 1
								when diesel_subsidized = "False" then 0 end;
              
alter table asia_subsidy_tracker modify column diesel_subsidized tinyint(1);              
              
select distinct subsidy_type from asia_subsidy_tracker;

alter table asia_subsidy_tracker modify column subsidy_type varchar(255);


# [3] CLEANING AND DATATYPE ADJUSTMENT of crude_oil_annual

select * from crude_oil_annual;

describe crude_oil_annual;

alter table crude_oil_annual
rename column `year` to `years`;

alter table crude_oil_annual
modify column brent_avg_usd_bbl decimal(10,2),
modify column wti_avg_usd_bbl decimal(10,2),
modify column brent_yoy_change_pct decimal(10,2),
modify column wti_yoy_change_pct decimal(10,2),
modify column key_event varchar(255),
modify column brent_wti_spread decimal(10,2),
modify column avg_price_usd_bbl decimal(10,2);


# [4] CLEANING AND DATATYPE ADJUSTMENT of fuel_tax_comparison

select * from fuel_tax_comparison;

describe fuel_tax_comparison;

alter table fuel_tax_comparison
modify column country varchar(255),
modify column region varchar(255),
modify column gasoline_tax_pct int,
modify column diesel_tax_pct int,
modify column vat_pct int,
modify column excise_usd_per_liter decimal(10,2),
modify column carbon_tax_active tinyint(1),
modify column total_tax_usd_per_liter decimal(10,2),
modify column tax_burden_category varchar(255);

update fuel_tax_comparison
set carbon_tax_active = case when carbon_tax_active = "True" then 1
							when carbon_tax_active = "False" then 0 end;
                            
select distinct country from asia_fuel_prices_detailed where country  in (select distinct country from asia_subsidy_tracker);


describe fuel_tax_comparison;

select distinct country, region
from fuel_tax_comparison
where country not in (select
					distinct t1.country 
				from asia_fuel_prices_detailed t1 
					join 
                    asia_subsidy_tracker t2 on t1.country=t2.country);
                    

# [5] CLEANING AND DATATYPE ADJUSTMENT of global_fuel_prices

select * from global_fuel_prices;

describe global_fuel_prices;

alter table global_fuel_prices
modify column country varchar(255),
modify column region varchar(255),
modify column iso3 varchar(50),
modify column gasoline_usd_per_liter decimal(10,2),
modify column diesel_usd_per_liter decimal(10,2),
modify column local_currency varchar(50),
modify column gasoline_local_price decimal(10,2),
modify column diesel_local_price decimal(10,2),
modify column is_asian int,
modify column avg_fuel_usd decimal(10,2)
;

select distinct country from global_fuel_prices;

select
count(255),
count(region),
count(iso3),
count(gasoline_usd_per_liter),
count(diesel_usd_per_liter),
count(local_currency),
count(gasoline_local_price),
count(diesel_local_price),
count(is_asian),
count(avg_fuel_usd)
from global_fuel_prices;


# [6] CLEANING AND DATATYPE ADJUSTMENT of price_trend_monthly

select * from price_trend_monthly;

describe price_trend_monthly;

update price_trend_monthly
set `date` = str_to_date(`date`,'%Y-%m-%d');

alter table price_trend_monthly
modify column `date` date;

alter table price_trend_monthly
add column year_date year;

update price_trend_monthly
set `month` = month(`date`);

alter table price_trend_monthly
modify column region varchar(255);

alter table price_trend_monthly
rename column `month` to month_date;

alter table price_trend_monthly
modify column mom_change_pct decimal(10,2);
describe price_trend_monthly;

update price_trend_monthly
set yoy_change_pct = case when yoy_change_pct = '' then null
							else yoy_change_pct end;
                            
select count(yoy_change_pct) from price_trend_monthly;

describe price_trend_monthly;

alter table price_trend_monthly
modify column mom_change_pct decimal(10,2);

alter table price_trend_monthly
modify column yoy_change_pct decimal(10,2);

update price_trend_monthly
set month_date = month(dates);

alter table price_trend_monthly
modify column month_date tinyint(1);
