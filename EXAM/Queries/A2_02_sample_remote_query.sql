-- ============================================================================
-- Task A2: Sample Remote Query via Database Link
-- Query SIM table from Node B (5 sample rows)
-- Execute this script while connected to telco_node_a database
-- ============================================================================

-- Query 1: Sample 5 rows from remote SIM table
SELECT 
    'Remote SIM@node_b_server' AS Source,
    SimID,
    SubscriberID,
    PhoneNumber,
    ActivationDate,
    Status
FROM SIM
LIMIT 5;

-- Query 2: Sample rows from remote Subscriber table
SELECT 
    'Remote Subscriber@node_b_server' AS Source,
    SubscriberID,
    FullName,
    NationalID,
    District,
    RegistrationDate
FROM Subscriber
LIMIT 5;

-- Query 3: Verify remote CDR_B access
SELECT 
    'Remote CDR_B@node_b_server' AS Source,
    COUNT(*) AS TotalRecords,
    SUM(Charge) AS TotalCharges_RWF,
    MIN(CallDate) AS EarliestCall,
    MAX(CallDate) AS LatestCall
FROM CDR_B;
