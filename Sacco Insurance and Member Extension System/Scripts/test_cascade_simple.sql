-- ============================================================================
-- SIMPLE CASCADE DELETE TEST - FOR BEGINNERS
-- Tests ON DELETE CASCADE between Claim → Payment
-- ============================================================================

-- ============================================================================
-- STEP 1: View data BEFORE deletion
-- ============================================================================
SELECT '=== BEFORE DELETION ===' AS Status;

-- Show Claims and their Payments
SELECT 
    c.ClaimID,
    c.AmountClaimed,
    c.Status AS ClaimStatus,
    p.PaymentID,
    p.Amount AS PaymentAmount
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.ClaimID IN (1, 2)
ORDER BY 
    c.ClaimID;

-- ============================================================================
-- TEST QUERY 1: Delete Claim with ClaimID = 1
-- This will automatically delete its Payment due to CASCADE
-- ============================================================================

SELECT '=== TEST 1: Deleting Claim 1 ===' AS Status;

-- Delete the claim
DELETE FROM Claim WHERE ClaimID = 1;

-- Check what remains
SELECT 
    c.ClaimID,
    c.AmountClaimed,
    c.Status AS ClaimStatus,
    p.PaymentID,
    p.Amount AS PaymentAmount
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.ClaimID = 1;

-- If no rows returned, CASCADE worked! The payment was deleted automatically.
SELECT 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Payment WHERE ClaimID = 1)
        THEN '✓ CASCADE WORKED: Payment for Claim 1 was automatically deleted'
        ELSE '✗ CASCADE FAILED: Payment still exists'
    END AS Result;

-- ============================================================================
-- TEST QUERY 2: Delete Claim with ClaimID = 2
-- This will automatically delete its Payment due to CASCADE
-- ============================================================================

SELECT '=== TEST 2: Deleting Claim 2 ===' AS Status;

-- Show before
SELECT 
    c.ClaimID,
    c.AmountClaimed,
    p.PaymentID,
    p.Amount
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.ClaimID = 2;

-- Delete the claim
DELETE FROM Claim WHERE ClaimID = 2;

-- Check what remains
SELECT 
    c.ClaimID,
    c.AmountClaimed,
    p.PaymentID,
    p.Amount
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.ClaimID = 2;

-- Verify CASCADE worked
SELECT 
    CASE 
        WHEN NOT EXISTS (SELECT 1 FROM Payment WHERE ClaimID = 2)
        THEN '✓ CASCADE WORKED: Payment for Claim 2 was automatically deleted'
        ELSE '✗ CASCADE FAILED: Payment still exists'
    END AS Result;

-- ============================================================================
-- FINAL SUMMARY
-- ============================================================================
SELECT '=== FINAL SUMMARY ===' AS Status;

-- Count remaining records
SELECT 
    'Claims Remaining' AS Table_Name,
    COUNT(*) AS Count
FROM 
    Claim
UNION ALL
SELECT 
    'Payments Remaining',
    COUNT(*)
FROM 
    Payment;

-- Show all remaining data
SELECT 
    c.ClaimID,
    c.AmountClaimed,
    c.Status,
    p.PaymentID,
    p.Amount AS PaymentAmount
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
ORDER BY 
    c.ClaimID;
