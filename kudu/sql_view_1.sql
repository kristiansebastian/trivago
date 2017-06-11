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
	group by page_name
	order by page_name limit 200) g
	
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
	and  g.page_name = min_new_vt.page_name;

/**
Output using random data with 1024000 rows:
+------------+-------------+--------------+------------------+----------------+--------------------------+-------------------------+
| page_name  | total_views | total_visits | average_duration | tld_max_visits | date_tld_max_bounce_rate | date_tld_min_new_visits |
+------------+-------------+--------------+------------------+----------------+--------------------------+-------------------------+
| page101006 | 20560       | 22897        | 51               | pt             | 2016-08-11/pt            | 2016-08-11/pt           |
| page101494 | 49140       | 10836        | 86               | es             | 2016-08-07/es            | 2016-08-07/es           |
| page102762 | 62631       | 30296        | 59               | pt             | 2016-04-26/pt            | 2016-04-26/pt           |
| page104249 | 61731       | 30103        | 37               | es             | 2017-01-23/es            | 2017-01-23/es           |
| page104474 | 21901       | 2492         | 38               | pt             | 2017-03-09/pt            | 2017-03-09/pt           |
| page104618 | 73854       | 32767        | 91               | es             | 2016-04-26/es            | 2016-04-26/es           |
| page10515  | 79328       | 2646         | 49               | es             | 2016-12-22/es            | 2016-12-22/es           |
| page10741  | 67769       | 9466         | 66               | es             | 2016-11-17/es            | 2016-11-17/es           |
| page11149  | 39941       | 14148        | 6                | es             | 2016-08-04/es            | 2016-08-04/es           |
| page11183  | 15625       | 4489         | 9                | pt             | 2017-04-08/pt            | 2017-04-08/pt           |
| page113244 | 36895       | 26403        | 8                | es             | 2016-11-11/es            | 2016-11-11/es           |
| page113374 | 50395       | 24949        | 23               | pt             | 2016-05-11/pt            | 2016-05-11/pt           |
| page114762 | 43585       | 26062        | 43               | es             | 2016-11-22/es            | 2016-11-22/es           |
| page115601 | 61740       | 9621         | 66               | pt             | 2016-05-02/pt            | 2016-05-02/pt           |
| page116330 | 29960       | 32767        | 28               | es             | 2016-10-30/es            | 2016-10-30/es           |
| page118548 | 5360        | 15259        | 46               | pt             | 2016-08-04/pt            | 2016-08-04/pt           |
| page120468 | 3870        | 20391        | 59               | pt             | 2016-07-18/pt            | 2016-07-18/pt           |
| page120583 | 2653        | 208          | 67               | pt             | 2017-01-22/pt            | 2017-01-22/pt           |
| page120674 | 49235       | 11024        | 77               | pt             | 2016-11-23/pt            | 2016-11-23/pt           |
| page123883 | 21322       | 5103         | 28               | pt             | 2016-10-09/pt            | 2016-10-09/pt           |
| page126462 | 47109       | 3610         | 78               | pt             | 2017-02-17/pt            | 2017-02-17/pt           |
| page126618 | 31093       | 30269        | 1                | pt             | 2017-04-04/pt            | 2017-04-04/pt           |
| page126641 | 26384       | 22341        | 37               | es             | 2017-04-14/es            | 2017-04-14/es           |
| page126787 | 48384       | 28761        | 42               | pt             | 2016-10-29/pt            | 2016-10-29/pt           |
| page126837 | 25445       | 3257         | 64               | pt             | 2017-02-13/pt            | 2017-02-13/pt           |
....
*/

