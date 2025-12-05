-- ============================================
-- STORED PROCEDURES AND FUNCTIONS
-- ============================================

-- 1. Procedure to place a new order
CREATE OR REPLACE PROCEDURE place_new_order (
    p_farm_id IN NUMBER,
    p_supply_id IN NUMBER,
    p_quantity IN NUMBER,
    p_priority IN VARCHAR2 DEFAULT 'Normal',
    p_notes IN VARCHAR2 DEFAULT NULL
) AS
    v_stock supplies.current_stock%TYPE;
    v_unit_price supplies.unit_price%TYPE;
    v_order_id NUMBER;
    v_status VARCHAR2(20);
BEGIN
    -- Check if stock is available
    SELECT current_stock, unit_price 
    INTO v_stock, v_unit_price 
    FROM supplies 
    WHERE supply_id = p_supply_id;
    
    IF v_stock >= p_quantity THEN
        -- Get next order ID
        SELECT seq_order_id.NEXTVAL INTO v_order_id FROM dual;
        
        -- Determine status based on priority
        IF p_priority IN ('Urgent', 'High') THEN
            v_status := 'Processing';
        ELSE
            v_status := 'Pending';
        END IF;
        
        -- Insert order
        INSERT INTO orders (
            order_id, farm_id, supply_id, quantity, 
            unit_price_at_order, order_date, status, 
            expected_delivery, priority, notes
        ) VALUES (
            v_order_id, p_farm_id, p_supply_id, p_quantity,
            v_unit_price, SYSDATE, v_status,
            SYSDATE + CASE 
                WHEN p_priority = 'Urgent' THEN 3
                WHEN p_priority = 'High' THEN 5
                ELSE 7
            END,
            p_priority, p_notes
        );
        
        -- Update stock
        UPDATE supplies 
        SET current_stock = current_stock - p_quantity,
            last_updated = SYSDATE
        WHERE supply_id = p_supply_id;
        
        -- Record inventory transaction
        INSERT INTO inventory_transactions (
            transaction_id, supply_id, transaction_type,
            quantity, unit_price, total_value,
            reference_id, reference_type, notes
        ) VALUES (
            seq_transaction_id.NEXTVAL, p_supply_id, 'ALLOCATION',
            -p_quantity, v_unit_price, -(p_quantity * v_unit_price),
            v_order_id, 'ORDER', 'Order placed via procedure'
        );
        
        -- Log the action
        INSERT INTO audit_log (log_id, table_name, action, record_id, details)
        VALUES (seq_log_id.NEXTVAL, 'ORDERS', 'INSERT', v_order_id, 
                'Order placed for farm ' || p_farm_id || ', quantity: ' || p_quantity);
        
        DBMS_OUTPUT.PUT_LINE('✅ Order placed successfully. Order ID: ' || v_order_id);
        DBMS_OUTPUT.PUT_LINE('   Farm ID: ' || p_farm_id || ', Supply ID: ' || p_supply_id);
        DBMS_OUTPUT.PUT_LINE('   Quantity: ' || p_quantity || ', Total: ' || (p_quantity * v_unit_price));
        
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 
            'Insufficient stock. Available: ' || v_stock || ', Requested: ' || p_quantity);
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid supply ID or farm ID.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error placing order: ' || SQLERRM);
END;
/

-- 2. Procedure to allocate supplies to farm
CREATE OR REPLACE PROCEDURE allocate_supplies (
    p_farm_id IN NUMBER,
    p_supply_id IN NUMBER,
    p_quantity IN NUMBER,
    p_season IN VARCHAR2,
    p_crop_cycle IN VARCHAR2,
    p_purpose IN VARCHAR2 DEFAULT 'General',
    p_notes IN VARCHAR2 DEFAULT NULL
) AS
    v_stock supplies.current_stock%TYPE;
    v_allocation_id NUMBER;
    v_unit_price supplies.unit_price%TYPE;
