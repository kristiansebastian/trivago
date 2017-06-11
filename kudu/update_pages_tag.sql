-- Tag name. Required := if not NULL is assigned as value.
set var:tag = 'tag_updated';
-- Pages to update the tag
set var:pages_names = ('page86971','page229516','page287084','page195031','page352877','page54248');

-- Update the pages tag
update pages set
  tag = ${var:tag}
where page_name in ${var:pages_names};

