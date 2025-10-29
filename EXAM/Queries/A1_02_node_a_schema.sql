-- ============================================================================
-- Task A1: Node A Schema & Data
-- Execute this script while connected to telco_node_a database
-- ============================================================================

-- Create CDR_A table (holds records where MOD(SimID, 2) = 0)
CREATE TABLE CDR_A (
    CdrID SERIAL PRIMARY KEY,
    SimID INT NOT NULL,
    CallType VARCHAR(20) NOT NULL CHECK (CallType IN ('Voice', 'SMS', 'Data')),
    CallDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Duration INT, -- in seconds for Voice, count for SMS, MB for Data
    Charge NUMERIC(10,2) NOT NULL,
    DestinationNumber VARCHAR(15),
    CONSTRAINT chk_simid_even CHECK (MOD(SimID, 2) = 0)
);

COMMENT ON TABLE CDR_A IS 'Call Detail Records - Node A (Even SimID via horizontal fragmentation)';

-- Insert sample data (5 rows with even SimID)
INSERT INTO CDR_A (SimID, CallType, CallDate, Duration, Charge, DestinationNumber) VALUES
(1002, 'Voice', '2025-01-15 09:30:00', 180, 450.00, '+250788123456'),
(1004, 'SMS', '2025-01-15 10:15:00', 1, 50.00, '+250788234567'),
(1006, 'Data', '2025-01-15 11:00:00', 512, 1200.00, NULL),
(1008, 'Voice', '2025-01-15 14:20:00', 300, 750.00, '+250788345678'),
(1010, 'SMS', '2025-01-15 16:45:00', 1, 50.00, '+250788456789');

-- Verification query
SELECT 
    'Node A' AS Node,
    COUNT(*) AS RowCount,
    SUM(MOD(CdrID, 97)) AS Checksum,
    MIN(SimID) AS MinSimID,
    MAX(SimID) AS MaxSimID
FROM CDR_A;
