-- orphaned_cost_entries.sql
--
-- Created:     2012-NOV-01     Michael Goldsmith
-- Updated:     n/a             n/a
--
-- This script will return orphaned cost entries based on the following parameters:
--  . The cost is active
--  . Either:
--     . The cost payee does not exist
--     . The linked event does not exist
--

SELECT 'payee' AS orphaned_from, payee_id AS orphaned_from_id, c.*
FROM cost c
WHERE c.active='Y'
AND c.payee_id NOT IN (SELECT DISTINCT(id) FROM payee)
UNION ALL
SELECT 'event_cost' AS orphaned_from, linked_obj_id AS orphaned_from_id, c.*
FROM cost c
WHERE c.active='Y'
AND c.linked_obj='event_cost'
AND c.linked_obj_id NOT IN (SELECT DISTINCT(id) FROM event_cost)
