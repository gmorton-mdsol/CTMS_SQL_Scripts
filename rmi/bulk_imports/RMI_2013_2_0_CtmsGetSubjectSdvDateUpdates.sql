-- RMI_2013_2_0-METRICS

-- select * from dbo.WebServicesLogInbound where inbounddate >'2014-03-01'
-- '111-201(CTMS)'

DECLARE @study nvarchar(4000) = '190-201(Prod)'
DECLARE @startid int = 0
DECLARE @blocksize int
DECLARE @studyid int = null
DECLARE @projectid int
DECLARE @IdToReturn bigint
DECLARE @CraRoleId int
DECLARE @SearchStartID int = @startid
DECLARE @SearchEndID int


select @studyId = s.StudyID, @projectid = p.projectid 
from dbo.Studies s join dbo.Projects p on s.ProjectID = p.ProjectID
where dbo.fnLocalDefault(P.ProjectName)+'('+dbo.fnLocalDefault(EnvironmentNameID)+')' = @study

if @StudyId is null raiserror('Unable to find Study ID for the given Project Name', 17, 1)

select @CraRoleId = cast(c.ConfigValue as int) from Configuration c where c.Tag = 'CRARoleForCTMSPull'
select @blocksize = max(auditid) from dbo.audits;

set @SearchStartID = dbo.fnAuditIDForFirstCreatedSubject(@StudyId)	
if isnull(@SearchStartID, -1) < @startid set @SearchStartID = @startid


set @SearchEndID = @SearchStartID + @blockSize


set @SearchStartID = @SearchStartID + 1
	
-- Create temp table, index to store datapage totals
if object_id(N'tempdb..#CtmsMetrics', N'U') is not null
begin
	if exists (select * from sys.indexes where object_id = object_id(N'tempdb..#CtmsMetrics', N'U') and name = N'IX_CtmsMetrics_DataPageId')
	begin
		drop index #CtmsMetrics.IX_CtmsMetrics_DataPageId;
	end
	drop table #CtmsMetrics;
end

create table #CtmsMetrics (
	DataPageId int, 
	TotalRequiresVerification int,
	TotalIsVerified int,
	TotalNotReviewed int, 
	TotalIsReviewed int,
	TotalOpenedQuery int,
	TotalAnsweredQuery int,
	TotalCancelledQuery int,
	TotalClosedQuery int,
	TotalIsTouched int,
	AuditID int,
    ReviewedDate DATETIME, 
    VerifiedDate DATETIME
)
create clustered index IX_CtmsMetrics_DataPageId on #CtmsMetrics (DataPageId)

-- Calculate datapage totals
-- Add datapages to temp table
insert into dbo.#CtmsMetrics (datapageid, AuditID)
select datapageid, max(AuditID) AuditID
from (
select dp.datapageid, a.AuditID from dbo.audits a with (nolock)
join dbo.datapages dp with (nolock) on a.objectid = dp.datapageid
join dbo.Records r with (nolock) on r.datapageid = dp.datapageid
join dbo.subjects s with (nolock) on s.subjectid = r.subjectid
join dbo.studysites ss with (nolock) on ss.studysiteid = s.studysiteid
where a.ObjectTypeID = 3
and ss.studyid = @studyid
and a.auditid between @SearchStartID and @SearchEndID
and exists (select null from dbo.CtmsSubjectMetricsAuditCategoryLookup acl 
            where acl.ObjectTypeID = 3 and a.AuditSubCategoryID = acl.SubCategoryId)
and s.Deleted = 0
and dp.Deleted = 0
union
-- Add datapages to temp table for any modified records
select r.datapageid, a.AuditID from dbo.audits a with (nolock)
join dbo.records r with (nolock) on r.recordid = a.objectid
join dbo.subjects s with (nolock) on s.subjectid = r.subjectid
join dbo.studysites ss with (nolock) on ss.studysiteid = s.studysiteid
where a.ObjectTypeID = 2
and ss.studyid = @studyid
and a.auditid between @SearchStartID and @SearchEndID
and exists (select null from dbo.CtmsSubjectMetricsAuditCategoryLookup acl 
            where acl.ObjectTypeID = 2 and a.AuditSubCategoryID = acl.SubCategoryId)
and s.Deleted = 0
and r.Deleted = 0
union
-- Add datapages to temp table for any modified datapoints  
select d.datapageid, a.AuditID from dbo.audits a with (nolock)
join dbo.datapoints d with (nolock) on a.objectid = d.datapointid
join dbo.records r with (nolock) on r.recordid = d.recordid
join dbo.subjects s with (nolock) on s.subjectid = r.subjectid
join dbo.studysites ss with (nolock) on ss.studysiteid = s.studysiteid
where a.ObjectTypeId = 1
and ss.studyid = @studyid
and a.auditid between @SearchStartID and @SearchEndID
and exists (select null from dbo.CtmsSubjectMetricsAuditCategoryLookup acl 
            where acl.ObjectTypeID = 1 and a.AuditSubCategoryID = acl.SubCategoryId)
and s.Deleted = 0
and r.Deleted = 0
and d.Deleted = 0) a
group by datapageid

