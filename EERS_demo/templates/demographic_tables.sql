-- Expects the following variables:
-- conf.project_root
-- data_files.files (list of files)
--   the files each have:
--      .name (name of the file itself)
--      .table.name (name of the table it is populating) 
--      .table.id (primary key/id of the table)
--      .delimiter (how the file is delimited (tab or comma))

-- ----------------------------------------------------------------------------
-- Demographics SQL file
-- ---------------------------------------------------------------------------- 
-- This file loads the following files into the database:
[% FOREACH file IN data_files.files %]
-- [% file.name %]
[% END %]
-- ----------------------------------------------------------------------------

[% FOREACH file IN data_files.files %]
-- ----------------------------------------------------------------------------
-- TABLE: [% file.table.name %]
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS [% file.table.name %];

-- create the table 
CREATE TABLE [% file.table.name %] (
	[% file.table.id %] INT PRIMARY KEY,
	description VARCHAR(255)
	);

LOAD DATA 
	INFILE '/var/www/[% conf.project_root %]/database/data/[% file.name %]' 
INTO 
	TABLE 
		[% file.table.name %]
	FIELDS 
		TERMINATED BY '[% file.delimiter %]'
	LINES 
		TERMINATED BY '\n';

-- end TABLE: [% file.table.name %]
-- ----------------------------------------------------------------------------
[% END %]
