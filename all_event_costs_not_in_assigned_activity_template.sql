/*
-- Author:			Michael Goldsmith
-- Creation Date:	2013-09-26
-- Updated by:
-- Update Date:
*/

/*
-- Description: Identify all event costs where the linked activity definition does not
--              exist within the assigned activity template for the respective study.
*/

SELECT
  dt.NAME AS drugtrial_name,
  sd.NAME AS site_name,
  tc.TRIGGER_NAME,
  ec.ID AS event_cost_id,
  ec.LINKED_OBJ_ID,
  ec.LINKED_OBJ,
  ec.NAME AS event_cost_name,
  ec.AMOUNT,
  ec.CURRENCY,
  ec.ACTIVE AS ec_active,
  tc.active AS trigger_active,
  sd.active AS site_active,
  dt.ACTIVE AS drugtrial_active
FROM drugtrial_def dt
  JOIN trigger_control tc
    ON tc.ASSIGNED_OBJ_ID = dt.ID AND tc.ASSIGNED_OBJ = 'drugtrial_def' AND tc.DATA_OBJECT = 'activity'
  JOIN event_cost ec
    ON ec.TRIGGER_CONTROL_ID = tc.ID
  LEFT OUTER JOIN (
    /* Find all billable template records per active study */
    SELECT
      dt.NAME STUDY,
      tc.ID TRIGGER_CONTROL_ID,
      aadt.ACTIVITY_DFN_ID
    FROM trigger_control tc
      INNER JOIN drugtrial_def dt
        ON tc.ASSIGNED_OBJ_ID = dt.ID AND tc.ASSIGNED_OBJ = 'drugtrial_def' AND dt.ACTIVE = 'Y'
      JOIN assigned_activity_tmpl aat
        ON aat.ASSIGNED_OBJ_ID = dt.ID
      JOIN assigned_activity_detail_tmpl aadt
        ON aadt.ASSIGNED_ACTIVITY_TMPL_ID = aat.ID AND aadt.BILLING_EVENT = 'Y'
    WHERE tc.DATA_OBJECT = 'activity') x
    ON x.TRIGGER_CONTROL_ID = ec.TRIGGER_CONTROL_ID AND ec.LINKED_OBJ_ID = x.ACTIVITY_DFN_ID AND ec.LINKED_OBJ = 'activity_dfn'
  JOIN site_def sd ON ec.COST_OBJ_ID AND ec.COST_OBJ='site_def'
WHERE dt.ACTIVE = 'Y' AND x.ACTIVITY_DFN_ID IS NULL
