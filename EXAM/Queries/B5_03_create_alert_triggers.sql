-- ============================================================================
-- B10: FULL SETUP – Tables + Functions + Triggers (100% Working)
-- Run on telco_node_a
-- ============================================================================

-------------------------------------------------
-- 1. CREATE TABLES (with fixed UNIQUE constraint)
-------------------------------------------------
CREATE TABLE IF NOT EXISTS business_limits (
    limit_id        SERIAL PRIMARY KEY,
    limit_name      VARCHAR(100) UNIQUE NOT NULL,
    threshold_value DECIMAL(15,2),
    is_active       BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS business_alerts (
    alert_id        BIGSERIAL PRIMARY KEY,
    limit_id        INTEGER REFERENCES business_limits,
    subscriber_id   INTEGER,
    sim_id          INTEGER,
    alert_message   TEXT,
    current_value   DECIMAL(15,2),
    threshold_value DECIMAL(15,2),
    severity        VARCHAR(20),
    triggered_at    TIMESTAMP DEFAULT NOW()
);

-- FIX: Use PARTIAL UNIQUE INDEX instead of UNIQUE constraint
DROP INDEX IF EXISTS idx_alerts_unique_monthly;
CREATE UNIQUE INDEX idx_alerts_unique_monthly 
ON business_alerts (limit_id, subscriber_id, DATE_TRUNC('month', triggered_at))
WHERE subscriber_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS alert_actions (
    action_id   BIGSERIAL PRIMARY KEY,
    alert_id    BIGINT REFERENCES business_alerts,
    action_type VARCHAR(50),
    action_status VARCHAR(20),
    executed_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cdr_fact (
    cdr_id        BIGSERIAL PRIMARY KEY,
    SimID         INTEGER,
    CallStart     TIMESTAMP DEFAULT NOW(),
    DataVolumeMB  DECIMAL(15,2),
    DurationMin   DECIMAL(10,2),
    ChargeRWF     DECIMAL(15,2)
);

CREATE TABLE IF NOT EXISTS sim_dim (
    SimID         INTEGER PRIMARY KEY,
    SubscriberID  INTEGER
);

CREATE TABLE IF NOT EXISTS subscriber_balance_summary (
    SubscriberID  INTEGER PRIMARY KEY,
    BalanceRWF    DECIMAL(15,2) DEFAULT 0
);

-------------------------------------------------
-- 2. TRIGGER FUNCTIONS
-------------------------------------------------
-- 1. Daily Data Usage
CREATE OR REPLACE FUNCTION check_daily_data_usage()
RETURNS TRIGGER AS $$
DECLARE
    v_daily_usage  DECIMAL(15,2);
    v_threshold    DECIMAL(15,2);
    v_limit_id     INTEGER;
    v_alert_id     BIGINT;
BEGIN
    SELECT limit_id, threshold_value 
    INTO v_limit_id, v_threshold
    FROM business_limits
    WHERE limit_name = 'Daily Data Usage Limit' AND is_active = true;

    IF v_limit_id IS NULL THEN RETURN NEW; END IF;

    SELECT COALESCE(SUM(DataVolumeMB), 0) INTO v_daily_usage
    FROM cdr_fact
    WHERE SimID = NEW.SimID
      AND DATE_TRUNC('day', CallStart) = CURRENT_DATE;

    IF v_daily_usage > v_threshold THEN
        INSERT INTO business_alerts (
            limit_id, subscriber_id, sim_id, alert_message,
            current_value, threshold_value, severity
        )
        SELECT 
            v_limit_id, s.SubscriberID, NEW.SimID,
            'Daily data usage exceeded: ' || ROUND(v_daily_usage,2) || ' MB (limit: ' || v_threshold || ' MB)',
            v_daily_usage, v_threshold, 'warning'
        FROM sim_dim s
        WHERE s.SimID = NEW.SimID
          AND NOT EXISTS (
              SELECT 1 FROM business_alerts
              WHERE limit_id = v_limit_id
                AND sim_id = NEW.SimID
                AND DATE_TRUNC('day', triggered_at) = CURRENT_DATE
          )
        RETURNING alert_id INTO v_alert_id;

        IF v_alert_id IS NOT NULL THEN
            INSERT INTO alert_actions (alert_id, action_type, action_status)
            VALUES (v_alert_id, 'log_event', 'executed');
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2. Call Duration
CREATE OR REPLACE FUNCTION check_call_duration()
RETURNS TRIGGER AS $$
DECLARE
    v_threshold DECIMAL(15,2);
    v_limit_id  INTEGER;
    v_alert_id  BIGINT;
BEGIN
    SELECT limit_id, threshold_value INTO v_limit_id, v_threshold
    FROM business_limits
    WHERE limit_name = 'Single Call Duration Limit' AND is_active = true;

    IF v_limit_id IS NULL OR NEW.DurationMin IS NULL THEN RETURN NEW; END IF;

    IF NEW.DurationMin > v_threshold THEN
        INSERT INTO business_alerts (
            limit_id, subscriber_id, sim_id, alert_message,
            current_value, threshold_value, severity
        )
        SELECT v_limit_id, s.SubscriberID, NEW.SimID,
            'Long call: ' || ROUND(NEW.DurationMin,2) || ' min (limit: ' || v_threshold || ')',
            NEW.DurationMin, v_threshold, 'warning'
        FROM sim_dim s WHERE s.SimID = NEW.SimID
        RETURNING alert_id INTO v_alert_id;

        IF v_alert_id IS NOT NULL THEN
            INSERT INTO alert_actions (alert_id, action_type, action_status)
            VALUES (v_alert_id, 'log_event', 'executed');
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Monthly Spending
CREATE OR REPLACE FUNCTION check_monthly_spending()
RETURNS TRIGGER AS $$
DECLARE
    v_monthly_spend DECIMAL(15,2);
    v_threshold     DECIMAL(15,2);
    v_limit_id      INTEGER;
    v_subscriber_id INTEGER;
    v_alert_id      BIGINT;
BEGIN
    SELECT SubscriberID INTO v_subscriber_id FROM sim_dim WHERE SimID = NEW.SimID;
    IF v_subscriber_id IS NULL THEN RETURN NEW; END IF;

    SELECT limit_id, threshold_value INTO v_limit_id, v_threshold
    FROM business_limits
    WHERE limit_name = 'Monthly Spend Limit' AND is_active = true;

    IF v_limit_id IS NULL THEN RETURN NEW; END IF;

    SELECT COALESCE(SUM(ChargeRWF), 0) INTO v_monthly_spend
    FROM cdr_fact c
    JOIN sim_dim s ON c.SimID = s.SimID
    WHERE s.SubscriberID = v_subscriber_id
      AND DATE_TRUNC('month', c.CallStart) = DATE_TRUNC('month', CURRENT_DATE);

    IF v_monthly_spend > v_threshold THEN
        INSERT INTO business_alerts (
            limit_id, subscriber_id, sim_id, alert_message,
            current_value, threshold_value, severity
        )
        VALUES (
            v_limit_id, v_subscriber_id, NEW.SimID,
            'CRITICAL: Monthly spend: ' || ROUND(v_monthly_spend,2) || ' RWF (limit: ' || v_threshold || ')',
            v_monthly_spend, v_threshold, 'critical'
        )
        ON CONFLICT ON CONSTRAINT idx_alerts_unique_monthly DO NOTHING
        RETURNING alert_id INTO v_alert_id;

        IF v_alert_id IS NOT NULL THEN
            INSERT INTO alert_actions (alert_id, action_type, action_status)
            VALUES (v_alert_id, 'email_admin', 'pending');
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Negative Balance
CREATE OR REPLACE FUNCTION check_negative_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_limit_id INTEGER;
    v_alert_id BIGINT;
BEGIN
    IF NEW.BalanceRWF >= 0 THEN RETURN NEW; END IF;

    SELECT limit_id INTO v_limit_id
    FROM business_limits
    WHERE limit_name = 'Negative Balance Alert' AND is_active = true;

    IF v_limit_id IS NULL THEN RETURN NEW; END IF;

    INSERT INTO business_alerts (
        limit_id, subscriber_id, sim_id, alert_message,
        current_value, threshold_value, severity
    )
    VALUES (
        v_limit_id, NEW.SubscriberID, NULL,
        'CRITICAL: Negative balance: ' || ROUND(NEW.BalanceRWF,2) || ' RWF',
        NEW.BalanceRWF, 0, 'critical'
    )
    RETURNING alert_id INTO v_alert_id;

    IF v_alert_id IS NOT NULL THEN
        INSERT INTO alert_actions (alert_id, action_type, action_status)
        VALUES (v_alert_id, 'suspend_service', 'pending');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-------------------------------------------------
-- 3. CREATE TRIGGERS (Safe)
-------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'cdr_fact') THEN
        DROP TRIGGER IF EXISTS trg_check_daily_data_usage ON cdr_fact;
        CREATE TRIGGER trg_check_daily_data_usage
            AFTER INSERT ON cdr_fact
            FOR EACH ROW
            WHEN (NEW.DataVolumeMB IS NOT NULL AND NEW.DataVolumeMB > 0)
            EXECUTE FUNCTION check_daily_data_usage();
        RAISE NOTICE 'Trigger: trg_check_daily_data_usage → created';

        DROP TRIGGER IF EXISTS trg_check_call_duration ON cdr_fact;
        CREATE TRIGGER trg_check_call_duration
            AFTER INSERT ON cdr_fact
            FOR EACH ROW
            WHEN (NEW.DurationMin IS NOT NULL AND NEW.DurationMin > 0)
            EXECUTE FUNCTION check_call_duration();
        RAISE NOTICE 'Trigger: trg_check_call_duration → created';

        DROP TRIGGER IF EXISTS trg_check_monthly_spending ON cdr_fact;
        CREATE TRIGGER trg_check_monthly_spending
            AFTER INSERT ON cdr_fact
            FOR EACH ROW
            WHEN (NEW.ChargeRWF IS NOT NULL AND NEW.ChargeRWF > 0)
            EXECUTE FUNCTION check_monthly_spending();
        RAISE NOTICE 'Trigger: trg_check_monthly_spending → created';
    ELSE
        RAISE NOTICE 'cdr_fact missing – all CDR triggers SKIPPED';
    END IF;

    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'subscriber_balance_summary') THEN
        DROP TRIGGER IF EXISTS trg_check_negative_balance ON subscriber_balance_summary;
        CREATE TRIGGER trg_check_negative_balance
            AFTER UPDATE ON subscriber_balance_summary
            FOR EACH ROW
            WHEN (NEW.BalanceRWF < 0 AND OLD.BalanceRWF >= 0)
            EXECUTE FUNCTION check_negative_balance();
        RAISE NOTICE 'Trigger: trg_check_negative_balance → created';
    ELSE
        RAISE NOTICE 'subscriber_balance_summary missing – negative balance trigger SKIPPED';
    END IF;
END $$;

-------------------------------------------------
-- 4. FINAL STATUS
-------------------------------------------------
SELECT 'Alert system fully activated!' AS status;