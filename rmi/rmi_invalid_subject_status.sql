/*
 * Author: Michael Goldsmith
 * Date:	2013-MAR-01
 */

/*
	
Galderma RMI script #1:  to identify all unmapped RMI status in CTMS

This script should produce a result set with studyName/siteName/allSubjectFields where the subject status does not match an
active subjectStatus dropdown value.


*/


SELECT d.name study_name
	, s.name site_name
	, sd.screening_no
	, d.active study_active
	, s.active site_active
	, sd.active subject_active
	, sd.status subject_status
	, sd.*
FROM subject_def sd
INNER JOIN site_address sa ON sd.location_id=sa.id
INNER JOIN site_def s ON sa.site_id=s.id
INNER JOIN drugtrial_def d ON s.drugtrial_id=d.id
LEFT JOIN dropdown_lookup ddl1 ON ddl1.tag='subjectStatus' AND ddl1.active='Y' AND ddl1.value=sd.status
WHERE ddl1.id IS NULL;