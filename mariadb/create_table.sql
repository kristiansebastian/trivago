 -- Create pages table
 CREATE TABLE pages (
  page_name VARCHAR(50),
  date_stats DATE,
  domain VARCHAR(63),
  tld CHAR(2),
  views INT UNSIGNED,
  visits SMALLINT UNSIGNED,
  average SMALLINT UNSIGNED,
  bounce_rate TINYINT UNSIGNED,
  new_visitors TINYINT UNSIGNED,
  tag VARCHAR(50)
) ENGINE=ColumnStore;
