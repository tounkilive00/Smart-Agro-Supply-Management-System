-- ============================================
-- DATA VALIDATION QUERIES
-- Verify data integrity and constraints
-- ============================================

-- 1. Verify foreign key relationships
SELECT 'Failed: Farm without manager' as check_type, COUNT(*) as issues
FROM farms WHERE manager_name IS NULL
UNION ALL
SELECT 'Failed: Order without valid farm', COUNT(*)
FROM orders o WHERE NOT EXISTS (
    SELECT 1 FROM farms f WHERE f.farm_id = o.farm_id
)
UNION ALL
SELECT 'Failed: Supply without category', COUNT(*)
FROM supplies s WHERE NOT EXISTS (
    SELECT 1 FROM supply_categories c WHERE c.category_id = s.category_id
)
UNION ALL
SELECT 'Failed: Negative stock', COUNT(*)
FROM supplies WHERE current_stock < 0;

-- 2. Check for orphaned records
SELECT 'Orphaned allocations' as issue_type, COUNT(*) as count
FROM allocations a
WHERE NOT EXISTS (
    SELECT 1 FROM farms f WHERE f.farm_id = a.farm_id
) OR NOT EXISTS (
    SELECT 1 FROM supplies s WHERE s.supply_id = a.supply_id
);

-- 3. Validate business rules
SELECT 'Expired supplies still in stock' as check_name, 
       COUNT(*) as count,
       LISTAGG(supply_name, ', ') WITHIN GROUP (ORDER BY supply_name) as items
FROM supplies 
WHERE expiry_date < SYSDATE AND current_stock > 0;

-- 4. Check data completeness
SELECT 
    'Farms' as table_name,
    COUNT(*) as total_rows,
    COUNT(DISTINCT farm_id) as unique_ids,
    SUM(CASE WHEN farm_name IS NULL THEN 1 ELSE 0 END) as null_names,
    SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) as null_locations
FROM farms
UNION ALL
SELECT 
    'Supplies',
    COUNT(*),
    COUNT(DISTINCT supply_id),
    SUM(CASE WHEN supply_name IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END)
FROM supplies
UNION ALL
SELECT 
    'Orders',
    COUNT(*),
    COUNT(DISTINCT order_id),
    SUM(CASE WHEN farm_id IS NULL THEN 1 ELSE 0 END),
    SUM(CASE WHEN supply_id IS NULL THEN 1 ELSE 0 END)
FROM orders;

-- 5. Verify constraint enforcement
SELECT 'Check constraint violations' as test, COUNT(*) as violations
FROM supplies 
WHERE unit_price < 0 
   OR current_stock < 0
   OR (min_stock_level IS NOT NULL AND max_stock_level IS NOT NULL 
       AND min_stock_level >= max_stock_level);

-- 6. Test trigger functionality
SELECT 'Orders on restricted days' as test_scenario, COUNT(*) as count
FROM audit_log 
WHERE table_name = 'ORDERS' 
  AND details LIKE '%Restricted day violation%';

-- 7. Validate audit trail
SELECT 
    table_name,
    action,
    COUNT(*) as action_count,
    MIN(action_date) as first_action,
    MAX(action_date) as last_action
FROM audit_log
GROUP BY table_name, action
ORDER BY table_name, action;

-- 8. Check for duplicate allocations
SELECT 
    farm_id, 
    supply_id, 
    season, 
    crop_cycle,
    COUNT(*) as duplicate_count
FROM allocations
GROUP BY farm_id, supply_id, season, crop_cycle
HAVING COUNT(*) > 1;

-- 9. Validate inventory transactions balance
SELECT 
    supply_id,
    supply_name,
    current_stock as system_stock,
    (SELECT SUM(quantity) FROM inventory_transactions 
     WHERE supply_id = s.supply_id) as transaction_total,
    CASE WHEN current_stock = (SELECT SUM(quantity) FROM inventory_transactions 
                               WHERE supply_id = s.supply_id)
         THEN 'BALANCED' 
         ELSE 'IMBALANCE: ' || (current_stock - (SELECT SUM(quantity) FROM inventory_transactions 
                                                 WHERE supply_id = s.supply_id))
    END as status
FROM supplies s
WHERE supply_id IN (SELECT DISTINCT supply_id FROM inventory_transactions);

-- 10. Performance validation
SELECT 
    'Query Performance' as test,
    (SELECT COUNT(*) FROM orders WHERE status = 'Delivered') as delivered_orders,
    (SELECT AVG(quantity) FROM orders WHERE status = 'Delivered') as avg_order_size,
    (SELECT MAX(total_amount) FROM orders) as largest_order
FROM dual;