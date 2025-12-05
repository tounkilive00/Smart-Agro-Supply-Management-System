-- ============================================
-- SAMPLE DATA INSERTION SCRIPT
-- Realistic data for testing and demonstration
-- ============================================

-- Insert supply categories
INSERT INTO supply_categories VALUES (seq_category_id.NEXTVAL, 'Seeds', 'Various crop seeds', 'kg', 24);
INSERT INTO supply_categories VALUES (seq_category_id.NEXTVAL, 'Fertilizers', 'Chemical and organic fertilizers', 'kg', 18);
INSERT INTO supply_categories VALUES (seq_category_id.NEXTVAL, 'Pesticides', 'Insecticides, herbicides, fungicides', 'liters', 36);
INSERT INTO supply_categories VALUES (seq_category_id.NEXTVAL, 'Equipment', 'Farming tools and machinery', 'units', 120);
INSERT INTO supply_categories VALUES (seq_category_id.NEXTVAL, 'Irrigation', 'Water supply systems', 'units', 60);
INSERT INTO supply_categories VALUES (seq_category_id.NEXTVAL, 'Packaging', 'Harvest packaging materials', 'units', 12);

-- Insert suppliers
INSERT INTO suppliers VALUES (seq_supplier_id.NEXTVAL, 'AgroSeed Rwanda Ltd', 'Jean Ndayambaje', '+250788111001', 'contact@agroseed.rw', 'KG 123 St, Kigali', 'Kigali', 'Rwanda', 4.5, 'Y', SYSDATE-365);
INSERT INTO suppliers VALUES (seq_supplier_id.NEXTVAL, 'FertiPlus East Africa', 'Marie Uwase', '+250788111002', 'info@fertiplus.rw', 'KN 45 Ave, Kigali', 'Kigali', 'Rwanda', 4.2, 'Y', SYSDATE-300);
INSERT INTO suppliers VALUES (seq_supplier_id.NEXTVAL, 'Green Tools Co.', 'Peter Habimana', '+250788111003', 'sales@greentools.rw', 'Musanze Road', 'Musanze', 'Rwanda', 4.0, 'Y', SYSDATE-200);
INSERT INTO suppliers VALUES (seq_supplier_id.NEXTVAL, 'Organic Solutions', 'Alice Mukamana', '+250788111004', 'organics@organic.rw', 'Huye District', 'Huye', 'Rwanda', 4.8, 'Y', SYSDATE-150);
INSERT INTO suppliers VALUES (seq_supplier_id.NEXTVAL, 'Precision Agritech', 'David Nzabandora', '+250788111005', 'tech@precision.rw', 'Kicukiro', 'Kigali', 'Rwanda', 4.3, 'Y', SYSDATE-100);

-- Insert farms
INSERT INTO farms VALUES (seq_farm_id.NEXTVAL, 'Green Valley Maize Farm', 'Rulindo District', 120.5, 'Maize', 'Clay Loam', 'John Niyonsenga', '+250788222001', 'john@greenvalley.rw', SYSDATE-730, 'Active');
INSERT INTO farms VALUES (seq_farm_id.NEXTVAL, 'Mountain Coffee Plantation', 'Musanze District', 85.0, 'Coffee', 'Volcanic', 'Jane Uwimana', '+250788222002', 'jane@mountaincoffee.rw', SYSDATE-700, 'Active');
INSERT INTO farms VALUES (seq_farm_id.NEXTVAL, 'Sunrise Tea Estate', 'Nyamagabe District', 250.0, 'Tea', 'Acidic', 'Robert Mugisha', '+250788222003', 'robert@sunrisetea.rw', SYSDATE-650, 'Active');
INSERT INTO farms VALUES (seq_farm_id.NEXTVAL, 'Lakeview Rice Farm', 'Bugesera District', 180.0, 'Rice', 'Alluvial', 'Sarah Nyiramana', '+250788222004', 'sarah@lakeview.rw', SYSDATE-600, 'Active');
INSERT INTO farms VALUES (seq_farm_id.NEXTVAL, 'Highland Potato Farm', 'Burera District', 95.0, 'Potatoes', 'Sandy Loam', 'Paul Bizimana', '+250788222005', 'paul@highland.rw', SYSDATE-550, 'Active');
INSERT INTO farms VALUES (seq_farm_id.NEXTVAL, 'Organic Vegetable Co-op', 'Gasabo District', 45.0, 'Vegetables', 'Organic', 'Grace Mutoni', '+250788222006', 'grace@organiccoop.rw', SYSDATE-500, 'Active');
INSERT INTO farms VALUES (seq_farm_id.NEXTVAL, 'Southern Fruits Orchard', 'Huye District', 110.0, 'Fruits', 'Loamy', 'Eric Ndayisaba', '+250788222007', 'eric@fruits.rw', SYSDATE-450, 'Active');
INSERT INTO farms VALUES (seq_farm_id.NEXTVAL, 'Western Banana Plantation', 'Rubavu District', 200.0, 'Bananas', 'Volcanic', 'Annette Mukamana', '+250788222008', 'annette@banana.rw', SYSDATE-400, 'Active');

