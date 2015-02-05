/*
-- duplicate_cost_entries.sql
--
-- Created:     2012-NOV-01     Michael Goldsmith
-- Updated:     n/a             n/a
--
-- This script will return duplicate cost entries in the sites based on the following parameters:
--  . Same cost name
--  . Same cost site (probably superflous to even check this, since it is implied in the name)
--  . Same cost category
--  . Same cost sub category
--  . Same amount
--  . Costs were created within 60 seconds of each other (this can probably be safely eliminated)
--
-- In a set of duplicate costs, only 1 will be returned, leaving the other(s)
-- If a set of duplicate costs has more than 2 entries, this will have to be run multiple times
-- If one of the costs in a set of duplicates has been approved, only the unapproved cost will be returned
-- If all of the costs in a set of duplicates have been approved, one of the approved costs will be returned
--
*/

SELECT c.id
FROM cost c, 
   (SELECT oc.name, oc.group_id, oc.category, oc.sub_category, oc.amount, oc.id, oc.create_date, oc.approved, count(*) AS cost_entries
    FROM 
       (SELECT name, group_id, category, sub_category, amount, id, create_date, approved 
        FROM cost 
        ORDER BY approved DESC) oc
    WHERE oc.group_id IN (SELECT id FROM site_def WHERE name IN ('431','432','433','435','436'))
    GROUP BY oc.name, oc.group_id, oc.category, oc.sub_category, oc.amount
    HAVING cost_entries > 1) AS d
WHERE c.name=d.name
AND c.group_id=d.group_id
AND c.category=d.category
AND c.amount=d.amount
AND c.sub_category=d.sub_category
AND c.id<>d.id 
AND ABS(TIME_TO_SEC(TIMEDIFF(d.create_date, c.create_date))) < 60

