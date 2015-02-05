/*
-- Author:			Michael Goldsmith
-- Creation Date:	24 Mar 2013
-- Updated by:
-- Update Date:
*/

/*
-- Description: 
--
-- Returns all visit reports including the study, site and activity which they are for. This
-- is useful to quickly find existing visit reports on deployments which have large numbers
-- of studies and sites.
*/

SELECT d.name drugtrial_name
	, s.name site_name
	, vr.name vr_name
	, a.name activity_name
	, ddl.display vr_status
	, rd.identifier report_ref
	, vr.create_date vr_create_date
	, s.id site_id, s.drugtrial_id
	, vr.id vr_id, vr.cra_id vr_cra_id
	, vr.activity_id vr_activity_id
	, vr.locked
FROM (SELECT * FROM visit_report WHERE active='Y' ORDER BY create_date DESC) vr
INNER JOIN site_def s ON vr.assoc_obj='site_def' AND vr.assoc_obj_id=s.id AND s.active='Y'
INNER JOIN drugtrial_def d ON s.drugtrial_id=d.id AND d.active='Y'
INNER JOIN activity a ON vr.activity_id=a.id
INNER JOIN questionnaire_group qg ON qg.assoc_obj='visit_report' AND qg.assoc_obj_id=vr.id
INNER JOIN report_dfn rd ON rd.id=qg.report_dfn_id
INNER JOIN report_status rs ON rs.active_version='Y' AND rs.assoc_obj='visit_report' AND rs.assoc_obj_id=vr.id
INNER JOIN dropdown_lookup ddl ON ddl.tag='visitReportStatus' AND rs.status=ddl.value
ORDER BY d.name, s.name, vr.create_date
