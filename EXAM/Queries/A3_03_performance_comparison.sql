-- ============================================================================
-- Task A3: Performance Comparison Summary
-- Create table to store performance metrics
-- Execute this script while connected to telco_node_a database
-- ============================================================================

-- Create performance comparison table
CREATE TABLE IF NOT EXISTS Performance_Comparison (
    TestID SERIAL PRIMARY KEY,
    ExecutionMode VARCHAR(20) NOT NULL,
    QueryType VARCHAR(50) NOT NULL,
    ExecutionTime_ms NUMERIC(10,2),
    PlanningTime_ms NUMERIC(10,2),
    TotalTime_ms NUMERIC(10,2),
    BuffersHit INT,
    BuffersRead INT,
    WorkersLaunched INT,
    TestTimestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE Performance_Comparison IS 'Performance metrics for serial vs parallel query execution';

-- Manual entry template (populate after running EXPLAIN ANALYZE)
-- Extract timing from EXPLAIN output and insert here

INSERT INTO Performance_Comparison 
    (ExecutionMode, QueryType, ExecutionTime_ms, PlanningTime_ms, TotalTime_ms, WorkersLaunched)
VALUES 
    ('Serial', 'Aggregation on CDR_ALL', 0.50, 0.20, 0.70, 0),
    ('Parallel', 'Aggregation on CDR_ALL', 0.35, 0.25, 0.60, 2);

-- View comparison summary
SELECT 
    ExecutionMode,
    QueryType,
    ExecutionTime_ms,
    PlanningTime_ms,
    TotalTime_ms,
    WorkersLaunched,
    CASE 
        WHEN ExecutionMode = 'Serial' THEN 'Baseline'
        ELSE CONCAT(
            ROUND(((LAG(TotalTime_ms) OVER (ORDER BY TestID) - TotalTime_ms) / 
                   LAG(TotalTime_ms) OVER (ORDER BY TestID) * 100)::numeric, 1),
            '% faster'
        )
    END AS PerformanceGain
FROM Performance_Comparison
ORDER BY TestID;

-- Summary statistics
SELECT 
    'Performance Summary' AS Report,
    COUNT(*) AS TotalTests,
    AVG(CASE WHEN ExecutionMode = 'Serial' THEN TotalTime_ms END) AS AvgSerial_ms,
    AVG(CASE WHEN ExecutionMode = 'Parallel' THEN TotalTime_ms END) AS AvgParallel_ms,
    ROUND(
        (AVG(CASE WHEN ExecutionMode = 'Serial' THEN TotalTime_ms END) - 
         AVG(CASE WHEN ExecutionMode = 'Parallel' THEN TotalTime_ms END)) /
        AVG(CASE WHEN ExecutionMode = 'Serial' THEN TotalTime_ms END) * 100
    , 1) AS PerformanceImprovement_Pct
FROM Performance_Comparison;
