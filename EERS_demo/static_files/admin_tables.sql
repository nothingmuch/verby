-- ----------------------------------------------------------------------------
-- Admin SQL file
-- ---------------------------------------------------------------------------- 
-- this file creates and loads all the data related to admin
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- TABLE: tbl_user
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS tbl_user;

-- create the table 
CREATE TABLE tbl_user (
	user_id INT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT,
	first_name VARCHAR(50) NOT NULL,
	last_name VARCHAR(50) NOT NULL,
	username VARCHAR(50) NOT NULL,	
	password VARCHAR(50) NOT NULL,
	password_expiration_date INT UNSIGNED NOT NULL,
	password_history VARCHAR(255) NOT NULL,
	access_level TINYINT UNSIGNED NOT NULL,
	active TINYINT UNSIGNED NOT NULL,
	locked TINYINT UNSIGNED NOT NULL,
	login_failures TINYINT UNSIGNED NOT NULL
	);
	
-- insert default user here	
-- NOTE: 
-- the password is "test"

INSERT INTO tbl_user 
		(first_name, last_name, username, password, password_expiration_date, 
		 password_history, access_level, active, locked, login_failures)
		VALUES("Stevan", "Little", "steve", "098f6bcd46", 0, "", 3, 1, 0, 0);
	
		
-- end TABLE: tbl_user 
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- TABLE: link_user_organization
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS link_user_organization;

-- create the table 
CREATE TABLE link_user_organization (
	user_id INT UNSIGNED NOT NULL,
    org_id INT UNSIGNED NOT NULL
	);
	
-- end TABLE: link_user_organization
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- TABLE: tbl_user_access_levels
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS tbl_user_access_levels;

-- create the table 
CREATE TABLE lkup_user_access_levels (
	access_level_id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
	name VARCHAR(50),
	sort_order TINYINT UNSIGNED
	);
	
-- add all my access levels	
INSERT INTO lkup_user_access_levels (access_level_id, name, sort_order) VALUES(1, "Standard User", 1);	
INSERT INTO lkup_user_access_levels (access_level_id, name, sort_order) VALUES(2, "Administrator", 2);
INSERT INTO lkup_user_access_levels (access_level_id, name, sort_order) VALUES(3, "Super User", 3);
	
-- end TABLE: tbl_sessions 
-- ----------------------------------------------------------------------------	

-- ----------------------------------------------------------------------------
-- TABLE: tbl_sessions
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS tbl_sessions;

-- create the table 
CREATE TABLE tbl_sessions (
	session_id CHAR(32) NOT NULL PRIMARY KEY,
	timeout INT UNSIGNED NOT NULL,
	user_id INT UNSIGNED NOT NULL,
	is_administrator TINYINT UNSIGNED NOT NULL
	);
	
-- end TABLE: tbl_sessions 
-- ----------------------------------------------------------------------------	
