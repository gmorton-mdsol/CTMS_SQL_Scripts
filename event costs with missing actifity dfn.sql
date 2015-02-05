SELECT dt.name STUDY, ec.id, ec.currency, ec.amount, ec.*
FROM 
drugtrial_def dt
JOIN trigger_control tc ON tc.assigned_obj_id=dt.id and tc.assigned_obj='drugtrial_def' and  tc.data_object='activity'
JOIN event_cost ec ON ec.trigger_control_id=tc.id
LEFT OUTER JOIN(
     /* Find all billable template records per active study */
    SELECT dt.name STUDY, tc.id TRIGGER_CONTROL_ID, aadt.ACTIVITY_DFN_ID
    FROM 
    trigger_control tc
    INNER JOIN drugtrial_def dt ON tc.assigned_obj_id=dt.id and tc.assigned_obj='drugtrial_def' and dt.active='Y'
     JOIN assigned_activity_tmpl aat on aat.assigned_obj_id=dt.id
     JOIN assigned_activity_detail_tmpl aadt on aadt.assigned_activity_tmpl_id=aat.id and aadt.billing_event='Y'
    WHERE 
      tc.data_object='activity'
 )X
 ON X.TRIGGER_CONTROL_ID=ec.trigger_control_id and ec.linked_obj_id=X.ACTIVITY_DFN_ID and ec.linked_obj='activity_dfn'
WHERE dt.active='Y' and X.ACTIVITY_DFN_ID IS NULL
limit 100000