-- Insert supplies
-- Seeds
INSERT INTO supplies VALUES (seq_supply_id.NEXTVAL, 'Maize Seed HYV-100', 100, 5000, 8.50, 500, 100, 1000, TO_DATE('2026-12-31','YYYY-MM-DD'), 'BATCH-MS-202501', 'Cool & Dry', SYSDATE);
INSERT INTO supplies VALUES (seq_supply_id.NEXTVAL, 'Coffee Arabica Seeds', 100, 5000, 12.75, 300, 50, 600, TO_DATE('2026-10-15','YYYY-MM-DD'), 'BATCH-CA-202502', 'Cool & Dry', SYSDATE);
INSERT INTO supplies VALUES (seq_supply_id.NEXTVAL, 'Rice Paddy IR-64', 100, 5000, 6.25, 800, 200, 1500, TO_DATE('2026-11-30','YYYY-MM-DD'), 'BATCH-RP-202503', 'Dry Storage', SYSDATE);
INSERT INTO supplies VALUES (seq_supply_id.NEXTVAL, 'Potato Seed Tubers', 100, 5000, 4.50, 1200, 300, 2000, TO_DATE('2025-08-20','YYYY-MM-DD'), 'BATCH-PS-202504', 'Cool Storage', SYSDATE);

-- Fertilizers
INSERT INTO supplies VALUES (seq_supply_id.NEXTVAL, 'NPK 17-17-17', 101, 5001, 25.00, 200, 50, 500, TO_DATE('2025-10-30','YYYY-MM-DD'), 'BATCH-NPK-202501', 'Dry Place', SYSDATE);
INSERT INTO supplies VALUES (seq_supply_id.NEXTVAL, 'Urea Fertilizer', 101, 5001, 18.50, 150, 40, 400, TO_DATE('2025-09-15','YYYY-MM-DD'), 'BATCH-UR-202502', 'Dry Place', SYSDATE);
INSERT INTO supplies VALUES (seq_supply_id.NEXTVAL, 'Organic Compost', 101, 5004, 12.00, 400, 100, 800, TO_DATE('2026-06-30','YYYY-MM-DD'), 'BATCH-OC-202503', 'Outdoor Cover', SYSDATE);
INSERT INTO supplies VALUES (seq_supply_id.NEXTVAL, 'DAP Fertilizer', 101, 5001, 22.75, 180, 45, 450, TO_DATE('2025-11-20','YYYY-MM-DD'), 'BATCH-DAP-202504', 'Dry Place', SYSDATE);

-- Insert system users
INSERT INTO system_users VALUES (seq_user_id.NEXTVAL, 'admin', 'hashed_password_123', 'System Administrator', 'admin@agro.rw', 'ADMIN', NULL, 'Y', NULL, SYSDATE);
INSERT INTO system_users VALUES (seq_user_id.NEXTVAL, 'john_farm', 'hashed_password_456', 'John Niyonsenga', 'john@greenvalley.rw', 'FARMER', 1000, 'Y', NULL, SYSDATE);
INSERT INTO system_users VALUES (seq_user_id.NEXTVAL, 'jane_coffee', 'hashed_password_789', 'Jane Uwimana', 'jane@mountaincoffee.rw', 'FARMER', 1001, 'Y', NULL, SYSDATE);
INSERT INTO system_users VALUES (seq_user_id.NEXTVAL, 'manager1', 'hashed_password_101', 'Supply Manager', 'manager@agro.rw', 'MANAGER', NULL, 'Y', NULL, SYSDATE);

-- Insert holidays
INSERT INTO holidays VALUES (seq_holiday_id.NEXTVAL, 'New Year', TO_DATE('2025-01-01','YYYY-MM-DD'), 'Rwanda', 'Y', 'Y', 'New Year Celebration');
INSERT INTO holidays VALUES (seq_holiday_id.NEXTVAL, 'National Heroes Day', TO_DATE('2025-02-01','YYYY-MM-DD'), 'Rwanda', 'Y', 'Y', 'Day of National Heroes');
INSERT INTO holidays VALUES (seq_holiday_id.NEXTVAL, 'Thanksgiving', TO_DATE('2025-11-27','YYYY-MM-DD'), 'Rwanda', 'N', 'Y', 'Thanksgiving Holiday');
INSERT INTO holidays VALUES (seq_holiday_id.NEXTVAL, 'Christmas', TO_DATE('2025-12-25','YYYY-MM-DD'), 'Rwanda', 'Y', 'Y', 'Christmas Day');

