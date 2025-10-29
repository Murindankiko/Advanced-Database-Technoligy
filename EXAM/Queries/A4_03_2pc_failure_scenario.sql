-- ============================================================================
-- Task A4: Two-Phase Commit - Failure & Recovery Scenario
-- Demonstrates in-doubt transaction and recovery
-- Execute on telco_node_a database
-- ============================================================================

DO $$
DECLARE
    v_topup_id INT;
    v_sim_id INT := 1003;
    v_amount NUMERIC(10,2) := 10000.00;
    v_transaction_ref VARCHAR(50) := 'TXN_FAIL_' || TO_CHAR(NOW(), 'YYYYMMDDHH24MISS');
BEGIN
    -- Start distributed transaction
    RAISE NOTICE '=== Starting Two-Phase Commit with Simulated Failure ===';
    RAISE NOTICE 'Transaction Ref: %', v_transaction_ref;
    
    -- Phase 1: PREPARE
    RAISE NOTICE 'Phase 1: PREPARE - Validating on both nodes...';
    
    -- Local operation: Insert TopUp on Node A
    INSERT INTO TopUp (SimID, Amount_RWF, PaymentMethod, TransactionRef)
    VALUES (v_sim_id, v_amount, 'Mobile Money', v_transaction_ref)
    RETURNING TopUpID INTO v_topup_id;
    
    RAISE NOTICE 'Local: TopUp record created with ID %', v_topup_id;
    
    -- Log local transaction as PREPARED
    INSERT INTO Transaction_Log (TransactionType, NodeName, RecordID, Status)
    VALUES ('TopUp', 'Node_A', v_topup_id, 'PREPARED');
    
    -- Simulate remote node preparation
    INSERT INTO Transaction_Log (TransactionType, NodeName, RecordID, Status)
    VALUES ('Subscriber_Update', 'Node_B', NULL, 'PREPARED');
    
    RAISE NOTICE 'Remote: Subscriber update prepared on Node_B';
    
    -- Phase 2: COMMIT - Simulate failure during commit phase
    RAISE NOTICE 'Phase 2: COMMIT - Attempting commit...';
    RAISE NOTICE 'SIMULATING NETWORK FAILURE DURING COMMIT PHASE';
    
    -- Simulate failure: raise exception before commit completes
    RAISE EXCEPTION 'Network timeout: Connection to Node_B lost during commit phase';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '=== FAILURE DETECTED ===';
        RAISE NOTICE 'Error: %', SQLERRM;
        RAISE NOTICE 'Transaction is now IN-DOUBT (prepared but not committed)';
        
        -- Log the in-doubt transaction
        INSERT INTO Transaction_Log (TransactionType, NodeName, RecordID, Status, ErrorMessage)
        VALUES ('TopUp', 'Node_A', v_topup_id, 'IN-DOUBT', SQLERRM);
        
        INSERT INTO Transaction_Log (TransactionType, NodeName, Status, ErrorMessage)
        VALUES ('Subscriber_Update', 'Node_B', 'IN-DOUBT', 'Commit phase interrupted');
        
        RAISE NOTICE 'Transaction logged as IN-DOUBT for manual recovery';
        
        -- In real 2PC, this would be handled by transaction manager
        -- For now, we'll rollback the local changes
        ROLLBACK;
END $$;

-- Query to find in-doubt transactions
SELECT 
    'In-Doubt Transactions' AS Report,
    TransactionType,
    NodeName,
    RecordID,
    Status,
    ErrorMessage,
    LogTimestamp
FROM Transaction_Log
WHERE Status = 'IN-DOUBT'
ORDER BY LogTimestamp DESC;
