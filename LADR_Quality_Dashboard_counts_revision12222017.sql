/*
	Author: Javi Sanz
	Creation Date: 03/18/2017
	Last revision Date: 12/22/2017
	Version: 3.0.2

	Background:
	Script to generate aggregated counts from the LADR data to populate a new application designed to improved quality through a dashboard like data visualization tool.

	Instructions:
	The script will create a series of tables to pull the data from the patient_dimension, visit_dimension, and observation_fact tables. 
	It will also combine all ontologies into a new ontology master table with an ad hoc ontology ID used throughout the counting process.
	The ontology will also be utilized to merge the results across sites and for some internal calculations for certain visualization enhancements in the application.
	
	ULtimately, there is a select query to be used to export the tables formatted accordingly into csv files to deliver to UCLA.
	
	For any questions regarding the script, feel free to contact me at
	jsanz@mednet.ucla.edu

	
	Revised items:
	10/09/17: add a header with some metadata to keep track of future changes.
	10/09/17: Incorporate items related to the visit details: length of stay and location. The change has inserted a new #6 step and renamed the previous #6 to #7, #7 to #8 and so forth.
	12/22/17: Fix issue with visit_details being excluded from final export (step 6.4)
	
	
	
*/



/* ************************************************************************************************
--Step 0: Schema name replacement
-----------------------------------------------------------------------
			In order to simplify the step of customizing the code to your environment,
			use the FIND and REPLACE tool in your text editor to change the schema names across the entire file
			REPLACE the entire string inside the double quotes "<CRCData Schema>" with the corresponding schema name in your environment
			REPLACE the entire string inside the double quotes "<Metadata Schema>" with the corresponding schema name in your environment
			
************************************************************************************************ */



/* ************************************************************************************************
--Step 1: CREATE ONTOLOGY TABLE
-----------------------------------------------------------------------
	Merge all available ontologies adding an arbitrary ID numeric field 
	to simplify the roll-up counting up the tree structure
	Join with concept_dimension to bring concept_cd field used to join to OBSERVATION_FACT
	Run on <Metadata Schema>
************************************************************************************************ */ 

--------------------------------------------------------------------------------------------------	   
-- Step 1.1: CREATE TABLE DASH_ONTOLOGY
--			 Run on <Metadata Schema>
--------------------------------------------------------------------------------------------------	
DROP  table DASH_ONTOLOGY PURGE;
  CREATE TABLE DASH_ONTOLOGY
   (	"C_HLEVEL" NUMBER(22,0) NOT NULL ENABLE, 
	"C_FULLNAME" VARCHAR2(700 BYTE) NOT NULL ENABLE, 
	"C_NAME" VARCHAR2(2000 BYTE) NOT NULL ENABLE, 
	"C_DIMCODE" VARCHAR2(700 BYTE), 
	"CONCEPT_CD" VARCHAR2(50 BYTE), 
	"C_VISUALATTRIBUTES" CHAR(3 BYTE) NOT NULL ENABLE, 
  	"C_TABLENAME" VARCHAR2(50 BYTE) NOT NULL ENABLE,
    "C_COLUMNNAME" VARCHAR2(50 BYTE) NOT NULL ENABLE, 
    "C_OPERATOR" VARCHAR2(10 BYTE) NOT NULL ENABLE,
	"ONT_ID" NUMBER(*,0), 
	"ONT_NAME" CHAR(15 BYTE)
   );

--------------------------------------------------------------------------------------------------	   
-- Step 1.2: Create primary key constraint
--			 Run this query from <Metadata schema>.
--------------------------------------------------------------------------------------------------	
   
ALTER TABLE DASH_ONTOLOGY ADD CONSTRAINT DAST_ONTOLOGY_ONT_PK PRIMARY KEY (ONT_ID);

--------------------------------------------------------------------------------------------------	   
-- Step 1.3: Use following statement to generate dynamic queries to combine data FROM different ontology source tables
--			 Run this query from <Metadata schema>. Replace <CRC schema> accordingly to match your environment.
--------------------------------------------------------------------------------------------------	
-- If necessary, GRANT permission <Metadata schema> in order to access <CRCData Schema>.CONCEPT_DIMENSION
GRANT SELECT ON <CRCData Schema>.CONCEPT_DIMENSION TO <Metadata schema>;
--grant SELECT on "LADR_CRCDATA_1_7_04"."CONCEPT_DIMENSION" to "LADR_METADATA_1_7_04";		--example at UCLA





