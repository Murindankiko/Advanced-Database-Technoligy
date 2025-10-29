-- ============================================================================
-- Task B6: Test CDR and TopUp Constraints
-- Execute on telco_node_a database
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== Testing CDR_A Constraints ===';
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 1: Valid CDR insert (should succeed)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 1: Valid CDR insert';
    BEGIN
        INSERT INTO CDR_A (SimID, CallType, CallDate, Duration, Charge, DestinationNumber)
        VALUES (1012, 'Voice', CURRENT_TIMESTAMP, 120, 300.00, '+250788111222');
        RAISE NOTICE 'PASS: Valid CDR inserted successfully';
        ROLLBACK;
    END;

    -----------------------------------------------------------------------
    -- Test 2: Negative charge (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 2: Negative charge (should fail)';
    BEGIN
        INSERT INTO CDR_A (SimID, CallType, CallDate, Duration, Charge)
        VALUES (1014, 'SMS', CURRENT_TIMESTAMP, 1, -50.00);
        RAISE NOTICE 'FAIL: Should have rejected negative charge';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected negative charge';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    RAISE NOTICE '';
    RAISE NOTICE '=== Testing TopUp Constraints ===';
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 3: Valid TopUp (should succeed)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 3: Valid TopUp insert';
    BEGIN
        INSERT INTO TopUp (SimID, Amount_RWF, PaymentMethod, TransactionRef)
        VALUES (1002, 2000.00, 'Mobile Money', 'TEST_TXN_001');
        RAISE NOTICE 'PASS: Valid TopUp inserted successfully';
        ROLLBACK;
    END;

    -----------------------------------------------------------------------
    -- Test 4: Invalid payment method (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 4: Invalid payment method (should fail)';
    BEGIN
        INSERT INTO TopUp (SimID, Amount_RWF, PaymentMethod, TransactionRef)
        VALUES (1002, 2000.00, 'Bitcoin', 'TEST_TXN_002');
        RAISE NOTICE 'FAIL: Should have rejected invalid payment method';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected invalid payment method';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    RAISE NOTICE '';
    RAISE NOTICE '=== All CDR and TopUp Constraint Tests Complete ===';
END $$;