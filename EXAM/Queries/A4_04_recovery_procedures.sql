-- ============================================================================
-- Task A4: Recovery Procedures for In-Doubt Transactions
-- Manual recovery of prepared transactions
-- Execute on telco_node_a database
-- ============================================================================

-- View all prepared transactions (simulated)
-- In real PostgreSQL 2PC, you would use: SELECT * FROM pg_prepared_xacts;
SELECT 
    'Prepared Transactions Requiring Recovery' AS Report,
    LogID,
    TransactionType,
    NodeName,
    RecordID,
    Status,
    LogTimestamp,
    ErrorMessage
FROM Transaction_Log
WHERE Status IN ('PREPARED', 'IN-DOUBT')
ORDER BY LogTimestamp;

-- Recovery Option 1: COMMIT PREPARED (if remote node confirms success)
DO $$
DECLARE
    v_log_record RECORD;
BEGIN
    RAISE NOTICE '=== Recovery Procedure: COMMIT PREPARED ===';
    
    -- Find in-doubt transactions
    FOR v_log_record IN 
        SELECT * FROM Transaction_Log 
        WHERE Status = 'IN-DOUBT' 
        ORDER BY LogID
    LOOP
        RAISE NOTICE 'Recovering transaction: % on %', 
            v_log_record.TransactionType, v_log_record.NodeName;
        
        -- Simulate checking with remote coordinator
        RAISE NOTICE 'Checking with transaction coordinator...';
        RAISE NOTICE 'Coordinator confirms: Remote node COMMITTED successfully';
        
        -- Update status to COMMITTED
        UPDATE Transaction_Log
        SET Status = 'COMMITTED_RECOVERED',
            LogTimestamp = CURRENT_TIMESTAMP,
            ErrorMessage = 'Recovered via manual COMMIT PREPARED'
        WHERE LogID = v_log_record.LogID;
        
        RAISE NOTICE 'Transaction % marked as COMMITTED_RECOVERED', v_log_record.LogID;
    END LOOP;
    
    RAISE NOTICE '=== Recovery Complete ===';
END $$;

-- Recovery Option 2: ROLLBACK PREPARED (if remote node failed)
-- Uncomment to demonstrate rollback recovery
/*
DO $$
DECLARE
    v_log_record RECORD;
BEGIN
    RAISE NOTICE '=== Recovery Procedure: ROLLBACK PREPARED ===';
    
    FOR v_log_record IN 
        SELECT * FROM Transaction_Log 
        WHERE Status = 'IN-DOUBT' 
        ORDER BY LogID
    LOOP
        RAISE NOTICE 'Rolling back transaction: % on %', 
            v_log_record.TransactionType, v_log_record.NodeName;
        
        -- Update status to ABORTED
        UPDATE Transaction_Log
        SET Status = 'ABORTED_RECOVERED',
            LogTimestamp = CURRENT_TIMESTAMP,
            ErrorMessage = 'Recovered via manual ROLLBACK PREPARED'
        WHERE LogID = v_log_record.LogID;
        
        -- Clean up the TopUp record if it exists
        IF v_log_record.RecordID IS NOT NULL THEN
            DELETE FROM TopUp WHERE TopUpID = v_log_record.RecordID;
            RAISE NOTICE 'Rolled back TopUp record ID %', v_log_record.RecordID;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=== Rollback Recovery Complete ===';
END $$;
*/

-- Final verification: Check transaction consistency
SELECT 
    Status,
    COUNT(*) AS TransactionCount,
    STRING_AGG(DISTINCT TransactionType, ', ') AS TransactionTypes
FROM Transaction_Log
GROUP BY Status
ORDER BY Status;

-- Verify TopUp table consistency
SELECT 
    'TopUp Table Verification' AS Report,
    COUNT(*) AS TotalTopUps,
    SUM(Amount_RWF) AS TotalAmount_RWF,
    COUNT(DISTINCT SimID) AS UniqueSimIDs
FROM TopUp;
