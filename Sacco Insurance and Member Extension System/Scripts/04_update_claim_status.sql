-- ============================================================================
-- TASK 4: UPDATE CLAIM STATUS AFTER SETTLEMENT
-- Updates claim status to 'Settled' when payment is processed
-- Reflects Rwandan SACCO claim settlement workflow
-- ============================================================================

-- Example 1: Update a specific claim after settlement
UPDATE Claim
SET Status = 'Settled'
WHERE ClaimID = 3 AND Status = 'Approved';

-- Example 2: Update all approved claims that have received payment
UPDATE Claim
SET Status = 'Settled'
WHERE ClaimID IN (
    SELECT c.ClaimID
    FROM Claim c
    INNER JOIN Payment p ON c.ClaimID = p.ClaimID
    WHERE c.Status = 'Approved'
);

-- Example 3: Update with verification (shows before and after)
-- Before update
SELECT 
    c.ClaimID,
    c.Status AS CurrentStatus,
    TO_CHAR(c.AmountClaimed, 'FML999,999,999') || ' RWF' AS AmountClaimed,
    COALESCE(TO_CHAR(p.Amount, 'FML999,999,999'), '0') || ' RWF' AS AmountPaid,
    CASE 
        WHEN p.PaymentID IS NOT NULL THEN 'Has Payment'
        ELSE 'No Payment'
    END AS PaymentStatus
FROM 
    Claim c
LEFT JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.Status IN ('Approved', 'Pending');

-- Perform the update
UPDATE Claim
SET Status = 'Settled'
WHERE ClaimID IN (
    SELECT c.ClaimID
    FROM Claim c
    INNER JOIN Payment p ON c.ClaimID = p.ClaimID
    WHERE c.Status IN ('Approved', 'Pending')
);

-- After update - verify changes
SELECT 
    c.ClaimID,
    c.Status AS UpdatedStatus,
    TO_CHAR(c.AmountClaimed, 'FML999,999,999') || ' RWF' AS AmountClaimed,
    TO_CHAR(p.Amount, 'FML999,999,999') || ' RWF' AS AmountPaid,
    p.PaymentDate,
    p.Method
FROM 
    Claim c
INNER JOIN 
    Payment p ON c.ClaimID = p.ClaimID
WHERE 
    c.Status = 'Settled';
