-- ============================================================================
-- TEST SCRIPT: CASCADE DELETE - Claim → Payment
-- Database: sacco (Rwanda SACCO Insurance System)
-- Purpose: Verify ON DELETE CASCADE constraint between Claim and Payment
-- ============================================================================

-- ============================================================================
-- INITIAL STATE: View current Claims and Payments
-- ============================================================================
SELECT '=== INITIAL STATE: All Claims and Payments ===' AS Test_Section;

SELECT 
    c.ClaimID,
    c.PolicyID,
    c.DateFiled,
    c.AmountClaimed,
    c.Status,
    p.PaymentID,
    p.Amount AS PaymentAmount,
    p.PaymentDate,
    p.Method
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
ORDER BY 
    c.ClaimID;

-- Count before deletion
SELECT 
    'Before Deletion' AS Stage,
    (SELECT COUNT(*) FROM Claim) AS Total_Claims,
    (SELECT COUNT(*) FROM Payment) AS Total_Payments;

-- ============================================================================
-- TEST 1: Delete Claim with Payment (ClaimID = 2)
-- Expected: Both Claim and its Payment should be deleted
-- ============================================================================
SELECT '=== TEST 1: Deleting Claim with Payment (ClaimID = 2) ===' AS Test_Section;

-- Show the claim and payment before deletion
SELECT 
    'Before Delete - ClaimID 2' AS Status,
    c.ClaimID,
    c.AmountClaimed,
    c.Status AS ClaimStatus,
    p.PaymentID,
    p.Amount AS PaymentAmount,
    p.Method
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.ClaimID = 2;

-- Perform the DELETE on Claim
DELETE FROM Claim WHERE ClaimID = 2;

-- Verify the claim is deleted
SELECT 
    'After Delete - ClaimID 2' AS Status,
    CASE 
        WHEN COUNT(*) = 0 THEN 'Claim Successfully Deleted'
        ELSE 'Claim Still Exists (ERROR)'
    END AS Claim_Status
FROM 
    Claim 
WHERE 
    ClaimID = 2;

-- Verify the payment is also deleted (CASCADE effect)
SELECT 
    'After Delete - Payment for ClaimID 2' AS Status,
    CASE 
        WHEN COUNT(*) = 0 THEN 'Payment Successfully Deleted (CASCADE WORKED)'
        ELSE 'Payment Still Exists (CASCADE FAILED)'
    END AS Payment_Status
FROM 
    Payment 
WHERE 
    ClaimID = 2;

-- ============================================================================
-- TEST 2: Delete Claim with Payment (ClaimID = 5)
-- Expected: Both Claim and its Payment should be deleted
-- ============================================================================
SELECT '=== TEST 2: Deleting Claim with Payment (ClaimID = 5) ===' AS Test_Section;

-- Show the claim and payment before deletion
SELECT 
    'Before Delete - ClaimID 5' AS Status,
    c.ClaimID,
    c.AmountClaimed,
    c.Status AS ClaimStatus,
    p.PaymentID,
    p.Amount AS PaymentAmount,
    p.Method
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.ClaimID = 5;

-- Perform the DELETE on Claim
DELETE FROM Claim WHERE ClaimID = 5;

-- Verify the claim is deleted
SELECT 
    'After Delete - ClaimID 5' AS Status,
    CASE 
        WHEN COUNT(*) = 0 THEN 'Claim Successfully Deleted'
        ELSE 'Claim Still Exists (ERROR)'
    END AS Claim_Status
FROM 
    Claim 
WHERE 
    ClaimID = 5;

-- Verify the payment is also deleted (CASCADE effect)
SELECT 
    'After Delete - Payment for ClaimID 5' AS Status,
    CASE 
        WHEN COUNT(*) = 0 THEN 'Payment Successfully Deleted (CASCADE WORKED)'
        ELSE 'Payment Still Exists (CASCADE FAILED)'
    END AS Payment_Status
FROM 
    Payment 
WHERE 
    ClaimID = 5;

-- ============================================================================
-- TEST 3: Delete Claim without Payment (ClaimID = 3)
-- Expected: Only Claim should be deleted, no Payment to cascade
-- ============================================================================
SELECT '=== TEST 3: Deleting Claim without Payment (ClaimID = 3) ===' AS Test_Section;

