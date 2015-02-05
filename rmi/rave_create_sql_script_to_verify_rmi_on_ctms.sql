DECLARE @study nvarchar(4000);
DECLARE @ProjectID int;
DECLARE @StudyID int = null;
DECLARE @CraRoleID int;

SET @study='BUP3031(Prod)'

SELECT @StudyID = s.StudyID, @ProjectID = p.ProjectID 
FROM dbo.Studies s
JOIN dbo.Projects p ON s.ProjectID = p.ProjectID
WHERE dbo.fnLocalDefault(P.ProjectName)+'('+dbo.fnLocalDefault(EnvironmentNameID)+')' = @study;

SELECT @CraRoleID = CAST(c.ConfigValue AS int)
FROM Configuration c
WHERE c.Tag = 'CRARoleForCTMSPull';

CREATE TABLE #CtmsMetrics (
	DataPageID int,
	Verified nvarchar(1),
	Reviewed nvarchar(1),
	TotalIsTouched int,
	AuditID int)
CREATE CLUSTERED INDEX IX_CtmsMetrics_DataPageID ON #CtmsMetrics (DataPageID)

INSERT INTO #CtmsMetrics (DataPageID, AuditID)
SELECT DataPageID, MAX(AuditID) AuditID
FROM (
    SELECT dp.DataPageID, a.AuditID
    FROM dbo.Audits a WITH (NOLOCK)
    JOIN dbo.DataPages dp WITH (NOLOCK) ON a.ObjectID = dp.DataPageID
    JOIN dbo.Records r WITH (NOLOCK) ON r.DataPageID = dp.DataPageID
    JOIN dbo.Subjects s WITH (NOLOCK) ON s.SubjectID = r.SubjectID
    JOIN dbo.StudySites ss WITH (NOLOCK) ON ss.StudySiteID = s.StudySiteID
    WHERE a.ObjectTypeID = 3
		AND ss.StudyID = @StudyID
		AND EXISTS (SELECT null FROM dbo.CtmsSubjectMetricsAuditCategoryLookup acl WHERE acl.ObjectTypeID = 3 AND a.AuditsubCategoryID = acl.SubCategoryId)
		AND s.Deleted = 0
		AND dp.Deleted = 0
    
    UNION
    
    -- Add DataPages to temp table for any modified Records
    SELECT r.DataPageID, a.AuditID
    FROM dbo.Audits a WITH (NOLOCK)
    JOIN dbo.Records r WITH (NOLOCK) ON r.RecordID = a.ObjectID
    JOIN dbo.Subjects s WITH (NOLOCK) ON s.SubjectID = r.SubjectID
    JOIN dbo.StudySites ss WITH (NOLOCK) ON ss.StudySiteID = s.StudySiteID
    WHERE a.ObjectTypeID = 2
		AND ss.StudyID = @StudyID
		AND EXISTS (SELECT null FROM dbo.CtmsSubjectMetricsAuditCategoryLookup acl WHERE acl.ObjectTypeID = 2 AND a.AuditsubCategoryID = acl.SubCategoryId)
		AND s.Deleted = 0
		AND r.Deleted = 0
		
    UNION
    
    -- Add DataPages to temp table for any modified DataPoints  
    SELECT d.DataPageID, a.AuditID
    FROM dbo.Audits a WITH (NOLOCK)
    JOIN dbo.DataPoints d WITH (NOLOCK) ON a.ObjectID = d.DataPointID
    JOIN dbo.Records r WITH (NOLOCK) ON r.RecordID = d.RecordID
    JOIN dbo.Subjects s WITH (NOLOCK) ON s.SubjectID = r.SubjectID
    JOIN dbo.StudySites ss WITH (NOLOCK) ON ss.StudySiteID = s.StudySiteID
    WHERE a.ObjectTypeID = 1
		AND ss.StudyID = @StudyID
		AND EXISTS (SELECT null FROM dbo.CtmsSubjectMetricsAuditCategoryLookup acl WHERE acl.ObjectTypeID = 1 AND a.AuditsubCategoryID = acl.SubCategoryId)
		AND s.Deleted = 0
		AND r.Deleted = 0
		AND d.Deleted = 0) a
