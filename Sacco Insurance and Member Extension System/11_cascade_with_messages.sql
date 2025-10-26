-- ============================================================================
-- CASCADE DELETE WITH MESSAGES - SACCO Insurance System (Rwanda)
-- Demonstrates CASCADE DELETE with visible notification messages
-- ============================================================================

-- ============================================================================
-- STEP 1: Create Audit Log Table (Optional but Recommended)
-- Tracks all deletions for audit purposes
-- ============================================================================

CREATE TABLE IF NOT EXISTS AuditLog (
    AuditID SERIAL PRIMARY KEY,
    TableName VARCHAR(50) NOT NULL,
    RecordID INT NOT NULL,
    Action VARCHAR(20) NOT NULL,
    DeletedBy VARCHAR(100),
    DeletedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Details TEXT
);

-- ============================================================================
-- STEP 2: Create Trigger Function for Payment Cascade Notification
-- This fires BEFORE a payment is deleted and logs a message
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_LogPaymentCascadeDelete()
RETURNS TRIGGER AS $$
BEGIN
    -- Raise a notice to show the cascade is happening
    RAISE NOTICE '🔔 CASCADE DELETE TRIGGERED: Payment ID % (Amount: RWF %, Method: %) is being deleted due to Claim ID % deletion',
        OLD.PaymentID, 
        OLD.Amount, 
        OLD.Method,
        OLD.ClaimID;
    
    -- Log to audit table
    INSERT INTO AuditLog (TableName, RecordID, Action, Details)
    VALUES (
        'Payment',
        OLD.PaymentID,
        'CASCADE DELETE',
        FORMAT('Payment ID %s (Amount: %s, Method: %s) deleted due to Claim ID %s deletion',
            OLD.PaymentID, OLD.Amount, OLD.Method, OLD.ClaimID)
    );
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_PaymentCascadeNotification ON Payment;
CREATE TRIGGER trg_PaymentCascadeNotification
BEFORE DELETE ON Payment
FOR EACH ROW
EXECUTE FUNCTION fn_LogPaymentCascadeDelete();

-- ============================================================================
-- STEP 3: Create Trigger Function for Claim Deletion Notification
-- This fires BEFORE a claim is deleted
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_LogClaimDelete()
RETURNS TRIGGER AS $$
DECLARE
    payment_count INT;
BEGIN
    -- Check if this claim has associated payments
    SELECT COUNT(*) INTO payment_count
    FROM Payment
    WHERE ClaimID = OLD.ClaimID;
    
    IF payment_count > 0 THEN
        RAISE NOTICE '⚠️  DELETING CLAIM: Claim ID % (Amount Claimed: RWF %, Status: %) - This will CASCADE DELETE % payment(s)',
            OLD.ClaimID,
            OLD.AmountClaimed,
            OLD.Status,
            payment_count;
    ELSE
        RAISE NOTICE 'ℹ️  DELETING CLAIM: Claim ID % (Amount Claimed: RWF %, Status: %) - No payments to cascade',
            OLD.ClaimID,
            OLD.AmountClaimed,
            OLD.Status;
    END IF;
    
    -- Log to audit table
    INSERT INTO AuditLog (TableName, RecordID, Action, Details)
    VALUES (
        'Claim',
        OLD.ClaimID,
        'DELETE',
        FORMAT('Claim ID %s (Amount: %s, Status: %s) deleted - %s payment(s) will cascade',
            OLD.ClaimID, OLD.AmountClaimed, OLD.Status, payment_count)
    );
    
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS trg_ClaimDeleteNotification ON Claim;
CREATE TRIGGER trg_ClaimDeleteNotification
BEFORE DELETE ON Claim
FOR EACH ROW
EXECUTE FUNCTION fn_LogClaimDelete();

-- ============================================================================
-- STEP 4: Create Stored Procedure for Safe Deletion with Reporting
-- This procedure deletes a claim and returns detailed information
-- ============================================================================

