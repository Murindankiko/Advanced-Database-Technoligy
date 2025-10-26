-- ============================================================================
-- SIMPLE CASCADE DELETE DEMONSTRATION
-- Quick test to see CASCADE DELETE in action with messages
-- ============================================================================

-- ============================================================================
-- QUERY 1: Delete Claim with Payment (CASCADE DELETE will occur)
-- ============================================================================

-- First, let's see what we're about to delete
SELECT 
    '🔍 BEFORE DELETION - Claim and Payment Details' AS info,
    c.ClaimID,
    c.PolicyID,
    c.AmountClaimed AS ClaimAmount,
    c.Status AS ClaimStatus,
    p.PaymentID,
    p.Amount AS PaymentAmount,
    p.Method AS PaymentMethod
FROM Claim c
INNER JOIN Payment p ON c.ClaimID = p.ClaimID
WHERE c.ClaimID = 4;

-- Now delete the claim (watch for CASCADE message in Messages tab)
DO $$
DECLARE
    v_claim_id INT := 4;
    v_payment_exists BOOLEAN;
BEGIN
    -- Check if payment exists
    SELECT EXISTS(SELECT 1 FROM Payment WHERE ClaimID = v_claim_id) 
    INTO v_payment_exists;
    
    IF v_payment_exists THEN
        RAISE NOTICE '═══════════════════════════════════════════════════════════';
        RAISE NOTICE '⚠️  CASCADE DELETE ALERT!';
        RAISE NOTICE '═══════════════════════════════════════════════════════════';
        RAISE NOTICE 'Deleting Claim ID: %', v_claim_id;
        RAISE NOTICE 'This claim has an associated payment that will be automatically deleted';
        RAISE NOTICE '───────────────────────────────────────────────────────────';
    END IF;
    
    -- Perform the delete
    DELETE FROM Claim WHERE ClaimID = v_claim_id;
    
    RAISE NOTICE '✅ Claim ID % deleted successfully', v_claim_id;
    RAISE NOTICE '✅ Associated payment was CASCADE DELETED automatically';
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- Verify both are gone
SELECT 
    '✅ AFTER DELETION - Verification' AS info,
    CASE 
        WHEN NOT EXISTS(SELECT 1 FROM Claim WHERE ClaimID = 4) 
        THEN 'Claim ID 4 successfully deleted'
        ELSE 'ERROR: Claim still exists'
    END AS claim_result,
    CASE 
        WHEN NOT EXISTS(SELECT 1 FROM Payment WHERE ClaimID = 4) 
        THEN 'Payment for Claim 4 successfully CASCADE DELETED'
        ELSE 'ERROR: Payment still exists'
    END AS payment_result;

-- ============================================================================
-- QUERY 2: Delete Claim without Payment (No CASCADE needed)
-- ============================================================================

-- Check what we're deleting
SELECT 
    '🔍 BEFORE DELETION - Claim without Payment' AS info,
    c.ClaimID,
    c.PolicyID,
    c.AmountClaimed,
    c.Status,
    CASE 
        WHEN p.PaymentID IS NULL THEN 'No payment exists'
        ELSE 'Payment exists'
    END AS payment_status
FROM Claim c
LEFT JOIN Payment p ON c.ClaimID = p.ClaimID
WHERE c.ClaimID = 5;

-- Delete claim without payment
DO $$
DECLARE
    v_claim_id INT := 5;
    v_payment_exists BOOLEAN;
BEGIN
    -- Check if payment exists
    SELECT EXISTS(SELECT 1 FROM Payment WHERE ClaimID = v_claim_id) 
    INTO v_payment_exists;
    
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    IF v_payment_exists THEN
        RAISE NOTICE '⚠️  CASCADE DELETE will occur';
    ELSE
        RAISE NOTICE 'ℹ️  Simple DELETE (no cascade needed)';
    END IF;
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE 'Deleting Claim ID: %', v_claim_id;
    
    -- Perform the delete
    DELETE FROM Claim WHERE ClaimID = v_claim_id;
    
    RAISE NOTICE '✅ Claim ID % deleted successfully', v_claim_id;
    IF NOT v_payment_exists THEN
        RAISE NOTICE 'ℹ️  No payment existed, so no cascade occurred';
    END IF;
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '';
END $$;

-- Verify deletion
SELECT 
    '✅ AFTER DELETION - Verification' AS info,
    CASE 
        WHEN NOT EXISTS(SELECT 1 FROM Claim WHERE ClaimID = 5) 
        THEN 'Claim ID 5 successfully deleted'
        ELSE 'ERROR: Claim still exists'
    END AS result;

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================
SELECT '═══════════════════════════════════════════════════════════' AS separator;
SELECT '📊 CASCADE DELETE TEST SUMMARY' AS title;
SELECT '═══════════════════════════════════════════════════════════' AS separator;

SELECT 
    'Total Claims Remaining' AS metric,
    COUNT(*)::TEXT AS value
FROM Claim
UNION ALL
SELECT 
    'Total Payments Remaining',
    COUNT(*)::TEXT
FROM Payment
UNION ALL
SELECT
    'Claims with Payments',
    COUNT(DISTINCT c.ClaimID)::TEXT
FROM Claim c
INNER JOIN Payment p ON c.ClaimID = p.ClaimID;
