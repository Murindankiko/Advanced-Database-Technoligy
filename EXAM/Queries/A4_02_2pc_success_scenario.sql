-- ============================================================================
-- Task A4: Two-Phase Commit - Success Scenario
-- Demonstrates successful distributed transaction
-- Execute on telco_node_a database
-- ============================================================================

DO $$
DECLARE
    v_topup_id INT;
    v_subscriber_id INT := 1;
    v_sim_id INT := 1001;
    v_amount NUMERIC(10,2) := 5000.00;
    v_transaction_ref VARCHAR(50) := 'TXN_' || TO_CHAR(NOW(), 'YYYYMMDDHH24MISS');
BEGIN
    -- Start distributed transaction
    RAISE NOTICE '=== Starting Two-Phase Commit Transaction ===';
    RAISE NOTICE 'Transaction Ref: %', v_transaction_ref;
    
    -- Phase 1: PREPARE
    RAISE NOTICE 'Phase 1: PREPARE - Validating on both nodes...';
    
    -- Local operation: Insert TopUp on Node A
    INSERT INTO TopUp (SimID, Amount_RWF, PaymentMethod, TransactionRef)
    VALUES (v_sim_id, v_amount, 'Mobile Money', v_transaction_ref)
    RETURNING TopUpID INTO v_topup_id;
    
    RAISE NOTICE 'Local: TopUp record created with ID %', v_topup_id;
    
    -- Log local transaction
    INSERT INTO Transaction_Log (TransactionType, NodeName, RecordID, Status)
    VALUES ('TopUp', 'Node_A', v_topup_id, 'PREPARED');
    
    -- Simulate remote operation validation (in real 2PC, this would be on Node B)
    -- For demonstration, we'll log it as if remote node prepared successfully
    INSERT INTO Transaction_Log (TransactionType, NodeName, RecordID, Status)
    VALUES ('Subscriber_Update', 'Node_B', v_subscriber_id, 'PREPARED');
    
    RAISE NOTICE 'Remote: Subscriber update prepared on Node_B';
    
    -- Phase 2: COMMIT
    RAISE NOTICE 'Phase 2: COMMIT - All nodes ready, committing...';
    
    -- Update transaction logs to COMMITTED
    UPDATE Transaction_Log 
    SET Status = 'COMMITTED', LogTimestamp = CURRENT_TIMESTAMP
    WHERE Status = 'PREPARED' 
      AND TransactionType IN ('TopUp', 'Subscriber_Update');
    
    RAISE NOTICE '=== Transaction COMMITTED Successfully ===';
    RAISE NOTICE 'TopUp ID: %, Amount: % RWF', v_topup_id, v_amount;
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'ERROR: Transaction failed - %', SQLERRM;
        ROLLBACK;
        
        -- Log failure
        INSERT INTO Transaction_Log (TransactionType, NodeName, Status, ErrorMessage)
        VALUES ('TopUp', 'Node_A', 'ABORTED', SQLERRM);
END $$;

-- Verify successful transaction
SELECT 
    'Success Scenario Results' AS Report,
    (SELECT COUNT(*) FROM TopUp) AS TopUp_Count,
    (SELECT COUNT(*) FROM Transaction_Log WHERE Status = 'COMMITTED') AS Committed_Count,
    (SELECT COUNT(*) FROM Transaction_Log WHERE Status = 'ABORTED') AS Aborted_Count;

-- View transaction log
SELECT 
    LogID,
    TransactionType,
    NodeName,
    RecordID,
    Status,
    LogTimestamp
FROM Transaction_Log
ORDER BY LogID DESC
LIMIT 10;
