SELECT dd.name AS study_name, a.name, agt.name
  , a.TAG
  , aa.NAME cur_transaction_id
  , CAST(SUBSTRING(LEFT(h.notes, LOCATE(''' , LAST_UPDT_BY_ID', h.notes)-1), LENGTH('update attribute_answers set NAME=''')+1) AS SIGNED) tgt_transaction_id 
  , h.CREATE_DATE
FROM history h 
INNER JOIN attribute_answers aa  ON h.target='attribute_answers' AND h.notes LIKE 'update attribute_answers set NAME=''%LAST_UPDT_BY_ID=NULL%' AND h.ROW_ID=aa.ID
INNER JOIN attribute_tmpl a ON  aa.ATTRIBUTE_TMPL_ID=a.ID
  INNER JOIN attribute_group_tmpl agt ON a.ATTRIBUTE_GROUP_TMPL_ID = agt.ID
LEFT JOIN drugtrial_def dd ON dd.ID=aa.ASSOC_OBJ_ID AND aa.ASSOC_OBJ='drugtrial_def'
  ORDER BY tgt_transaction_id