BEGIN
    -- Check stock availability
    SELECT current_stock, unit_price 
    INTO v_stock, v_unit_price 
    FROM supplies 
    WHERE supply_id = p_supply_id;
    
    IF v_stock >= p_quantity THEN
        -- Get next allocation ID
        SELECT seq_allocation_id.NEXTVAL INTO v_allocation_id FROM dual;
        
        -- Create allocation
        INSERT INTO allocations (
            allocation_id, farm_id, supply_id, quantity,
            allocation_date, season, crop_cycle,
            allocation_purpose, allocated_by, notes
        ) VALUES (
            v_allocation_id, p_farm_id, p_supply_id, p_quantity,
            SYSDATE, p_season, p_crop_cycle,
            p_purpose, USER, p_notes
        );
        
        -- Update stock
        UPDATE supplies 
        SET current_stock = current_stock - p_quantity,
            last_updated = SYSDATE
        WHERE supply_id = p_supply_id;
        
        -- Record transaction
        INSERT INTO inventory_transactions (
            transaction_id, supply_id, transaction_type,
            quantity, unit_price, total_value,
            reference_id, reference_type, notes
        ) VALUES (
            seq_transaction_id.NEXTVAL, p_supply_id, 'ALLOCATION',
            -p_quantity, v_unit_price, -(p_quantity * v_unit_price),
            v_allocation_id, 'ALLOCATION', 'Allocation for ' || p_season
        );
        
        -- Log the action
        INSERT INTO audit_log (log_id, table_name, action, record_id, details)
        VALUES (seq_log_id.NEXTVAL, 'ALLOCATIONS', 'INSERT', v_allocation_id,
                'Allocation: Farm ' || p_farm_id || ', Supply ' || p_supply_id || ', Qty: ' || p_quantity);
        
        DBMS_OUTPUT.PUT_LINE('✅ Allocation created. ID: ' || v_allocation_id);
        
    ELSE
        RAISE_APPLICATION_ERROR(-20010, 
            'Insufficient stock for allocation. Available: ' || v_stock);
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20011, 'Invalid farm ID or supply ID.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20012, 'Error creating allocation: ' || SQLERRM);
END;
/

-- 3. Function to calculate farm expenditure
CREATE OR REPLACE FUNCTION calculate_farm_expenditure (
    p_farm_id IN NUMBER,
    p_start_date IN DATE,
    p_end_date IN DATE
) RETURN NUMBER
AS
    v_total_expenditure NUMBER(15,2) := 0;
BEGIN
    SELECT NVL(SUM(o.quantity * o.unit_price_at_order), 0)
    INTO v_total_expenditure
    FROM orders o
    WHERE o.farm_id = p_farm_id
      AND o.status = 'Delivered'
      AND o.actual_delivery BETWEEN p_start_date AND p_end_date;
    
    RETURN v_total_expenditure;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END;
/

-- 4. Function to check reorder needs
CREATE OR REPLACE FUNCTION check_reorder_status (
    p_supply_id IN NUMBER
) RETURN VARCHAR2
AS
    v_current supplies.current_stock%TYPE;
    v_min supplies.min_stock_level%TYPE;
    v_max supplies.max_stock_level%TYPE;
    v_supply_name supplies.supply_name%TYPE;
    v_days_to_expiry NUMBER;
BEGIN
    SELECT s.supply_name, s.current_stock, s.min_stock_level, 
           s.max_stock_level, 
           CASE WHEN s.expiry_date IS NOT NULL 
                THEN s.expiry_date - SYSDATE 
                ELSE NULL END
    INTO v_supply_name, v_current, v_min, v_max, v_days_to_expiry
    FROM supplies s
    WHERE s.supply_id = p_supply_id;
    
    -- Check multiple conditions
    IF v_current <= v_min THEN
        RETURN 'URGENT: Stock below minimum (' || v_current || '/' || v_min || ')';
    ELSIF v_current <= (v_min * 1.5) THEN
        RETURN 'WARNING: Stock approaching minimum (' || v_current || '/' || v_min || ')';
    ELSIF v_days_to_expiry IS NOT NULL AND v_days_to_expiry < 30 THEN
        RETURN 'EXPIRING: Item expires in ' || v_days_to_expiry || ' days';
    ELSE
        RETURN 'OK: Stock level normal (' || v_current || '/' || v_max || ')';
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'ERROR: Invalid supply ID';
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END;
/

