/*
-- Get all event cost records where the event cost is associated with a study by a trigger,
-- but the activity defination which it is linked to no longer exists in the study's
-- assigned activity template.
*/
SELECT dt.name drugtrial_name
    , site.name site_name
    , ad.name activity_name
    , ec.*
FROM event_cost ec
INNER JOIN trigger_control tc  ON ec.trigger_control_id=tc.id
INNER JOIN drugtrial_def dt ON tc.assigned_obj_id=dt.id
INNER JOIN site_def site ON site.id=ec.cost_obj_id
LEFT JOIN activity_dfn ad ON ec.linked_obj='activity_dfn' AND ad.id=ec.linked_obj_id
LEFT JOIN (
        /* Get all subject visit activity definition records assigned to every study */
        SELECT ad.id, d.id drugtrial_id
        FROM drugtrial_def d
        INNER JOIN assigned_activity_tmpl aat ON aat.assigned_obj='drugtrial_def' and aat.assigned_obj_id=d.id
        INNER JOIN assigned_activity_detail_tmpl aadt ON aat.id=aadt.assigned_activity_tmpl_id
        INNER JOIN activity_dfn ad ON aadt.activity_dfn_id=ad.id
    ) T ON T.id=ad.id AND dt.id=T.drugtrial_id
WHERE T.id IS NULL
        