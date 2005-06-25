-- ----------------------------------------------------------------------------
-- Report SQL file
-- ---------------------------------------------------------------------------- 
-- this file creates and loads all the data related to reports
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- TABLE: lkup_report_cycles
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS lkup_report_cycles;

-- create the table 
CREATE TABLE lkup_report_cycles (
	report_cycle_id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
	name VARCHAR(50),
	sort_order TINYINT UNSIGNED
	);
	
-- end TABLE: lkup_report_cycles 
-- ----------------------------------------------------------------------------	

-- ----------------------------------------------------------------------------
-- TABLE: tbl_hewitt_norms
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS tbl_hewitt_norms;

-- create the table 
CREATE TABLE tbl_hewitt_norms (
	question_id MEDIUMINT UNSIGNED, 
	scoretype_id TINYINT UNSIGNED,
	score TINYINT UNSIGNED
	);

LOAD DATA 
	INFILE '/var/www/premier/database/data/tbl_hewitt_norms.csv' 
INTO 
	TABLE 
		tbl_hewitt_norms 
	FIELDS 
		TERMINATED BY ',' 
	LINES 
		TERMINATED BY '\n';		
	
	
-- end TABLE: tbl_hewitt_norms
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- TABLE: lkup_2003_engagement_scores
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS lkup_2003_engagement_scores;

-- create the table 
CREATE TABLE lkup_2003_engagement_scores (
	org_id INT UNSIGNED, 
	org_name VARCHAR(255),
	score TINYINT UNSIGNED
	);	
	
-- end TABLE: lkup_2003_engagement_scores
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- TABLE: tbl_questions
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS tbl_questions;

-- create the table 
CREATE TABLE tbl_questions (
	question_id TINYINT UNSIGNED PRIMARY KEY,
	question TEXT
	);

LOAD DATA 
	INFILE '/var/www/premier/database/data/tbl_questions.txt' 
INTO 
	TABLE 
		tbl_questions
	FIELDS 
		TERMINATED BY '\t' 
	LINES 
		TERMINATED BY '\n';

-- end TABLE: tbl_questions
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- TABLE: tbl_survey_results_2003
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS tbl_survey_results_2003;

