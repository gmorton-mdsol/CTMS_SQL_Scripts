select dd.id as "drugtrial_id"
    , dd.name as "drugtrial_name"
    , site.name as "site_name"
    , sd.screening_no
    , sc.name as "subject_crf_name"
    , scp.name as "scp_name"
    , sc.assigned_crf_base_tmpl_id
    , scp.assigned_crf_page_tmpl_id
    , h2.notes as "insert_assigned_crf_page_tmpl"
    , h1.notes as "insert_assigned_crf_base_tmpl"
from subject_crf_page scp
inner join subject_crf sc on sc.id=scp.subject_crf_id
inner join subject_def sd on sd.id=sc.subject_id
inner join site_address sa on sa.id=sd.location_id
inner join site_def site on site.id=sa.site_id
inner join drugtrial_def dd on dd.id=site.drugtrial_id
left join assigned_crf_page_tmpl acpt on acpt.id=scp.assigned_crf_page_tmpl_id
left join assigned_crf_base_tmpl acbt on acbt.id=sc.assigned_crf_base_tmpl_id
left join history h1 on h1.row_id=sc.assigned_crf_base_tmpl_id
left join history h2 on h2.row_id=scp.assigned_crf_page_tmpl_id
where  dd.name in ('AssureRX ARX1006(PROD)','Rigel-C-935788-047(PROD)','TV-45070-CNS-20005 OA(PROD)','TAV-ONYC-206(PROD)')
and ((acpt.id is null and scp.assigned_crf_page_tmpl_id is not null) or (acbt.id is null and sc.assigned_crf_base_tmpl_id is not null))
and (h1.auto_id is null or h1.notes like 'insert%')
and (h2.auto_id is null or h2.notes like 'insert%')
