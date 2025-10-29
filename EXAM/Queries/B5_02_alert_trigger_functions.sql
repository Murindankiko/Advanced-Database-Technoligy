-- B10: Alert Trigger Functions
-- Implements Event-Condition-Action pattern for automatic alert generation

-- Function to check daily data usage and generate alerts
CREATE OR REPLACE FUNCTION check_daily_data_usage()
RETURNS TRIGGER AS $$
DECLARE
    v_daily_usage DECIMAL(15,2);
    v_threshold DECIMAL(15,2);
    v_limit_id INTEGER;
BEGIN
    -- Get the threshold for daily data usage
    SELECT limit_id, threshold_value INTO v_limit_id, v_threshold
    FROM business_limits
    WHERE limit_name = 'Daily Data Usage Limit' AND is_active = true;
    
    IF v_limit_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Calculate today's data usage for this SIM
    SELECT COALESCE(SUM(DataVolumeMB), 0) INTO v_daily_usage
    FROM cdr_fact
    WHERE SimID = NEW.SimID
        AND DATE(CallStart) = CURRENT_DATE;
    
    -- Check if threshold exceeded
    IF v_daily_usage > v_threshold THEN
        -- Insert alert if not already exists for today
        INSERT INTO business_alerts (
            limit_id, subscriber_id, sim_id, alert_message,
            current_value, threshold_value, severity
        )
        SELECT 
            v_limit_id,
            s.SubscriberID,
            NEW.SimID,
            'Daily data usage exceeded: ' || ROUND(v_daily_usage, 2) || ' MB used (limit: ' || v_threshold || ' MB)',
            v_daily_usage,
            v_threshold,
            'warning'
        FROM sim_dim s
        WHERE s.SimID = NEW.SimID
            AND NOT EXISTS (
                SELECT 1 FROM business_alerts
                WHERE limit_id = v_limit_id
                    AND sim_id = NEW.SimID
                    AND DATE(triggered_at) = CURRENT_DATE
            );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to check call duration and generate alerts
CREATE OR REPLACE FUNCTION check_call_duration()
RETURNS TRIGGER AS $$
DECLARE
    v_threshold DECIMAL(15,2);
    v_limit_id INTEGER;
BEGIN
    -- Get the threshold for call duration
    SELECT limit_id, threshold_value INTO v_limit_id, v_threshold
    FROM business_limits
    WHERE limit_name = 'Single Call Duration Limit' AND is_active = true;
    
    IF v_limit_id IS NULL OR NEW.DurationMin IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Check if call duration exceeds threshold
    IF NEW.DurationMin > v_threshold THEN
        INSERT INTO business_alerts (
            limit_id, subscriber_id, sim_id, alert_message,
            current_value, threshold_value, severity
        )
        SELECT 
            v_limit_id,
            s.SubscriberID,
            NEW.SimID,
            'Unusually long call detected: ' || ROUND(NEW.DurationMin, 2) || ' minutes (limit: ' || v_threshold || ' minutes)',
            NEW.DurationMin,
            v_threshold,
            'warning'
        FROM sim_dim s
        WHERE s.SimID = NEW.SimID;
        
        -- Create automated action to log this event
        INSERT INTO alert_actions (alert_id, action_type, action_status)
        VALUES (currval('business_alerts_alert_id_seq'), 'log_event', 'executed');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to check monthly spending and generate critical alerts
CREATE OR REPLACE FUNCTION check_monthly_spending()
RETURNS TRIGGER AS $$
DECLARE
    v_monthly_spend DECIMAL(15,2);
    v_threshold DECIMAL(15,2);
    v_limit_id INTEGER;
    v_subscriber_id INTEGER;
BEGIN
    -- Get subscriber ID
    SELECT SubscriberID INTO v_subscriber_id
    FROM sim_dim
    WHERE SimID = NEW.SimID;
    
    IF v_subscriber_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Get the threshold for monthly spending
    SELECT limit_id, threshold_value INTO v_limit_id, v_threshold
    FROM business_limits
    WHERE limit_name = 'Monthly Spend Limit' AND is_active = true;
    
    IF v_limit_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Calculate this month's total spending for this subscriber
    SELECT COALESCE(SUM(c.ChargeRWF), 0) INTO v_monthly_spend
    FROM cdr_fact c
    JOIN sim_dim s ON c.SimID = s.SimID
    WHERE s.SubscriberID = v_subscriber_id
        AND DATE_TRUNC('month', c.CallStart) = DATE_TRUNC('month', CURRENT_DATE);
    
    -- Check if threshold exceeded
    IF v_monthly_spend > v_threshold THEN
        -- Insert critical alert
        INSERT INTO business_alerts (
            limit_id, subscriber_id, sim_id, alert_message,
            current_value, threshold_value, severity
        )
        VALUES (
            v_limit_id,
            v_subscriber_id,
            NEW.SimID,
            'CRITICAL: Monthly spending limit exceeded: ' || ROUND(v_monthly_spend, 2) || ' RWF (limit: ' || v_threshold || ' RWF)',
            v_monthly_spend,
            v_threshold,
            'critical'
        )
        ON CONFLICT DO NOTHING;
        
        -- Create automated action to notify admin
        INSERT INTO alert_actions (alert_id, action_type, action_status)
        VALUES (currval('business_alerts_alert_id_seq'), 'email_admin', 'pending');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to check negative balance
CREATE OR REPLACE FUNCTION check_negative_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_limit_id INTEGER;
BEGIN
    -- Only check if balance went negative
    IF NEW.BalanceRWF >= 0 THEN
        RETURN NEW;
    END IF;
    
    -- Get the limit configuration
    SELECT limit_id INTO v_limit_id
    FROM business_limits
    WHERE limit_name = 'Negative Balance Alert' AND is_active = true;
    
    IF v_limit_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Insert critical alert for negative balance
    INSERT INTO business_alerts (
        limit_id, subscriber_id, sim_id, alert_message,
        current_value, threshold_value, severity
    )
    VALUES (
        v_limit_id,
        NEW.SubscriberID,
        NULL,
        'CRITICAL: Subscriber balance is negative: ' || ROUND(NEW.BalanceRWF, 2) || ' RWF',
        NEW.BalanceRWF,
        0,
        'critical'
    );
    
    -- Create automated action to suspend service
    INSERT INTO alert_actions (alert_id, action_type, action_status)
    VALUES (currval('business_alerts_alert_id_seq'), 'suspend_service', 'pending');
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

SELECT 'Alert trigger functions created successfully' as status;
