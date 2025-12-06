# Data Dictionary - Smart Agro-Supply Management System

## Overview
This document provides detailed information about all database tables, columns, constraints, and relationships.

## Table: FARMS
| Column Name | Data Type | Constraints | Description | Sample Value |
|-------------|-----------|-------------|-------------|--------------|
| FARM_ID | NUMBER(10) | PK, NOT NULL | Unique farm identifier | 1000 |
| FARM_NAME | VARCHAR2(100) | NOT NULL, UNIQUE | Name of the farm | Green Valley Maize Farm |
| LOCATION | VARCHAR2(200) | NULL | Geographical location | Rulindo District |
| SIZE_HECTARES | NUMBER(10,2) | CHECK > 0 | Farm area in hectares | 120.50 |
| CROP_TYPE | VARCHAR2(100) | NULL | Primary crop grown | Maize |
| SOIL_TYPE | VARCHAR2(50) | NULL | Soil classification | Clay Loam |
| MANAGER_NAME | VARCHAR2(100) | NULL | Farm manager name | John Niyonsenga |
| CONTACT_PHONE | VARCHAR2(20) | NULL | Contact number | +250788222001 |
| EMAIL | VARCHAR2(100) | NULL | Contact email | john@greenvalley.rw |
| REGISTRATION_DATE | DATE | DEFAULT SYSDATE | Date farm registered | 16-NOV-2025 |
| STATUS | VARCHAR2(20) | CHECK values | Farm status | Active |

## Table: SUPPLIERS
| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| SUPPLIER_ID | NUMBER(10) | PK, NOT NULL | Unique supplier identifier |
| SUPPLIER_NAME | VARCHAR2(150) | NOT NULL | Supplier company name |
| CONTACT_PERSON | VARCHAR2(100) | NULL | Primary contact person |
| PHONE | VARCHAR2(20) | NULL | Contact phone number |
| EMAIL | VARCHAR2(100) | UNIQUE | Contact email address |
| ADDRESS | VARCHAR2(300) | NULL | Physical address |
| CITY | VARCHAR2(100) | NULL | City location |
| COUNTRY | VARCHAR2(50) | DEFAULT 'Rwanda' | Country of operation |
| RATING | NUMBER(2,1) | CHECK (1-5) | Supplier performance rating |
| IS_ACTIVE | CHAR(1) | CHECK (Y/N) | Active status flag |
| REGISTRATION_DATE | DATE | DEFAULT SYSDATE | Registration date |

## Table: SUPPLIES
| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| SUPPLY_ID | NUMBER(10) | PK, NOT NULL | Unique supply identifier |
| SUPPLY_NAME | VARCHAR2(150) | NOT NULL | Name of the supply item |
| CATEGORY_ID | NUMBER(5) | FK to categories | Supply category |
| SUPPLIER_ID | NUMBER(10) | FK to suppliers | Supplier reference |
| UNIT_PRICE | NUMBER(10,2) | CHECK >= 0 | Price per unit |
| CURRENT_STOCK | NUMBER(10,2) | DEFAULT 0, CHECK >=0 | Available quantity |
| MIN_STOCK_LEVEL | NUMBER(10,2) | DEFAULT 10 | Reorder threshold |
| MAX_STOCK_LEVEL | NUMBER(10,2) | NULL | Maximum stock capacity |
| EXPIRY_DATE | DATE | NULL | Expiration date |
| BATCH_NUMBER | VARCHAR2(50) | NULL | Manufacturing batch |
| STORAGE_CONDITIONS | VARCHAR2(100) | NULL | Storage requirements |
| LAST_UPDATED | DATE | DEFAULT SYSDATE | Last update timestamp |

## Table: ORDERS
| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| ORDER_ID | NUMBER(10) | PK, NOT NULL | Unique order identifier |
| FARM_ID | NUMBER(10) | FK to farms | Farm placing order |
| SUPPLY_ID | NUMBER(10) | FK to supplies | Supply being ordered |
| QUANTITY | NUMBER(10,2) | CHECK > 0 | Order quantity |
| UNIT_PRICE_AT_ORDER | NUMBER(10,2) | NULL | Price at time of order |
| TOTAL_AMOUNT | NUMBER(12,2) | GENERATED | Calculated total |
| ORDER_DATE | DATE | DEFAULT SYSDATE | Date order placed |
| STATUS | VARCHAR2(20) | CHECK values | Order status |
| EXPECTED_DELIVERY | DATE | NULL | Estimated delivery date |
| ACTUAL_DELIVERY | DATE | NULL | Actual delivery date |
| PRIORITY | VARCHAR2(10) | CHECK values | Order priority level |
| NOTES | VARCHAR2(500) | NULL | Additional notes |

## Table: ALLOCATIONS
| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| ALLOCATION_ID | NUMBER(10) | PK, NOT NULL | Unique allocation identifier |
| FARM_ID | NUMBER(10) | FK to farms | Farm receiving allocation |
| SUPPLY_ID | NUMBER(10) | FK to supplies | Supply being allocated |
| QUANTITY | NUMBER(10,2) | CHECK > 0 | Allocation quantity |
| ALLOCATION_DATE | DATE | DEFAULT SYSDATE | Date of allocation |
| SEASON | VARCHAR2(50) | NULL | Agricultural season |
| CROP_CYCLE | VARCHAR2(30) | NULL | Crop growth cycle |
| ALLOCATION_PURPOSE | VARCHAR2(100) | NULL | Purpose of allocation |
| ALLOCATED_BY | VARCHAR2(100) | DEFAULT USER | User who made allocation |
| NOTES | VARCHAR2(500) | NULL | Additional notes |

## Table: AUDIT_LOG
| Column Name | Data Type | Constraints | Description |
|-------------|-----------|-------------|-------------|
| LOG_ID | NUMBER(10) | PK, NOT NULL | Unique log identifier |
| TABLE_NAME | VARCHAR2(50) | NOT NULL | Table being audited |
| ACTION | VARCHAR2(20) | CHECK values | Type of action |
| RECORD_ID | VARCHAR2(100) | NULL | Affected record ID |
| OLD_VALUES | CLOB | NULL | Previous values |
| NEW_VALUES | CLOB | NULL | New values |
| USER_NAME | VARCHAR2(100) | DEFAULT USER | User performing action |
| USER_IP | VARCHAR2(50) | NULL | User IP address |
| ACTION_DATE | TIMESTAMP | DEFAULT SYSTIMESTAMP | Action timestamp |
| SESSION_ID | VARCHAR2(100) | NULL | Database session ID |
| DETAILS | VARCHAR2(1000) | NULL | Additional details |

## Relationships
1. **FARMS → ORDERS** (1:N) - One farm can place many orders
2. **SUPPLIES → ORDERS** (1:N) - One supply item can be in many orders
3. **SUPPLIERS → SUPPLIES** (1:N) - One supplier provides many supplies
4. **FARMS → ALLOCATIONS** (1:N) - One farm receives many allocations
5. **SUPPLIES → ALLOCATIONS** (1:N) - One supply can be allocated many times

## Business Rules Enforced
1. Orders cannot be placed on weekdays or public holidays
2. Stock levels cannot go negative
3. Allocations must respect farm size capacity
4. Expired supplies cannot be ordered
5. Minimum stock levels trigger reorder alerts