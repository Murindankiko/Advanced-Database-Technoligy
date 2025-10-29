-- ============================================================================
-- Task A1: Create CDR_ALL View (UNION ALL)
-- Execute this script while connected to telco_node_a database
-- ============================================================================

-- Create unified view combining local and remote CDR data
CREATE OR REPLACE VIEW CDR_ALL AS
SELECT 
    CdrID,
    SimID,
    CallType,
    CallDate,
    Duration,
    Charge,
    DestinationNumber,
    'Node_A' AS SourceNode
FROM CDR_A
UNION ALL
SELECT 
    CdrID,
    SimID,
    CallType,
    CallDate,
    Duration,
    Charge,
    DestinationNumber,
    'Node_B' AS SourceNode
FROM CDR_B;

COMMENT ON VIEW CDR_ALL IS 'Unified view of all CDR records across both nodes';

-- Verification: Total count and checksum
SELECT 
    'CDR_ALL (Combined)' AS View_Name,
    COUNT(*) AS TotalRows,
    SUM(MOD(CdrID, 97)) AS CombinedChecksum,
    COUNT(DISTINCT SourceNode) AS NodeCount
FROM CDR_ALL;

-- Verification: Distribution by node
SELECT 
    SourceNode,
    COUNT(*) AS RowCount,
    SUM(Charge) AS TotalCharge,
    AVG(Charge) AS AvgCharge
FROM CDR_ALL
GROUP BY SourceNode
ORDER BY SourceNode;

-- Verification: Fragmentation correctness
SELECT 
    SourceNode,
    SimID,
    MOD(SimID, 2) AS SimID_Mod,
    CASE 
        WHEN SourceNode = 'Node_A' AND MOD(SimID, 2) = 0 THEN 'Correct'
        WHEN SourceNode = 'Node_B' AND MOD(SimID, 2) = 1 THEN 'Correct'
        ELSE 'ERROR: Wrong Node!'
    END AS FragmentationCheck
FROM CDR_ALL
ORDER BY SimID;