GROUP BY DataPageID;

UPDATE cm1
SET Reviewed = CASE WHEN t2.TotalNotReviewed = 0 AND t2.TotalIsReviewed > 0 THEN 'Y' ELSE 'N' END
FROM #CtmsMetrics cm1
JOIN (SELECT r.DataPageID,
		SUM(CAST(o.RequiresReview AS int)) AS TotalNotReviewed,
		SUM(CAST(o.IsReviewed AS int)) AS TotalIsReviewed
	FROM #CtmsMetrics cm2
	JOIN dbo.Records r WITH (NOLOCK) ON r.DataPageID = cm2.DataPageID
	JOIN dbo.DataPoints d WITH (NOLOCK) ON r.RecordID = d.RecordID
	JOIN dbo.Fields f WITH (NOLOCK) ON d.FieldID = f.FieldID
	JOIN dbo.ObjectStatus o WITH (NOLOCK) ON o.ObjectTypeID = 1 
		AND o.ObjectID = d.DataPointID
		AND o.RoleID = @CraRoleID  
	WHERE d.Deleted = 0
		AND ISNULL(d.IsUserDeactivated, 0) = 0 
		AND r.Deleted = 0
		AND ISNULL(r.IsUserDeactivated, 0) = 0
		AND ((r.RecordPosition = 0 AND f.IsLog = 0)
			OR (r.RecordPosition > 0 AND f.IsLog = 1))
	GROUP BY r.DataPageID) AS t2 ON cm1.DataPageID = t2.DataPageID;

UPDATE cm1
SET Verified = CASE WHEN t2.TotalRequiresVerification = 0 AND t2.TotalIsVerified > 0 THEN 'Y' ELSE 'N' END,
	TotalIsTouched = t2.TotalIsTouched
FROM #CtmsMetrics cm1
JOIN (SELECT r.DataPageID,
		SUM(CAST(o.RequiresVerification as int)) AS TotalRequiresVerification,
		SUM(CAST(o.IsVerified AS int)) AS TotalIsVerified,
		SUM(CAST(o.IsTouched AS int)) AS TotalIsTouched 
	FROM #CtmsMetrics cm2
	JOIN dbo.Records r WITH (NOLOCK) ON r.DataPageID = cm2.DataPageID
	JOIN dbo.DataPoints d WITH (NOLOCK) ON r.RecordID = d.RecordID
	JOIN dbo.Fields f WITH (NOLOCK) ON d.FieldID = f.FieldID
	JOIN dbo.ObjectStatus o WITH (NOLOCK) ON o.ObjectTypeID = 1 
		AND o.ObjectID = d.DataPointID
		AND o.RoleID = -2  
	WHERE d.Deleted = 0
		AND ISNULL(d.IsUserDeactivated,0) = 0 
		AND r.Deleted = 0
		AND ISNULL(r.IsUserDeactivated,0) = 0
		AND ((r.RecordPosition = 0 AND f.IsLog = 0)
			OR (r.RecordPosition > 0 AND f.IsLog = 1))
	GROUP BY r.DataPageID) AS t2 ON cm1.DataPageID = t2.DataPageID;
	
CREATE TABLE #CtmsSql (
	SQL_STMNT nvarchar(max),
	subject_crf_page_reference varchar(50),
	activity_name nvarchar(1000),
	activity_reference varchar(50))

