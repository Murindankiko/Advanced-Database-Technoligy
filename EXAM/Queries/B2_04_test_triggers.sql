-- ============================================================================
-- Task B7: Test E-C-A Triggers for Balance Maintenance
-- Execute on telco_node_a database
-- ============================================================================

DO $$
DECLARE
    v_initial_balance NUMERIC;
    v_simid INT := 1002;
    r RECORD;  -- THIS WAS MISSING! Must declare loop variable
BEGIN
    RAISE NOTICE '=== Testing E-C-A Triggers for Balance Maintenance ===';
    RAISE NOTICE '';

    -- Show initial state
    RAISE NOTICE 'Initial Balance for SimID %:', v_simid;
    PERFORM * FROM SUBSCR_BALANCE WHERE SimID = v_simid;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'SimID % not found in SUBSCR_BALANCE. Insert a base row first.', v_simid;
    END IF;

    SELECT CurrentBalance_RWF INTO v_initial_balance
    FROM SUBSCR_BALANCE WHERE SimID = v_simid;

    RAISE NOTICE 'Initial: TotalTopUps=%, TotalCharges=%, Balance=%, TopUpCount=%, CallCount=%',
        (SELECT TotalTopUps_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT TotalCharges_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        v_initial_balance,
        (SELECT TopUpCount FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT CallCount FROM SUBSCR_BALANCE WHERE SimID = v_simid);
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 1: INSERT TopUp
    -----------------------------------------------------------------------
    RAISE NOTICE '--- Test 1: INSERT TopUp ---';
    INSERT INTO TopUp (SimID, Amount_RWF, PaymentMethod, TransactionRef)
    VALUES (v_simid, 10000.00, 'Mobile Money', 'TEST_B7_001');

    RAISE NOTICE 'TopUp inserted: +10000.00 RWF';

    RAISE NOTICE 'After TopUp INSERT:';
    RAISE NOTICE 'TotalTopUps=%, TotalCharges=%, Balance=%, TopUpCount=%',
        (SELECT TotalTopUps_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT TotalCharges_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT CurrentBalance_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT TopUpCount FROM SUBSCR_BALANCE WHERE SimID = v_simid);
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 2: INSERT CDR
    -----------------------------------------------------------------------
    RAISE NOTICE '--- Test 2: INSERT CDR ---';
    INSERT INTO CDR_A (SimID, CallType, CallDate, Duration, Charge, DestinationNumber)
    VALUES (v_simid, 'Voice', CURRENT_TIMESTAMP, 300, 750.00, '+250788999888');

    RAISE NOTICE 'CDR inserted: -750.00 RWF';

    RAISE NOTICE 'After CDR INSERT:';
    RAISE NOTICE 'TotalTopUps=%, TotalCharges=%, Balance=%, CallCount=%',
        (SELECT TotalTopUps_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT TotalCharges_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT CurrentBalance_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT CallCount FROM SUBSCR_BALANCE WHERE SimID = v_simid);
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 3: UPDATE TopUp Amount
    -----------------------------------------------------------------------
    RAISE NOTICE '--- Test 3: UPDATE TopUp Amount ---';
    UPDATE TopUp
    SET Amount_RWF = 12000.00
    WHERE TransactionRef = 'TEST_B7_001';

    RAISE NOTICE 'TopUp updated: 10000 to 12000 (+2000.00 adjustment)';

    RAISE NOTICE 'After TopUp UPDATE:';
    RAISE NOTICE 'TotalTopUps=%, TotalCharges=%, Balance=%',
        (SELECT TotalTopUps_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT TotalCharges_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT CurrentBalance_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid);
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 4: DELETE CDR
    -----------------------------------------------------------------------
    RAISE NOTICE '--- Test 4: DELETE CDR ---';
    DELETE FROM CDR_A
    WHERE SimID = v_simid AND Charge = 750.00;

    RAISE NOTICE 'CDR deleted: +750.00 back to balance';

    RAISE NOTICE 'After CDR DELETE:';
    RAISE NOTICE 'TotalTopUps=%, TotalCharges=%, Balance=%, CallCount=%',
        (SELECT TotalTopUps_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT TotalCharges_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT CurrentBalance_RWF FROM SUBSCR_BALANCE WHERE SimID = v_simid),
        (SELECT CallCount FROM SUBSCR_BALANCE WHERE SimID = v_simid);
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Audit Trail
    -----------------------------------------------------------------------
    RAISE NOTICE '--- Audit Trail ---';
    RAISE NOTICE 'Full history of balance changes for SimID %:', v_simid;

    FOR r IN
        SELECT AuditID, OperationType, SourceTable, AmountChange_RWF,
               OldBalance_RWF, NewBalance_RWF, AuditTimestamp
        FROM SUBSCR_BAL_AUDIT
        WHERE SimID = v_simid
        ORDER BY AuditID
    LOOP
        RAISE NOTICE 'AuditID=% | % % | Delta=%, Old=%, New=%, Time=%',
            r.AuditID,
            r.OperationType,
            r.SourceTable,
            r.AmountChange_RWF,
            r.OldBalance_RWF,
            r.NewBalance_RWF,
            r.AuditTimestamp;
    END LOOP;

    RAISE NOTICE '';
    RAISE NOTICE '=== All Trigger Tests Complete ===';
    RAISE NOTICE 'Check audit log above to see complete history of balance changes';
    RAISE NOTICE 'Test data will be cleaned up below...';

    -----------------------------------------------------------------------
    -- Cleanup
    -----------------------------------------------------------------------
    RAISE NOTICE '';
    RAISE NOTICE '--- Cleanup Test Data ---';
    DELETE FROM TopUp WHERE TransactionRef LIKE 'TEST_B7_%';
    RAISE NOTICE 'Deleted test TopUp records';

    UPDATE SUBSCR_BALANCE
    SET TotalTopUps_RWF = TotalTopUps_RWF - 12000.00,
        CurrentBalance_RWF = v_initial_balance,
        TopUpCount = TopUpCount - 1
    WHERE SimID = v_simid;

    RAISE NOTICE 'Balance reset to initial state: % RWF', v_initial_balance;
    RAISE NOTICE 'All test data cleaned. Safe to re-run.';
END $$;