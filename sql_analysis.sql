use global_oil_price;

/* [1] How much of global fuel price change is passed to retail prices across countries? */

# due to missing data of diesel retail price of different countries we are evaluating this only for the gasoline. and using global price of brent crude
# formula change in retail price/ change in global crude

select country, year_date, price_effect
from(
select
	country,
    year_date,
    round((retail_l-lag(retail_l) over w)/nullif((brent_l-lag(brent_l) over w),0),2) as price_effect
from(select
		year_date,
		country,
		avg(gasoline_usd_per_liter) as retail_l,
		avg(brent_crude_usd_bbl)/159 as brent_l
	from 
		global_oil_price.v_price_trend_monthly
	group by 
		country, year_date)t
window w as (partition by country order by year_date))t
where price_effect is not null;



/* [2] Do higher fuel subsidies reduce the transmission and volatility of global oil price changes in domestic fuel markets? */

# The analysis is based on cross-sectional comparison of countries for year 2026 and only limited to the gasoline due to lack of data.

with country_2026 as (SELECT 
        country,
		year_date,
		AVG(gasoline_usd_per_liter) AS gasoline_p_liter,
		AVG(brent_crude_usd_bbl) / 159 AS brent_p_liter
    FROM
        v_price_trend_monthly
    WHERE
        year_date = '2026'
    GROUP BY country , year_date)
SELECT 
	t1.country,
   round( t1.gasoline_p_liter / nullif( t1.brent_p_liter, 0), 2) as `retail/global(usd)`,
   t3.gasoline_tax_pct,
   t2.subsidy_pct_gdp
FROM
    country_2026 t1
    join v_asia_subsidy_tracker t2 on t1.country = t2.country
    join
	v_fuel_tax_comparison t3 on t2.country = t3.country
order by
	t1.country;
    


/* [3] Are fuel prices across the 12 countries converging or diverging over time? */

# considering only gasoline

with yearly_data_country as (select
	 year_date,
	country,
    avg(gasoline_usd_per_liter) as country_yearly_avg
from
	v_price_trend_monthly t1
group by
	country, year_date
order by 
	year_date, country),
total_yearly_average as( select
		year_date,
		avg(gasoline_usd_per_liter) as total_yearly_avg
    from
		v_price_trend_monthly
	group by 
		year_date)
select
	year_date,
    round(avg(`sqr(change)`),2) as `divergence( stddev )`
from (select
	*,
    power(t.change_from_global_avg,2) as `sqr(change)`
from (select
    t2.year_date,
    t1.country,
    t2.total_yearly_avg,
    t1.country_yearly_avg,
    t2.total_yearly_avg - t1.country_yearly_avg as change_from_global_avg
from
	yearly_data_country t1
    join
    total_yearly_average t2 on t1.year_date = t2.year_date) t) t
group by
	year_date
    ;
     
    
    
/* [4] Is price volatility driven more by global price movement or domestic policy (tax/subsidy)? */

# considering only gasoline and brent crude.

with domestic_dev_yearly as ( select
	country,
	year_date,
    stddev(gasoline_usd_per_liter) as dev_gasoline,
    avg(gasoline_usd_per_liter) as avg_gasoline
from
	v_price_trend_monthly
group by
	country, year_date),
crude_dev as (select
	year_date,
    stddev((brent_crude_usd_bbl/159)) as dev_brent,
    avg((brent_crude_usd_bbl/159)) as avg_brent
from
	v_price_trend_monthly
group by
	year_date)
select
	t1.country,
	t1.year_date,
	-- round(t1.dev_gasoline,2) as `volatility_retail(absolute)`,
    -- round(t2.dev_brent,2) as `volatility_crude(absolute)`,
    round(t1.dev_gasoline/t1.avg_gasoline,2) as `volatility_retail(relative)`,
    round(t2.dev_brent/t2.avg_brent,2) as `volatility_crude(relative)`,
    round(t2.avg_brent - t1.avg_gasoline, 2) as `crude - retail`
from
	domestic_dev_yearly t1
    join
    crude_dev t2 on t1.year_date = t2.year_date
order by
	country,-- `volatility_retail(relative)`;
    year_date;
     
   
   
/* [5] Which countries systematically favor diesel over petrol (or vice versa) through taxation? */

with tax_diff as (
    select
        country,
        avg(gasoline_tax_pct - diesel_tax_pct) as avg_tax_diff
    from v_fuel_tax_comparison
    group by country
)
select
    country,
    round(avg_tax_diff, 3) as avg_tax_difference,
    case
        when avg_tax_diff > 0 then 'Favors Diesel (higher petrol tax)'
        when avg_tax_diff < 0 then 'Favors Petrol (higher diesel tax)'
        else 'Neutral'
    end as policy_bias
from tax_diff
order by avg_tax_difference desc;



/* [6] Which countries achieve lower prices despite moderate/high tax—indicating efficient pricing mechanisms? */

with cte as (select
	t1.tax_burden_category,
    avg(t2.gasoline_usd_per_liter) as categ_avg_gasoline
from
	v_fuel_tax_comparison t1
    join
    v_global_fuel_prices t2 on t1.country = t2.country
where
	t1.tax_burden_category in ('high','moderate')
group by
	t1.tax_burden_category)
select
	t1.tax_burden_category,
	t2.country,
    t2.gasoline_usd_per_liter,
    round(t1.categ_avg_gasoline, 2) as category_avg,
    round(t2.gasoline_usd_per_liter-t1.categ_avg_gasoline, 2) as diff_gasoline
from
	cte t1
    join
    v_global_fuel_prices t2 on t1.tax_burden_category = t2.tax_burden_category
where
	t2.gasoline_usd_per_liter <= t1.categ_avg_gasoline and t1.tax_burden_category in ('moderate','high')
order by t1.tax_burden_category asc, diff_gasoline desc;




/* [7] How does rolling 3-month or 6-month volatility differ across countries? */

with monthly_data as (select country, 
						dates, 
						avg(gasoline_usd_per_liter) as gasoline_p_liter, 
                        avg(brent_crude_usd_bbl/159) as brent_p_liter 
					from v_price_trend_monthly
					group by country, dates)
select
	country,
    year(dates),
    month(dates),
    case when month(dates) >= 3 then round(stddev(gasoline_p_liter) over(partition by country 
																	order by dates 
																	rows between 2 preceding and current row), 2) end as rolling_dev_3months,
	case when month(dates) >= 6 then round(stddev(gasoline_p_liter) over(partition by country 
																	order by dates 
																	rows between 5 preceding and current row), 2) end as rolling_dev_6months
from
	monthly_data;




/* [8] Which countries absorb global shocks vs transmit them fully in 2026? */

select *,
	change_in_retail_price-change_in_crude_price as diff_in_changes
from(select
	country,
    dates,
    round(gasoline_usd_per_liter - lag(gasoline_usd_per_liter) over(partition by country order by year_date), 2) as change_in_retail_price,
    round((brent_crude_usd_bbl - lag(brent_crude_usd_bbl) over(partition by country order by year_date))/159, 2) as change_in_crude_price
from
	v_price_trend_monthly)t
where
	dates = '2026-04-01'
order by
	diff_in_changes desc;
