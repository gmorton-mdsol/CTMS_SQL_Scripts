SELECT r.identifier report_ref
	, r.display_name
	, CONCAT(r.dir_path, r.name) filename
	, rp.name param_name
	, rp.value param_value
	, r.id report_id
	, rp.id param_id
FROM report_dfn r
LEFT JOIN report_params rp ON r.id=rp.report_dfn_id 
WHERE rp.active='Y' AND r.active='Y'
AND r.identifier LIKE 'FUP%'
