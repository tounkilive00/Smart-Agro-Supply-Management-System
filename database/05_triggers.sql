-- ============================================
-- TRIGGERS IMPLEMENTATION
-- Advanced programming with business rules
-- ============================================

-- 1. Audit Logging Function
CREATE OR REPLACE FUNCTION log_audit_entry (
    p_table_name IN VARCHAR2,
    p_action IN VARCHAR2,
    p_record_id IN VARCHAR2,
    p_old_values IN CLOB DEFAULT NULL,
    p_new_values IN CLOB DEFAULT NULL,
    p_details IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER
AS
    v_log_id NUMBER;
    v_user_ip VARCHAR2(50);
BEGIN
    -- Get next log ID
    SELECT seq_log_id.NEXTVAL INTO v_log_id FROM dual;
    
    -- Get user IP (simplified)
    BEGIN
        SELECT SYS_CONTEXT('USERENV', 'IP_ADDRESS') INTO v_user_ip FROM dual;
    EXCEPTION
        WHEN OTHERS THEN v_user_ip := 'UNKNOWN';
    END;
    
    -- Insert audit record
    INSERT INTO audit_log (
        log_id, table_name, action, record_id,
        old_values, new_values, user_name,
        user_ip, session_id, details
    ) VALUES (
        v_log_id, p_table_name, p_action, p_record_id,
        p_old_values, p_new_values, USER,
        v_user_ip, SYS_CONTEXT('USERENV', 'SESSIONID'), p_details
    );
    
    RETURN v_log_id;
    
EXCEPTION
    WHEN OTHERS THEN
        -- If audit fails, still allow operation but log error
        INSERT INTO audit_log (log_id, table_name, action, details)
        VALUES (seq_log_id.NEXTVAL, 'AUDIT_SYSTEM', 'ERROR', 
                'Failed to log: ' || SQLERRM);
        RETURN -1;
END;
/

-- 2. Function to check if current day is restricted
CREATE OR REPLACE FUNCTION is_restricted_day 
RETURN BOOLEAN
AS
    v_day_of_week VARCHAR2(20);
    v_is_holiday NUMBER;
BEGIN
    -- Check if today is a weekday (Monday=2 to Friday=6 in Oracle)
    SELECT TO_CHAR(SYSDATE, 'D') INTO v_day_of_week FROM dual;
    
    IF v_day_of_week BETWEEN '2' AND '6' THEN
        -- Check if today is a holiday
        SELECT COUNT(*) INTO v_is_holiday
        FROM holidays
        WHERE holiday_date = TRUNC(SYSDATE)
          AND is_public_holiday = 'Y';
        
        RETURN TRUE; -- Restricted on weekdays and holidays
    END IF;
    
    RETURN FALSE; -- Allowed on weekends
END;
/

-- 3. Compound Trigger: Restrict orders on restricted days
CREATE OR REPLACE TRIGGER restrict_orders_compound
FOR INSERT OR UPDATE ON orders
COMPOUND TRIGGER

    -- Declaration section
    TYPE t_order_rec IS RECORD (
        order_id orders.order_id%TYPE,
        farm_id orders.farm_id%TYPE,
        supply_id orders.supply_id%TYPE
    );
    
    TYPE t_order_tab IS TABLE OF t_order_rec;
    g_orders t_order_tab := t_order_tab();
    
    v_restricted_day BOOLEAN;
    
    -- Before statement
    BEFORE STATEMENT IS
    BEGIN
        v_restricted_day := is_restricted_day();
        
        IF v_restricted_day THEN
            RAISE_APPLICATION_ERROR(-20030, 
                'Orders cannot be placed or modified on weekdays or public holidays. ' ||
                'Please try again on weekends.');
        END IF;
    END BEFORE STATEMENT;
    
    -- Before each row
    BEFORE EACH ROW IS
    BEGIN
        -- Additional business rule: Cannot order expired supplies
        DECLARE
            v_expiry_date supplies.expiry_date%TYPE;
        BEGIN
            SELECT expiry_date INTO v_expiry_date
            FROM supplies
            WHERE supply_id = :NEW.supply_id;
            
            IF v_expiry_date < SYSDATE THEN
                RAISE_APPLICATION_ERROR(-20031, 
                    'Cannot order expired supply. Expiry date: ' || 
                    TO_CHAR(v_expiry_date, 'DD-MON-YYYY'));
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20032, 'Invalid supply ID');
        END;
    END BEFORE EACH ROW;
    
    -- After each row
    AFTER EACH ROW IS
        v_log_id NUMBER;
    BEGIN
        -- Add to collection for bulk processing
        g_orders.EXTEND;
        g_orders(g_orders.LAST) := t_order_rec(
            :NEW.order_id, :NEW.farm_id, :NEW.supply_id
        );
        
        -- Log the individual action
        v_log_id := log_audit_entry(
            'ORDERS',
            CASE WHEN INSERTING THEN 'INSERT' ELSE 'UPDATE' END,
            :NEW.order_id,
            CASE WHEN UPDATING THEN 
                'Farm: ' || :OLD.farm_id || ', Supply: ' || :OLD.supply_id || 
                ', Qty: ' || :OLD.quantity || ', Status: ' || :OLD.status
            END,
            'Farm: ' || :NEW.farm_id || ', Supply: ' || :NEW.supply_id || 
            ', Qty: ' || :NEW.quantity || ', Status: ' || :NEW.status,
            'Order ' || CASE WHEN INSERTING THEN 'placed' ELSE 'updated' END
        );
    END AFTER EACH ROW;
    
    -- After statement
    AFTER STATEMENT IS
    BEGIN
        -- Send notification for bulk operations (simulated)
        IF g_orders.COUNT > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Processed ' || g_orders.COUNT || ' order(s)');
            
            -- Here you could add code to:
            -- 1. Send email notifications
            -- 2. Update dashboards
            -- 3. Trigger downstream processes
        END IF;
        
        -- Clear collection
        g_orders.DELETE;
    END AFTER STATEMENT;