update cm1
set 
 TotalNotReviewed=t2.TotalNotReviewed,
 TotalIsReviewed=t2.TotalIsReviewed
from dbo.#CtmsMetrics cm1
join (select r.datapageid,
sum(cast(o.RequiresReview as int)) as TotalNotReviewed,
sum(cast(o.IsReviewed as int)) as TotalIsReviewed
from dbo.#CtmsMetrics cm2
join dbo.records r with (nolock) on r.datapageid = cm2.datapageid
join dbo.datapoints d with (nolock) on r.recordid = d.recordid
join dbo.fields f with (nolock) on d.fieldid = f.fieldid
join dbo.objectstatus o with (nolock) on o.objecttypeid = 1 
	and o.objectid = d.datapointid and o.roleid = @CraRoleId  
where 
	d.deleted = 0 and isnull(d.isuserdeactivated,0) = 0 
and r.deleted = 0 and isnull(r.isuserdeactivated,0) = 0
and ((r.recordposition = 0 and f.islog = 0) or (r.recordposition > 0 and f.islog = 1))
group by r.datapageid
) as t2
on cm1.datapageid = t2.datapageid

update cm1
set 
 TotalRequiresVerification = t2.TotalREquiresVerification,
 TotalIsVerified = t2.TotalIsVerified,
 TotalIsTouched=t2.TotalIsTouched
from dbo.#CtmsMetrics cm1
join (select r.datapageid,
sum(cast(o.RequiresVerification as int)) as TotalRequiresVerification,
sum(cast(o.IsVerified as int)) as TotalIsVerified,
sum(cast(o.IsTouched as int)) as TotalIsTouched	
from dbo.#CtmsMetrics cm2
join dbo.records r with (nolock) on r.datapageid = cm2.datapageid
join dbo.datapoints d with (nolock) on r.recordid = d.recordid
join dbo.fields f with (nolock) on d.fieldid = f.fieldid
join dbo.objectstatus o with (nolock) on o.objecttypeid = 1 
	and o.objectid = d.datapointid and o.roleid = -2  
where 
	d.deleted = 0 and isnull(d.isuserdeactivated,0) = 0 
and r.deleted = 0 and isnull(r.isuserdeactivated,0) = 0
and ((r.recordposition = 0 and f.islog = 0) or (r.recordposition > 0 and f.islog = 1))
group by r.datapageid
) as t2
on cm1.datapageid = t2.datapageid

if object_id(N'tempdb..#QueryMetrics', N'U') is not null
begin
	if exists (select * from sys.indexes where object_id = object_id(N'tempdb..#QueryMetrics', N'U')  and name = N'IX_QueryMetrics_DataPageId')
	begin
		drop index #QueryMetrics.IX_QueryMetrics_DataPageId;
	end
	drop table #QueryMetrics;
end

create table #QueryMetrics (
    DataPageId int,
    QueryStatusId int,
    Total int
)
create unique index IX_QueryMetrics_DataPageId
    on #QueryMetrics (DataPageId, QueryStatusId)
    include (Total) --Covering Unique index

insert into #QueryMetrics
select cm2.DataPageId, QueryStatusId, count(*)
from #CtmsMetrics cm2
	join dbo.Records r with (nolock) on r.DataPageID = cm2.DataPageId
	join dbo.DataPoints d with (nolock) on r.RecordID = d.RecordID
	join dbo.Markings m with (nolock) on d.DataPointID = m.DataPointId
	join dbo.Fields f with (nolock) on d.FieldID = f.FieldID
