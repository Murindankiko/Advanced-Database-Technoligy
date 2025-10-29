-- ============================================================================
-- Task A4: Two-Phase Commit & Recovery
-- Step 1: Setup tables for 2PC demonstration
-- Execute on telco_node_a database
-- ============================================================================

-- Create TopUp table on Node A (local)
CREATE TABLE IF NOT EXISTS TopUp (
    TopUpID SERIAL PRIMARY KEY,
    SimID INT NOT NULL,
    TopUpDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Amount_RWF NUMERIC(10,2) NOT NULL CHECK (Amount_RWF > 0),
    PaymentMethod VARCHAR(20) DEFAULT 'Mobile Money',
    TransactionRef VARCHAR(50) UNIQUE
);

COMMENT ON TABLE TopUp IS 'Airtime top-up transactions';

-- Create audit log table
CREATE TABLE IF NOT EXISTS Transaction_Log (
    LogID SERIAL PRIMARY KEY,
    TransactionType VARCHAR(50),
    NodeName VARCHAR(20),
    RecordID INT,
    Status VARCHAR(20),
    LogTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ErrorMessage TEXT
);

COMMENT ON TABLE Transaction_Log IS 'Audit log for distributed transactions';
