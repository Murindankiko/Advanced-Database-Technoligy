-- ============================================================================
-- Task A3: Parallel vs Serial Aggregation
-- Step 1: Serial Aggregation Baseline
-- Execute this script while connected to telco_node_a database
-- ============================================================================

-- Disable parallel query execution for baseline
SET max_parallel_workers_per_gather = 0;

-- Serial aggregation query with execution plan
EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
SELECT 
    CallType,
    COUNT(*) AS CallCount,
    SUM(Charge) AS TotalCharge_RWF,
    AVG(Charge) AS AvgCharge_RWF,
    MIN(Charge) AS MinCharge_RWF,
    MAX(Charge) AS MaxCharge_RWF,
    SUM(Duration) AS TotalDuration
FROM CDR_ALL
GROUP BY CallType
ORDER BY TotalCharge_RWF DESC;

-- Capture actual results
SELECT 
    'Serial Execution' AS ExecutionMode,
    CallType,
    COUNT(*) AS CallCount,
    SUM(Charge) AS TotalCharge_RWF,
    AVG(Charge) AS AvgCharge_RWF,
    ROUND(AVG(Duration)::numeric, 2) AS AvgDuration
FROM CDR_ALL
GROUP BY CallType
ORDER BY TotalCharge_RWF DESC;

-- Reset to default
RESET max_parallel_workers_per_gather;
