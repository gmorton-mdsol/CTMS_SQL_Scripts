SELECT SIG.*, SIA.ATTRIBUTE_ID, SIA.attribute_name, SIA.attribute_value
FROM (SELECT dt.id AS DRUGTRIAL_ID
      , dt.name AS DRUGTRIAL_NAME
      , agt.id as ATTRIBUTE_GROUP_ID
      , agt.name AS ATTRIBUTE_GROUP_NAME
    FROM drugtrial_def dt
    JOIN attribute_group_tmpl agt ON agt.active='Y' AND agt.prevent_assignment='Y' AND agt.type='30'
    JOIN attribute_tmpl at ON at.active='Y' AND at.attribute_group_tmpl_id = agt.id AND at.name='msgId'
    JOIN attribute_answers aa on aa.attribute_tmpl_id = at.id AND aa.assoc_obj='drugtrial_def' AND dt.id = aa.assoc_obj_id
    JOIN rules r ON r.identifier=aa.name
    where dt.active='Y' and r.active='Y'
    order by dt.id, r.ORDER_INDEX) SIG -- di_study_import_groups
LEFT JOIN (SELECT aa.ID  AS "ATTRIBUTE_ID"
      , at.NAME AS "ATTRIBUTE_NAME"
      , CASE WHEN length(at.DD_TAG)>0 THEN aa.DD_VALUE ELSE aa.NAME END AS "ATTRIBUTE_VALUE"
      , at.ID as ATTRIBUTE_TMPL_ID
      , agt.id as ATTRIBUTE_GROUP_ID
      , aa.assoc_obj_id AS DRUGTRIAL_ID
    FROM attribute_group_tmpl agt
    JOIN attribute_tmpl at on at.attribute_group_tmpl_id = agt.id
    LEFT OUTER JOIN attribute_answers aa on aa.attribute_tmpl_id = at.id and aa.assoc_obj='drugtrial_def'
    WHERE agt.prevent_assignment='Y'
    AND (NOT(at.multi_ans = 'Y') or at.multi_ans is null)
    order by at.NAME) SIA -- di_study_import_attributes
  ON SIG.DRUGTRIAL_ID=SIA.DRUGTRIAL_ID AND SIG.ATTRIBUTE_GROUP_ID=SIA.ATTRIBUTE_GROUP_ID