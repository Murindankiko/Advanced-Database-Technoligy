-- B10: Test Alert System
-- Generates test data to trigger various alerts

-- Test 1: Trigger daily data usage alert
INSERT INTO cdr_fact (SimID, CallStart, DurationMin, DataVolumeMB, ChargeRWF)
VALUES 
    (1, CURRENT_TIMESTAMP, 0, 3000, 0),  -- First usage
    (1, CURRENT_TIMESTAMP + INTERVAL '1 hour', 0, 2500, 0);  -- This should trigger alert (total > 5000 MB)

-- Verify daily data usage alert
SELECT 
    'Daily Data Usage Alert' as test_case,
    alert_message,
    current_value,
    threshold_value,
    severity,
    triggered_at
FROM business_alerts
WHERE limit_id = (SELECT limit_id FROM business_limits WHERE limit_name = 'Daily Data Usage Limit')
ORDER BY triggered_at DESC
LIMIT 1;

-- Test 2: Trigger long call duration alert
INSERT INTO cdr_fact (SimID, CallStart, DurationMin, DataVolumeMB, ChargeRWF)
VALUES (2, CURRENT_TIMESTAMP, 150, 0, 500);  -- 150 minutes exceeds 120 minute limit

-- Verify call duration alert
SELECT 
    'Call Duration Alert' as test_case,
    alert_message,
    current_value,
    threshold_value,
    severity,
    triggered_at
FROM business_alerts
WHERE limit_id = (SELECT limit_id FROM business_limits WHERE limit_name = 'Single Call Duration Limit')
ORDER BY triggered_at DESC
LIMIT 1;

-- Test 3: Trigger monthly spending alert
-- First, add multiple charges to exceed 50,000 RWF
INSERT INTO cdr_fact (SimID, CallStart, DurationMin, DataVolumeMB, ChargeRWF)
VALUES 
    (3, CURRENT_TIMESTAMP, 100, 500, 25000),
    (3, CURRENT_TIMESTAMP + INTERVAL '1 hour', 100, 500, 30000);  -- Total 55,000 RWF

-- Verify monthly spending alert
SELECT 
    'Monthly Spending Alert' as test_case,
    alert_message,
    current_value,
    threshold_value,
    severity,
    triggered_at
FROM business_alerts
WHERE limit_id = (SELECT limit_id FROM business_limits WHERE limit_name = 'Monthly Spend Limit')
ORDER BY triggered_at DESC
LIMIT 1;

-- Test 4: View all alerts summary
SELECT 
    bl.limit_name,
    COUNT(*) as alert_count,
    ba.severity,
    ba.alert_status
FROM business_alerts ba
JOIN business_limits bl ON ba.limit_id = bl.limit_id
GROUP BY bl.limit_name, ba.severity, ba.alert_status
ORDER BY alert_count DESC;

-- Test 5: View pending alert actions
SELECT 
    aa.action_id,
    ba.alert_message,
    aa.action_type,
    aa.action_status,
    aa.created_at
FROM alert_actions aa
JOIN business_alerts ba ON aa.alert_id = ba.alert_id
WHERE aa.action_status = 'pending'
ORDER BY aa.created_at DESC;
