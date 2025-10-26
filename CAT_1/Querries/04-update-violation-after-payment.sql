-- ============================================
-- Procedure: Update Violation Status After Payment
-- Updates violation and fine status when payment is made
-- ============================================

-- Example: Process a payment for Fine #1 (Violation #1)
BEGIN;

-- Insert payment record
INSERT INTO Payment (FineID, Amount, PaymentDate, Method)
VALUES (1, 50000, CURRENT_TIMESTAMP, 'Mobile Money');

-- Update fine status
UPDATE Fine
SET Status = 'Paid'
WHERE FineID = 1;

-- Update violation status
UPDATE Violation
SET Status = 'Paid'
WHERE ViolationID = (SELECT ViolationID FROM Fine WHERE FineID = 1);

COMMIT;

-- Verify the update
SELECT 
    v.ViolationID,
    v.Type AS ViolationType,
    v.Status AS ViolationStatus,
    f.FineID,
    f.Status AS FineStatus,
    p.PaymentID,
    p.Amount AS PaymentAmount,
    p.PaymentDate,
    p.Method AS PaymentMethod
FROM 
    Violation v
    INNER JOIN Fine f ON v.ViolationID = f.ViolationID
    LEFT JOIN Payment p ON f.FineID = p.FineID
WHERE 
    v.ViolationID = 1;

-- ============================================
-- Reusable Function: Process Payment
-- ============================================
CREATE OR REPLACE FUNCTION process_payment(
    p_fine_id INT,
    p_amount DECIMAL(10, 2),
    p_method VARCHAR(50)
)
RETURNS VOID AS $$
BEGIN
    -- Insert payment
    INSERT INTO Payment (FineID, Amount, PaymentDate, Method)
    VALUES (p_fine_id, p_amount, CURRENT_TIMESTAMP, p_method);
    
    -- Update fine status
    UPDATE Fine
    SET Status = 'Paid'
    WHERE FineID = p_fine_id;
    
    -- Update violation status
    UPDATE Violation
    SET Status = 'Paid'
    WHERE ViolationID = (SELECT ViolationID FROM Fine WHERE FineID = p_fine_id);
    
    RAISE NOTICE 'Payment processed successfully for Fine ID: %', p_fine_id;
END;
$$ LANGUAGE plpgsql;

-- Example usage:
-- SELECT process_payment(2, 30000, 'Mobile Money');
