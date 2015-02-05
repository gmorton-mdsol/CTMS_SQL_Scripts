/*
-- Author:			Michael Goldsmith
-- Creation Date:	07 Aug 2013
-- Updated by:
-- Update Date:
*/

SET @start_date = '2013-08-25';       /* Start date for service usage to search for, or NULL if any*/
SET @end_date   = '2013-08-28';       /* End date for the servuce usage to search for, or NULL id any */
SET @services   = 'export_handler';   /* Comma deliminated list of services, or NULL if any */
SET @min_exec_time = 0;               /* Minimum execution time to search for */
SET @resource_id   = NULL;            /* Resource ID to search for, or NULL if any */

SELECT sut.resource_id
	, r.user_id
	, CONCAT(r.first_name, ' ', r.last_name) user_name
	, role.name role_name
	, sut.service_name
	, sut.mode
	, FROM_UNIXTIME(UNIX_TIMESTAMP(sut.create_date)-(sut.execution_time/1000)) start_time
	, sut.create_date end_time 
	, SEC_TO_TIME(sut.execution_time/1000) total_exec_time
FROM service_use_tracking sut
LEFT JOIN resource_def r ON sut.resource_id=r.id
LEFT JOIN role_def role ON role.id=sut.role_id
WHERE sut.execution_time >= @min_exec_time
	AND (@start_date IS NULL OR (@start_date IS NOT NULL AND @start_date <= sut.create_date))
	AND (@end_date IS NULL OR (@end_date IS NOT NULL AND @end_date > sut.create_date))
	AND (@services IS NULL OR (@services IS NOT NULL AND FIND_IN_SET(sut.service_name, @services) != 0))
	AND (@resource_id IS NULL OR (@resource_id IS NOT NULL AND sut.resource_id=@resource_id));
	