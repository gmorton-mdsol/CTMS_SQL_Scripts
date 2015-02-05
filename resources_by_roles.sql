
SELECT R.name role_name
	, res.first_name
	, res.last_name
	, res.active
	, res.system_user
	, rr.active role_assignment_active
FROM (SELECT id, name FROM role_def WHERE name IN ('Admin(SU)', 'SU New')) R
LEFT JOIN resource_role rr ON R.id=rr.role_id
LEFT JOIN resource_def res ON rr.resource_id=res.id;
