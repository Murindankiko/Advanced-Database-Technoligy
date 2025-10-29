-- ============================================================================
-- Task B6: Add constraints to CDR and TopUp tables
-- Execute on appropriate databases (CDR on both nodes, TopUp on node_a)
-- ============================================================================

-- For CDR_A (execute on telco_node_a)
-- Note: CDR_A already has chk_simid_even from A1

ALTER TABLE CDR_A
    ADD CONSTRAINT chk_charge_positive 
        CHECK (Charge > 0),
    ADD CONSTRAINT chk_duration_nonnegative 
        CHECK (Duration IS NULL OR Duration >= 0),
    ADD CONSTRAINT chk_calldate_reasonable 
        CHECK (CallDate >= '2020-01-01' AND CallDate <= CURRENT_TIMESTAMP + INTERVAL '1 hour');

COMMENT ON CONSTRAINT chk_charge_positive ON CDR_A IS 'Charge must be positive';
COMMENT ON CONSTRAINT chk_duration_nonnegative ON CDR_A IS 'Duration cannot be negative';
COMMENT ON CONSTRAINT chk_calldate_reasonable ON CDR_A IS 'Call date must be reasonable (2020 to now)';

-- For TopUp (execute on telco_node_a)
-- Note: TopUp already has CHECK (Amount_RWF > 0) from A4

ALTER TABLE TopUp
    ADD CONSTRAINT chk_topup_date_reasonable 
        CHECK (TopUpDate >= '2020-01-01' AND TopUpDate <= CURRENT_TIMESTAMP + INTERVAL '1 hour'),
    ADD CONSTRAINT chk_payment_method_valid 
        CHECK (PaymentMethod IN ('Mobile Money', 'Bank Transfer', 'Cash', 'Credit Card'));

COMMENT ON CONSTRAINT chk_topup_date_reasonable ON TopUp IS 'TopUp date must be reasonable';
COMMENT ON CONSTRAINT chk_payment_method_valid ON TopUp IS 'Payment method must be valid option';

-- View all constraints
SELECT 
    'CDR_A Constraints' AS Table_Name,
    conname AS Constraint_Name,
    pg_get_constraintdef(oid) AS Constraint_Definition
FROM pg_constraint
WHERE conrelid = 'cdr_a'::regclass
ORDER BY conname;

SELECT 
    'TopUp Constraints' AS Table_Name,
    conname AS Constraint_Name,
    pg_get_constraintdef(oid) AS Constraint_Definition
FROM pg_constraint
WHERE conrelid = 'topup'::regclass
ORDER BY conname;
