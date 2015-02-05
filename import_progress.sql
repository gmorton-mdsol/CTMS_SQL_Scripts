
SELECT H.drugtrial_name
  , H.import_name
  , H.AUTO_ID
  , H.lastTransactionId
  , H.ENTRY_DATE
FROM(
  SELECT @sql:=RIGHT(h.NOTES, length(h.NOTES)-length('update attribute_answers set NAME="'))
    , CAST(LEFT(@sql,INSTR(@sql, '\'')-1) AS UNSIGNED) AS "lastTransactionId"
    , h.AUTO_ID
    , h.ENTRY_DATE
    , dd.NAME AS "drugtrial_name"
    , agt.NAME AS "import_name"
  from attribute_answers aa
  INNER JOIN drugtrial_def dd ON aa.ASSOC_OBJ='drugtrial_def' AND aa.ASSOC_OBJ_ID=dd.ID
  INNER JOIN attribute_tmpl at ON aa.ATTRIBUTE_TMPL_ID = at.ID
  INNER JOIN attribute_group_tmpl agt ON at.ATTRIBUTE_GROUP_TMPL_ID = agt.ID
  INNER JOIN history h ON aa.id=h.row_id
  WHERE at.NAME='lastTransactionId'
  AND agt.NAME='04ImpSubjects'
  -- AND dd.NAME='SB5-G31-RA(Prod)'
  AND h.target='attribute_answers' AND h.NOTES LIKE 'update %'
  ) H
ORDER BY H.AUTO_ID