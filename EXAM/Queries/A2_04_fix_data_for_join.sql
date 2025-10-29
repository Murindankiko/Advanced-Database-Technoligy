-- ============================================================================
-- Task A2: Fix Data to Enable Distributed Join
-- Add matching SIM records for even SimIDs in CDR_A
-- Execute this script while connected to telco_node_b database
-- ============================================================================

-- Insert additional SIM records with even SimIDs to match CDR_A
INSERT INTO SIM (SimID, SubscriberID, PhoneNumber, ActivationDate, Status) VALUES
(1002, 1, '+250788123456', '2024-01-12', 'Active'),
(1004, 2, '+250788234567', '2024-02-17', 'Active'),
(1006, 3, '+250788345678', '2024-03-22', 'Active');

-- Verify SIM table now has both odd and even SimIDs
SELECT 
    SimID,
    SubscriberID,
    PhoneNumber,
    Status,
    MOD(SimID, 2) AS SimID_Parity,
    CASE 
        WHEN MOD(SimID, 2) = 0 THEN 'Even (matches CDR_A)'
        ELSE 'Odd (matches CDR_B)'
    END AS FragmentNote
FROM SIM
ORDER BY SimID;

-- Now re-run the distributed join query from A2_03 on telco_node_a
-- It should return matching results