where d.StudyId = @studyid 
	and d.Deleted = 0 and isnull(d.IsUserDeactivated, 0) = 0 
	and r.Deleted = 0 and isnull(r.IsUserDeactivated, 0) = 0
	and m.MarkingTypeId = 3  --queries
	and m.QueryStatusId in (1, 2, 3, 4)
	and m.MarkingActive = 1
	and ((r.RecordPosition = 0 and f.IsLog = 0) or (r.RecordPosition > 0 and f.IsLog = 1))
group by cm2.DataPageID, m.QueryStatusId

update cm1
set TotalOpenedQuery = t2.Total
from #CtmsMetrics cm1
join (select DataPageId, Total
		from #QueryMetrics
		where QueryStatusID = 1) as t2
on cm1.DataPageId = t2.DataPageId

update cm1
set TotalAnsweredQuery = t2.Total
from #CtmsMetrics cm1
join (select DataPageId, Total
		from #QueryMetrics
		where QueryStatusID = 2) as t2
on cm1.DataPageId = t2.DataPageId

update cm1
set TotalClosedQuery = t2.Total
from #CtmsMetrics cm1
join (select DataPageId, Total
		from #QueryMetrics
		where QueryStatusID = 3) as t2
on cm1.DataPageId = t2.DataPageId

update cm1
set TotalCancelledQuery = t2.Total
from #CtmsMetrics cm1
join (select DataPageId, Total
		from #QueryMetrics
		where QueryStatusID = 4) as t2
on cm1.DataPageId = t2.DataPageId

-- Determine the verified and reviewed date 
-- Only return dates when it is possible there is an audit for the datapage 
-- i.e. TotalIsVerified > 0 && TotalRequiresVerification == 0 
UPDATE dbo.#ctmsmetrics 
SET    VerifiedDate = t2.maxverifyaudit 
FROM   dbo.#ctmsmetrics cm1 
     JOIN (SELECT t.datapageid, 
                  Max(audittime) MaxVerifyAudit 
           FROM   dbo.#ctmsmetrics t 
                  JOIN datapages dpg 
                    ON dpg.datapageid = t.datapageid 
                  JOIN records rec 
                    ON rec.datapageid = dpg.datapageid 
                  JOIN datapoints dps 
                    ON dps.recordid = rec.recordid 
                  JOIN audits au 
                    ON au.objectid = dps.datapointid 
                       AND au.objecttypeid = 1 
                       AND au.auditsubcategoryid = 17 --auditsubcategoryR.name = Verify 
           WHERE  t.totalrequiresverification = 0 
                  AND t.totalisverified > 0 
                  -- NOTE: uncomment to enable data paging when determining the audit date. this is not currently used
                  --       as it can result in the date changing on CTMS as it is passing through the audits, resulting
                  --       in 'unstable' dates if import is running or stalled. 
                  AND au.auditid BETWEEN @SearchStartID AND @SearchEndID -- NOTE: uncommented! 
           GROUP  BY t.datapageid) t2 
       ON cm1.datapageid = t2.datapageid 

UPDATE dbo.#ctmsmetrics 
SET    ReviewedDate = t2.maxreviewaudit 
FROM   dbo.#ctmsmetrics cm1 
     JOIN (SELECT t.datapageid, 
                  Max(audittime) MaxReviewAudit 
           FROM   dbo.#ctmsmetrics t 
                  JOIN datapages dpg 
                    ON dpg.datapageid = t.datapageid 
                  JOIN records rec 
                    ON rec.datapageid = dpg.datapageid 
                  JOIN datapoints dps 
                    ON dps.recordid = rec.recordid 
                  JOIN audits au 
                    ON au.objectid = dps.datapointid 
                       AND au.objecttypeid = 1 
                       AND au.auditsubcategoryid = 14 --auditsubcategoryR.name = Review 
           WHERE  t.totalnotreviewed = 0 
                  AND t.totalisreviewed > 0 -- NOTE: see above comments regarding data paging 
                  AND au.auditid BETWEEN @SearchStartID AND @SearchEndID 
           GROUP  BY t.datapageid) t2 
       ON cm1.datapageid = t2.datapageid ;
       
drop table #QueryMetrics;

if object_id(N'tempdb..#res', N'U') is not null drop table dbo.#res    
create table #res (
	FormDataGuid nvarchar(36),
	ReviewedDate NVARCHAR(256), 
	VerifiedDate NVARCHAR(256) 
); 