INSERT INTO #CtmsSql
SELECT N'(scp.NAME="' + REPLACE(dbo.fnLocalDefault(fo.FormName), N'"', N'""') + N'" ' + 
    N'AND scp.NUMERIC_REF="' + Convert(nvarchar(50),(ISNULL(i.InstanceRepeatNumber,0)+1)) + N'" ' + 
    N'AND scp.ALPHA_REF="' + Convert(nvarchar(50),(ISNULL(dp.PageRepeatNumber,0)+1)) + N'" ' + 
    N'AND scp.REPEAT_KEY="' + Convert(nvarchar(50),(ISNULL(dp.PageRepeatNumber,0)+1)) + N'" ' +  
    N'AND scp.REVIEWED="' + ISNULL(tmpDP.Reviewed,'N') + '" ' + 
    N'AND scp.VERIFIED="' + ISNULL(tmpDP.Verified,'N') + '" ' +
    N'AND dd.NAME="' + REPLACE(@study, '"', '""') + '" ' + 
    N'AND site.NAME="' + REPLACE(si.sitenumber, '"', '""') + '" ' + 
    N'AND sd.SCREENING_NO="' + REPLACE(s.subjectname, '"', '""') + '")' AS SQL_STMNT,
    fo.OID as subject_crf_page_reference,
    REPLACE(ISNULL(LTRIM(RTRIM(SUBSTRING(dbo.fnLocalizedInstanceName('eng', ip.ParentInstanceID), 1, 65))) + ', ', '') 
        + ISNULL(LTRIM(RTRIM(SUBSTRING(dbo.fnLocalizedInstanceName('eng', i.ParentInstanceID), 1, 65))) + ', ', '') 
        + ISNULL(LTRIM(RTRIM(SUBSTRING(dbo.fnLocalizedInstanceName('eng', i.InstanceID), 1, 65))), ''), '"', '""') AS activity_name, 
    fl.Oid as activity_reference
FROM #CtmsMetrics tmpDP
JOIN dbo.DataPages dp WITH (NOLOCK) ON tmpDP.DataPageID = dp.DataPageID
LEFT JOIN dbo.Instances i WITH (NOLOCK) ON dp.InstanceID = i.InstanceID
LEFT JOIN dbo.Instances ip WITH (NOLOCK) ON ip.InstanceID = i.ParentInstanceID
LEFT JOIN dbo.Folders fl WITH (NOLOCK) ON fl.FolderID = i.FolderID
JOIN dbo.Forms fo WITH (NOLOCK) ON fo.FormID = dp.FormID
JOIN dbo.Records r WITH (NOLOCK) ON r.DataPageID = dp.DataPageID
JOIN dbo.Subjects s WITH (NOLOCK) ON s.SubjectID = r.SubjectID
JOIN dbo.StudySites ss WITH (NOLOCK) ON ss.StudySiteID = s.StudySiteID
JOIN dbo.Sites si WITH (NOLOCK) ON si.SiteID = ss.SiteID        
JOIN dbo.ObjectTags2 ot WITH (NOLOCK) ON ot.ProjectID = @ProjectID 
    AND ot.ObjectTypeID = 101 AND ot.active = 1
    AND ot.TagOID IN ('Visit Folder')
    AND ot.TagValue = fl.OID
WHERE ss.StudyID = @StudyID 
    AND tmpDP.TotalIsTouched IS NOT NULL
