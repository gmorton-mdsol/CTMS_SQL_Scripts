/*
 * Author: Michael Goldsmith
 * Date:	2013-MAR-01
 *
 * (v2 - restrict results to active subjects only)
 */

/*
	
Galderma RMI Script #3: to identify ongoing duplicate subjects passed by RMI into CTMS

This script should output studyName/siteName/allSubjectData where the subject_def.UUID = subject_def.SCREENING_NO.  

*/

SELECT d.name study_name
	, s.name site_name
	, sd.*
FROM (SELECT uuid FROM subject_def WHERE uuid=screening_no AND active='Y') U
INNER JOIN subject_def sd
INNER JOIN site_address sa ON sd.location_id=sa.id
INNER JOIN site_def s ON sa.site_id=s.id
INNER JOIN drugtrial_def d ON s.drugtrial_id=d.id
WHERE sd.uuid=U.uuid AND sd.active='Y';