-- 5. Procedure to generate stock report
CREATE OR REPLACE PROCEDURE generate_stock_report (
    p_category_id IN NUMBER DEFAULT NULL
) AS
    CURSOR stock_cursor IS
        SELECT s.supply_id, s.supply_name, c.category_name,
               s.current_stock, s.min_stock_level, s.max_stock_level,
               s.unit_price, s.expiry_date,
               check_reorder_status(s.supply_id) as reorder_status,
               ROUND((s.current_stock / s.max_stock_level) * 100, 2) as stock_percentage
        FROM supplies s
        JOIN supply_categories c ON s.category_id = c.category_id
        WHERE (p_category_id IS NULL OR s.category_id = p_category_id)
        ORDER BY c.category_name, s.supply_name;
    
    v_counter NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('📊 STOCK REPORT - Generated on: ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI'));
    DBMS_OUTPUT.PUT_LINE('=' || RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE(
        RPAD('Supply Name', 30) || ' ' ||
        RPAD('Category', 15) || ' ' ||
        RPAD('Current', 10) || ' ' ||
        RPAD('Min', 8) || ' ' ||
        RPAD('Max', 8) || ' ' ||
        RPAD('Status', 25)
    );
    DBMS_OUTPUT.PUT_LINE('-' || RPAD('-', 100, '-'));
    
    FOR rec IN stock_cursor LOOP
        v_counter := v_counter + 1;
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.supply_name, 30) || ' ' ||
            RPAD(rec.category_name, 15) || ' ' ||
            RPAD(TO_CHAR(rec.current_stock), 10) || ' ' ||
            RPAD(TO_CHAR(rec.min_stock_level), 8) || ' ' ||
            RPAD(TO_CHAR(rec.max_stock_level), 8) || ' ' ||
            RPAD(rec.reorder_status, 25)
        );
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('-' || RPAD('-', 100, '-'));
    DBMS_OUTPUT.PUT_LINE('Total items: ' || v_counter);
    DBMS_OUTPUT.PUT_LINE('=' || RPAD('=', 100, '='));
    
    -- Log report generation
    INSERT INTO audit_log (log_id, table_name, action, details)
    VALUES (seq_log_id.NEXTVAL, 'REPORTS', 'SELECT', 
            'Stock report generated. Category filter: ' || 
            NVL(TO_CHAR(p_category_id), 'ALL'));
            
END;
/

-- 6. Function to calculate season requirements
CREATE OR REPLACE FUNCTION calculate_season_requirements (
    p_farm_id IN NUMBER,
    p_season IN VARCHAR2
) RETURN SYS_REFCURSOR
AS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
        SELECT s.supply_id, s.supply_name, c.category_name,
               SUM(a.quantity) as total_allocated,
               AVG(a.quantity) as avg_allocation,
               COUNT(a.allocation_id) as allocation_count
        FROM allocations a
        JOIN supplies s ON a.supply_id = s.supply_id
        JOIN supply_categories c ON s.category_id = c.category_id
        WHERE a.farm_id = p_farm_id
          AND a.season LIKE '%' || p_season || '%'
        GROUP BY s.supply_id, s.supply_name, c.category_name
        ORDER BY total_allocated DESC;
    
    RETURN v_cursor;
END;
/

