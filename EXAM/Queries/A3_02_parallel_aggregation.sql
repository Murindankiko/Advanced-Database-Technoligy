-- ============================================================================
-- Task A3: Parallel Aggregation with Hints
-- Step 2: Force Parallel Execution
-- Execute this script while connected to telco_node_a database
-- ============================================================================

-- Enable parallel query execution
SET max_parallel_workers_per_gather = 4;
SET parallel_setup_cost = 0;
SET parallel_tuple_cost = 0;
SET min_parallel_table_scan_size = 0;
SET min_parallel_index_scan_size = 0;

-- Parallel aggregation query with execution plan
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
    'Parallel Execution' AS ExecutionMode,
    CallType,
    COUNT(*) AS CallCount,
    SUM(Charge) AS TotalCharge_RWF,
    AVG(Charge) AS AvgCharge_RWF,
    ROUND(AVG(Duration)::numeric, 2) AS AvgDuration
FROM CDR_ALL
GROUP BY CallType
ORDER BY TotalCharge_RWF DESC;

-- Reset to defaults
RESET max_parallel_workers_per_gather;
RESET parallel_setup_cost;
RESET parallel_tuple_cost;
RESET min_parallel_table_scan_size;
RESET min_parallel_index_scan_size;