END restrict_orders_compound;
/

-- 4. Trigger: Auto-update stock on order delivery
CREATE OR REPLACE TRIGGER update_stock_on_delivery
AFTER UPDATE OF status ON orders
FOR EACH ROW
WHEN (NEW.status = 'Delivered' AND OLD.status != 'Delivered')
DECLARE
    v_log_id NUMBER;
BEGIN
    -- Update actual delivery date if not set
    IF :NEW.actual_delivery IS NULL THEN
        :NEW.actual_delivery := SYSDATE;
    END IF;
    
    -- Log the delivery
    v_log_id := log_audit_entry(
        'ORDERS',
        'DELIVERED',
        :NEW.order_id,
        NULL,
        'Delivered on: ' || TO_CHAR(:NEW.actual_delivery, 'DD-MON-YYYY'),
        'Order marked as delivered'
    );
    
    DBMS_OUTPUT.PUT_LINE('Order ' || :NEW.order_id || ' delivered successfully.');
    
EXCEPTION
    WHEN OTHERS THEN
        -- Log error but don't fail the transaction
        INSERT INTO audit_log (log_id, table_name, action, details)
        VALUES (seq_log_id.NEXTVAL, 'TRIGGERS', 'ERROR', 
                'update_stock_on_delivery failed: ' || SQLERRM);
END;
/

-- 5. Trigger: Prevent stock from going negative
CREATE OR REPLACE TRIGGER prevent_negative_stock
BEFORE UPDATE OF current_stock ON supplies
FOR EACH ROW
BEGIN
    IF :NEW.current_stock < 0 THEN
        RAISE_APPLICATION_ERROR(-20040, 
            'Stock cannot be negative. Attempted to set stock to: ' || :NEW.current_stock);
    END IF;
END;
/

-- 6. Trigger: Audit all DML on supplies table
CREATE OR REPLACE TRIGGER audit_supplies_changes
AFTER INSERT OR UPDATE OR DELETE ON supplies
FOR EACH ROW
DECLARE
    v_action VARCHAR2(20);
    v_record_id VARCHAR2(100);
    v_old_values CLOB;
    v_new_values CLOB;