-- create the table 
CREATE TABLE tbl_survey_results_2003 (
    org_id INT UNSIGNED,
    gender_id TINYINT UNSIGNED,
    shift_id TINYINT UNSIGNED,
    ethnic_group_id TINYINT UNSIGNED,
    contract_id TINYINT UNSIGNED,
    service_length_id TINYINT UNSIGNED,
    age_id TINYINT UNSIGNED,
    job_family_id TINYINT UNSIGNED,
    fte_status_id TINYINT UNSIGNED,
    job_title_id SMALLINT UNSIGNED,
    manager_level_id TINYINT UNSIGNED,
    q1 TINYINT UNSIGNED,
    q2 TINYINT UNSIGNED,
    q3 TINYINT UNSIGNED,
    q4 TINYINT UNSIGNED,
    q5 TINYINT UNSIGNED,
    q6 TINYINT UNSIGNED,
    q7 TINYINT UNSIGNED,
    q80 TINYINT UNSIGNED,
    q81 TINYINT UNSIGNED,
    q82 TINYINT UNSIGNED,
    q83 TINYINT UNSIGNED,
    q84 TINYINT UNSIGNED,
    q90 TINYINT UNSIGNED,
    q91 TINYINT UNSIGNED,
    q92 TINYINT UNSIGNED,
    q93 TINYINT UNSIGNED,
    q94 TINYINT UNSIGNED,
    q95 TINYINT UNSIGNED,
    q96 TINYINT UNSIGNED,
    q97 TINYINT UNSIGNED,
    q98 TINYINT UNSIGNED,
    q99 TINYINT UNSIGNED,
    q100 TINYINT UNSIGNED,
    q101 TINYINT UNSIGNED,
    q11 TINYINT UNSIGNED,
    q12 TINYINT UNSIGNED,
    q13 TINYINT UNSIGNED,
    q14 TINYINT UNSIGNED,
    q15 TINYINT UNSIGNED,
    q16 TINYINT UNSIGNED,
    q17 TINYINT UNSIGNED,
    q18 TINYINT UNSIGNED,
    q19 TINYINT UNSIGNED,
    q20 TINYINT UNSIGNED,
    q21 TINYINT UNSIGNED,
    q22 TINYINT UNSIGNED,
    q23 TINYINT UNSIGNED,
    q24 TINYINT UNSIGNED,
    q25 TINYINT UNSIGNED,
    q26 TINYINT UNSIGNED,
    q27 TINYINT UNSIGNED,
    q28 TINYINT UNSIGNED,
    q29 TINYINT UNSIGNED,
    q30 TINYINT UNSIGNED,
    q31 TINYINT UNSIGNED,
    q32 TINYINT UNSIGNED,
    q33 TINYINT UNSIGNED,
    q34 TINYINT UNSIGNED,
    q35 TINYINT UNSIGNED,
    q36 TINYINT UNSIGNED,
    q37 TINYINT UNSIGNED,
    q38 TINYINT UNSIGNED,
    q39 TINYINT UNSIGNED,
    q40 TINYINT UNSIGNED,
    q41 TINYINT UNSIGNED,
    q42 TINYINT UNSIGNED,
    q43 TINYINT UNSIGNED,
    q44 TINYINT UNSIGNED,
    q45 TINYINT UNSIGNED,
    q46 TINYINT UNSIGNED,
    q47 TINYINT UNSIGNED,
    q48 TINYINT UNSIGNED,
    q49 TINYINT UNSIGNED,
    q50 TINYINT UNSIGNED,
    q51 TINYINT UNSIGNED,
    q52 TINYINT UNSIGNED,
    q53 TINYINT UNSIGNED,
    q54 TINYINT UNSIGNED,
    q55 TINYINT UNSIGNED,
    q56 TINYINT UNSIGNED,
	id SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY,
	INDEX _id (id),
    INDEX _org_id (org_id),
    INDEX _gender_id (gender_id),
    INDEX _shift_id (shift_id),
    INDEX _ethnic_group_id (ethnic_group_id),
    INDEX _contract_id (contract_id),
    INDEX _service_length_id (service_length_id),
    INDEX _age_id (age_id),
    INDEX _job_family_id (job_family_id),
    INDEX _fte_status_id (fte_status_id),
    INDEX _job_title_id (job_title_id),
    INDEX _manager_level_id (manager_level_id)
	);
        
LOAD DATA 
	INFILE '/var/www/premier/database/data/tbl_survey_results_2003.csv' 
INTO 
	TABLE 
		tbl_survey_results_2003
	FIELDS 
		TERMINATED BY ',' 
	LINES 
		TERMINATED BY '\n';
        
