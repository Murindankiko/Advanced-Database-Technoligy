-- ============================================================================
-- Task B7: E-C-A Trigger for Denormalized Totals
-- Step 1: Create balance and audit tables
-- Execute on telco_node_a database
-- ============================================================================

-- Create SUBSCR_BALANCE table (denormalized summary)
CREATE TABLE SUBSCR_BALANCE (
    SimID INT PRIMARY KEY,
    TotalTopUps_RWF NUMERIC(12,2) DEFAULT 0 NOT NULL,
    TotalCharges_RWF NUMERIC(12,2) DEFAULT 0 NOT NULL,
    CurrentBalance_RWF NUMERIC(12,2) GENERATED ALWAYS AS (TotalTopUps_RWF - TotalCharges_RWF) STORED,
    TopUpCount INT DEFAULT 0 NOT NULL,
    CallCount INT DEFAULT 0 NOT NULL,
    LastTopUpDate TIMESTAMP,
    LastCallDate TIMESTAMP,
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_totals_nonnegative CHECK (TotalTopUps_RWF >= 0 AND TotalCharges_RWF >= 0)
);

COMMENT ON TABLE SUBSCR_BALANCE IS 'Denormalized subscriber balance summary maintained by triggers';
COMMENT ON COLUMN SUBSCR_BALANCE.CurrentBalance_RWF IS 'Computed column: TotalTopUps - TotalCharges';

-- Create SUBSCR_BAL_AUDIT table (audit log)
CREATE TABLE SUBSCR_BAL_AUDIT (
    AuditID SERIAL PRIMARY KEY,
    SimID INT NOT NULL,
    OperationType VARCHAR(10) NOT NULL CHECK (OperationType IN ('INSERT', 'UPDATE', 'DELETE')),
    SourceTable VARCHAR(20) NOT NULL CHECK (SourceTable IN ('TopUp', 'CDR_A')),
    SourceRecordID INT,
    AmountChange_RWF NUMERIC(12,2),
    OldBalance_RWF NUMERIC(12,2),
    NewBalance_RWF NUMERIC(12,2),
    AuditTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UserName VARCHAR(50) DEFAULT CURRENT_USER,
    TransactionID BIGINT DEFAULT txid_current()
);

COMMENT ON TABLE SUBSCR_BAL_AUDIT IS 'Audit trail for all balance changes';

-- Create indexes for performance
CREATE INDEX idx_subscr_balance_lastupdated ON SUBSCR_BALANCE(LastUpdated);
CREATE INDEX idx_audit_simid ON SUBSCR_BAL_AUDIT(SimID);
CREATE INDEX idx_audit_timestamp ON SUBSCR_BAL_AUDIT(AuditTimestamp);
CREATE INDEX idx_audit_source ON SUBSCR_BAL_AUDIT(SourceTable, SourceRecordID);

-- Initialize balance records for existing SIMs
INSERT INTO SUBSCR_BALANCE (SimID)
SELECT DISTINCT SimID FROM (
    SELECT SimID FROM TopUp
    UNION
    SELECT SimID FROM CDR_A
) AS all_sims
ON CONFLICT (SimID) DO NOTHING;

-- Update with existing data
UPDATE SUBSCR_BALANCE sb
SET 
    TotalTopUps_RWF = COALESCE((SELECT SUM(Amount_RWF) FROM TopUp WHERE SimID = sb.SimID), 0),
    TopUpCount = COALESCE((SELECT COUNT(*) FROM TopUp WHERE SimID = sb.SimID), 0),
    LastTopUpDate = (SELECT MAX(TopUpDate) FROM TopUp WHERE SimID = sb.SimID);

UPDATE SUBSCR_BALANCE sb
SET 
    TotalCharges_RWF = COALESCE((SELECT SUM(Charge) FROM CDR_A WHERE SimID = sb.SimID), 0),
    CallCount = COALESCE((SELECT COUNT(*) FROM CDR_A WHERE SimID = sb.SimID), 0),
    LastCallDate = (SELECT MAX(CallDate) FROM CDR_A WHERE SimID = sb.SimID);

-- View initial balances
SELECT 
    'Initial Balances' AS Report,
    SimID,
    TotalTopUps_RWF,
    TotalCharges_RWF,
    CurrentBalance_RWF,
    TopUpCount,
    CallCount
FROM SUBSCR_BALANCE
ORDER BY SimID;
