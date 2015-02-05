
SET @start_date = '2013-10-29';       /* Start date, or NULL if any */
SET @end_date   = '2013-10-29';       /* End date, or NULL id any */

SELECT scp.ID AS CRF_PAGE_ID
  , scp.IDENTIFIER AS CRF_PAGE_IDENTIFIER
  , scp.UUID AS CRF_PAGE_UUID
  , scp.NAME AS CRF_PAGE_NAME
  , scp.REFERENCE AS CRF_PAGE_REFERENCE
  , scp.VERIFIED AS CRF_PAGE_VERIFIED
  , il.ID AS INTEGRATION_LOG_ID
  , h.CREATE_DATE
  , il.NAME AS IMPORTER
  , il.CREATE_DATE AS IMPORT_START_TIME
  , il.UPDATE_DATE AS IMPORT_END_TIME
  , LEFT(il.TGT_FILE_NAME, LOCATE('/', il.TGT_FILE_NAME)-1) TGT_PATH
  , SUBSTRING(il.TGT_FILE_NAME, LOCATE('/', il.TGT_FILE_NAME)+1) TGT_FILE
  , il.COMMENTS
  , il.DETAIL
FROM 
  (SELECT *
    FROM history
    WHERE TARGET='subject_crf_page' 
    AND NOTES LIKE 'insert into subject_crf_page%'
	AND (@start_date IS NULL OR CREATE_DATE >= @start_date)
	AND (@end_date IS NULL OR CREATE_DATE < @end_date)) h
LEFT JOIN 
  (SELECT ID
    , NAME
    , COMMENTS
    , DETAIL
    , CREATE_DATE
    , UPDATE_DATE
    , SUBSTRING(TGT_FILE_NAME, LOCATE('releases/', TGT_FILE_NAME)+LENGTH('releases/0123456789012345678901234567890123456789/app/WEB-INF/../../glue//')) TGT_FILE_NAME
   FROM integration_log
   WHERE (@start_date IS NULL OR CREATE_DATE >= @start_date)
   AND (@end_date IS NULL OR CREATE_DATE < @end_date)) il ON h.CREATE_DATE BETWEEN il.CREATE_DATE AND il.UPDATE_DATE
INNER JOIN subject_crf_page scp ON scp.ID=h.ROW_ID AND il.NAME=scp.AUTO_UPDATE_SRC
WHERE (@start_date IS NULL OR CREATE_DATE >= @start_date)
   AND (@end_date IS NULL OR CREATE_DATE < @end_date)