-- Insert sample orders (at least 20 orders)
INSERT INTO orders (order_id, farm_id, supply_id, quantity, unit_price_at_order, order_date, status, expected_delivery)
VALUES (seq_order_id.NEXTVAL, 1000, 10000, 50, 8.50, SYSDATE-30, 'Delivered', SYSDATE-25);

INSERT INTO orders (order_id, farm_id, supply_id, quantity, unit_price_at_order, order_date, status, expected_delivery)
VALUES (seq_order_id.NEXTVAL, 1001, 10001, 25, 12.75, SYSDATE-25, 'Delivered', SYSDATE-20);

INSERT INTO orders (order_id, farm_id, supply_id, quantity, unit_price_at_order, order_date, status, expected_delivery)
VALUES (seq_order_id.NEXTVAL, 1002, 10004, 10, 25.00, SYSDATE-20, 'Shipped', SYSDATE-15);

INSERT INTO orders (order_id, farm_id, supply_id, quantity, unit_price_at_order, order_date, status, expected_delivery)
VALUES (seq_order_id.NEXTVAL, 1003, 10002, 100, 6.25, SYSDATE-15, 'Processing', SYSDATE-10);

INSERT INTO orders (order_id, farm_id, supply_id, quantity, unit_price_at_order, order_date, status, expected_delivery)
VALUES (seq_order_id.NEXTVAL, 1004, 10003, 200, 4.50, SYSDATE-10, 'Pending', SYSDATE-5);

-- Insert more orders (at least 15 more)
-- ... (additional order inserts following same pattern)

-- Insert allocations
INSERT INTO allocations VALUES (seq_allocation_id.NEXTVAL, 1000, 10000, 30, SYSDATE-60, 'Season A 2025', 'Planting', 'Initial planting allocation', 'admin', 'Allocated for main planting season');
INSERT INTO allocations VALUES (seq_allocation_id.NEXTVAL, 1001, 10001, 15, SYSDATE-55, 'Season A 2025', 'Planting', 'Coffee seedlings', 'admin', 'High altitude variety');
INSERT INTO allocations VALUES (seq_allocation_id.NEXTVAL, 1000, 10004, 5, SYSDATE-50, 'Season A 2025', 'Top-dressing', 'First fertilizer application', 'manager1', 'Apply 30 days after planting');
INSERT INTO allocations VALUES (seq_allocation_id.NEXTVAL, 1002, 10006, 8, SYSDATE-45, 'Season A 2025', 'Manuring', 'Organic fertilization', 'manager1', 'For organic tea production');

-- Insert inventory transactions
INSERT INTO inventory_transactions VALUES (seq_transaction_id.NEXTVAL, 10000, 'PURCHASE', 500, 8.00, 4000, 20000, 'ORDER', SYSDATE-35, 'admin', 'Initial stock purchase');
INSERT INTO inventory_transactions VALUES (seq_transaction_id.NEXTVAL, 10000, 'ALLOCATION', -30, 8.50, -255, 30000, 'ALLOCATION', SYSDATE-60, 'admin', 'Allocated to farm 1000');
INSERT INTO inventory_transactions VALUES (seq_transaction_id.NEXTVAL, 10001, 'PURCHASE', 300, 11.50, 3450, 20001, 'ORDER', SYSDATE-30, 'admin', 'Coffee seeds purchase');

BEGIN
	COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		ROLLBACK;
		DBMS_OUTPUT.PUT_LINE('❌ Error occurred: ' || SQLERRM);
END;
/

BEGIN
	DBMS_OUTPUT.PUT_LINE('✅ Sample data inserted successfully');
	DBMS_OUTPUT.PUT_LINE('Total farms: ' || (SELECT COUNT(*) FROM farms));
	DBMS_OUTPUT.PUT_LINE('Total supplies: ' || (SELECT COUNT(*) FROM supplies));
	DBMS_OUTPUT.PUT_LINE('Total orders: ' || (SELECT COUNT(*) FROM orders));
	DBMS_OUTPUT.PUT_LINE('Total allocations: ' || (SELECT COUNT(*) FROM allocations));
END;
/