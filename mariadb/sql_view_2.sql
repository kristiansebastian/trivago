set @domain = 'domain1';
set @first_date = '2016-04-24';
set @last_date = '2017-04-26';
set @tlds = 'es,pt';

select 
	g.page_name, g.total_views, g.total_visits, g.average_duration, 
	max_vw.tld as tld_max_visits,
	max_vt.date_tld as date_tld_max_bounce_rate,
	min_new_vt.date_tld as date_tld_min_new_visits
	
from (
	-- Create grouped data (total views, total visits and average duration) by page name 
	select 	page_name, 
		sum(views) as total_views, sum(visits) as total_visits, avg(average) as average_duration 
	from pages 
	where domain = @domain and @first_date<= date_stats and date_stats <= @last_date and 
		find_in_set(tld,@tlds)
	group by page_name) g
	
join (
	-- Create tld with max visits by page name 
	select distinct page_name,tld,visits 
	from (
		select page_name,domain,tld,visits, 
			max(visits) over (partition by page_name,domain) max_visits 
		from pages 
		where domain = @domain and @first_date <= date_stats and date_stats <= @last_date and 
			find_in_set(tld,@tlds)) a 
	where a.visits = a.max_visits) max_vw
	
join (
	-- Create date + tld with max bounce rate by page name 
	select distinct page_name,concat_ws('/',date_stats,tld) as date_tld,bounce_rate 
	from (
		select page_name,domain,date_stats,tld,bounce_rate,
			max(bounce_rate) over (partition by page_name,domain) max_bounce_rate 
		from pages 
		where domain = @domain and @first_date <= date_stats and date_stats <= @last_date and
			find_in_set(tld,@tlds)) a 
	where a.bounce_rate = a.max_bounce_rate) max_vt
	
join (
	-- Create date + tld with min visitors by page name 
	select distinct page_name, concat_ws('/',date_stats,tld) as date_tld, new_visitors 
	from (
		select page_name,domain,date_stats,tld,new_visitors,
		min(new_visitors) over (partition by page_name,domain) min_new_visitors 
		from pages 
		where domain = @domain and @first_date <= date_stats and date_stats <= @last_date and
			find_in_set(tld,@tlds)) a 
	where a.new_visitors = a.min_new_visitors) min_new_vt

on 
	g.page_name = max_vw.page_name
	and  g.page_name = max_vt.page_name 
	and g.page_name = min_new_vt.page_name
	and total_views > 2149000
	
order by average_duration;
