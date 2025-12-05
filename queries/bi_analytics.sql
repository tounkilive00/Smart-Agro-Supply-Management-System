-- ============================================
-- AUDIT REVIEW AND COMPLIANCE QUERIES
-- ============================================

-- 1. Complete Audit Trail
SELECT 
    log_id,
    TO_CHAR(action_date, 'YYYY-MM-DD HH24:MI:SS') as timestamp,
    table_name,
    action,
    record_id,
    user_name,
    user_ip,
    session_id,
    SUBSTR(details, 1, 100) as details_summary,
    CASE 
        WHEN action IN ('INSERT', 'UPDATE', 'DELETE') THEN 'DML'
        WHEN action IN ('SELECT', 'LOGIN') THEN 'ACCESS'
        ELSE 'SYSTEM'
    END as audit_category
FROM audit_log
ORDER BY action_date DESC
FETCH FIRST 50 ROWS ONLY;

-- 2. Security Violations and Attempts
SELECT 
    user_name,
    COUNT(*) as total_actions,
    SUM(CASE WHEN details LIKE '%violation%' OR details LIKE '%denied%' THEN 1 ELSE 0 END) as violations,
    SUM(CASE WHEN details LIKE '%restricted%' THEN 1 ELSE 0 END) as restricted_attempts,
    MIN(action_date) as first_attempt,
    MAX(action_date) as last_attempt
FROM audit_log
GROUP BY user_name
HAVING SUM(CASE WHEN details LIKE '%violation%' OR details LIKE '%denied%' THEN 1 ELSE 0 END) > 0
ORDER BY violations DESC;

-- 3. Table Modification History
SELECT 
    table_name,
    action,
    COUNT(*) as count,
    MIN(action_date) as first_change,
    MAX(action_date) as last_change,
    LISTAGG(DISTINCT user_name, ', ') WITHIN GROUP (ORDER BY user_name) as users_involved
FROM audit_log
WHERE action IN ('INSERT', 'UPDATE', 'DELETE')
GROUP BY table_name, action
ORDER BY table_name, action;

-- 4. User Activity Timeline
WITH user_sessions AS (
    SELECT 
        user_name,
        TO_CHAR(action_date, 'YYYY-MM-DD') as activity_date,
        TO_CHAR(MIN(action_date), 'HH24:MI') as first_action,
        TO_CHAR(MAX(action_date), 'HH24:MI') as last_action,
        COUNT(*) as actions_count,
        COUNT(DISTINCT table_name) as tables_accessed,
        LISTAGG(DISTINCT action, ', ') WITHIN GROUP (ORDER BY action) as actions_performed
    FROM audit_log
    WHERE user_name NOT IN ('SYS', 'SYSTEM')
    GROUP BY user_name, TO_CHAR(action_date, 'YYYY-MM-DD')
)
SELECT 
    user_name,
    activity_date,
    first_action,
    last_action,
    actions_count,
    tables_accessed,
    actions_performed,
    ROUND((TO_DATE(last_action, 'HH24:MI') - TO_DATE(first_action, 'HH24:MI')) * 24 * 60, 0) as session_minutes
FROM user_sessions
ORDER BY activity_date DESC, actions_count DESC;

-- 5. Compliance Check: Weekend/Holiday Violations
SELECT 
    TO_CHAR(action_date, 'Day') as day_of_week,
    TO_CHAR(action_date, 'YYYY-MM-DD') as action_date,
    user_name,
    table_name,
    action,
    details
FROM audit_log
WHERE details LIKE '%Restricted%' 
   OR details LIKE '%weekday%' 
   OR details LIKE '%holiday%'
   OR details LIKE '%violation%'
ORDER BY action_date DESC;

-- 6. Data Change Analysis by Hour
SELECT 
    EXTRACT(HOUR FROM action_date) as hour_of_day,
    COUNT(*) as total_actions,
    SUM(CASE WHEN action = 'INSERT' THEN 1 ELSE 0 END) as inserts,
    SUM(CASE WHEN action = 'UPDATE' THEN 1 ELSE 0 END) as updates,
    SUM(CASE WHEN action = 'DELETE' THEN 1 ELSE 0 END) as deletes,
    COUNT(DISTINCT user_name) as active_users
