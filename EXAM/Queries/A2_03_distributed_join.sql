-- ============================================================================
-- Task A2: Distributed Join (Local CDR_A + Remote Subscriber)
-- Join local CDR_A with remote Subscriber@node_b_server on SimID
-- Execute this script while connected to telco_node_a database
-- ============================================================================

-- Distributed Join Query: CDR_A (local) with SIM and Subscriber (remote)
SELECT 
    cdr.CdrID,
    cdr.SimID,
    sim.PhoneNumber,
    sub.FullName AS SubscriberName,
    sub.District,
    cdr.CallType,
    cdr.CallDate,
    cdr.Duration,
    cdr.Charge AS Charge_RWF,
    'Node_A (Local) + Node_B (Remote)' AS JoinType
FROM CDR_A cdr
INNER JOIN SIM sim ON cdr.SimID = sim.SimID
INNER JOIN Subscriber sub ON sim.SubscriberID = sub.SubscriberID
ORDER BY cdr.CallDate
LIMIT 10;

-- Alternative: Show join execution plan
EXPLAIN (ANALYZE, BUFFERS, VERBOSE)
SELECT 
    cdr.CdrID,
    cdr.CallType,
    cdr.Charge,
    sub.FullName,
    sub.District
FROM CDR_A cdr
INNER JOIN SIM sim ON cdr.SimID = sim.SimID
INNER JOIN Subscriber sub ON sim.SubscriberID = sub.SubscriberID
LIMIT 5;

-- Summary statistics of distributed join
SELECT 
    sub.District,
    COUNT(cdr.CdrID) AS CallCount,
    SUM(cdr.Charge) AS TotalCharges_RWF,
    AVG(cdr.Charge) AS AvgCharge_RWF,
    STRING_AGG(DISTINCT cdr.CallType, ', ') AS CallTypes
FROM CDR_A cdr
INNER JOIN SIM sim ON cdr.SimID = sim.SimID
INNER JOIN Subscriber sub ON sim.SubscriberID = sub.SubscriberID
GROUP BY sub.District
ORDER BY TotalCharges_RWF DESC;