insert into #res
select 
	dp.Guid as FormDataGuid,
    Replace(CONVERT(VARCHAR, tmpDP.ReviewedDate, 120), ' ', 'T') AS ReviewedDate, 
    Replace(CONVERT(VARCHAR, tmpDP.VerifiedDate, 120), ' ', 'T') AS VerifiedDate 
from 
	dbo.#CtmsMetrics tmpDP
join dbo.datapages dp with (nolock) on tmpDP.datapageid = dp.datapageid
left join dbo.instances i with (nolock) on dp.instanceid = i.instanceid
left join dbo.instances ip with (nolock) on ip.instanceid = i.ParentInstanceID
left join dbo.folders fl with (nolock) on fl.folderid = i.folderid
join dbo.forms fo with (nolock) on fo.formid = dp.formid
join dbo.Records r with (nolock) on r.datapageid = dp.datapageid
join dbo.subjects s with (nolock) on s.subjectid = r.subjectid
join dbo.studysites ss with (nolock) on ss.studysiteid = s.studysiteid
join dbo.sites si with (nolock) on si.siteid = ss.siteid		
join dbo.ObjectTags2 ot with (nolock) on ot.projectid = @projectid 
	and ot.objecttypeid = 101 and ot.active = 1
	and ot.tagoid in ('Visit Folder')
	and ot.tagvalue = fl.oid
where ss.studyid = @studyid 
	and tmpDP.TotalIsTouched is not null
union
select 
	dp.Guid as FormDataGuid,
    Replace(CONVERT(VARCHAR, tmpDP.ReviewedDate, 120), ' ', 'T') AS ReviewedDate, 
    Replace(CONVERT(VARCHAR, tmpDP.VerifiedDate, 120), ' ', 'T') AS VerifiedDate 
from 
	dbo.#CtmsMetrics tmpDP
join dbo.datapages dp with (nolock) on tmpDP.datapageid = dp.datapageid
left join dbo.instances i with (nolock) on dp.instanceid = i.instanceid
left join dbo.instances ip with (nolock) on ip.instanceid = i.ParentInstanceID
left join dbo.folders fl with (nolock) on fl.folderid = i.folderid
join dbo.forms fo with (nolock) on fo.formid = dp.formid
join dbo.Records r with (nolock) on r.datapageid = dp.datapageid
join dbo.subjects s with (nolock) on s.subjectid = r.subjectid
join dbo.studysites ss with (nolock) on ss.studysiteid = s.studysiteid
join dbo.sites si with (nolock) on si.siteid = ss.siteid		
	and fl.oid is null
where ss.studyid = @studyid 
	and tmpDP.TotalIsTouched is not null

if not exists (select null from #res) return

SELECT ('UPDATE subject_crf_page SET '
    + CASE WHEN VerifiedDate IS NOT NULL THEN ('verified_date="' + REPLACE(VerifiedDate, 'T', ' ') + '" ') ELSE '' END
    + CASE WHEN VerifiedDate IS NOT NULL AND ReviewedDate IS NOT NULL THEN ', ' ELSE '' END
    + CASE WHEN ReviewedDate IS NOT NULL THEN ('reviewed_date="' + REPLACE(ReviewedDate, 'T', ' ') + '" ') ELSE '' END
    + ('WHERE uuid="' + FormDataGuid + '";' + char(13)+ char(10))) AS "SQLScriptForCMP"
FROM #res
WHERE VerifiedDate IS NOT NULL OR ReviewedDate IS NOT NULL
UNION ALL
SELECT ('UPDATE subject_crf_page SET verified="Y" WHERE verified_date IS NOT NULL;' + char(13)+ char(10)) AS "SQLScriptForCMP"
WHERE EXISTS (SELECT null FROM #res WHERE VerifiedDate IS NOT NULL)
UNION ALL
SELECT ('UPDATE subject_crf_page SET reviewed="Y" WHERE reviewed_date IS NOT NULL;' + char(13)+ char(10)) AS "SQLScriptForCMP"
WHERE EXISTS (SELECT null FROM #res WHERE ReviewedDate IS NOT NULL);

if object_id(N'tempdb..#res', N'U') is not null drop table dbo.#res
if object_id(N'tempdb..#CtmsMetrics', N'U') is not null drop table dbo.#CtmsMetrics