SELECT 'INSERT INTO DASH_ONTOLOGY SELECT ONT.C_HLEVEL, ont.C_FULLNAME, ont.C_NAME, ont.C_DIMCODE, dim.CONCEPT_CD, ont.C_VISUALATTRIBUTES, ont.C_TABLENAME, ont.C_COLUMNNAME,
ont.C_OPERATOR, (row_number() over (order by ONT.C_HLEVEL, ont.C_FULLNAME) + nvl((SELECT MAX(ONT_ID)  FROM DASH_ONTOLOGY),0)) ONT_ID, '''|| x.C_TABLE_NAME  || ''' AS ONT_NAME FROM  ' || x.C_TABLE_NAME || ' ont 
  LEFT JOIN <CRCData schema>.CONCEPT_DIMENSION dim ON ont.C_DIMCODE = dim.CONCEPT_PATH; COMMIT;' FROM (SELECT DISTINCT(C_TABLE_NAME) as C_TABLE_NAME FROM TABLE_ACCESS) x ; 

-------------------------------------------------------------------------------------------------- 
-- Step 1.4: Generate one entry per ontology record and merging all the different tables conforming the ontology
--			 Run queries FROM Step 1.2 on <CRCData schema> to populate DASH_ONTOLOGY
--			 Run on <Metadata Schema>
--------------------------------------------------------------------------------------------------

/* this is an example of one of the queries being generated
----------------------------------------------------------------------------------------------------------------------------------
--Example of the code produced in UCLA environment
  INSERT INTO DASH_ONTOLOGY SELECT ONT.C_HLEVEL, ont.C_FULLNAME, ont.C_NAME, ont.C_DIMCODE, dim.CONCEPT_CD, ont.C_VISUALATTRIBUTES, ont.C_TABLENAME, ont.C_COLUMNNAME,
ont.C_OPERATOR, (row_number() over (order by ONT.C_HLEVEL, ont.C_FULLNAME) + nvl((SELECT MAX(ONT_ID)  FROM DASH_ONTOLOGY),0)) ONT_ID, 'SHRINE' AS ONT_NAME FROM  SHRINE ont 
  LEFT JOIN LADR_CRCDATA_1_7_04.CONCEPT_DIMENSION dim ON ont.C_FULLNAME = dim.CONCEPT_PATH; 
  COMMIT;
  27,938 rows inserted.
INSERT INTO DASH_ONTOLOGY SELECT ONT.C_HLEVEL, ont.C_FULLNAME, ont.C_NAME, ont.C_DIMCODE, dim.CONCEPT_CD, ont.C_VISUALATTRIBUTES, ont.C_TABLENAME, ont.C_COLUMNNAME,
ont.C_OPERATOR, (row_number() over (order by ONT.C_HLEVEL, ont.C_FULLNAME) + nvl((SELECT MAX(ONT_ID)  FROM DASH_ONTOLOGY),0)) ONT_ID, 'LADR_DIAGS' AS ONT_NAME FROM  LADR_DIAGS ont 
  LEFT JOIN LADR_CRCDATA_1_7_04.CONCEPT_DIMENSION dim ON ont.C_FULLNAME = dim.CONCEPT_PATH; 
  COMMIT;
  109,782 rows inserted.
INSERT INTO DASH_ONTOLOGY SELECT ONT.C_HLEVEL, ont.C_FULLNAME, ont.C_NAME, ont.C_DIMCODE, dim.CONCEPT_CD, ont.C_VISUALATTRIBUTES, ont.C_TABLENAME, ont.C_COLUMNNAME,
ont.C_OPERATOR, (row_number() over (order by ONT.C_HLEVEL, ont.C_FULLNAME) + nvl((SELECT MAX(ONT_ID)  FROM DASH_ONTOLOGY),0)) ONT_ID, 'LADR_LABS' AS ONT_NAME FROM  LADR_LABS ont 
  LEFT JOIN LADR_CRCDATA_1_7_04.CONCEPT_DIMENSION dim ON ont.C_FULLNAME = dim.CONCEPT_PATH; 
  COMMIT;
  83,212 rows inserted.
INSERT INTO DASH_ONTOLOGY SELECT ONT.C_HLEVEL, ont.C_FULLNAME, ont.C_NAME, ont.C_DIMCODE, dim.CONCEPT_CD, ont.C_VISUALATTRIBUTES, ont.C_TABLENAME, ont.C_COLUMNNAME,
ont.C_OPERATOR, (row_number() over (order by ONT.C_HLEVEL, ont.C_FULLNAME) + nvl((SELECT MAX(ONT_ID)  FROM DASH_ONTOLOGY),0)) ONT_ID, 'LADR_PROCS' AS ONT_NAME FROM  LADR_PROCS ont 
  LEFT JOIN LADR_CRCDATA_1_7_04.CONCEPT_DIMENSION dim ON ont.C_FULLNAME = dim.CONCEPT_PATH; 
  COMMIT;
  185,066 rows inserted.
----------------------------------------------------------------------------------------------------------------------------------
*/

   
--Total number of elements and highest ontology level 
SELECT COUNT(*) FROM DASH_ONTOLOGY;      			   --415998
SELECT COUNT(DISTINCT ONT_ID) FROM DASH_ONTOLOGY;      --415998
SELECT max(c_hlevel) FROM DASH_ONTOLOGY;               --17