-- Show the claim before deletion
SELECT 
    'Before Delete - ClaimID 3' AS Status,
    c.ClaimID,
    c.AmountClaimed,
    c.Status AS ClaimStatus,
    CASE 
        WHEN p.PaymentID IS NULL THEN 'No Payment Exists'
        ELSE 'Payment Exists'
    END AS Payment_Status
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.ClaimID = 3;

-- Perform the DELETE on Claim
DELETE FROM Claim WHERE ClaimID = 3;

-- Verify the claim is deleted
SELECT 
    'After Delete - ClaimID 3' AS Status,
    CASE 
        WHEN COUNT(*) = 0 THEN 'Claim Successfully Deleted'
        ELSE 'Claim Still Exists (ERROR)'
    END AS Claim_Status
FROM 
    Claim 
WHERE 
    ClaimID = 3;

-- ============================================================================
-- TEST 4: Delete Multiple Claims with Payments
-- Expected: All claims and their payments should be deleted
-- ============================================================================
SELECT '=== TEST 4: Deleting Multiple Claims (ClaimID = 1 and 4) ===' AS Test_Section;

-- Show claims before deletion
SELECT 
    'Before Delete - Multiple Claims' AS Status,
    c.ClaimID,
    c.AmountClaimed,
    p.PaymentID,
    p.Amount AS PaymentAmount
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.ClaimID IN (1, 4);

-- Perform the DELETE on multiple Claims
DELETE FROM Claim WHERE ClaimID IN (1, 4);

-- Verify claims are deleted
SELECT 
    'After Delete - Multiple Claims' AS Status,
    CASE 
        WHEN COUNT(*) = 0 THEN 'All Claims Successfully Deleted'
        ELSE 'Some Claims Still Exist (ERROR)'
    END AS Claims_Status
FROM 
    Claim 
WHERE 
    ClaimID IN (1, 4);

-- Verify payments are also deleted (CASCADE effect)
SELECT 
    'After Delete - Payments for Multiple Claims' AS Status,
    CASE 
        WHEN COUNT(*) = 0 THEN 'All Payments Successfully Deleted (CASCADE WORKED)'
        ELSE 'Some Payments Still Exist (CASCADE FAILED)'
    END AS Payments_Status
FROM 
    Payment 
WHERE 
    ClaimID IN (1, 4);

-- ============================================================================
-- FINAL STATE: View remaining Claims and Payments
-- ============================================================================
SELECT '=== FINAL STATE: Remaining Claims and Payments ===' AS Test_Section;

SELECT 
    c.ClaimID,
    c.PolicyID,
    c.DateFiled,
    c.AmountClaimed,
    c.Status,
    p.PaymentID,
    p.Amount AS PaymentAmount,
    p.PaymentDate,
    p.Method
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
ORDER BY 
    c.ClaimID;

-- Count after all deletions
SELECT 
    'After All Deletions' AS Stage,
    (SELECT COUNT(*) FROM Claim) AS Total_Claims,
    (SELECT COUNT(*) FROM Payment) AS Total_Payments;

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================
SELECT '=== CASCADE DELETE TEST SUMMARY ===' AS Test_Section;

SELECT 
    'CASCADE DELETE Test Results' AS Test_Name,
    CASE 
        WHEN (SELECT COUNT(*) FROM Payment WHERE ClaimID IN (1, 2, 4, 5)) = 0 
        THEN '✓ PASSED - All payments cascaded correctly'
        ELSE '✗ FAILED - Some payments were not deleted'
    END AS Test_Result;

-- ============================================================================
-- VERIFICATION: Check Foreign Key Constraint
-- ============================================================================
SELECT '=== VERIFY CASCADE CONSTRAINT IN DATABASE ===' AS Test_Section;

SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS references_table,
    ccu.column_name AS references_column,
    rc.delete_rule AS cascade_rule
FROM
    information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
    JOIN information_schema.referential_constraints rc
      ON rc.constraint_name = tc.constraint_name
WHERE
    tc.table_name = 'payment'
    AND tc.constraint_type = 'FOREIGN KEY'
    AND kcu.column_name = 'claimid';

-- ============================================================================
-- NOTE: After running this test, you may want to re-run the data insertion
-- script (02_insert_data.sql) to restore the deleted records for further testing
-- ============================================================================
