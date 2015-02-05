/*
-- Author:			Michael Goldsmith
-- Creation Date:	16 Nov 2012
-- Updated by:
-- Update Date:
*/

/*
-- Description: 
--
-- Returns the number of concurrent users active on the system within a given time-span, along
-- with the average execution time, broken down by the hour.
*/

SELECT R.yr
	, R.mo
	, R.da
	, R.hr
	, (SUM(sum_execution_time) / SUM(resource_usage)) avg_execution_time_ms
	, COUNT(*) concurent_users
FROM
    (SELECT YEAR(create_date) yr
		, MONTH(create_date) mo
		, DAY(create_date) da
		, HOUR(create_date) hr
		, resource_id
		, SUM(execution_time) sum_execution_time
		, COUNT(*) resource_usage
    FROM service_use_tracking
    WHERE create_date BETWEEN '2012-06-01' AND '2012-11-17'
    GROUP BY yr,mo,da,hr,resource_id) R
GROUP BY R.yr, R.mo, R.da, R.hr