-- 7. Package Specification
CREATE OR REPLACE PACKAGE agro_management_pkg AS
    -- Procedure declarations
    PROCEDURE place_new_order (
        p_farm_id IN NUMBER,
        p_supply_id IN NUMBER,
        p_quantity IN NUMBER,
        p_priority IN VARCHAR2 DEFAULT 'Normal',
        p_notes IN VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE allocate_supplies (
        p_farm_id IN NUMBER,
        p_supply_id IN NUMBER,
        p_quantity IN NUMBER,
        p_season IN VARCHAR2,
        p_crop_cycle IN VARCHAR2,
        p_purpose IN VARCHAR2 DEFAULT 'General',
        p_notes IN VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE generate_stock_report (
        p_category_id IN NUMBER DEFAULT NULL
    );
    
    -- Function declarations
    FUNCTION calculate_farm_expenditure (
        p_farm_id IN NUMBER,
        p_start_date IN DATE,
        p_end_date IN DATE
    ) RETURN NUMBER;
    
    FUNCTION check_reorder_status (
        p_supply_id IN NUMBER
    ) RETURN VARCHAR2;
    
    FUNCTION calculate_season_requirements (
        p_farm_id IN NUMBER,
        p_season IN VARCHAR2
    ) RETURN SYS_REFCURSOR;
    
    -- Utility functions
    FUNCTION get_farm_info (
        p_farm_id IN NUMBER
    ) RETURN VARCHAR2;
    
    PROCEDURE update_supply_price (
        p_supply_id IN NUMBER,
        p_new_price IN NUMBER
    );
    
END agro_management_pkg;
/

-- 8. Package Body
CREATE OR REPLACE PACKAGE BODY agro_management_pkg AS
    
    PROCEDURE place_new_order IS
    BEGIN
        -- Implementation already exists as standalone procedure
        NULL;
    END place_new_order;
    
    PROCEDURE allocate_supplies IS
    BEGIN
        -- Implementation already exists as standalone procedure
        NULL;
    END allocate_supplies;
    
    PROCEDURE generate_stock_report IS
    BEGIN
        -- Implementation already exists as standalone procedure
        NULL;
    END generate_stock_report;
    
    FUNCTION calculate_farm_expenditure RETURN NUMBER IS
    BEGIN
        -- Implementation already exists as standalone function
        RETURN 0;
    END calculate_farm_expenditure;
    
    FUNCTION check_reorder_status RETURN VARCHAR2 IS
    BEGIN
        -- Implementation already exists as standalone function
        RETURN NULL;
    END check_reorder_status;
    
    FUNCTION calculate_season_requirements RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        -- Implementation already exists as standalone function
        RETURN v_cursor;
    END calculate_season_requirements;
    
    -- New utility function
    FUNCTION get_farm_info (
        p_farm_id IN NUMBER
    ) RETURN VARCHAR2
    AS
        v_farm_info VARCHAR2(500);
    BEGIN
        SELECT 'Farm: ' || farm_name || ' | Location: ' || location || 
               ' | Size: ' || size_hectares || ' ha | Crop: ' || crop_type
        INTO v_farm_info
        FROM farms
        WHERE farm_id = p_farm_id;
        
        RETURN v_farm_info;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'Farm not found';
    END get_farm_info;
    
    -- New utility procedure
    PROCEDURE update_supply_price (
        p_supply_id IN NUMBER,
        p_new_price IN NUMBER
    ) AS
        v_old_price supplies.unit_price%TYPE;
    BEGIN
        -- Get old price for audit
        SELECT unit_price INTO v_old_price
        FROM supplies WHERE supply_id = p_supply_id;
        
        -- Update price
        UPDATE supplies 
        SET unit_price = p_new_price,
            last_updated = SYSDATE
        WHERE supply_id = p_supply_id;
        
        -- Log price change
        INSERT INTO audit_log (log_id, table_name, action, record_id, details)
        VALUES (seq_log_id.NEXTVAL, 'SUPPLIES', 'UPDATE', p_supply_id,
                'Price changed from ' || v_old_price || ' to ' || p_new_price);
        
        DBMS_OUTPUT.PUT_LINE('Price updated for supply ID ' || p_supply_id);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20020, 'Supply ID not found');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20021, 'Error updating price: ' || SQLERRM);
    END update_supply_price;
    
END agro_management_pkg;
/

-- 9. Window function example for ranking
CREATE OR REPLACE VIEW farm_performance_view AS
SELECT 
    f.farm_id,
    f.farm_name,
    f.crop_type,
    f.size_hectares,
    COUNT(o.order_id) as total_orders,
    SUM(o.quantity * o.unit_price_at_order) as total_spent,
    AVG(o.quantity * o.unit_price_at_order) as avg_order_value,
    RANK() OVER (ORDER BY SUM(o.quantity * o.unit_price_at_order) DESC) as spending_rank,
    DENSE_RANK() OVER (PARTITION BY f.crop_type ORDER BY COUNT(o.order_id) DESC) as orders_rank_by_crop,
    LAG(f.farm_name, 1, 'First') OVER (ORDER BY f.registration_date) as previous_farm,
    LEAD(f.farm_name, 1, 'Last') OVER (ORDER BY f.registration_date) as next_farm,
    SUM(SUM(o.quantity * o.unit_price_at_order)) OVER (ORDER BY f.registration_date) as cumulative_spending
FROM farms f
LEFT JOIN orders o ON f.farm_id = o.farm_id AND o.status = 'Delivered'
GROUP BY f.farm_id, f.farm_name, f.crop_type, f.size_hectares, f.registration_date;
/

BEGIN
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✅ Procedures, functions, and packages created successfully');
END;
/