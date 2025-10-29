-- ============================================================================
-- Task B: Test SIM Constraints
-- Execute on telco_node_b database
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE '=== Testing SIM Constraints ===';
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 1: Valid SIM insert (should succeed)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 1: Valid SIM insert';
    BEGIN
        INSERT INTO SIM (SimID, SubscriberID, PhoneNumber, ActivationDate, Status)
        VALUES (2001, 1, '+250788999888', '2024-09-01', 'Active');
        RAISE NOTICE 'PASS: Valid SIM inserted successfully';
        ROLLBACK;
    END;

    -----------------------------------------------------------------------
    -- Test 2: Valid SIM with Suspended status (should succeed)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 2: Valid SIM with Suspended status';
    BEGIN
        INSERT INTO SIM (SimID, SubscriberID, PhoneNumber, ActivationDate, Status)
        VALUES (2002, 2, '+250788777666', '2024-09-05', 'Suspended');
        RAISE NOTICE 'PASS: SIM with Suspended status inserted successfully';
        ROLLBACK;
    END;

    RAISE NOTICE '';
    RAISE NOTICE '--- Testing Constraint Violations ---';
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 3: Invalid phone format (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 3: Invalid phone format (should fail)';
    BEGIN
        INSERT INTO SIM (SimID, SubscriberID, PhoneNumber, ActivationDate, Status)
        VALUES (2003, 1, '0788123456', '2024-09-01', 'Active');
        RAISE NOTICE 'FAIL: Should have rejected invalid phone format';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected invalid phone format';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    -----------------------------------------------------------------------
    -- Test 4: NULL PhoneNumber (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 4: NULL PhoneNumber (should fail)';
    BEGIN
        INSERT INTO SIM (SimID, SubscriberID, PhoneNumber, ActivationDate, Status)
        VALUES (2004, 1, NULL, '2024-09-01', 'Active');
        RAISE NOTICE 'FAIL: Should have rejected NULL PhoneNumber';
    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected NULL PhoneNumber';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    -----------------------------------------------------------------------
    -- Test 5: Negative SimID (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 5: Negative SimID (should fail)';
    BEGIN
        INSERT INTO SIM (SimID, SubscriberID, PhoneNumber, ActivationDate, Status)
        VALUES (-100, 1, '+250788555444', '2024-09-01', 'Active');
        RAISE NOTICE 'FAIL: Should have rejected negative SimID';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected negative SimID';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    -----------------------------------------------------------------------
    -- Test 6: Invalid Status (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 6: Invalid Status (should fail)';
    BEGIN
        INSERT INTO SIM (SimID, SubscriberID, PhoneNumber, ActivationDate, Status)
        VALUES (2005, 1, '+250788333222', '2024-09-01', 'InvalidStatus');
        RAISE NOTICE 'FAIL: Should have rejected invalid Status';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected invalid Status';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    RAISE NOTICE '';
    RAISE NOTICE '=== All SIM Constraint Tests Complete ===';
END $$;