-- ----------------------------------------------------------------------------
-- fix the data to have proper nulls
-- ----------------------------------------------------------------------------
UPDATE tbl_survey_results_2003 SET org_id = NULL WHERE org_id = 0;
UPDATE tbl_survey_results_2003 SET gender_id = NULL WHERE gender_id = 0;
UPDATE tbl_survey_results_2003 SET shift_id = NULL WHERE shift_id = 0;
UPDATE tbl_survey_results_2003 SET ethnic_group_id = NULL WHERE ethnic_group_id = 0;
UPDATE tbl_survey_results_2003 SET contract_id = NULL WHERE contract_id = 0;
UPDATE tbl_survey_results_2003 SET service_length_id = NULL WHERE service_length_id = 0;
UPDATE tbl_survey_results_2003 SET age_id = NULL WHERE age_id = 0;
UPDATE tbl_survey_results_2003 SET job_family_id = NULL WHERE job_family_id = 0;
UPDATE tbl_survey_results_2003 SET fte_status_id = NULL WHERE fte_status_id = 0;
UPDATE tbl_survey_results_2003 SET job_title_id = NULL WHERE job_title_id = 0;
UPDATE tbl_survey_results_2003 SET manager_level_id = NULL WHERE manager_level_id = 0;
UPDATE tbl_survey_results_2003 SET q1 = NULL WHERE q1 = 0;
UPDATE tbl_survey_results_2003 SET q2 = NULL WHERE q2 = 0;
UPDATE tbl_survey_results_2003 SET q3 = NULL WHERE q3 = 0;
UPDATE tbl_survey_results_2003 SET q4 = NULL WHERE q4 = 0;
UPDATE tbl_survey_results_2003 SET q5 = NULL WHERE q5 = 0;
UPDATE tbl_survey_results_2003 SET q6 = NULL WHERE q6 = 0;
UPDATE tbl_survey_results_2003 SET q7 = NULL WHERE q7 = 0;
UPDATE tbl_survey_results_2003 SET q80 = NULL WHERE q80 = 0;
UPDATE tbl_survey_results_2003 SET q81 = NULL WHERE q81 = 0;
UPDATE tbl_survey_results_2003 SET q82 = NULL WHERE q82 = 0;
UPDATE tbl_survey_results_2003 SET q83 = NULL WHERE q83 = 0;
UPDATE tbl_survey_results_2003 SET q84 = NULL WHERE q84 = 0;
UPDATE tbl_survey_results_2003 SET q90 = NULL WHERE q90 = 0;
UPDATE tbl_survey_results_2003 SET q91 = NULL WHERE q91 = 0;
UPDATE tbl_survey_results_2003 SET q92 = NULL WHERE q92 = 0;
UPDATE tbl_survey_results_2003 SET q93 = NULL WHERE q93 = 0;
UPDATE tbl_survey_results_2003 SET q94 = NULL WHERE q94 = 0;
UPDATE tbl_survey_results_2003 SET q95 = NULL WHERE q95 = 0;
UPDATE tbl_survey_results_2003 SET q96 = NULL WHERE q96 = 0;
UPDATE tbl_survey_results_2003 SET q97 = NULL WHERE q97 = 0;
UPDATE tbl_survey_results_2003 SET q98 = NULL WHERE q98 = 0;
UPDATE tbl_survey_results_2003 SET q99 = NULL WHERE q99 = 0;
UPDATE tbl_survey_results_2003 SET q100 = NULL WHERE q100 = 0;
UPDATE tbl_survey_results_2003 SET q101 = NULL WHERE q101 = 0;
UPDATE tbl_survey_results_2003 SET q11 = NULL WHERE q11 = 0;
UPDATE tbl_survey_results_2003 SET q12 = NULL WHERE q12 = 0;
UPDATE tbl_survey_results_2003 SET q13 = NULL WHERE q13 = 0;
UPDATE tbl_survey_results_2003 SET q14 = NULL WHERE q14 = 0;
UPDATE tbl_survey_results_2003 SET q15 = NULL WHERE q15 = 0;
UPDATE tbl_survey_results_2003 SET q16 = NULL WHERE q16 = 0;
UPDATE tbl_survey_results_2003 SET q17 = NULL WHERE q17 = 0;
UPDATE tbl_survey_results_2003 SET q18 = NULL WHERE q18 = 0;
UPDATE tbl_survey_results_2003 SET q19 = NULL WHERE q19 = 0;
UPDATE tbl_survey_results_2003 SET q20 = NULL WHERE q20 = 0;
UPDATE tbl_survey_results_2003 SET q21 = NULL WHERE q21 = 0;
UPDATE tbl_survey_results_2003 SET q22 = NULL WHERE q22 = 0;
UPDATE tbl_survey_results_2003 SET q23 = NULL WHERE q23 = 0;
UPDATE tbl_survey_results_2003 SET q24 = NULL WHERE q24 = 0;
UPDATE tbl_survey_results_2003 SET q25 = NULL WHERE q25 = 0;
UPDATE tbl_survey_results_2003 SET q26 = NULL WHERE q26 = 0;
UPDATE tbl_survey_results_2003 SET q27 = NULL WHERE q27 = 0;
UPDATE tbl_survey_results_2003 SET q28 = NULL WHERE q28 = 0;
UPDATE tbl_survey_results_2003 SET q29 = NULL WHERE q29 = 0;
UPDATE tbl_survey_results_2003 SET q30 = NULL WHERE q30 = 0;
UPDATE tbl_survey_results_2003 SET q31 = NULL WHERE q31 = 0;
UPDATE tbl_survey_results_2003 SET q32 = NULL WHERE q32 = 0;
UPDATE tbl_survey_results_2003 SET q33 = NULL WHERE q33 = 0;
UPDATE tbl_survey_results_2003 SET q34 = NULL WHERE q34 = 0;
UPDATE tbl_survey_results_2003 SET q35 = NULL WHERE q35 = 0;
UPDATE tbl_survey_results_2003 SET q36 = NULL WHERE q36 = 0;
UPDATE tbl_survey_results_2003 SET q37 = NULL WHERE q37 = 0;
UPDATE tbl_survey_results_2003 SET q38 = NULL WHERE q38 = 0;
UPDATE tbl_survey_results_2003 SET q39 = NULL WHERE q39 = 0;
UPDATE tbl_survey_results_2003 SET q40 = NULL WHERE q40 = 0;
UPDATE tbl_survey_results_2003 SET q41 = NULL WHERE q41 = 0;
UPDATE tbl_survey_results_2003 SET q42 = NULL WHERE q42 = 0;
UPDATE tbl_survey_results_2003 SET q43 = NULL WHERE q43 = 0;
UPDATE tbl_survey_results_2003 SET q44 = NULL WHERE q44 = 0;
UPDATE tbl_survey_results_2003 SET q45 = NULL WHERE q45 = 0;
UPDATE tbl_survey_results_2003 SET q46 = NULL WHERE q46 = 0;
UPDATE tbl_survey_results_2003 SET q47 = NULL WHERE q47 = 0;
UPDATE tbl_survey_results_2003 SET q48 = NULL WHERE q48 = 0;
UPDATE tbl_survey_results_2003 SET q49 = NULL WHERE q49 = 0;
UPDATE tbl_survey_results_2003 SET q50 = NULL WHERE q50 = 0;
UPDATE tbl_survey_results_2003 SET q51 = NULL WHERE q51 = 0;
UPDATE tbl_survey_results_2003 SET q52 = NULL WHERE q52 = 0;
UPDATE tbl_survey_results_2003 SET q53 = NULL WHERE q53 = 0;
UPDATE tbl_survey_results_2003 SET q54 = NULL WHERE q54 = 0;
UPDATE tbl_survey_results_2003 SET q55 = NULL WHERE q55 = 0;
UPDATE tbl_survey_results_2003 SET q56 = NULL WHERE q56 = 0;        

