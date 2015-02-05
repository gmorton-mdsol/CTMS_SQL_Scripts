SELECT 
    rm.id rm_id,
    rm.name model_name,
    COALESCE(d1.name, d2.name) study_name,
    s.name site_name,
    rm . *
FROM
    recruitment_model rm
        LEFT JOIN
    drugtrial_def d1 ON rm.assoc_obj = 'drugtrial_def'
        AND rm.assoc_obj_id = d1.id
        LEFT JOIN
    site_def s ON rm.assoc_obj = 'site_def'
        AND rm.assoc_obj_id = s.id
        LEFT JOIN
    drugtrial_def d2 ON s.drugtrial_id = d2.id
WHERE
    s.id IS NOT NULL OR d1.id IS NOT NULL