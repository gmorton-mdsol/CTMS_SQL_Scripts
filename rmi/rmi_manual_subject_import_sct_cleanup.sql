 /*
--*****************************************************************************
-- Author:                  Michael Goldsmith
-- Creation Date:           2014-MAY-06
-- Updated By:              
-- Update Date:             
-- Task Management Ticket:  
-- Support Ticket:          
-- URL:                     
--*****************************************************************************
 
--*****************************************************************************
-- Description: The purpose of this script is to correct invalid subject status
--              values in the status_change_tracking table, as well as remove
--              duplicate entries caused by a bulk RMI subject data import.
--
--              Any previously existing status_change_tracking records for the
--              study will be removed, as well as any records which were not
--              created as the result of an RMI pull.
--
--              Since the status_change_tracking records created by the manual
--              pull are the correct [and complete set of] status changes from
--              Rave, and the STATUS_DATE is set to the CREATE_DATE when created
--              by the Rave import:
--                - If a record for a status change DID NOT already exist prior
--                  to the manual import, the STATUS_DATE will be that of the
--                  manual import (unchanged).
--                - If a record for a status change DID exist prior to the manual
--                  import, the STATUS_DATE will be set to that of the respective
--                  original record.

-- Keywords:    RMI, Status Change Tracking, Subject Status, Rave Integration,
--              Manual RMI Import

-- Logic:
--
-- 1. Either:
--    create backup table of status_change_tracking -> status_change_tracking_bak (when debugging)
--     .. or ..
--    perform mysqldump of table prior to script execution (execution in deployed site)
-- 2. Determine start and end time of import
-- 3. Create temp table for all status_change_tracking records -> sct_org_date_tmp (containing original status dates)
--    where:
--      - the subject is within the study
--      - the AUTO_UPDATE_SRC='subject_activity_csv_import' (only records which came over from RMI)
--      - the CREATE_DATE is not between the import timespan (only records which did not come from the manual import)
--    with:
--      - status_change_tracking.STATUS_DATE
--      - additional column "subject_status_index" which is an incrementing 1-based integer value
--        for each record where:
--          - the subject and status are the same
--      - additional column "subject_status_key"
--        which is a concatenation of:
--          - drugtrial_def.NAME
--          - site_def.NAME
--          - subject_def.SCREENING_NO
--          - subject_status_change.STATUS
--          - "subject_status_index"
--    NOTE:
--      - status_change_tracking must be ordered by ASSOC_OBJ_ID, STATUS, STATUS_DATE prior to calculating "subject_status_index"
--      - ensure the CREATE_DATE and "subject_status_index" are both in ascending order (i.e. min(create_date) has
--        index of 1; max(create_date) has highest index for the subject and status)
-- 4. Delete all status_change_tracking records (leaving only those which came from the manual import for the study)
--    where:
--      - the subject is within the study
--      - either:
--         - the AUTO_UPDATE_SRC != 'subject_activity_csv_import' (any records which did NOT come over from RMI)
--         - or:
--           - the AUTO_UPDATE_SRC = 'subject_activity_csv_import' (only records which came over from RMI)
--           - the CREATE_DATE is not between the import timespan (only records which did not come from the manual import)
-- 5. Update status_change_tracking (setting the STATUS_DATE to the first occurrence from the original status dates)
--*****************************************************************************
*/

SET @import_name='ImportRaveSubjects';
SET @import_filename='rmi_rave_spCtmsGetSubjectData_dump_all.csv.xml';
SET @import_date='2014-04-12';  
SET @drugtrial_name='PARTNER II A(Prod)';

/*
-- -----------------------------------
-- When testing, uncomment this section to quickly backup the original
-- status_change_tracking table.

-- 1. create backup table of status_change_tracking -> status_change_tracking_bak (when debugging)
DROP TABLE IF EXISTS status_change_tracking_bak;
  
CREATE TABLE status_change_tracking_bak AS
SELECT * FROM status_change_tracking;

-- -----------------------------------
*/

START TRANSACTION;

/*
-- 2. Determine start and end time of import
*/
SELECT @import_start := CREATE_DATE AS "import_start"
  , @import_end := UPDATE_DATE AS "import_end"
FROM integration_log
WHERE NAME = @import_name
  AND CREATE_DATE >= @import_date
  AND SRC_FILE_NAME = @import_filename
  AND UPDATE_DATE IS NOT NULL -- restrict to completed imports
LIMIT 1;


/*
* The next several queries require the status_change_tracking to be pre-ordered.
* For the sake of efficiency we will sort it once and keep as a temp table.
* As an added bonus, it will be limited to records for the study (shaves about 1 sec
* off execution time, but script is much cleaner also).
*/
DROP TEMPORARY TABLE IF EXISTS sct_sorted_tmp;

CREATE TEMPORARY TABLE sct_sorted_tmp AS
SELECT sct.ID
  , sct.STATUS
  , sct.STATUS_DATE
  , sct.ASSOC_OBJ_ID
  , sct.ASSOC_OBJ
  , sct.CREATE_DATE
  , sct.AUTO_UPDATE_SRC
  , dd.NAME AS "drugtrial_name"
  , site.NAME AS "site_name"
  , sd.SCREENING_NO
FROM status_change_tracking sct
INNER JOIN subject_def sd ON sct.ASSOC_OBJ_ID = sd.ID AND sct.ASSOC_OBJ = 'subject_def'
INNER JOIN site_address sa ON sd.LOCATION_ID = sa.ID
INNER JOIN site_def site ON sa.SITE_ID = site.ID
INNER JOIN drugtrial_def dd ON site.DRUGTRIAL_ID = dd.ID
WHERE dd.NAME = @drugtrial_name
ORDER BY sct.ASSOC_OBJ_ID, sct.STATUS, sct.STATUS_DATE;