-- end TABLE: tbl_survey_results_2003
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- TABLE: tbl_survey_results_2005
-- ----------------------------------------------------------------------------

-- drop the old one if it exists	
DROP TABLE IF EXISTS tbl_survey_results_2005;

-- create the table 
CREATE TABLE tbl_survey_results_2005 (
    org_id INT UNSIGNED,
    gender_id TINYINT UNSIGNED,
    shift_id TINYINT UNSIGNED,
    ethnic_group_id TINYINT UNSIGNED,
    contract_id TINYINT UNSIGNED,
    service_length_id TINYINT UNSIGNED,
    age_id TINYINT UNSIGNED,
    job_family_id TINYINT UNSIGNED,
    fte_status_id TINYINT UNSIGNED,
    job_title_id SMALLINT UNSIGNED,
    manager_level_id TINYINT UNSIGNED,
    q1 TINYINT UNSIGNED,
    q2 TINYINT UNSIGNED,
    q3 TINYINT UNSIGNED,
    q4 TINYINT UNSIGNED,
    q5 TINYINT UNSIGNED,
    q6 TINYINT UNSIGNED,
    q7 TINYINT UNSIGNED,
    q80 TINYINT UNSIGNED,
    q81 TINYINT UNSIGNED,
    q82 TINYINT UNSIGNED,
    q83 TINYINT UNSIGNED,
    q84 TINYINT UNSIGNED,
    q90 TINYINT UNSIGNED,
    q91 TINYINT UNSIGNED,
    q92 TINYINT UNSIGNED,
    q93 TINYINT UNSIGNED,
    q94 TINYINT UNSIGNED,
    q95 TINYINT UNSIGNED,
    q96 TINYINT UNSIGNED,
    q97 TINYINT UNSIGNED,
    q98 TINYINT UNSIGNED,
    q99 TINYINT UNSIGNED,
    q100 TINYINT UNSIGNED,
    q101 TINYINT UNSIGNED,
    q11 TINYINT UNSIGNED,
    q12 TINYINT UNSIGNED,
    q13 TINYINT UNSIGNED,
    q14 TINYINT UNSIGNED,
    q15 TINYINT UNSIGNED,
    q16 TINYINT UNSIGNED,
    q17 TINYINT UNSIGNED,
    q18 TINYINT UNSIGNED,
    q19 TINYINT UNSIGNED,
    q20 TINYINT UNSIGNED,
    q21 TINYINT UNSIGNED,
    q22 TINYINT UNSIGNED,
    q23 TINYINT UNSIGNED,
    q24 TINYINT UNSIGNED,
    q25 TINYINT UNSIGNED,
    q26 TINYINT UNSIGNED,
    q27 TINYINT UNSIGNED,
    q28 TINYINT UNSIGNED,
    q29 TINYINT UNSIGNED,
    q30 TINYINT UNSIGNED,
    q31 TINYINT UNSIGNED,
    q32 TINYINT UNSIGNED,
    q33 TINYINT UNSIGNED,
    q34 TINYINT UNSIGNED,
    q35 TINYINT UNSIGNED,
    q36 TINYINT UNSIGNED,
    q37 TINYINT UNSIGNED,
    q38 TINYINT UNSIGNED,
    q39 TINYINT UNSIGNED,
    q40 TINYINT UNSIGNED,
    q41 TINYINT UNSIGNED,
    q42 TINYINT UNSIGNED,
    q43 TINYINT UNSIGNED,
    q44 TINYINT UNSIGNED,
    q45 TINYINT UNSIGNED,
    q46 TINYINT UNSIGNED,
    q47 TINYINT UNSIGNED,
    q48 TINYINT UNSIGNED,
    q49 TINYINT UNSIGNED,
    q50 TINYINT UNSIGNED,
    q51 TINYINT UNSIGNED,
    q52 TINYINT UNSIGNED,
    q53 TINYINT UNSIGNED,
    q54 TINYINT UNSIGNED,
    q55 TINYINT UNSIGNED,
    q56 TINYINT UNSIGNED,
	id SMALLINT UNSIGNED AUTO_INCREMENT NOT NULL PRIMARY KEY,
	INDEX _id (id),
    INDEX _org_id (org_id),
    INDEX _gender_id (gender_id),
    INDEX _shift_id (shift_id),
    INDEX _ethnic_group_id (ethnic_group_id),
    INDEX _contract_id (contract_id),
    INDEX _service_length_id (service_length_id),
    INDEX _age_id (age_id),
    INDEX _job_family_id (job_family_id),
    INDEX _fte_status_id (fte_status_id),
    INDEX _job_title_id (job_title_id),
    INDEX _manager_level_id (manager_level_id)
	);
    
