-- ============================================
-- TABLES CREATION SCRIPT
-- All tables in 3NF with proper constraints
-- ============================================

-- Connect as agro_app_user

-- 1. FARMS Table
CREATE TABLE farms (
    farm_id NUMBER(10) 
        CONSTRAINT pk_farm PRIMARY KEY,
    farm_name VARCHAR2(100) 
        CONSTRAINT nn_farm_name NOT NULL,
    location VARCHAR2(200),
    size_hectares NUMBER(10,2) 
        CONSTRAINT chk_farm_size CHECK (size_hectares > 0),
    crop_type VARCHAR2(100),
    soil_type VARCHAR2(50),
    manager_name VARCHAR2(100),
    contact_phone VARCHAR2(20),
    email VARCHAR2(100),
    registration_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) DEFAULT 'Active' 
        CONSTRAINT chk_farm_status CHECK (status IN ('Active','Inactive','Suspended')),
    CONSTRAINT unq_farm_name UNIQUE (farm_name)
) TABLESPACE agro_data;

-- 2. SUPPLIERS Table
CREATE TABLE suppliers (
    supplier_id NUMBER(10) 
        CONSTRAINT pk_supplier PRIMARY KEY,
    supplier_name VARCHAR2(150) 
        CONSTRAINT nn_supplier_name NOT NULL,
    contact_person VARCHAR2(100),
    phone VARCHAR2(20),
    email VARCHAR2(100),
    address VARCHAR2(300),
    city VARCHAR2(100),
    country VARCHAR2(50) DEFAULT 'Rwanda',
    rating NUMBER(2,1) 
        CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
    is_active CHAR(1) DEFAULT 'Y' 
        CONSTRAINT chk_supplier_active CHECK (is_active IN ('Y','N')),
    registration_date DATE DEFAULT SYSDATE,
    CONSTRAINT unq_supplier_email UNIQUE (email)
) TABLESPACE agro_data;

-- 3. SUPPLY_CATEGORIES Table (Lookup)
CREATE TABLE supply_categories (
    category_id NUMBER(5) 
        CONSTRAINT pk_category PRIMARY KEY,
    category_name VARCHAR2(50) 
        CONSTRAINT nn_category_name NOT NULL,
    description VARCHAR2(200),
    unit_of_measure VARCHAR2(20),
    shelf_life_months NUMBER(3)
) TABLESPACE agro_data;

-- 4. SUPPLIES Table
CREATE TABLE supplies (
    supply_id NUMBER(10) 
        CONSTRAINT pk_supply PRIMARY KEY,
    supply_name VARCHAR2(150) 
        CONSTRAINT nn_supply_name NOT NULL,
    category_id NUMBER(5) 
        CONSTRAINT fk_supply_category REFERENCES supply_categories(category_id),
    supplier_id NUMBER(10) 
        CONSTRAINT fk_supply_supplier REFERENCES suppliers(supplier_id),
    unit_price NUMBER(10,2) 
        CONSTRAINT chk_unit_price CHECK (unit_price >= 0),
    current_stock NUMBER(10,2) DEFAULT 0 
        CONSTRAINT chk_current_stock CHECK (current_stock >= 0),
    min_stock_level NUMBER(10,2) DEFAULT 10,
    max_stock_level NUMBER(10,2),
    expiry_date DATE,
    batch_number VARCHAR2(50),
    storage_conditions VARCHAR2(100),
    last_updated DATE DEFAULT SYSDATE,
    CONSTRAINT chk_stock_levels CHECK (min_stock_level < max_stock_level)
) TABLESPACE agro_data;

-- 5. ORDERS Table
CREATE TABLE orders (
    order_id NUMBER(10) 
        CONSTRAINT pk_order PRIMARY KEY,
    farm_id NUMBER(10) 
        CONSTRAINT fk_order_farm REFERENCES farms(farm_id),
    supply_id NUMBER(10) 
        CONSTRAINT fk_order_supply REFERENCES supplies(supply_id),
    quantity NUMBER(10,2) 
        CONSTRAINT chk_order_qty CHECK (quantity > 0),
    unit_price_at_order NUMBER(10,2),
    total_amount NUMBER(12,2) GENERATED ALWAYS AS (quantity * unit_price_at_order) VIRTUAL,
    order_date DATE DEFAULT SYSDATE,
    status VARCHAR2(20) DEFAULT 'Pending' 
        CONSTRAINT chk_order_status CHECK (status IN ('Pending','Approved','Processing','Shipped','Delivered','Cancelled')),
    expected_delivery DATE,
    actual_delivery DATE,
    priority VARCHAR2(10) DEFAULT 'Normal' 
        CONSTRAINT chk_priority CHECK (priority IN ('Low','Normal','High','Urgent')),
    notes VARCHAR2(500)
) TABLESPACE agro_data;

-- 6. ALLOCATIONS Table
CREATE TABLE allocations (
    allocation_id NUMBER(10) 
        CONSTRAINT pk_allocation PRIMARY KEY,
    farm_id NUMBER(10) 
        CONSTRAINT fk_allocation_farm REFERENCES farms(farm_id),
    supply_id NUMBER(10) 
        CONSTRAINT fk_allocation_supply REFERENCES supplies(supply_id),
    quantity NUMBER(10,2) 
        CONSTRAINT chk_allocation_qty CHECK (quantity > 0),
    allocation_date DATE DEFAULT SYSDATE,
    season VARCHAR2(50),
    crop_cycle VARCHAR2(30),
    allocation_purpose VARCHAR2(100),
    allocated_by VARCHAR2(100) DEFAULT USER,
    notes VARCHAR2(500),
    CONSTRAINT unq_farm_supply_season UNIQUE (farm_id, supply_id, season, crop_cycle)
) TABLESPACE agro_data;

