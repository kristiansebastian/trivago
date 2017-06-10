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
Output example:
+-----------+-------------+--------------+------------------+----------------+--------------------------+-------------------------+
| page_name | total_views | total_visits | average_duration | tld_max_visits | date_tld_max_bounce_rate | date_tld_min_new_visits |
+-----------+-------------+--------------+------------------+----------------+--------------------------+-------------------------+
| page40    |    88421376 |     38052864 |          36.0000 | pt             | 2016-12-10/es            | 2016-12-10/es           |
| page111   |    11545600 |     13811712 |          79.0000 | es             | 2017-01-05/es            | 2017-01-05/es           |
| page361   |    77426688 |     22930432 |          19.0000 | es             | 2016-11-25/es            | 2016-11-25/es           |
| page120   |    73318400 |      9859072 |          36.0000 | pt             | 2016-11-02/pt            | 2016-11-02/pt           |
| page300   |    19491840 |     20631552 |          99.0000 | es             | 2017-02-26/es            | 2017-02-26/es           |
| page6     |    71075840 |      1356800 |          49.0000 | pt             | 2016-09-02/pt            | 2016-09-02/pt           |
| page341   |    42168320 |     26633216 |          21.0000 | es             | 2016-11-19/es            | 2016-11-19/es           |
| page310   |     9995264 |     37116928 |          70.0000 | pt             | 2016-09-12/pt            | 2016-09-12/pt           |
| page25    |    85457920 |     14524416 |          66.0000 | es             | 2017-04-23/es            | 2016-12-21/es           |
| page17    |    74130432 |      7070720 |          88.0000 | es             | 2017-03-15/es            | 2017-03-15/es           |
| page241   |    51891200 |     11760640 |          82.0000 | es             | 2017-02-19/es            | 2017-02-19/es           |
| page61    |    38596608 |     15630336 |          49.0000 | pt             | 2016-10-04/pt            | 2016-10-04/pt           |
| page110   |    16923648 |      1651712 |          96.0000 | es             | 2016-07-25/es            | 2016-07-25/es           |
| page390   |    65430528 |     27485184 |           1.0000 | pt             | 2017-04-11/pt            | 2017-04-11/pt           |
| page290   |     2224128 |     20675584 |          46.0000 | pt             | 2016-06-20/pt            | 2016-06-20/pt           |
| page11    |     5912576 |     38732800 |          55.0000 | es             | 2016-07-07/es            | 2016-07-07/es           |
| page4     |    63841280 |     10633216 |           2.0000 | pt             | 2017-01-29/pt            | 2017-01-29/pt           |
| page16    |    30951424 |      3378176 |          27.0000 | es             | 2016-11-13/es            | 2016-11-13/es           |
| page351   |   115126272 |     30373888 |          22.5000 | pt             | 2017-03-05/pt            | 2017-03-05/pt           |
| page31    |    51734528 |     34946048 |          95.0000 | pt             | 2017-03-14/pt            | 2017-03-14/pt           |
| page160   |     7648256 |      5370880 |          13.0000 | pt             | 2016-06-12/pt            | 2016-06-12/pt           |
| page320   |    43507712 |     13179904 |          10.0000 | pt             | 2016-07-16/pt            | 2016-07-16/pt           |
| page35    |    77107200 |     24787968 |          73.0000 | es             | 2016-08-14/es            | 2016-08-14/es           |
| page36    |    49613824 |     20049920 |           5.0000 | pt             | 2016-08-16/pt            | 2016-08-16/pt           |
| page20    |    46753792 |     12190720 |          34.0000 | pt             | 2016-09-26/pt            | 2016-09-26/pt           |
+-----------+-------------+--------------+------------------+----------------+--------------------------+-------------------------+
*/