CREATE OR REPLACE FUNCTION sp_DeleteClaimWithReport(p_ClaimID INT)
RETURNS TABLE(
    Action VARCHAR,
    TableName VARCHAR,
    RecordID INT,
    Details TEXT,
    DeletedAt TIMESTAMP
) AS $$
DECLARE
    v_payment_count INT;
    v_claim_amount DECIMAL;
    v_claim_status VARCHAR;
BEGIN
    -- Check if claim exists
    IF NOT EXISTS (SELECT 1 FROM Claim WHERE ClaimID = p_ClaimID) THEN
        RAISE EXCEPTION 'Claim ID % does not exist', p_ClaimID;
    END IF;
    
    -- Get claim details before deletion
    SELECT AmountClaimed, Status INTO v_claim_amount, v_claim_status
    FROM Claim
    WHERE ClaimID = p_ClaimID;
    
    -- Count associated payments
    SELECT COUNT(*) INTO v_payment_count
    FROM Payment
    WHERE ClaimID = p_ClaimID;
    
    -- Display summary message
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '📋 DELETION SUMMARY FOR CLAIM ID: %', p_ClaimID;
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    RAISE NOTICE '   Claim Amount: RWF %', v_claim_amount;
    RAISE NOTICE '   Claim Status: %', v_claim_status;
    RAISE NOTICE '   Associated Payments: %', v_payment_count;
    RAISE NOTICE '───────────────────────────────────────────────────────────';
    
    IF v_payment_count > 0 THEN
        RAISE NOTICE '⚠️  CASCADE DELETE will remove % payment record(s)', v_payment_count;
    ELSE
        RAISE NOTICE 'ℹ️  No payments to cascade delete';
    END IF;
    
    RAISE NOTICE '═══════════════════════════════════════════════════════════';
    
    -- Perform the deletion (this will trigger cascade)
    DELETE FROM Claim WHERE ClaimID = p_ClaimID;
    
    RAISE NOTICE '✅ Deletion completed successfully!';
    RAISE NOTICE '';
    
    -- Return audit log entries for this deletion
    RETURN QUERY
    SELECT 
        a.Action::VARCHAR,
        a.TableName::VARCHAR,
        a.RecordID,
        a.Details,
        a.DeletedAt
    FROM AuditLog a
    WHERE a.RecordID = p_ClaimID 
       OR a.Details LIKE '%Claim ID ' || p_ClaimID || '%'
    ORDER BY a.DeletedAt DESC
    LIMIT 10;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TEST QUERIES - Run these to see CASCADE DELETE messages
-- ============================================================================

-- ============================================================================
-- TEST 1: View current state before deletion
-- ============================================================================
SELECT '═══════════════════════════════════════════════════════════' AS separator;
SELECT '📊 CURRENT STATE - Claims and Payments' AS test_name;
SELECT '═══════════════════════════════════════════════════════════' AS separator;

SELECT 
    c.ClaimID,
    c.PolicyID,
    c.AmountClaimed,
    c.Status AS ClaimStatus,
    CASE 
        WHEN p.PaymentID IS NOT NULL THEN '✓ Has Payment'
        ELSE '✗ No Payment'
    END AS PaymentStatus,
    COALESCE(p.PaymentID, 0) AS PaymentID,
    COALESCE(p.Amount, 0) AS PaymentAmount,
    COALESCE(p.Method, 'N/A') AS PaymentMethod
FROM Claim c
LEFT JOIN Payment p ON c.ClaimID = p.ClaimID
ORDER BY c.ClaimID;

-- ============================================================================
-- TEST 2: Delete a Claim that HAS a Payment (CASCADE will trigger)
-- Watch for NOTICE messages in the Messages tab!
-- ============================================================================
SELECT '═══════════════════════════════════════════════════════════' AS separator;
SELECT '🧪 TEST 2: Deleting Claim ID 1 (HAS Payment - CASCADE Expected)' AS test_name;
SELECT '═══════════════════════════════════════════════════════════' AS separator;

-- This will show CASCADE DELETE messages
DELETE FROM Claim WHERE ClaimID = 1;

