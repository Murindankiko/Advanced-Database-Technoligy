-- B10: Alert Management Queries
-- Queries for monitoring and managing the alert system

-- Query 1: Active alerts dashboard
SELECT 
    ba.alert_id,
    bl.limit_name,
    ba.subscriber_id,
    ba.sim_id,
    ba.alert_message,
    ba.current_value,
    ba.threshold_value,
    ba.severity,
    ba.alert_status,
    ba.triggered_at,
    EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - ba.triggered_at))/60 as minutes_since_alert
FROM business_alerts ba
JOIN business_limits bl ON ba.limit_id = bl.limit_id
WHERE ba.alert_status = 'new'
ORDER BY 
    CASE ba.severity 
        WHEN 'critical' THEN 1
        WHEN 'warning' THEN 2
        WHEN 'info' THEN 3
    END,
    ba.triggered_at DESC;

-- Query 2: Alert statistics by severity
SELECT 
    severity,
    alert_status,
    COUNT(*) as alert_count,
    MIN(triggered_at) as first_alert,
    MAX(triggered_at) as latest_alert
FROM business_alerts
WHERE DATE(triggered_at) >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY severity, alert_status
ORDER BY severity, alert_status;

-- Query 3: Top subscribers by alert count
SELECT 
    ba.subscriber_id,
    sd.SubscriberName,
    COUNT(*) as total_alerts,
    COUNT(*) FILTER (WHERE ba.severity = 'critical') as critical_alerts,
    COUNT(*) FILTER (WHERE ba.severity = 'warning') as warning_alerts,
    MAX(ba.triggered_at) as last_alert_time
FROM business_alerts ba
LEFT JOIN subscriber_dim sd ON ba.subscriber_id = sd.SubscriberID
WHERE ba.subscriber_id IS NOT NULL
GROUP BY ba.subscriber_id, sd.SubscriberName
HAVING COUNT(*) > 0
ORDER BY total_alerts DESC, critical_alerts DESC
LIMIT 10;

-- Query 4: Alert resolution performance
SELECT 
    bl.limit_name,
    COUNT(*) as total_alerts,
    COUNT(*) FILTER (WHERE ba.alert_status = 'resolved') as resolved_count,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ba.alert_status = 'resolved') / COUNT(*), 2) as resolution_rate,
    AVG(EXTRACT(EPOCH FROM (ba.acknowledged_at - ba.triggered_at))/60) 
        FILTER (WHERE ba.acknowledged_at IS NOT NULL) as avg_response_time_minutes
FROM business_alerts ba
JOIN business_limits bl ON ba.limit_id = bl.limit_id
WHERE DATE(ba.triggered_at) >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY bl.limit_name
ORDER BY total_alerts DESC;

-- Query 5: Acknowledge an alert (example)
-- UPDATE business_alerts
-- SET alert_status = 'acknowledged',
--     acknowledged_at = CURRENT_TIMESTAMP,
--     acknowledged_by = 'admin_user'
-- WHERE alert_id = 1;

-- Query 6: Resolve an alert with notes (example)
-- UPDATE business_alerts
-- SET alert_status = 'resolved',
--     resolution_notes = 'Customer contacted and issue resolved'
-- WHERE alert_id = 1;

-- Query 7: Disable a business limit temporarily
-- UPDATE business_limits
-- SET is_active = false
-- WHERE limit_name = 'Daily Data Usage Limit';

-- Query 8: Alert trend analysis (daily)
SELECT 
    DATE(triggered_at) as alert_date,
    bl.limit_name,
    COUNT(*) as alert_count,
    COUNT(DISTINCT ba.subscriber_id) as affected_subscribers
FROM business_alerts ba
JOIN business_limits bl ON ba.limit_id = bl.limit_id
WHERE DATE(triggered_at) >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(triggered_at), bl.limit_name
ORDER BY alert_date DESC, alert_count DESC;