LOAD DATA 
	INFILE '/var/www/premier/database/data/tbl_survey_results_2005.csv' 
INTO 
	TABLE 
		tbl_survey_results_2005
	FIELDS 
		TERMINATED BY ',' 
	LINES 
		TERMINATED BY '\n';
        
-- ----------------------------------------------------------------------------
-- fix the data to have proper nulls
-- ----------------------------------------------------------------------------
UPDATE tbl_survey_results_2005 SET org_id = NULL WHERE org_id = 0;
UPDATE tbl_survey_results_2005 SET gender_id = NULL WHERE gender_id = 0;
UPDATE tbl_survey_results_2005 SET shift_id = NULL WHERE shift_id = 0;
UPDATE tbl_survey_results_2005 SET ethnic_group_id = NULL WHERE ethnic_group_id = 0;
UPDATE tbl_survey_results_2005 SET contract_id = NULL WHERE contract_id = 0;
UPDATE tbl_survey_results_2005 SET service_length_id = NULL WHERE service_length_id = 0;
UPDATE tbl_survey_results_2005 SET age_id = NULL WHERE age_id = 0;
UPDATE tbl_survey_results_2005 SET job_family_id = NULL WHERE job_family_id = 0;
UPDATE tbl_survey_results_2005 SET fte_status_id = NULL WHERE fte_status_id = 0;
UPDATE tbl_survey_results_2005 SET job_title_id = NULL WHERE job_title_id = 0;
UPDATE tbl_survey_results_2005 SET manager_level_id = NULL WHERE manager_level_id = 0;
UPDATE tbl_survey_results_2005 SET q1 = NULL WHERE q1 = 0;
UPDATE tbl_survey_results_2005 SET q2 = NULL WHERE q2 = 0;
UPDATE tbl_survey_results_2005 SET q3 = NULL WHERE q3 = 0;
UPDATE tbl_survey_results_2005 SET q4 = NULL WHERE q4 = 0;
UPDATE tbl_survey_results_2005 SET q5 = NULL WHERE q5 = 0;
UPDATE tbl_survey_results_2005 SET q6 = NULL WHERE q6 = 0;
UPDATE tbl_survey_results_2005 SET q7 = NULL WHERE q7 = 0;
UPDATE tbl_survey_results_2005 SET q80 = NULL WHERE q80 = 0;
UPDATE tbl_survey_results_2005 SET q81 = NULL WHERE q81 = 0;
UPDATE tbl_survey_results_2005 SET q82 = NULL WHERE q82 = 0;
UPDATE tbl_survey_results_2005 SET q83 = NULL WHERE q83 = 0;
UPDATE tbl_survey_results_2005 SET q84 = NULL WHERE q84 = 0;
UPDATE tbl_survey_results_2005 SET q90 = NULL WHERE q90 = 0;
UPDATE tbl_survey_results_2005 SET q91 = NULL WHERE q91 = 0;
UPDATE tbl_survey_results_2005 SET q92 = NULL WHERE q92 = 0;
UPDATE tbl_survey_results_2005 SET q93 = NULL WHERE q93 = 0;
UPDATE tbl_survey_results_2005 SET q94 = NULL WHERE q94 = 0;
UPDATE tbl_survey_results_2005 SET q95 = NULL WHERE q95 = 0;
UPDATE tbl_survey_results_2005 SET q96 = NULL WHERE q96 = 0;
UPDATE tbl_survey_results_2005 SET q97 = NULL WHERE q97 = 0;
UPDATE tbl_survey_results_2005 SET q98 = NULL WHERE q98 = 0;
UPDATE tbl_survey_results_2005 SET q99 = NULL WHERE q99 = 0;
UPDATE tbl_survey_results_2005 SET q100 = NULL WHERE q100 = 0;
UPDATE tbl_survey_results_2005 SET q101 = NULL WHERE q101 = 0;
UPDATE tbl_survey_results_2005 SET q11 = NULL WHERE q11 = 0;
UPDATE tbl_survey_results_2005 SET q12 = NULL WHERE q12 = 0;
UPDATE tbl_survey_results_2005 SET q13 = NULL WHERE q13 = 0;
UPDATE tbl_survey_results_2005 SET q14 = NULL WHERE q14 = 0;
UPDATE tbl_survey_results_2005 SET q15 = NULL WHERE q15 = 0;
UPDATE tbl_survey_results_2005 SET q16 = NULL WHERE q16 = 0;
UPDATE tbl_survey_results_2005 SET q17 = NULL WHERE q17 = 0;
UPDATE tbl_survey_results_2005 SET q18 = NULL WHERE q18 = 0;
UPDATE tbl_survey_results_2005 SET q19 = NULL WHERE q19 = 0;
UPDATE tbl_survey_results_2005 SET q20 = NULL WHERE q20 = 0;
UPDATE tbl_survey_results_2005 SET q21 = NULL WHERE q21 = 0;
UPDATE tbl_survey_results_2005 SET q22 = NULL WHERE q22 = 0;
UPDATE tbl_survey_results_2005 SET q23 = NULL WHERE q23 = 0;
UPDATE tbl_survey_results_2005 SET q24 = NULL WHERE q24 = 0;
UPDATE tbl_survey_results_2005 SET q25 = NULL WHERE q25 = 0;
UPDATE tbl_survey_results_2005 SET q26 = NULL WHERE q26 = 0;
UPDATE tbl_survey_results_2005 SET q27 = NULL WHERE q27 = 0;
UPDATE tbl_survey_results_2005 SET q28 = NULL WHERE q28 = 0;
UPDATE tbl_survey_results_2005 SET q29 = NULL WHERE q29 = 0;
UPDATE tbl_survey_results_2005 SET q30 = NULL WHERE q30 = 0;
UPDATE tbl_survey_results_2005 SET q31 = NULL WHERE q31 = 0;
UPDATE tbl_survey_results_2005 SET q32 = NULL WHERE q32 = 0;
UPDATE tbl_survey_results_2005 SET q33 = NULL WHERE q33 = 0;
UPDATE tbl_survey_results_2005 SET q34 = NULL WHERE q34 = 0;
UPDATE tbl_survey_results_2005 SET q35 = NULL WHERE q35 = 0;
UPDATE tbl_survey_results_2005 SET q36 = NULL WHERE q36 = 0;
UPDATE tbl_survey_results_2005 SET q37 = NULL WHERE q37 = 0;
UPDATE tbl_survey_results_2005 SET q38 = NULL WHERE q38 = 0;
UPDATE tbl_survey_results_2005 SET q39 = NULL WHERE q39 = 0;
UPDATE tbl_survey_results_2005 SET q40 = NULL WHERE q40 = 0;
UPDATE tbl_survey_results_2005 SET q41 = NULL WHERE q41 = 0;
UPDATE tbl_survey_results_2005 SET q42 = NULL WHERE q42 = 0;
UPDATE tbl_survey_results_2005 SET q43 = NULL WHERE q43 = 0;
UPDATE tbl_survey_results_2005 SET q44 = NULL WHERE q44 = 0;
UPDATE tbl_survey_results_2005 SET q45 = NULL WHERE q45 = 0;
UPDATE tbl_survey_results_2005 SET q46 = NULL WHERE q46 = 0;
UPDATE tbl_survey_results_2005 SET q47 = NULL WHERE q47 = 0;
UPDATE tbl_survey_results_2005 SET q48 = NULL WHERE q48 = 0;
UPDATE tbl_survey_results_2005 SET q49 = NULL WHERE q49 = 0;
UPDATE tbl_survey_results_2005 SET q50 = NULL WHERE q50 = 0;
UPDATE tbl_survey_results_2005 SET q51 = NULL WHERE q51 = 0;
UPDATE tbl_survey_results_2005 SET q52 = NULL WHERE q52 = 0;
UPDATE tbl_survey_results_2005 SET q53 = NULL WHERE q53 = 0;
UPDATE tbl_survey_results_2005 SET q54 = NULL WHERE q54 = 0;
UPDATE tbl_survey_results_2005 SET q55 = NULL WHERE q55 = 0;
UPDATE tbl_survey_results_2005 SET q56 = NULL WHERE q56 = 0;  

-- end TABLE: tbl_survey_results_2005
-- ----------------------------------------------------------------------------

