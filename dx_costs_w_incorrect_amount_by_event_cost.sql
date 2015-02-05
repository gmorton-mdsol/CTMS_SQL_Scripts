/*
-- Author:			Michael Goldsmith
-- Creation Date:	2013-12-09
-- Updated by:
-- Update Date:
*/

/*
-- Description:  Diagnostic script to identify generated costs which would need to be
--               adjusted based on their associated event costs.
*/

SELECT cost.*
FROM event_cost ec
LEFT OUTER JOIN event_payee ep ON ep.linked_obj_id = ec.id
INNER JOIN trigger_control tc ON ec.trigger_control_id = tc.id
INNER JOIN cost ON  cost.linked_obj_id = ec.id AND cost.linked_obj = 'event_cost'
LEFT OUTER JOIN payment_cost_items pci ON pci.assoc_obj = 'cost' AND pci.assoc_obj_id = cost.id
WHERE (ep.id IS NULL OR ep.split_payment IS NULL) /* need to work on handling split payment cost adjustment still so exclude for now */
  AND (cost.category IS NULL OR cost.category NOT IN ('35', '40'))
  AND (cost.sub_category = '25' AND cost.amount <> 
      (CASE
        WHEN tc.COST_ADJUSTMENT_RULE = '10'
        THEN (((ROUND(ec.amount * ec.cost_holdback_perc) / 100)) + cost.multiplier)
        ELSE ((ROUND(ec.amount * ec.cost_holdback_perc) / 100))
      END)
    OR (cost.sub_category = '20' AND cost.amount <> 
        (CASE
          WHEN tc.COST_ADJUSTMENT_RULE = '10' 
          THEN ((ec.amount - (ROUND(ec.amount * ec.cost_holdback_perc) / 100)) + cost.multiplier)
          ELSE (ec.amount - (ROUND(ec.amount * ec.cost_holdback_perc) / 100))
        END))
    OR ((cost.sub_category IS NULL OR cost.sub_category NOT IN ('20', '25')) AND cost.amount <> 
      (CASE
        WHEN tc.COST_ADJUSTMENT_RULE = '10'
        THEN (ec.amount + cost.multiplier) ELSE ec.amount
      END)))
  AND (cost.approved IS NULL OR cost.approved = 'N')
  AND pci.id IS NULL
