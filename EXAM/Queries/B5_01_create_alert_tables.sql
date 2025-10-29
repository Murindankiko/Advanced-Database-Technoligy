-- B10: Business Limit Alert System
-- Creates tables and infrastructure for monitoring business limits and generating alerts

-- Create business limits configuration table
CREATE TABLE IF NOT EXISTS business_limits (
    limit_id SERIAL PRIMARY KEY,
    limit_name VARCHAR(100) NOT NULL UNIQUE,
    limit_type VARCHAR(50) NOT NULL, -- 'daily_usage', 'monthly_spend', 'call_duration', etc.
    threshold_value DECIMAL(15,2) NOT NULL,
    threshold_unit VARCHAR(20), -- 'RWF', 'minutes', 'MB', etc.
    check_frequency VARCHAR(20) DEFAULT 'realtime', -- 'realtime', 'hourly', 'daily'
    alert_severity VARCHAR(20) DEFAULT 'warning', -- 'info', 'warning', 'critical'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create alerts log table
CREATE TABLE IF NOT EXISTS business_alerts (
    alert_id SERIAL PRIMARY KEY,
    limit_id INTEGER REFERENCES business_limits(limit_id),
    subscriber_id INTEGER, -- Can be NULL for system-wide alerts
    sim_id INTEGER,
    alert_message TEXT NOT NULL,
    current_value DECIMAL(15,2),
    threshold_value DECIMAL(15,2),
    severity VARCHAR(20),
    alert_status VARCHAR(20) DEFAULT 'new', -- 'new', 'acknowledged', 'resolved'
    triggered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMP,
    acknowledged_by VARCHAR(100),
    resolution_notes TEXT
);

-- Create alert actions table (for automated responses)
CREATE TABLE IF NOT EXISTS alert_actions (
    action_id SERIAL PRIMARY KEY,
    alert_id INTEGER REFERENCES business_alerts(alert_id),
    action_type VARCHAR(50), -- 'suspend_service', 'send_sms', 'email_admin', 'reduce_speed'
    action_status VARCHAR(20) DEFAULT 'pending', -- 'pending', 'executed', 'failed'
    executed_at TIMESTAMP,
    execution_result TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample business limits
INSERT INTO business_limits (limit_name, limit_type, threshold_value, threshold_unit, alert_severity) VALUES
    ('Daily Data Usage Limit', 'daily_usage', 5000, 'MB', 'warning'),
    ('Monthly Spend Limit', 'monthly_spend', 50000, 'RWF', 'critical'),
    ('Single Call Duration Limit', 'call_duration', 120, 'minutes', 'warning'),
    ('Daily Call Count Limit', 'daily_calls', 100, 'calls', 'info'),
    ('Negative Balance Alert', 'balance_check', 0, 'RWF', 'critical'),
    ('High International Usage', 'international_usage', 10000, 'RWF', 'warning')
ON CONFLICT (limit_name) DO NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_alerts_subscriber ON business_alerts(subscriber_id);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON business_alerts(alert_status);
CREATE INDEX IF NOT EXISTS idx_alerts_triggered ON business_alerts(triggered_at);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON business_alerts(severity);

SELECT 'Alert system tables created with ' || COUNT(*) || ' business limits configured' as status
FROM business_limits;