FROM audit_log
WHERE action_date >= TRUNC(SYSDATE) - 7
GROUP BY EXTRACT(HOUR FROM action_date)
ORDER BY hour_of_day;

-- 7. Suspicious Activity Detection
SELECT 
    user_name,
    COUNT(DISTINCT session_id) as session_count,
    COUNT(*) as total_actions,
    COUNT(DISTINCT table_name) as tables_touched,
    COUNT(DISTINCT TO_CHAR(action_date, 'YYYY-MM-DD')) as active_days,
    MIN(action_date) as first_seen,
    MAX(action_date) as last_seen,
    CASE 
        WHEN COUNT(*) > 1000 AND COUNT(DISTINCT TO_CHAR(action_date, 'YYYY-MM-DD')) = 1 THEN 'HIGH_VOLUME_SINGLE_DAY'
        WHEN COUNT(DISTINCT session_id) > 10 THEN 'MULTIPLE_SESSIONS'
        WHEN COUNT(DISTINCT table_name) = (SELECT COUNT(*) FROM user_tables) THEN 'ACCESSED_ALL_TABLES'
        ELSE 'NORMAL'
    END as suspicion_level
FROM audit_log
WHERE user_name NOT IN ('SYS', 'SYSTEM')
GROUP BY user_name
HAVING COUNT(*) > 100
ORDER BY total_actions DESC;

-- 8. Audit Trail Cleanup Recommendations
SELECT 
    'Records older than 90 days' as category,
    COUNT(*) as record_count,
    ROUND(SUM(DBMS_LOB.GETLENGTH(old_values) + DBMS_LOB.GETLENGTH(new_values)) / 1024 / 1024, 2) as size_mb,
    MIN(action_date) as oldest_record,
    MAX(action_date) as newest_record
FROM audit_log
WHERE action_date < SYSDATE - 90
UNION ALL
SELECT 
    'SELECT operations only',
    COUNT(*),
    ROUND(SUM(DBMS_LOB.GETLENGTH(old_values) + DBMS_LOB.GETLENGTH(new_values)) / 1024 / 1024, 2),
    MIN(action_date),
    MAX(action_date)
FROM audit_log
WHERE action = 'SELECT'
UNION ALL
SELECT 
    'System operations (SYS/SYSTEM)',
    COUNT(*),
    ROUND(SUM(DBMS_LOB.GETLENGTH(old_values) + DBMS_LOB.GETLENGTH(new_values)) / 1024 / 1024, 2),
    MIN(action_date),
    MAX(action_date)
FROM audit_log
WHERE user_name IN ('SYS', 'SYSTEM');

-- 9. Data Integrity Verification through Audit
SELECT 
    a.table_name,
    a.record_id,
    a.action,
    a.action_date,
    a.user_name,
    a.details,
    (SELECT COUNT(*) FROM farms WHERE farm_id = TO_NUMBER(a.record_id)) as farm_exists,
    (SELECT COUNT(*) FROM supplies WHERE supply_id = TO_NUMBER(a.record_id)) as supply_exists,
    (SELECT COUNT(*) FROM orders WHERE order_id = TO_NUMBER(a.record_id)) as order_exists
FROM audit_log a
WHERE a.table_name IN ('FARMS', 'SUPPLIES', 'ORDERS')
  AND a.action = 'DELETE'
  AND a.action_date >= SYSDATE - 30
ORDER BY a.action_date DESC;

-- 10. Generate Audit Summary Report
SELECT 
    'Audit Summary Report' as report_title,
    TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') as generated_at,
    (SELECT COUNT(*) FROM audit_log) as total_audit_records,
    (SELECT COUNT(DISTINCT user_name) FROM audit_log WHERE user_name NOT IN ('SYS', 'SYSTEM')) as unique_users,
    (SELECT COUNT(DISTINCT table_name) FROM audit_log) as tables_audited,
    (SELECT MIN(action_date) FROM audit_log) as audit_start_date,
    (SELECT MAX(action_date) FROM audit_log) as audit_end_date,
    (SELECT ROUND(SUM(DBMS_LOB.GETLENGTH(old_values) + DBMS_LOB.GETLENGTH(new_values)) / 1024 / 1024, 2) 
     FROM audit_log) as audit_size_mb
FROM dual;