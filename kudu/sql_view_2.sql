-- Search variables
set var:domain = 'domain1';
-- 2016-04-24
set var:first_date = 1461456000;
-- 2017-04-26
set var:last_date = 1493164800;
set var:tlds = ('es','pt');

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
	where domain = ${var:domain} and ${var:first_date} <= date_stats and date_stats <= ${var:last_date}
	    and tld in ${var:tlds}
	group by page_name) g
	
join (
	-- Create tld with max visits by page name 
	select distinct page_name,tld,visits 
	from (
		select page_name,domain,tld,visits, 
			max(visits) over (partition by page_name,domain) max_visits 
		from pages 
        where domain = ${var:domain} and ${var:first_date} <= date_stats and date_stats <= ${var:last_date}
            and tld in ${var:tlds}) a
	where a.visits = a.max_visits) max_vs
	
join (
	-- Create date + tld with max bounce rate by page name 
	select distinct page_name, concat(from_unixtime(date_stats, 'yyyy-MM-dd'), '/', tld) as date_tld,bounce_rate
	from (
		select page_name,domain,date_stats,tld,bounce_rate,
			max(bounce_rate) over (partition by page_name,domain) max_bounce_rate 
		from pages 
        where domain = ${var:domain} and ${var:first_date} <= date_stats and date_stats <= ${var:last_date}
            and tld in ${var:tlds}) a
	where a.bounce_rate = a.max_bounce_rate) max_br
	
join (
	-- Create date + tld with min visitors by page name 
	select distinct page_name, concat(from_unixtime(date_stats, 'yyyy-MM-dd'), '/', tld) as date_tld, new_visitors
	from (
		select page_name,domain,date_stats,tld,new_visitors,
		min(new_visitors) over (partition by page_name,domain) min_new_visitors 
		from pages 
        where domain = ${var:domain} and ${var:first_date} <= date_stats and date_stats <= ${var:last_date}
            and tld in ${var:tlds}) a
	where a.new_visitors = a.min_new_visitors) min_new_vt

on 
	g.page_name = max_vs.page_name
	and  g.page_name = max_br.page_name
	and g.page_name = min_new_vt.page_name
	and total_views > 14900
	
order by average_duration;

/**
Output using random data with 1024000 rows:
+------------+-------------+--------------+------------------+----------------+--------------------------+-------------------------+
| page_name  | total_views | total_visits | average_duration | tld_max_visits | date_tld_max_bounce_rate | date_tld_min_new_visits |
+------------+-------------+--------------+------------------+----------------+--------------------------+-------------------------+
| page259373 | 25524       | 23921        | 1                | pt             | 2016-11-04/pt            | 2016-11-04/pt           |
| page126618 | 31093       | 30269        | 1                | pt             | 2017-04-04/pt            | 2017-04-04/pt           |
| page50324  | 16027       | 31299        | 3                | es             | 2017-03-18/es            | 2017-03-18/es           |
| page13465  | 67607       | 32767        | 3                | pt             | 2016-05-10/pt            | 2016-05-10/pt           |
| page70589  | 76805       | 32767        | 4                | es             | 2016-09-04/es            | 2016-09-04/es           |
| page282537 | 24454       | 14994        | 4                | pt             | 2016-05-24/pt            | 2016-05-24/pt           |
| page193856 | 66206       | 30822        | 5                | es             | 2017-03-24/es            | 2017-03-24/es           |
| page334215 | 72214       | 15125        | 5                | pt             | 2017-02-07/pt            | 2017-02-07/pt           |
| page24815  | 50988       | 18128        | 6                | pt             | 2016-10-25/pt            | 2016-10-25/pt           |
| page11149  | 39941       | 14148        | 6                | es             | 2016-08-04/es            | 2016-08-04/es           |
| page52126  | 49628       | 25326        | 7                | pt             | 2016-09-05/pt            | 2016-09-05/pt           |
| page2113   | 40706       | 12207        | 8                | es             | 2017-04-11/es            | 2017-04-11/es           |
| page355669 | 25442       | 14799        | 8                | es             | 2016-11-03/es            | 2016-11-03/es           |
| page202727 | 45214       | 2430         | 8                | pt             | 2016-12-23/pt            | 2016-12-23/pt           |
| page351573 | 27103       | 32767        | 8                | es             | 2016-09-16/es            | 2016-09-16/es           |
| page345648 | 44785       | 5322         | 8                | pt             | 2016-10-14/pt            | 2016-10-14/pt           |
| page33939  | 54764       | 5944         | 8                | pt             | 2016-05-26/pt            | 2016-05-26/pt           |
| page113244 | 36895       | 26403        | 8                | es             | 2016-11-11/es            | 2016-11-11/es           |
...
*/