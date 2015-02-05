/* SITE Linking non templated activities to match against assigned templates */
update  assigned_activity_tmpl aat
    , assigned_activity_detail_tmpl aadt
    , activity_dfn ad
    , activity a
    , site_def s
set a.asgnd_activity_detail_tmpl_id=aadt.id
where a.type='visit'
and a.asgnd_activity_detail_tmpl_id is null
and a.name=ad.name
and ad.type=a.type
and ad.assoc_obj=a.assoc_obj and a.assoc_obj='site_def' and a.assoc_obj_id=s.id
and s.drugtrial_id=aat.assigned_obj_id and aadt.assigned_activity_tmpl_id=aat.id and aadt.activity_dfn_id=ad.id;
