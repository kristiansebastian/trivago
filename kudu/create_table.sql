 -- Create the Impala pages table. Required to create the Kudu table from it
 CREATE TABLE pages_impala (
  page_name STRING,
  date_stats STRING,
  domain STRING,
  tld STRING,
  views INT,
  visits SMALLINT,
  average SMALLINT,
  bounce_rate TINYINT,
  new_visitors TINYINT,
  tag STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '|'
LOCATION '/sfmta/';

-- Create Kudu table. How to design the schema https://kudu.apache.org/docs/schema_design.html

-- The primary key is critical to for the query performance. This columns are part of the primary
-- key because the views query them (in the where clause)

-- The key partition is critical to distribute and spread data evenly across all servers. I have
-- selected the domain and tld this seems a reasonable partition key but more testing on field values
-- is required to select the best partition key.

-- Kudu doesn't support timestamp so date must be stored as unixtime (BIGINT type)
-- Format the unixtime is possible with from_unixtime(t, 'yyyy-MM-dd') but
-- queries must be performed with timestamp
CREATE TABLE pages
PRIMARY KEY (domain, date_stats, tld)
PARTITION BY HASH(domain, tld) PARTITIONS 8
STORED AS KUDU
AS SELECT
  UNIX_TIMESTAMP(date_stats,  'yyyy-MM-dd') AS date_stats,
  domain,
  tld,
  page_name,
  views,
  visits,
  average,
  bounce_rate,
  new_visitors,
  tag
FROM pages_impala;

-- create table test_kudu primary key (t) partition by hash (ts) partitions 1 stored as kudu as select ts from test;
