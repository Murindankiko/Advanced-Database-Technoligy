-- ============================================================================
-- Test Subscriber Constraints
-- Execute on telco_node_b database
-- ============================================================================

DO $$
DECLARE
    r   RECORD;      -- not used, just to silence "no destination" warnings
BEGIN
    RAISE NOTICE '=== Testing Subscriber Constraints ===';
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 1: Valid insert (should succeed)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 1: Valid subscriber insert';
    BEGIN
        INSERT INTO Subscriber (FullName, NationalID, District, RegistrationDate)
        VALUES ('Uwimana Alice', '1199580045678901', 'Huye', '2024-06-15');
        RAISE NOTICE 'PASS: Valid subscriber inserted successfully';
        ROLLBACK;
    END;

    -----------------------------------------------------------------------
    -- Test 2: Valid insert without optional NationalID (should succeed)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 2: Valid subscriber without National ID';
    BEGIN
        INSERT INTO Subscriber (FullName, District, RegistrationDate)
        VALUES ('Mugabo Patrick', 'Muhanga', '2024-07-20');
        RAISE NOTICE 'PASS: Subscriber without National ID inserted successfully';
        ROLLBACK;
    END;

    RAISE NOTICE '';
    RAISE NOTICE '--- Testing Constraint Violations ---';
    RAISE NOTICE '';

    -----------------------------------------------------------------------
    -- Test 3: NULL FullName (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 3: NULL FullName (should fail)';
    BEGIN
        INSERT INTO Subscriber (FullName, District, RegistrationDate)
        VALUES (NULL, 'Kigali', '2024-08-01');
        RAISE NOTICE 'FAIL: Should have rejected NULL FullName';
    EXCEPTION
        WHEN not_null_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected NULL FullName';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    -----------------------------------------------------------------------
    -- Test 4: FullName too short (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 4: FullName too short (should fail)';
    BEGIN
        INSERT INTO Subscriber (FullName, District, RegistrationDate)
        VALUES ('AB', 'Kigali', '2024-08-01');
        RAISE NOTICE 'FAIL: Should have rejected short FullName';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected short FullName';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    -----------------------------------------------------------------------
    -- Test 5: Invalid NationalID format (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 5: Invalid NationalID format (should fail)';
    BEGIN
        INSERT INTO Subscriber (FullName, NationalID, District, RegistrationDate)
        VALUES ('Mukamana Grace', '12345', 'Rubavu', '2024-08-01');
        RAISE NOTICE 'FAIL: Should have rejected invalid NationalID';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected invalid NationalID format';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    -----------------------------------------------------------------------
    -- Test 6: Invalid District (should fail)
    -----------------------------------------------------------------------
    RAISE NOTICE 'Test 6: Invalid District (should fail)';
    BEGIN
        INSERT INTO Subscriber (FullName, District, RegistrationDate)
        VALUES ('Habimana Jean', 'InvalidDistrict', '2024-08-01');
        RAISE NOTICE 'FAIL: Should have rejected invalid District';
    EXCEPTION
        WHEN check_violation THEN
            RAISE NOTICE 'PASS: Correctly rejected invalid District';
            RAISE NOTICE '   Error: %', SQLERRM;
    END;

    RAISE NOTICE '';
    RAISE NOTICE '=== All Subscriber Constraint Tests Complete ===';
END $$;