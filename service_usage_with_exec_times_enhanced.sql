
/*
-- Author:			Michael Goldsmith
-- Creation Date:	07 Aug 2013
-- Updated by:
-- Update Date:
*/

SET @start_date = '2013-08-05';       /* Start date for service usage to search for, or NULL if any*/
SET @end_date   = '2013-08-06';       /* End date for the servuce usage to search for, or NULL id any */
SET @services   = NULL;               /* Comma deliminated list of services, or NULL if any */
SET @min_exec_time = 60*1000;         /* Minimum execution time to search for */
SET @resource_id   = NULL;            /* Resource ID to search for, or NULL if any */

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS tmp_service_usage_filtered;

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_service_usage_filtered
AS (
	SELECT sut.resource_id
		, sut.service_name
		, sut.mode
		, sut.role_id
		, FROM_UNIXTIME((UNIX_TIMESTAMP(sut.create_date)-(sut.execution_time/1000))+1) start_time
		, sut.create_date end_time 
		, TIME_FORMAT(SEC_TO_TIME(sut.execution_time/1000),'%Hh %im %s secs.') total_exec_time
	FROM service_use_tracking sut
	WHERE sut.execution_time >= @min_exec_time
		AND (@start_date IS NULL OR (@start_date IS NOT NULL AND @start_date <= sut.create_date))
		AND (@end_date IS NULL OR (@end_date IS NOT NULL AND @end_date > sut.create_date))
		AND (@services IS NULL OR (@services IS NOT NULL AND FIND_IN_SET(sut.service_name, @services) != 0))
		AND (@resource_id IS NULL OR (@resource_id IS NOT NULL AND sut.resource_id=@resource_id))
);

SELECT MAX(end_time), MIN(start_time)
INTO @end_date, @start_date
FROM tmp_service_usage_filtered;

DROP TEMPORARY TABLE IF EXISTS tmp_service_usage;

CREATE TEMPORARY TABLE IF NOT EXISTS tmp_service_usage
AS (
	SELECT sut.resource_id
		, sut.service_name
		, sut.mode
		, sut.role_id
		, sut.create_date 
		, sut.execution_time
	FROM service_use_tracking sut
	WHERE sut.create_date >= @start_date AND sut.create_date <= @end_date
);

SELECT X.*
	, r.user_id
	, CONCAT(r.first_name, ' ', r.last_name) user_name
	, role.name role_name
	, (SELECT COUNT(*)
	FROM tmp_service_usage
	WHERE create_date >= X.start_time
	AND create_date <= X.end_time) AS requsts_while_running
FROM tmp_service_usage_filtered X
LEFT JOIN resource_def r ON X.resource_id=r.id
LEFT JOIN role_def role ON X.role_id=role.id;

COMMIT;