BEGIN
    -- Determine action
    IF INSERTING THEN
        v_action := 'INSERT';
        v_record_id := :NEW.supply_id;
        v_new_values := 'Name: ' || :NEW.supply_name || ', Stock: ' || :NEW.current_stock || 
                       ', Price: ' || :NEW.unit_price;
    ELSIF UPDATING THEN
        v_action := 'UPDATE';
        v_record_id := :NEW.supply_id;
        v_old_values := 'Name: ' || :OLD.supply_name || ', Stock: ' || :OLD.current_stock || 
                       ', Price: ' || :OLD.unit_price;
        v_new_values := 'Name: ' || :NEW.supply_name || ', Stock: ' || :NEW.current_stock || 
                       ', Price: ' || :NEW.unit_price;
    ELSE
        v_action := 'DELETE';
        v_record_id := :OLD.supply_id;
        v_old_values := 'Name: ' || :OLD.supply_name || ', Stock: ' || :OLD.current_stock || 
                       ', Price: ' || :OLD.unit_price;
    END IF;
    
    -- Log the change
    log_audit_entry(
        'SUPPLIES',
        v_action,
        v_record_id,
        v_old_values,
        v_new_values,
        CASE 
            WHEN UPDATING('unit_price') THEN 'Price changed'
            WHEN UPDATING('current_stock') THEN 'Stock level adjusted'
            ELSE 'General update'
        END
    );
    
END;
/

-- 7. Trigger: Validate allocation doesn't exceed farm capacity
CREATE OR REPLACE TRIGGER validate_allocation_capacity
BEFORE INSERT ON allocations
FOR EACH ROW
DECLARE
    v_farm_size farms.size_hectares%TYPE;
    v_supply_category supply_categories.category_name%TYPE;
    v_recommended_max NUMBER;
BEGIN
    -- Get farm size
    SELECT size_hectares INTO v_farm_size
    FROM farms WHERE farm_id = :NEW.farm_id;
    
    -- Get supply category
    SELECT c.category_name INTO v_supply_category
    FROM supplies s
    JOIN supply_categories c ON s.category_id = c.category_id
    WHERE s.supply_id = :NEW.supply_id;
    
    -- Define recommended maximum based on farm size and category
    CASE v_supply_category
        WHEN 'Fertilizers' THEN
            v_recommended_max := v_farm_size * 2; -- 2kg per hectare
        WHEN 'Seeds' THEN
            v_recommended_max := v_farm_size * 5; -- 5kg per hectare
        WHEN 'Pesticides' THEN
            v_recommended_max := v_farm_size * 0.5; -- 0.5L per hectare
        ELSE
            v_recommended_max := 1000; -- Default high value
    END CASE;
    
    -- Check if allocation exceeds recommended maximum
    IF :NEW.quantity > v_recommended_max THEN
        RAISE_APPLICATION_ERROR(-20050,
            'Allocation exceeds recommended maximum for farm size. ' ||
            'Farm size: ' || v_farm_size || ' ha, ' ||
            'Recommended max for ' || v_supply_category || ': ' || v_recommended_max || 
            ', Requested: ' || :NEW.quantity);
    END IF;
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20051, 'Invalid farm ID or supply ID');
END;
/

-- 8. System trigger for database logon (audit)
CREATE OR REPLACE TRIGGER system_logon_audit
AFTER LOGON ON DATABASE
BEGIN
    INSERT INTO audit_log (log_id, table_name, action, details)
    VALUES (seq_log_id.NEXTVAL, 'SYSTEM', 'LOGON', 
            'User logged in at ' || TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS'));
END;
/

-- 9. Instead-of trigger for view updates (example)
CREATE OR REPLACE TRIGGER instead_of_farm_view
INSTEAD OF INSERT ON farm_performance_view
FOR EACH ROW
BEGIN
    -- This demonstrates how you could handle view updates
    -- In reality, you would update the underlying tables
    DBMS_OUTPUT.PUT_LINE('View updates must go through base tables');
    RAISE_APPLICATION_ERROR(-20060, 
        'Direct updates to this view are not allowed. Use base tables.');
END;
/

BEGIN
    DBMS_OUTPUT.PUT_LINE('✅ Triggers created successfully');
END;
/