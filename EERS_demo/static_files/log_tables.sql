-- ----------------------------------------------------------------------------
-- Log SQL file
-- ---------------------------------------------------------------------------- 
-- this file creates and loads all the data related to loggin
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- TABLE: tbl_PDF_report 
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS tbl_PDF_report;

-- create the table 
CREATE TABLE tbl_PDF_report (
	pdf_report_id MEDIUMINT UNSIGNED PRIMARY KEY AUTO_INCREMENT, 
	session_id VARCHAR(32), 
	running TINYINT UNSIGNED,
	done TINYINT UNSIGNED,
	retrieved TINYINT UNSIGNED,
	error TINYINT UNSIGNED,
	time VARCHAR(255),
	timestamp DATETIME
	);
	
-- end TABLE: tbl_PDF_report
-- ----------------------------------------------------------------------------	

-- ----------------------------------------------------------------------------
-- TABLE: tbl_event_log
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS tbl_event_log;

-- create the table 
CREATE TABLE tbl_event_log (	
	event_log_id SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
	session_id VARCHAR(20), 
	date_created DATE, 
	event VARCHAR(255), 
	ip VARCHAR(255)
	);

-- end TABLE: tbl_event_log
-- ----------------------------------------------------------------------------