-- Verify the payment was also deleted
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM Claim WHERE ClaimID = 1) 
        THEN '❌ FAILED: Claim still exists'
        ELSE '✅ SUCCESS: Claim deleted'
    END AS claim_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Payment WHERE ClaimID = 1) 
        THEN '❌ FAILED: Payment still exists (CASCADE did not work)'
        ELSE '✅ SUCCESS: Payment cascaded and deleted'
    END AS payment_status;

-- ============================================================================
-- TEST 3: Delete a Claim that has NO Payment (No CASCADE needed)
-- ============================================================================
SELECT '═══════════════════════════════════════════════════════════' AS separator;
SELECT '🧪 TEST 3: Deleting Claim ID 3 (NO Payment - No CASCADE)' AS test_name;
SELECT '═══════════════════════════════════════════════════════════' AS separator;

-- This will show a message that no cascade is needed
DELETE FROM Claim WHERE ClaimID = 3;

-- Verify deletion
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM Claim WHERE ClaimID = 3) 
        THEN '❌ FAILED: Claim still exists'
        ELSE '✅ SUCCESS: Claim deleted'
    END AS result;

-- ============================================================================
-- TEST 4: Use the stored procedure for detailed reporting
-- ============================================================================
SELECT '═══════════════════════════════════════════════════════════' AS separator;
SELECT '🧪 TEST 4: Using Stored Procedure to Delete Claim ID 2' AS test_name;
SELECT '═══════════════════════════════════════════════════════════' AS separator;

-- This will show detailed messages and return audit log
SELECT * FROM sp_DeleteClaimWithReport(2);

-- ============================================================================
-- TEST 5: View Audit Log of all deletions
-- ============================================================================
SELECT '═══════════════════════════════════════════════════════════' AS separator;
SELECT '📜 AUDIT LOG - All Deletion Activities' AS test_name;
SELECT '═══════════════════════════════════════════════════════════' AS separator;

SELECT 
    AuditID,
    TableName,
    RecordID,
    Action,
    Details,
    TO_CHAR(DeletedAt, 'YYYY-MM-DD HH24:MI:SS') AS DeletedAt
FROM AuditLog
ORDER BY DeletedAt DESC;

-- ============================================================================
-- TEST 6: Summary Report
-- ============================================================================
SELECT '═══════════════════════════════════════════════════════════' AS separator;
SELECT '📊 FINAL STATE - Remaining Claims and Payments' AS test_name;
SELECT '═══════════════════════════════════════════════════════════' AS separator;

SELECT 
    'Claims' AS TableName,
    COUNT(*) AS RemainingRecords
FROM Claim
UNION ALL
SELECT 
    'Payments',
    COUNT(*)
FROM Payment;

-- Detailed view
SELECT 
    c.ClaimID,
    c.PolicyID,
    c.AmountClaimed,
    c.Status AS ClaimStatus,
    COALESCE(p.PaymentID, 0) AS PaymentID,
    COALESCE(p.Amount, 0) AS PaymentAmount
FROM Claim c
LEFT JOIN Payment p ON c.ClaimID = p.ClaimID
ORDER BY c.ClaimID;

-- ============================================================================
-- CLEANUP: How to remove the triggers and audit system (optional)
-- ============================================================================

-- Uncomment these lines if you want to remove the notification system:
/*
DROP TRIGGER IF EXISTS trg_PaymentCascadeNotification ON Payment;
DROP TRIGGER IF EXISTS trg_ClaimDeleteNotification ON Claim;
DROP FUNCTION IF EXISTS fn_LogPaymentCascadeDelete();
DROP FUNCTION IF EXISTS fn_LogClaimDelete();
DROP FUNCTION IF EXISTS sp_DeleteClaimWithReport(INT);
DROP TABLE IF EXISTS AuditLog;
*/

-- ============================================================================
-- NOTES:
-- 1. Watch the "Messages" tab in pgAdmin to see NOTICE messages
-- 2. The AuditLog table keeps a permanent record of all deletions
-- 3. The stored procedure provides the most detailed reporting
-- 4. Triggers fire automatically for any DELETE operation
-- ============================================================================
