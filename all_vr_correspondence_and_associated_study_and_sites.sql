SELECT d.name drugtrial_name
	, s.name site_name
	, vr.name vr_name
	, c.name cor_name
	, a.name activity_name
	, rd.identifier report_ref
	/*
	, CASE
		WHEN c.assoc_obj='activity' THEN 'Confirmation Letter'
		WHEN c.assoc_obj='visit_report' THEN 'Follow-Up Letter'
	  END AS type
	*/
	, c.create_date cor_create_date
	, s.id site_id, s.drugtrial_id
	, vr.id vr_id, vr.cra_id vr_cra_id
	, vr.activity_id vr_activity_id
	, c.id correspondence_id
FROM (SELECT * FROM visit_report WHERE active='Y' ORDER BY create_date DESC) vr
INNER JOIN site_def s ON (vr.assoc_obj='site_def' AND vr.assoc_obj_id=s.id AND s.active='Y')
INNER JOIN drugtrial_def d ON (s.drugtrial_id=d.id AND d.active='Y')
INNER JOIN correspondence c
	ON (c.assoc_obj='visit_report' AND c.assoc_obj_id=vr.id) OR (c.assoc_obj='activity' AND c.assoc_obj_id=vr.activity_id)
INNER JOIN activity a
	ON a.active='Y' AND vr.activity_id=a.id 
INNER JOIN questionnaire_group qg ON (qg.assoc_obj='correspondence' AND qg.assoc_obj_id=c.id)
INNER JOIN report_dfn rd ON rd.id=qg.report_dfn_id
ORDER BY d.name, s.name, c.create_date