/*
-- 3. Create temp table for all status_change_tracking records -> sct_org_date_tmp (containing original status dates)
*/
SET @v_prv_subj=NULL;
SET @v_prv_stat=NULL;
SET @v_counter=0;

DROP TEMPORARY TABLE IF EXISTS sct_org_date_tmp;

CREATE TEMPORARY TABLE sct_org_date_tmp AS
SELECT @v_counter := CASE 
      WHEN @v_prv_subj = sst.SCREENING_NO AND @v_prv_stat = sst.STATUS 
      THEN @v_counter + 1
      ELSE 1 
    END AS "subject_status_index"
    , CONCAT(sst.drugtrial_name, '-', sst.site_name, '-', sst.SCREENING_NO, '-', sst.STATUS, '-', @v_counter) AS "subject_status_key"
  , @v_prv_stat := sst.STATUS AS STATUS
  , @v_prv_subj := sst.SCREENING_NO AS SCREENING_NO 
  , sst.STATUS_DATE
  , sst.CREATE_DATE
FROM sct_sorted_tmp sst
WHERE sst.AUTO_UPDATE_SRC = 'subject_activity_csv_import'
  AND sst.CREATE_DATE NOT BETWEEN @import_start AND @import_end;
  
-- Get count of status_change_tracking records prior to deleting
SELECT COUNT(*) INTO @sct_pre_count FROM status_change_tracking sct;

/*
-- 4. Delete all status_change_tracking records (leaving only those which came from the manual import for the study)
*/
DELETE FROM sct
USING status_change_tracking sct
INNER JOIN subject_def sd ON sct.ASSOC_OBJ_ID=sd.ID AND sct.ASSOC_OBJ='subject_def'
INNER JOIN site_address sa ON sd.LOCATION_ID = sa.ID
INNER JOIN site_def site ON sa.SITE_ID = site.ID
INNER JOIN drugtrial_def dd ON site.DRUGTRIAL_ID = dd.ID
WHERE dd.NAME = @drugtrial_name
  AND (sct.AUTO_UPDATE_SRC != 'subject_activity_csv_import'
    OR (sct.AUTO_UPDATE_SRC = 'subject_activity_csv_import'
      AND sct.CREATE_DATE NOT BETWEEN @import_start AND @import_end));

-- Get count of status_change_tracking records after deleting [to determine number of records deleted]
SELECT COUNT(*) INTO @sct_post_count FROM status_change_tracking sct;

-- Create temporary of status_change_tracking records which came from the manual import
SET @v_prv_subj=NULL;
SET @v_prv_stat=NULL;
SET @v_counter=0;

DROP TEMPORARY TABLE IF EXISTS sct_from_man_import;

CREATE TEMPORARY TABLE sct_from_man_import AS
SELECT ID AS "sct_id"
    , @v_counter := CASE 
        WHEN @v_prv_subj = SCREENING_NO AND @v_prv_stat = STATUS 
        THEN @v_counter + 1
        ELSE 1 
      END AS "subject_status_index"
    , CONCAT(drugtrial_name, '-', site_name, '-', SCREENING_NO, '-', STATUS, '-', @v_counter) AS "subject_status_key"
    , @v_prv_stat := STATUS AS STATUS
    , @v_prv_subj := SCREENING_NO AS SCREENING_NO 
    , STATUS_DATE
    , CREATE_DATE
FROM sct_sorted_tmp
WHERE CREATE_DATE BETWEEN @import_start AND @import_end;
  
-- Determine how many record will have the STATUS_DATE updated (should be same as sct_from_man_import count)
SELECT COUNT(*) INTO @sct_update_count
FROM status_change_tracking sct
INNER JOIN sct_from_man_import sfmi ON sct.ID = sfmi.sct_id
INNER JOIN sct_org_date_tmp sodt ON sfmi.subject_status_key = sodt.subject_status_key
WHERE sct.STATUS_DATE != sodt.STATUS_DATE;


/*
-- 5. Update status_change_tracking (setting the STATUS_DATE to the first occurrence from the original status dates)
*/
UPDATE status_change_tracking sct
INNER JOIN sct_from_man_import sfmi ON sct.ID = sfmi.sct_id
INNER JOIN sct_org_date_tmp sodt ON sfmi.subject_status_key = sodt.subject_status_key
SET sct.STATUS_DATE = sodt.STATUS_DATE;

-- Output script metrics
SELECT "sct_pre_count" AS "metric", @sct_pre_count AS "value"
UNION ALL
SELECT "sct_post_count" AS "metric", @sct_post_count AS "value" 
UNION ALL
SELECT "sct_records_deleted" AS "metric", @sct_pre_count-@sct_post_count AS "value"
UNION ALL
SELECT "sct_from_man_import count" AS "metric", COUNT(*) AS "value" FROM sct_from_man_import
UNION ALL
SELECT "sct_update_count" AS "metric", @sct_update_count AS "value";
  
DROP TEMPORARY TABLE sct_from_man_import;

DROP TEMPORARY TABLE sct_org_date_tmp;

DROP TEMPORARY TABLE sct_sorted_tmp;

COMMIT;

/*
-- -----------------------------------
-- When testing, uncomment this section to quickly restore the original
-- status_change_tracking table from backup.

DELETE FROM status_change_tracking;

INSERT INTO status_change_tracking
SELECT * FROM status_change_tracking_bak;

-- -----------------------------------
*/
