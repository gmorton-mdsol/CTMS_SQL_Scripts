/*
-- Author:			Michael Goldsmith
-- Creation Date:	08 Mar 2013
-- Updated by:
-- Update Date:
*/

/*
-- Description: 
--
-- Returns all resources in a CTMS deployment (excluding system users) and how long it has been since
-- the user has used the system.
*/

SELECT r.id
	, r.active
	, r.first_name
	, r.last_name
	, r.user_id
	, S.last_usage
	, period_diff(date_format(now(), '%Y%m'), date_format(S.last_usage, '%Y%m')) last_usage_months
FROM 
	(SELECT resource_id, MAX(create_date) last_usage
	FROM service_use_tracking
	GROUP BY resource_id) S 
RIGHT JOIN resource_def r ON S.resource_id=r.id
WHERE r.system_user='N'
ORDER BY last_usage