-- Search variables
set @domain = 'domain1';
set @first_date = '2016-04-24';
set @last_date = '2017-04-26';
set @tlds = 'es,pt';

select 
	g.page_name, g.total_views, g.total_visits, g.average_duration, 
	max_vs.tld as tld_max_visits,
	max_br.date_tld as date_tld_max_bounce_rate,
	min_new_vt.date_tld as date_tld_min_new_visits
	
from (
	-- Create grouped data (total views, total visits and average duration) by page name 
	select 	page_name, 
		sum(views) as total_views, sum(visits) as total_visits, avg(average) as average_duration 
	from pages 
	where domain = @domain and @first_date <= date_stats and date_stats <= @last_date and 
		find_in_set(tld,@tlds) 
	group by page_name
	order by page_name limit 200) g
	
join (
	-- Create tld with max visits by page name
 	select distinct page_name,tld,visits 
	from (
	
		select page_name,domain,tld,visits, 
			max(visits) over (partition by page_name,domain) max_visits 
		from pages 
		where domain = @domain and @first_date <= date_stats and date_stats <= @last_date and 
			find_in_set(tld,@tlds)) a 
	where a.visits = a.max_visits) max_vs
	
join (
	-- Create date + tld with max bounce rate by page name 
 	select distinct page_name,concat_ws('/',date_stats,tld) as date_tld,bounce_rate 
	from (
		select page_name,domain,date_stats,tld,bounce_rate,
			max(bounce_rate) over (partition by page_name,domain) max_bounce_rate 
		from pages 
		where domain = @domain and @first_date <= date_stats and date_stats <= @last_date and
			find_in_set(tld,@tlds)) a 
	where a.bounce_rate = a.max_bounce_rate) max_br
	
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
	g.page_name = max_vs.page_name
	and  g.page_name = max_br.page_name 
	and  g.page_name = min_new_vt.page_name;

/**
Output using random data with 1024000 rows:
+------------+-------------+--------------+------------------+----------------+--------------------------+-------------------------+
| page_name  | total_views | total_visits | average_duration | tld_max_visits | date_tld_max_bounce_rate | date_tld_min_new_visits |
+------------+-------------+--------------+------------------+----------------+--------------------------+-------------------------+
| page300151 |       24309 |        22022 |          65.0000 | es             | 2017-01-15/es            | 2017-01-15/es           |
| page226735 |       64900 |         4164 |          48.0000 | es             | 2016-10-22/es            | 2016-10-22/es           |
| page339649 |       77957 |        17521 |          10.0000 | pt             | 2016-07-11/pt            | 2016-07-11/pt           |
| page314233 |       58991 |        12522 |          57.0000 | es             | 2016-11-18/es            | 2016-11-18/es           |
| page307417 |       66505 |         7394 |          34.0000 | es             | 2017-02-01/es            | 2017-02-01/es           |
| page113374 |       50395 |        24949 |          23.0000 | pt             | 2016-05-11/pt            | 2016-05-11/pt           |
| page206795 |       29097 |        24538 |          26.0000 | es             | 2016-12-05/es            | 2016-12-05/es           |
| page33939  |       54764 |         5944 |           8.0000 | pt             | 2016-05-26/pt            | 2016-05-26/pt           |
| page236183 |       70516 |        35852 |          76.0000 | pt             | 2016-09-12/pt            | 2016-09-12/pt           |
| page120583 |        2653 |          208 |          67.0000 | pt             | 2017-01-22/pt            | 2017-01-22/pt           |
| page217418 |       32706 |        27594 |          18.0000 | es             | 2016-10-27/es            | 2016-10-27/es           |
| page169099 |       21736 |        28146 |          52.0000 | es             | 2016-12-09/es            | 2016-12-09/es           |
| page294645 |       45215 |        35110 |          16.0000 | es             | 2016-05-02/es            | 2016-05-02/es           |
| page227046 |       64422 |         5343 |          62.0000 | es             | 2016-11-23/es            | 2016-11-23/es           |
*/

