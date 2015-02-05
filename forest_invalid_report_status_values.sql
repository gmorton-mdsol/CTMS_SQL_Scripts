USE forest_prod;

CREATE TEMPORARY TABLE chron_report_status AS
SELECT C.*, CASE Count(*) WHEN 1 THEN '' ELSE 'Multiple records with same timestamp' END AS rs_table_issues
FROM
	(SELECT A.ID,A.ASSOC_OBJ_ID,A.ASSOC_OBJ,A.ASSIGNED_OBJ_ID,A.ASSIGNED_OBJ,A.NAME,A.STATUS,A.CATEGORY,A.TYPE,A.ACTIVE_VERSION,A.REQUESTED_REVIEWER_ID,A.SPONSOR_REVIEWER_ID,A.REVIEW_DATE,A.REVIEWED,A.REVIEWED_BY,A.REVIEWED_BY_OBJ,A.REVIEWED_BY_ID,A.REVIEW2_DATE,A.REVIEWED2,A.REVIEWED2_BY,A.REVIEWED2_BY_OBJ,A.REVIEWED2_BY_ID,A.FINALISED_DATE,A.FINALISED,A.FINALISED_BY,A.FINALISED_BY_OBJ,A.FINALISED_BY_ID,A.RECEIVED_DATE,A.RECEIVED,A.RECEIVED_BY,A.RECEIVED_BY_OBJ,A.RECEIVED_BY_ID,A.SIGNED_DATE,A.SIGNED,A.SIGNED_BY,A.SIGNED_BY_OBJ,A.SIGNED_BY_ID,A.SUBMITTED_DATE,A.SUBMITTED,A.SUBMITTED_BY,A.SUBMITTED_BY_OBJ,A.SUBMITTED_BY_ID,A.SUBMISSION_DEADLINE,A.APPROVAL_DEADLINE,A.SENT_DATE,A.SUPPORT_DOCUMENT,A.REQUESTED_APPROVER_ID,A.APPROVED,A.APPROVED_DATE,A.APPROVED_BY,A.APPROVED_BY_OBJ,A.APPROVED_BY_ID,A.APPROVED2,A.APPROVED2_DATE,A.APPROVED2_BY,A.APPROVED2_BY_OBJ,A.APPROVED2_BY_ID,A.APPROVED3,A.APPROVED3_DATE,A.APPROVED3_BY,A.APPROVED3_BY_OBJ,A.APPROVED3_BY_ID,A.APPROVED4,A.APPROVED4_DATE,A.APPROVED4_BY,A.APPROVED4_BY_OBJ,A.APPROVED4_BY_ID,A.FOLLOWUP_DATE,A.FOLLOWUP,A.FOLLOWUP_BY,A.FOLLOWUP_BY_OBJ,A.FOLLOWUP_BY_ID,A.X1_DATE,A.X2_DATE,A.X3_DATE,A.X4_DATE,A.UPDATED_BY_ID,A.DESCRIPTION,B.CREATE_DATE,A.USER_TIME_ZONE,A.TZ_ID,A.UPDATE_DATE,A.AUTO_UPDATE_DATE,A.AUTO_UPDATE_SRC,A.LAST_UPDT_BY_ID,A.CREATED_BY_ID,A.ACTIVE,A.ARCHIVE_FLAG,A.DEL_FLAG
	FROM
		(SELECT * FROM report_status ORDER BY update_date) A
	INNER JOIN
		(SELECT * FROM report_status ORDER BY create_date) B ON A.assoc_obj_id=B.assoc_obj_id
	WHERE 
		(A.update_date IS NULL AND B.active_version='Y') 
		OR 
		(A.update_date IS NOT NULL AND A.update_date=B.create_date)
	ORDER BY A.assoc_obj_id, B.create_date) C
GROUP BY C.id;

SELECT X.issue_type, X.incorrect_status_count
	, act.id activity_id, X.id report_status_id, vr.id visit_report_id
	, dt.name study_name, s.name site_name, vr.type vr_type
	, act.reference, act.start_date, act.done_date
	, X.status report_status
	, X.finalised_date, X.finalised, X.finalised_by
	, X.review_date, X.reviewed, X.reviewed_by
	, X.approved_date, X.approved, X.approved_by
FROM (
	/* Determine reports where the status checkboxes are inconsistant with the workflow */
	SELECT 'Missing Approved or Finalised' issue_type, rs.*, count(*) incorrect_statuses
	FROM
		(SELECT * FROM report_status WHERE active_version='Y'	AND status NOT IN ('3','11')) RSA
	INNER JOIN
		(SELECT * FROM report_status WHERE status IN ('31', '32', '35') AND (approved='N' OR finalised='N')) rs
	ON RSA.assoc_obj_id=rs.assoc_obj_id
	WHERE RSA.status IN ('31', '32', '35')
	GROUP BY RSA.assoc_obj_id

	UNION ALL

	SELECT 'Missing Reviewed' issue_type, rs.*, count(*) incorrect_statuses
	FROM (SELECT * FROM chron_report_status WHERE status IN ('31','41')) RSR
	INNER JOIN forest_prod.chron_report_status rs ON RSR.assoc_obj_id=rs.assoc_obj_id
	WHERE RSR.create_date < rs.create_date	AND rs.reviewed='N'
	GROUP BY rs.assoc_obj_id
	) X
LEFT JOIN visit_report vr on vr.id=X.assoc_obj_id
LEFT JOIN activity act ON act.assoc_obj_id=vr.id
LEFT JOIN site_def s on s.id=vr.assoc_obj_id
LEFT JOIN drugtrial_def dt on dt.id=s.drugtrial_id
