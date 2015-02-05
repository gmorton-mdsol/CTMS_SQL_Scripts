-- Find subjects which were orphaned through one of the following conditions:
--   1. Site Address being deleted without moving subject to another Site Address first
--   2. Organization being deleted while still linked to a Site Address
--   3. Address being deleted while still linked to a Site Address
--
-- Note: 1. Inactive subjects are excluded
--       2. This query does not check for the condition of an inactive site_address, address_def or
--          company_def record
--       3. This query does not check for the condition of a site_address not being a subject
--          location
--

SELECT 'site_address' AS orphaned_from_obj, s.location_id AS orphaned_from_obj_id, s.id AS subject_id
FROM subject_def s
WHERE s.location_id NOT IN (SELECT DISTINCT(id) FROM site_address)
AND s.active='Y'
UNION ALL
SELECT 'address_def' AS orphaned_from_obj, a.address_id AS orphaned_from_obj_id, s.id AS subject_id
FROM subject_def s, 
   (SELECT id, address_id 
    FROM site_address 
    WHERE address_id NOT IN (SELECT DISTINCT(id) FROM address_def) 
    GROUP BY id, address_id) a
WHERE s.location_id=a.id
AND s.active='Y'
UNION ALL
SELECT 'company_def' AS orphaned_from_obj, a.company_id AS orphaned_from_obj_id, s.id AS subject_id
FROM subject_def s,
   (SELECT id, company_id 
    FROM site_address
    WHERE company_id NOT IN (SELECT DISTINCT(id) FROM company_def)
    GROUP BY id, company_id) a
WHERE s.location_id=a.id
AND s.active='Y'