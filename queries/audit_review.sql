-- Audit Review Query - Smart Agro-Supply Management System
-- This file contains SQL queries for reviewing audit logs

SELECT 
	LOG_ID,
	TABLE_NAME,
	ACTION,
	RECORD_ID,
	USER_NAME,
	ACTION_DATE,
	DETAILS
FROM AUDIT_LOG
ORDER BY ACTION_DATE DESC;