-- 7. AUDIT_LOG Table
CREATE TABLE audit_log (
    log_id NUMBER(10) 
        CONSTRAINT pk_audit_log PRIMARY KEY,
    table_name VARCHAR2(50) 
        CONSTRAINT nn_table_name NOT NULL,
    action VARCHAR2(20) 
        CONSTRAINT chk_audit_action CHECK (action IN ('INSERT','UPDATE','DELETE','SELECT','LOGIN')),
    record_id VARCHAR2(100),
    old_values CLOB,
    new_values CLOB,
    user_name VARCHAR2(100) DEFAULT USER,
    user_ip VARCHAR2(50),
    action_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    session_id VARCHAR2(100),
    details VARCHAR2(1000)
) TABLESPACE agro_data;

-- 8. HOLIDAYS Table
CREATE TABLE holidays (
    holiday_id NUMBER(10) 
        CONSTRAINT pk_holiday PRIMARY KEY,
    holiday_name VARCHAR2(100) 
        CONSTRAINT nn_holiday_name NOT NULL,
    holiday_date DATE 
        CONSTRAINT nn_holiday_date NOT NULL,
    country VARCHAR2(50) DEFAULT 'Rwanda',
    is_recurring CHAR(1) DEFAULT 'N' 
        CONSTRAINT chk_recurring CHECK (is_recurring IN ('Y','N')),
    is_public_holiday CHAR(1) DEFAULT 'Y',
    description VARCHAR2(300),
    CONSTRAINT unq_holiday_date UNIQUE (holiday_date, country)
) TABLESPACE agro_data;

-- 9. USERS Table (for authentication)
CREATE TABLE system_users (
    user_id NUMBER(10) 
        CONSTRAINT pk_user PRIMARY KEY,
    username VARCHAR2(50) 
        CONSTRAINT nn_username NOT NULL 
        CONSTRAINT unq_username UNIQUE,
    password_hash VARCHAR2(200) 
        CONSTRAINT nn_password NOT NULL,
    full_name VARCHAR2(100),
    email VARCHAR2(100),
    role VARCHAR2(30) DEFAULT 'USER' 
        CONSTRAINT chk_user_role CHECK (role IN ('ADMIN','MANAGER','FARMER','SUPPLIER','VIEWER')),
    farm_id NUMBER(10) 
        CONSTRAINT fk_user_farm REFERENCES farms(farm_id),
    is_active CHAR(1) DEFAULT 'Y' 
        CONSTRAINT chk_user_active CHECK (is_active IN ('Y','N')),
    last_login TIMESTAMP,
    created_date DATE DEFAULT SYSDATE
) TABLESPACE agro_data;

-- 10. INVENTORY_TRANSACTIONS Table
CREATE TABLE inventory_transactions (
    transaction_id NUMBER(10) 
        CONSTRAINT pk_transaction PRIMARY KEY,
    supply_id NUMBER(10) 
        CONSTRAINT fk_trans_supply REFERENCES supplies(supply_id),
    transaction_type VARCHAR2(20) 
        CONSTRAINT chk_trans_type CHECK (transaction_type IN ('PURCHASE','ALLOCATION','ADJUSTMENT','RETURN','WASTE')),
    quantity NUMBER(10,2),
    unit_price NUMBER(10,2),
    total_value NUMBER(12,2),
    reference_id NUMBER(10), -- links to order_id or allocation_id
    reference_type VARCHAR2(20),
    transaction_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    performed_by VARCHAR2(100) DEFAULT USER,
    notes VARCHAR2(500)
) TABLESPACE agro_data;

-- Create indexes for performance
CREATE INDEX idx_farms_location ON farms(location) TABLESPACE agro_idx;
CREATE INDEX idx_supplies_category ON supplies(category_id) TABLESPACE agro_idx;
CREATE INDEX idx_supplies_supplier ON supplies(supplier_id) TABLESPACE agro_idx;
CREATE INDEX idx_orders_farm_date ON orders(farm_id, order_date) TABLESPACE agro_idx;
CREATE INDEX idx_orders_status ON orders(status) TABLESPACE agro_idx;
CREATE INDEX idx_allocations_farm_season ON allocations(farm_id, season) TABLESPACE agro_idx;
CREATE INDEX idx_audit_table_date ON audit_log(table_name, action_date) TABLESPACE agro_idx;
CREATE INDEX idx_supplies_expiry ON supplies(expiry_date) TABLESPACE agro_idx;
CREATE INDEX idx_inventory_supply_date ON inventory_transactions(supply_id, transaction_date) TABLESPACE agro_idx;

-- Create sequences
CREATE SEQUENCE seq_farm_id START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE seq_supplier_id START WITH 5000 INCREMENT BY 1;
CREATE SEQUENCE seq_category_id START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE seq_supply_id START WITH 10000 INCREMENT BY 1;
CREATE SEQUENCE seq_order_id START WITH 20000 INCREMENT BY 1;
CREATE SEQUENCE seq_allocation_id START WITH 30000 INCREMENT BY 1;
CREATE SEQUENCE seq_log_id START WITH 1 INCREMENT BY 1 MAXVALUE 9999999999;
CREATE SEQUENCE seq_holiday_id START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_user_id START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE seq_transaction_id START WITH 1 INCREMENT BY 1;

COMMIT;