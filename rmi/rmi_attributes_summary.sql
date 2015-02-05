SELECT dd.NAME AS "drugtrial_name"
  , aa.ID AS "attribute_answer_id"
  , agt.NAME AS "attribute_group_name"
  , att.NAME AS "attribute_name"
  , aa.NAME AS "attribute_value"
  , aa.DD_VALUE AS "attribute_dd_value"
FROM attribute_group_tmpl agt
INNER JOIN attribute_tmpl att ON agt.ID = att.ATTRIBUTE_GROUP_TMPL_ID
INNER JOIN attribute_answers aa ON att.ID = aa.ATTRIBUTE_TMPL_ID
  INNER JOIN drugtrial_def dd ON dd.ID=aa.ASSOC_OBJ_ID AND aa.ASSOC_OBJ='drugtrial_def' 
WHERE att.TYPE='30'
  ORDER BY dd.NAME, agt.name