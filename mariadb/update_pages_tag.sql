-- Tag name. Required := if not NULL is assigned as value.
set @tag := 'tag_updated';
-- Pages to update the tag
set @pages_names = 'page86971,page229516,page287084,page195031,page352877,page54248';

-- Update the pages tag
update pages set
  tag = @tag
where find_in_set(page_name,@pages_names);

