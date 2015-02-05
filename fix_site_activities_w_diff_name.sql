/* FIX SITE activities with different name to template BY SWAPPING NAMES */
update  assigned_activity_detail_tmpl aadt
    , activity_dfn ad
    , activity act
set act.name=ad.name
WHERE act.assoc_obj='site_def' AND act.asgnd_activity_detail_tmpl_id=aadt.id
 AND aadt.activity_dfn_id=ad.id
 AND ad.name <> act.name
