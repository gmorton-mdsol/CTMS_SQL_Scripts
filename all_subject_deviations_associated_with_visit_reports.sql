/*
-- Author:			Michael Goldsmith
-- Creation Date:	20 Feb 2013
-- Updated by:
-- Update Date:
*/

/*
-- Description: 
--
-- Returns all subject deviations which are linked to a visit report. This is helpful when
-- testing something for a visit report which requires subject deviations, but it is not 
-- known which visit report.
*/

SELECT d.name study
	, s.name site_name
	, v.name visit_report_name
	, va.name activity_name
	, rd.identifier report_reference
	, D.*, v.id visit_report_id
FROM (
	SELECT description subj_deviation_description
		, id subject_deviation_id
		, deviations_id
		, subject_id
		, activity_id
		, create_date
	FROM subject_deviations
	WHERE activity_id IS NOT NULL
	) D
INNER JOIN activity a ON D.activity_id=a.id AND a.linked_obj='visit_report'
LEFT JOIN visit_report v ON a.linked_obj_id=v.id
LEFT JOIN site_def s ON s.id=v.assoc_obj_id
LEFT JOIN drugtrial_def d ON d.id=s.drugtrial_id
LEFT JOIN activity va ON v.activity_id=va.id
LEFT JOIN questionnaire_group qg ON qg.assoc_obj='visit_report' AND qg.assoc_obj_id=v.id
LEFT JOIN report_dfn rd ON rd.id=qg.report_dfn_id
ORDER BY D.create_date DESC