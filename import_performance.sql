SET @import_name = NULL;

SELECT il.ID
  , il.create_date start_date
  , COALESCE(il.update_date, S.create_date) end_date
  , SEC_TO_TIME(UNIX_TIMESTAMP(COALESCE(il.update_date, S.create_date)) - UNIX_TIMESTAMP(il.create_date)) execution_time 
  , il.tgt_file_name
  , il.name
  , il.comments
FROM integration_log il
LEFT JOIN
  (SELECT auto_id
      , execution_time
      , FROM_UNIXTIME(UNIX_TIMESTAMP(create_date)-(execution_time/1000)) start_date
      , create_date 
    FROM service_use_tracking
    WHERE service_name='upload' AND MODE='upload') S ON ABS(UNIX_TIMESTAMP(il.create_date) - UNIX_TIMESTAMP(S.start_date)) < 5
WHERE @import_name IS NULL OR il.name=@import_name;