UNION
SELECT N'(scp.NAME="' + REPLACE(dbo.fnLocalDefault(fo.FormName), N'"', N'""') + N'" ' + 
    N'AND scp.NUMERIC_REF="' + Convert(nvarchar(50),(ISNULL(i.InstanceRepeatNumber,0)+1)) + N'" ' + 
    N'AND scp.ALPHA_REF="' + Convert(nvarchar(50),(ISNULL(dp.PageRepeatNumber,0)+1)) + N'" ' + 
    N'AND scp.REPEAT_KEY="' + Convert(nvarchar(50),(ISNULL(dp.PageRepeatNumber,0)+1)) + N'" ' +  
    N'AND scp.REVIEWED="' + ISNULL(tmpDP.Reviewed,'N') + '" ' + 
    N'AND scp.VERIFIED="' + ISNULL(tmpDP.Verified,'N') + '" ' +
    N'AND dd.NAME="' + REPLACE(@study, '"', '""') + '" ' + 
    N'AND site.NAME="' + REPLACE(si.sitenumber, '"', '""') + '" ' + 
    N'AND sd.SCREENING_NO="' + REPLACE(s.subjectname, '"', '""') + '")' AS SQL_STMNT,
    fo.OID as subject_crf_page_reference,
    ISNULL(REPLACE(ISNULL(ltrim(rtrim(substring(dbo.fnLocalizedInstanceName('eng', ip.ParentInstanceID), 1, 65))) + ', ', '') 
        + ISNULL(ltrim(rtrim(substring(dbo.fnLocalizedInstanceName('eng', i.ParentInstanceID), 1, 65))) + ', ', '') 
        + ISNULL(ltrim(rtrim(substring(dbo.fnLocalizedInstanceName('eng', i.InstanceID), 1, 65))), ''), '"', '""'),
    'Subject') as activity_name, 
    fl.Oid as activity_reference
FROM #CtmsMetrics tmpDP
JOIN dbo.DataPages dp WITH (NOLOCK) ON tmpDP.DataPageID = dp.DataPageID
LEFT JOIN dbo.Instances i WITH (NOLOCK) ON dp.InstanceID = i.InstanceID
LEFT JOIN dbo.Instances ip WITH (NOLOCK) ON ip.InstanceID = i.ParentInstanceID
LEFT JOIN dbo.Folders fl WITH (NOLOCK) ON fl.FolderID = i.FolderID
JOIN dbo.Forms fo WITH (NOLOCK) ON fo.FormID = dp.FormID
JOIN dbo.Records r WITH (NOLOCK) ON r.DataPageID = dp.DataPageID
JOIN dbo.Subjects s WITH (NOLOCK) ON s.SubjectID = r.SubjectID
JOIN dbo.StudySites ss WITH (NOLOCK) ON ss.StudySiteID = s.StudySiteID
JOIN dbo.Sites si WITH (NOLOCK) ON si.SiteID = ss.SiteID        
    AND fl.OID IS NULL
WHERE ss.StudyID = @StudyID 
    AND tmpDP.TotalIsTouched IS NOT NULL

DECLARE @RowCount int
SELECT @RowCount = COUNT(*) FROM #CtmsSql

DECLARE @SqlText nvarchar(max)
SELECT @SqlText = coalesce(@SqlText,'') + SQL_STMNT + ' OR ' + char(13)+ char(10) FROM #CtmsSql;

SET @SqlText='SELECT dd.NAME AS drugtrial_name, "SubjectMetrics" AS ImportType, CASE WHEN count(*)=' + convert(nvarchar(50),@RowCount) + ' THEN "Data is correct" ELSE "Data does not match" END AS "Status"'+ char(13)+ char(10) +
	'FROM subject_crf_page scp'+ char(13)+ char(10)+
	'INNER JOIN subject_crf sc ON scp.SUBJECT_CRF_ID = sc.ID'+ char(13)+ char(10)+
	'INNER JOIN subject_def sd ON sc.SUBJECT_ID = sd.ID'+ char(13)+ char(10)+
	'INNER JOIN site_address sa ON sd.LOCATION_ID = sa.ID'+ char(13)+ char(10)+
	'INNER JOIN site_def site ON sa.SITE_ID = site.ID'+ char(13)+ char(10)+
	'INNER JOIN drugtrial_def dd ON site.DRUGTRIAL_ID = dd.ID'+ char(13)+ char(10)+
	'WHERE ' + LEFT(@SqlText, LEN(@SqlText)-5)
  
SELECT CAST(@SqlText AS XML) AS 'SqlScriptToRunOnCTMS';

DROP INDEX #CtmsMetrics.IX_CtmsMetrics_DataPageID;
DROP TABLE #CtmsMetrics;
DROP TABLE #CtmsSql;