/* ************************************************************************************************
--Step 2: CREATE temp node table using C_FULLNAME
-----------------------------------------------------------------------
	Create temp node table 
	There is one additional field to record  the parent for each ontology level (in our case the max is 17 but I have coded it to take up to 20 levels deep)
	It uses the C_fullname split by '\' to identify each portion of the name that belongs to each level
	CONCEPT_CD will be used on Step 5 to attach the corresponding ONT_ID to every entry in the OBSERVATION_FACT table
	Run on <Metadata Schema>
	Running time: 11 SECONDS
************************************************************************************************ */ 
DROP TABLE DASH_ONT_NODES_temp PURGE;
CREATE TABLE DASH_ONT_NODES_temp AS
SELECT DISTINCT dash.ont_id as ont_id,
		dash.C_hlevel,
		dash.c_fullname,
		dash.c_name,
		dash.concept_cd,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,3))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level1,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,4))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level2,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,5))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level3,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,6))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level4,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,7))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level5,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,8))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level6,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,9))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level7,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,10))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level8,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,11))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level9,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,12))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level10,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,13))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level11,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,14))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level12,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,15))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level13,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,16))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level14,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,17))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level15,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,18))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level16,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,19))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level17,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,20))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level18,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,21))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level19,
		SUBSTR(dash.c_fullname,1,(INSTR(dash.c_fullname,'\',1,22))- INSTR(dash.c_fullname,'\',1,1)+1) as c_name_level20
FROM DASH_ONTOLOGY dash
; 
'

-----------------------------------------------------------------------
--	CONFIRM COUNTS AND QA OUTPUT
-----------------------------------------------------------------------
SELECT COUNT(*) FROM  DASH_ONT_NODES_temp;                    --415,962
SELECT COUNT(DISTINCT ONT_ID) FROM  DASH_ONT_NODES_temp;      --415,962
SELECT * FROM  DASH_ONT_NODES_temp;


/* ************************************************************************************************
--Step 3: CREATE FINAL node table
-----------------------------------------------------------------------
	A node represents every point in the ontology structures that also displayes the children pertaining to it
	Finalize the node table by replacing the name portion with the corresponding ontology ID until the all level are done.
	We self join the temp table up to 20 times (one per level) to accomplish this. Please, add additional statements if your ontology is deeper than 20 levels
	The temp table has an index on C_FULLNAME for better performance
	Run on <Metadata Schema>
	--25 SECONDS

************************************************************************************************ */ 

DROP TABLE DASH_ONT_NODES PURGE;
CREATE TABLE DASH_ONT_NODES AS
SELECT DISTINCT
DASH.*,
ont1.ont_id as ont_id_level1,
ont2.ont_id as ont_id_level2,
ont3.ont_id as ont_id_level3,
ont4.ont_id as ont_id_level4,
ont5.ont_id as ont_id_level5,
ont6.ont_id as ont_id_level6,
ont7.ont_id as ont_id_level7,
ont8.ont_id as ont_id_level8,
ont9.ont_id as ont_id_level9,
ont10.ont_id as ont_id_level10,
ont11.ont_id as ont_id_level11,
ont12.ont_id as ont_id_level12,
ont13.ont_id as ont_id_level13,
ont14.ont_id as ont_id_level14,
ont15.ont_id as ont_id_level15,
ont16.ont_id as ont_id_level16,
ont17.ont_id as ont_id_level17,
ont18.ont_id as ont_id_level18,
ont19.ont_id as ont_id_level19,
ont20.ont_id as ont_id_level20
FROM DASH_ONT_NODES_temp DASH
LEFT JOIN DASH_ONTOLOGY ont1 on dash.c_name_level1 = ont1.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont2 on dash.c_name_level2 = ont2.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont3 on dash.c_name_level3 = ont3.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont4 on dash.c_name_level4 = ont4.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont5 on dash.c_name_level5 = ont5.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont6 on dash.c_name_level6 = ont6.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont7 on dash.c_name_level7 = ont7.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont8 on dash.c_name_level8 = ont8.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont9 on dash.c_name_level9 = ont9.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont10 on dash.c_name_level10 = ont10.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont11 on dash.c_name_level11 = ont11.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont12 on dash.c_name_level12 = ont12.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont13 on dash.c_name_level13 = ont13.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont14 on dash.c_name_level14 = ont14.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont15 on dash.c_name_level15 = ont15.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont16 on dash.c_name_level16 = ont16.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont17 on dash.c_name_level17 = ont17.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont18 on dash.c_name_level18 = ont18.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont19 on dash.c_name_level19 = ont19.C_FULLNAME
LEFT JOIN DASH_ONTOLOGY ont20 on dash.c_name_level20 = ont20.C_FULLNAME;


-----------------------------------------------------------------------
--	CONFIRM COUNTS AND QA OUTPUT
-----------------------------------------------------------------------
SELECT COUNT(*) FROM DASH_ONT_NODES;                     --416058
SELECT COUNT(DISTINCT ONT_ID) FROM DASH_ONT_NODES;       --415998
SELECT * FROM DASH_ONT_NODES;

SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level17 IS NOT NULL;                     --2
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level16 IS NOT NULL;                     --9
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level15 IS NOT NULL;                     --24
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level14 IS NOT NULL;                     --85
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level13 IS NOT NULL;                     --200
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level12 IS NOT NULL;                     --552
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level11 IS NOT NULL;                     --1621
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level10 IS NOT NULL;                     --5926 
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level9 IS NOT NULL;                      --126257
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level8 IS NOT NULL;                      --235433
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level7 IS NOT NULL;                      --331955
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level6 IS NOT NULL;                      --387552
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level5 IS NOT NULL;                      --408069
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level4 IS NOT NULL;                      --414967
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level3 IS NOT NULL;                      --415986
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level2 IS NOT NULL;                      --416050
SELECT COUNT(*) FROM DASH_ONT_NODES WHERE ont_id_level1 IS NOT NULL;                      --416058



/* ************************************************************************************************
--Step 4: CREATE and populate optimized copy of observation fact  
-----------------------------------------------------------------------
	This version of the OBSERVATION_FACT table only includes the patient_num, year, and ontology ID along with all its parents
	We join OBSERVATION_FACT to DASH_ONT_NODES to accomplish this
	
************************************************************************************************ */   


/*---------------------------------------------------------------------
--Step 4.1: CREATE DASH_OBSERVATION table 
--			Join OBSERVATION_FACT to DASH_ONT_NODES to create a new version of	
--			every record in the fact table but with the optimized elements for
--			aggregated counting.
*/---------------------------------------------------------------------

--In order to CREATE the DASH_OBSERVATION table on this section from <Metadata schema>, 
--you will need to GRANT permissions to SELECT from <Metadata Schema> to <CRCData schema>."OBSERVATION_FACT"
--Run this on <CRCData schema>
grant SELECT on <CRCData schema>."OBSERVATION_FACT" to <Metadata schema>;
--grant SELECT on "LADR_CRCDATA_1_7_04"."OBSERVATION_FACT" to "LADR_METADATA_1_7_04";		--example at UCLA

DROP TABLE DASH_OBSERVATION PURGE;
CREATE TABLE DASH_OBSERVATION AS
SELECT 
  OB.PATIENT_NUM,
  EXTRACT(YEAR FROM OB.START_DATE) AS ONT_YEAR,
  ONT_ID,
  ONT.ONT_ID_LEVEL1,
  ONT.ONT_ID_LEVEL2,
  ONT.ONT_ID_LEVEL3,
  ONT.ONT_ID_LEVEL4,
  ONT.ONT_ID_LEVEL5,
  ONT.ONT_ID_LEVEL6,
  ONT.ONT_ID_LEVEL7,
  ONT.ONT_ID_LEVEL8,
  ONT.ONT_ID_LEVEL9,
  ONT.ONT_ID_LEVEL10,
  ONT.ONT_ID_LEVEL11,
  ONT.ONT_ID_LEVEL12,
  ONT.ONT_ID_LEVEL13,
  ONT.ONT_ID_LEVEL14,
  ONT.ONT_ID_LEVEL15,
  ONT.ONT_ID_LEVEL16,
  ONT.ONT_ID_LEVEL17,
  ONT.ONT_ID_LEVEL18,
  ONT.ONT_ID_LEVEL19,
  ONT.ONT_ID_LEVEL20
FROM <CRCData schema>.OBSERVATION_FACT OB
JOIN DASH_ONT_NODES     			ONT ON OB.CONCEPT_CD = ONT.CONCEPT_CD;

SELECT COUNT(*) FROM DASH_OBSERVATION;    --437,363,157
/*---------------------------------------------------------------------
--Step 4.2: INSERT  rest of demographic records FROM PATIENT_DIMENSION (except for age see Step 5)
--			Dynamic query generation to calculate rest of demographic records FROM PATIENT_DIMENSION
--			Run this query from <Metadata schema>. Replace <CRC schema> accordingly to match your environment.
*/-----------------------------------------------------------------------

--In order to INSERT into DASH_OBSERVATION table from <Metadata schema>, 
--you will need to GRANT permissions to SELECT from <Metadata Schema> to <CRCData schema>."PATIENT_DIMENSION"
--Run this on <CRCData schema>
grant SELECT on <CRCData schema>."PATIENT_DIMENSION" to <Metadata schema>;
--grant SELECT on "LADR_CRCDATA_1_7_04"."PATIENT_DIMENSION" to "UCREX_METADATA_1_7_04";		--example at UCLA


SELECT 'INSERT INTO DASH_OBSERVATION SELECT 
  OB.PATIENT_NUM,
  EXTRACT(YEAR FROM SYSDATE) AS ONT_YEAR,
  ONT.ONT_ID,
  NOD.ONT_ID_LEVEL1,
  NOD.ONT_ID_LEVEL2,
  NOD.ONT_ID_LEVEL3,
  NOD.ONT_ID_LEVEL4,
  NOD.ONT_ID_LEVEL5,
  NOD.ONT_ID_LEVEL6,
  NOD.ONT_ID_LEVEL7,
  NOD.ONT_ID_LEVEL8,
  NOD.ONT_ID_LEVEL9,
  NOD.ONT_ID_LEVEL10,
  NOD.ONT_ID_LEVEL11,
  NOD.ONT_ID_LEVEL12,
  NOD.ONT_ID_LEVEL13,
  NOD.ONT_ID_LEVEL14,
  NOD.ONT_ID_LEVEL15,
  NOD.ONT_ID_LEVEL16,
  NOD.ONT_ID_LEVEL17,
  NOD.ONT_ID_LEVEL18,
  NOD.ONT_ID_LEVEL19,
  NOD.ONT_ID_LEVEL20
FROM <CRCData schema>.PATIENT_DIMENSION     OB
JOIN DASH_ONTOLOGY      ONT ON OB.' || c_columnname || '  = ONT.c_name
JOIN DASH_ONT_NODES     NOD ON ONT.ont_ID = NOD.ONT_ID
where ont.c_columnname = ''' ||c_columnname || '''; commit;'  
FROM (
		SELECT DISTINCT c_columnname 
		FROM DASH_ONTOLOGY 
		WHERE c_columnname IN ('language_cd','religion_cd','marital_status_cd','race_cd','sex_cd')
	);
'
--4,804,422 rows inserted.		--language_cd
--3,842,215 rows inserted.		--religion_cd
--3,294,209 rows inserted.		--marital_status_cd
--453,904 rows inserted.		--race_cd
--4,826,071 rows inserted.		--sex_cd


-- Ethnicity and vital_status_cd are being recorded in OBSERVATION_FACT 	

 
-------------------------------------------------------------------------------------------------- 
-- Step 4.3: Generate individual demographics patient entries for each ontology level ID by year
--			 Run these queries FROM <Metadata schema>
--			 It is necessary to GRANT permissions to PATIENT_DIMENSION for <Metadata schema>
--			 Remove double quotation marks when pasting the queries in your canvas
--			 COMMIT changes afterwards.
--------------------------------------------------------------------------------------------------


/* this is an example of one of the queries being generated
----------------------------------------------------------------------------------------------------------------------------------
INSERT INTO DASH_OBSERVATION SELECT  
  OB.PATIENT_NUM, 
  EXTRACT(YEAR FROM SYSDATE) AS ONT_YEAR, 
  ONT.ID, 
  NOD.ONT_ID_LEVEL1, 
  NOD.ONT_ID_LEVEL2, 
  NOD.ONT_ID_LEVEL3, 
  NOD.ONT_ID_LEVEL4, 
  NOD.ONT_ID_LEVEL5, 
  NOD.ONT_ID_LEVEL6, 
  NOD.ONT_ID_LEVEL7, 
  NOD.ONT_ID_LEVEL8, 
  NOD.ONT_ID_LEVEL9, 
  NOD.ONT_ID_LEVEL10, 
  NOD.ONT_ID_LEVEL11, 
  NOD.ONT_ID_LEVEL12, 
  NOD.ONT_ID_LEVEL13, 
  NOD.ONT_ID_LEVEL14, 
  NOD.ONT_ID_LEVEL15, 
  NOD.ONT_ID_LEVEL16, 
  NOD.ONT_ID_LEVEL17, 
  NOD.ONT_ID_LEVEL18,
  NOD.ONT_ID_LEVEL19,
  NOD.ONT_ID_LEVEL20
FROM <CRCData schema>.PATIENT_DIMENSION     OB 
JOIN DASH_ONTOLOGY      ONT ON OB.language_cd  = ONT.c_name 
JOIN DASH_ONT_NODES     NOD ON ONT.ID = NOD.ONT_ID 
where ont.c_columnname = 'language_cd';
----------------------------------------------------------------------------------------------------------------------------------
*/



/* ************************************************************************************************
--Step 5: Add age demographic information
--        This piece of code it dynamically generates queries using the PATIENT_DIMENSION
--			to aggregate patient counts by calculating ages and ultimately joining the result to the ontology entry
--
--------------------------------------------------------------------------------------------------
--  Comments:
--  Modify schema names accordingly for <Metadata schema> and <CRCData schema>
--  SQL SERVER: YEAR(start_date) instead of EXTRACT(YEAR FROM SYSDATE)
--
************************************************************************************************ */   
-------------------------------------------------------------------------------------------------- 
-- Step 5.1: Create table in <CRCData schema>
--			 Run this command from <Metadata schema>
-------------------------------------------------------------------------------------------------- 
  DROP TABLE DASH_AGE PURGE;
  CREATE TABLE DASH_AGE
   (	ONT_ID NUMBER, 
	OBSERVATION_YEAR NUMBER, 
	PATIENT_NUM NUMBER
   );
--------------------------------------------------------------------------------------------------
-- Step 5.2: Dynamic query generation to calculate age for each patient and pairing it to the corresponding ONTOLOGY_ID
--			 Run this query from <Metadata schema>. Replace <CRC schema> accordingly to match your environment.
--------------------------------------------------------------------------------------------------
SELECT 'INSERT INTO DASH_AGE SELECT ' || '''' || ont.ont_id || '''' || ' as ont_id, EXTRACT(YEAR FROM SYSDATE) AS observation_year, patient_num 
FROM <CRCData schema>.patient_dimension WHERE ' || ont.c_columnname || ' '  || ont.c_operator ||' ' || ont.c_dimcode || '; COMMIT;' as query_to_run
FROM DASH_ONTOLOGY         ont
JOIN DASH_ONT_NODES     NOD ON ONT.ont_ID = NOD.ONT_ID
WHERE 
		ont.C_TABLENAME = 'patient_dimension'
		AND ont.C_VISUALATTRIBUTES = 'LA'
		AND ont.c_columnname = 'birth_date';


   
-------------------------------------------------------------------------------------------------- 
-- Step 5.3: Generate entries per patient and by age group
--			 Run this query from <Metadata schema> 
--------------------------------------------------------------------------------------------------


/* this is an example of one of the queries being generated
----------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO DASH_AGE SELECT '4580749' as ont_id, EXTRACT(YEAR FROM SYSDATE) AS observation_year, patient_num 
FROM LADR_CRCDATA_1_7_04.patient_dimension WHERE birth_date BETWEEN sysdate - (365.25 * 9) AND sysdate - (365.25 * 8) ;
----------------------------------------------------------------------------------------------------------------------------------
*/



/*---------------------------------------------------------------------
--Step 5.4: INSERT Age records FROM DASH_AGE 
--			Run this query from <Metadata schema>
-----------------------------------------------------------------------

*/---------------------------------------------------------------------
INSERT INTO DASH_OBSERVATION
SELECT DISTINCT
  OB.PATIENT_NUM,
  EXTRACT(YEAR FROM SYSDATE) AS ONT_YEAR,
  NOD.ont_ID,
  NOD.ONT_ID_LEVEL1,
  NOD.ONT_ID_LEVEL2,
  NOD.ONT_ID_LEVEL3,
  NOD.ONT_ID_LEVEL4,
  NOD.ONT_ID_LEVEL5,
  NOD.ONT_ID_LEVEL6,
  NOD.ONT_ID_LEVEL7,
  NOD.ONT_ID_LEVEL8,
  NOD.ONT_ID_LEVEL9,
  NOD.ONT_ID_LEVEL10,
  NOD.ONT_ID_LEVEL11,
  NOD.ONT_ID_LEVEL12,
  NOD.ONT_ID_LEVEL13,
  NOD.ONT_ID_LEVEL14,
  NOD.ONT_ID_LEVEL15,
  NOD.ONT_ID_LEVEL16,
  NOD.ONT_ID_LEVEL17,
  NOD.ONT_ID_LEVEL18,
  NOD.ONT_ID_LEVEL19,
  NOD.ONT_ID_LEVEL20
FROM DASH_AGE             OB
JOIN <Metadata schema>.DASH_ONT_NODES       NOD ON OB.ont_ID = NOD.ONT_ID;commit;
--4,223,704 rows inserted.
   

/* ************************************************************************************************
--Step 6: PULL visit dimension data 
--        This piece of code it dynamically generates queries using the VISIT_DIMENSION
--			to aggregate patient counts by calculating ages and ultimately joining the result to the ontology entry
--
--------------------------------------------------------------------------------------------------
--  Comments:
--  Modify schema names accordingly for <Metadata schema> and <CRCData schema>
--  SQL SERVER: YEAR(start_date) instead of EXTRACT(YEAR FROM SYSDATE)
--
************************************************************************************************ */   
-------------------------------------------------------------------------------------------------- 
-- Step 6.1: Create table in <CRCData schema>
--			 Run this command from <Metadata schema>
-------------------------------------------------------------------------------------------------- 
  DROP TABLE DASH_VISIT PURGE;
  CREATE TABLE DASH_VISIT
   (	ONT_ID NUMBER, 
	ONT_YEAR  NUMBER, 
	PATIENT_NUM NUMBER
   );
--------------------------------------------------------------------------------------------------
-- Step 6.2: Dynamic query generation to calculate age for each patient and pairing it to the corresponding ONTOLOGY_ID
--			 Run this query from <Metadata schema>. Replace <CRC schema> accordingly to match your environment.
--------------------------------------------------------------------------------------------------
SELECT 'INSERT INTO DASH_VISIT SELECT ' || '''' || ont.ont_id || '''' || ' as ont_id, EXTRACT(YEAR FROM start_date) AS ONT_YEAR , patient_num 
FROM <CRCData schema>.visit_dimension WHERE ' || ont.c_columnname || ' '  || ont.c_operator ||' ' || ont.c_dimcode || '; COMMIT;' as query_to_run
FROM ladr_DASH_ONTOLOGY         ont
JOIN ladr_DASH_ONT_NODES     NOD ON ONT.ont_ID = NOD.ONT_ID
WHERE 
		C_TABLENAME = 'visit_dimension'
		AND C_VISUALATTRIBUTES = 'LA';
-------------------------------------------------------------------------------------------------- 
-- Step 6.3: Generate entries per patient and per visit detail item
--			 Run this query from <Metadata schema> 
--------------------------------------------------------------------------------------------------


/* this is an example of one of the queries being generated
----------------------------------------------------------------------------------------------------------------------------------
INSERT INTO DASH_VISIT SELECT '324' as ont_id, EXTRACT(YEAR FROM start_date) AS observation_year, patient_num 
FROM I2B2_visit_dimension WHERE inout_cd = 'OA'; COMMIT;
----------------------------------------------------------------------------------------------------------------------------------
*/



/*---------------------------------------------------------------------
--Step 6.4: INSERT Visit details records FROM DASH_VISIT into DASH_OBSERVATION
--			Run this query from <Metadata schema>
-----------------------------------------------------------------------

*/---------------------------------------------------------------------
INSERT INTO DASH_OBSERVATION
SELECT DISTINCT
  OB.PATIENT_NUM,
  ob.ONT_YEAR,
  NOD.ont_ID,
  NOD.ONT_ID_LEVEL1,
  NOD.ONT_ID_LEVEL2,
  NOD.ONT_ID_LEVEL3,
  NOD.ONT_ID_LEVEL4,
  NOD.ONT_ID_LEVEL5,
  NOD.ONT_ID_LEVEL6,
  NOD.ONT_ID_LEVEL7,
  NOD.ONT_ID_LEVEL8,
  NOD.ONT_ID_LEVEL9,
  NOD.ONT_ID_LEVEL10,
  NOD.ONT_ID_LEVEL11,
  NOD.ONT_ID_LEVEL12,
  NOD.ONT_ID_LEVEL13,
  NOD.ONT_ID_LEVEL14,
  NOD.ONT_ID_LEVEL15,
  NOD.ONT_ID_LEVEL16,
  NOD.ONT_ID_LEVEL17,
  NOD.ONT_ID_LEVEL18,
  NOD.ONT_ID_LEVEL19,
  NOD.ONT_ID_LEVEL20
FROM DASH_VISIT             OB
JOIN <Metadata schema>.DASH_ONT_NODES       NOD ON OB.ont_ID = NOD.ONT_ID;commit;
--11,521,057 rows inserted.   


/* ************************************************************************************************
--Step 7: CREATE final aggregated counts for individual elements and rolled-up to every parent in the ontology
-----------------------------------------------------------------------
	We count DISTINCT patients by year and by node level ID, one pass per level
************************************************************************************************ */   

--------------------------------------------------------------------------------------------------
-- Step 7.1: Create final table where to load the counts
--			 --			Run this query from <Metadata schema>
--------------------------------------------------------------------------------------------------
DROP TABLE DASH_<Site acronym> PURGE;
CREATE TABLE DASH_<Site acronym>
   (	"ONT_YEAR" NUMBER, 
	"ONT_ID" NUMBER, 
	"PAT_COUNT" NUMBER, 
	"TOTAL_OBSERVATIONS" NUMBER, 
	"UPDATE_DATE" DATE
   ) ;

--------------------------------------------------------------------------------------------------
-- Step 7.2: Dynamic query generation to calculate aggregated counts by node level ID
--			 Run this query from <Metadata schema>. Replace <CRC schema> accordingly to match your environment. Do the same with <Site Acronym>
--------------------------------------------------------------------------------------------------
SELECT 'insert into DASH_<Site acronym> 
		SELECT 
		ONT_YEAR,
		ONT_ID_LEVEL' || C_HLEVEL || ' as ONT_ID,
		COUNT(DISTINCT PATIENT_NUM)  AS PATIENT_COUNT,
		COUNT(*)                     AS TOTAL_OBSERVATIONS,
		SYSDATE AS UPDATE_DATE
		FROM <Metadata schema>.DASH_OBSERVATION
		WHERE ONT_ID_LEVEL' || C_HLEVEL || ' IS NOT NULL
		GROUP BY ONT_YEAR,ONT_ID_LEVEL' || C_HLEVEL || '; COMMIT;' 
FROM (
		SELECT DISTINCT(C_HLEVEL) 
		FROM DASH_ONTOLOGY 
		ORDER BY C_HLEVEL
	);

 
-------------------------------------------------------------------------------------------------- 
-- Step 7.3: Generate individual patient counts for each ontology level ID by year
--			 Run this query from <Metadata schema>.
--------------------------------------------------------------------------------------------------


/* this is an example of one of the queries being generated in UCLA environment
----------------------------------------------------------------------------------------------------------------------------------
insert into DASH_UCLA
		SELECT 
		ONT_YEAR,
		ONT_ID_LEVEL2 as ONT_ID,
		COUNT(DISTINCT PATIENT_NUM)  AS PATIENT_COUNT,
		COUNT(*)                     AS TOTAL_OBSERVATIONS,
		SYSDATE AS UPDATE_DATE
		FROM LADR_DASH_OBSERVATION
		WHERE ONT_ID_LEVEL2 IS NOT NULL
		GROUP BY ONT_YEAR,ONT_ID_LEVEL2; COMMIT;
----------------------------------------------------------------------------------------------------------------------------------
*/

-------------------------------------------------------------------------------------------------- 
-- Step 7.4: Generate counts for all years combined (2 hours)
--			 Run this query from <Metadata schema>. Replace <CRC schema> accordingly to match your environment. Do the same with <Site Acronym>
--------------------------------------------------------------------------------------------------
SELECT 'insert into DASH_<Site Acronym>
		SELECT 
		9999,
		ONT_ID_LEVEL' || C_HLEVEL || ' as ONT_ID,
		COUNT(DISTINCT PATIENT_NUM)  AS PATIENT_COUNT,
		COUNT(*)                     AS TOTAL_OBSERVATIONS,
		SYSDATE AS UPDATE_DATE
		FROM <CRCData schema>.DASH_OBSERVATION
		WHERE ONT_ID_LEVEL' || C_HLEVEL || ' IS NOT NULL
		GROUP BY ONT_ID_LEVEL' || C_HLEVEL || '; COMMIT;' 
FROM (
		SELECT DISTINCT(C_HLEVEL) 
		FROM DASH_ONTOLOGY 
		ORDER BY C_HLEVEL
	);
--Example of the dynamically generated query 	
"insert into DASH_UCLA
		SELECT 
				9999,
				ONT_ID_LEVEL1 as ONT_ID,
				COUNT(DISTINCT PATIENT_NUM)  AS PATIENT_COUNT,
				COUNT(*)                     AS TOTAL_OBSERVATIONS,
				SYSDATE AS UPDATE_DATE
		FROM LADR_METADATA_1_7_04.DASH_OBSERVATION
		WHERE ONT_ID_LEVEL1 IS NOT NULL
		GROUP BY ONT_ID_LEVEL1; COMMIT;"


-------------------------------------------------------------------------------------------------- 
-- Step 7.5: Generate counts for individual ontology items ignoring roll-ups
--			There is a feature in the dashboard that allows to filter out ontology elements and 
--			their children based on the availability of data.
--			In order to provide the info to enable this feature, we need to calculate
--			The counts for each individual ontology record alone, without the children's records taking into account
--			Assigning year '8888' allows to separate this year from the others during data manipulation
--			Run this query from <Metadata schema>. Replace <CRC schema> accordingly to match your environment. Do the same with <Site Acronym>
--------------------------------------------------------------------------------------------------		
insert into LADR_DASH_UCLA
	SELECT 
		8888 as ONT_YEAR,
		ont.ONT_ID as ONT_ID,
		NVL(COUNT(DISTINCT PATIENT_NUM),null)  AS PATIENT_COUNT,
		NVL(COUNT(ob.ont_id),null)             AS TOTAL_OBSERVATIONS,
		SYSDATE AS UPDATE_DATE
	FROM LADR_DASH_ONTOLOGY   ont
    LEFT JOIN LADR_DASH_OBSERVATION ob ON ont.ont_id = ob.ont_id
		GROUP BY ont.ONT_ID;
		COMMIT;
select count(*) from LADR_DASH_UCLA   ; --     1020953
--415,998 rows inserted.
		    --415,962 rows inserted.
/* ************************************************************************************************
--Step 8: Final data pull: In order to be able to interpret and remap the results to common items 
--						across suites at the time of displaying the results
************************************************************************************************ */		
--Ontology (save file as DASH_ONTOLOGY_<Site_Acronym>.csv)
SELECT * FROM DASH_ONTOLOGY;

--	Actual results (save file as DASH_<Site_Acronym>.csv)
SELECT * FROM DASH_<Site Acronym>;


/* ************************************************************************************************
--Step 9: DELETE temp tables created during the process
************************************************************************************************ */
DROP TABLE DASH_AGE PURGE;
DROP TABLE DASH_OBSERVATION PURGE;
DROP TABLE DASH_VISIT PURGE;

--	If no changes are made to the ontology, you are welcome to keep DASH_ONTOLOGY AND DASH_ONT_NODES tables 
-- 	instead of recreating them every run. This will allow you to start the process on Step 4 after the first time
--	Otherwise
DROP TABLE DASH_ONT_NODES PURGE; 
DROP TABLE DASH_ONT_NODES_temp PURGE; 
DROP TABLE DASH_<Site Acronym> PURGE; 

 
