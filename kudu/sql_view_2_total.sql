-- Search variables
set var:domain = 'domain1';
-- 2016-04-24
set var:first_date = 1461456000;
-- 2017-04-26
set var:last_date = 1493164800;
set var:tlds = ('es','pt');

select 
	sum(g.total_views) as total_views, 
	sum(g.total_visits) as total_visits, 
	sum(g.average_duration) as average_duration
	
from (
	-- Create grouped data (total views, total visits and average duration) by page name 
	select 	page_name, 
		sum(views) as total_views, sum(visits) as total_visits, avg(average) as average_duration 
	from pages 
	where domain = ${var:domain} and ${var:first_date} <= date_stats and date_stats <= ${var:last_date}
	    and tld in ${var:tlds}
	group by page_name
) g

where g.total_views > 14900;

/**
Output using random data with 1024000 rows:
+-------------+--------------+------------------+
| total_views | total_visits | average_duration |
+-------------+--------------+------------------+
| 11632126    | 4647073      | 12005            |
+-------------+--------------+------------------+
*/
	
