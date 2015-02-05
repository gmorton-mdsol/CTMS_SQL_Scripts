/*
--************************************************************************************************
-- Author:			Michael Goldsmith
-- Creation Date:	2013-07-03
-- Updated by:		
-- Update Date:		
--************************************************************************************************
 
--************************************************************************************************
-- Description: 

-- Variables: @db_schema	Name of the schema to retreive the record count for
--
--************************************************************************************************
*/	

SET @db_schema = 'forest_prod';

/* Ensure GROUP_CONCAT does not truncate after 1024 chars */
SET @org_value = @@group_concat_max_len;
SET @@group_concat_max_len = 32768;

/* Construct a series of SELECTs to retreive record count joined by UNIONs */
SET @sql_stmt = (SELECT GROUP_CONCAT(CONCAT('SELECT "', table_name, '" AS `table`, COUNT(*) as records FROM ', @db_schema,'.', table_name) 
      SEPARATOR ' UNION ' )
      FROM information_schema.tables
      WHERE table_schema=@db_schema);

/* Execute the generated SQL and deallocate */
PREPARE table_list FROM @sql_stmt;
EXECUTE table_list;
DEALLOCATE PREPARE table_list;

/* Restore system variable */
SET @@group_concat_max_len = @org_value;