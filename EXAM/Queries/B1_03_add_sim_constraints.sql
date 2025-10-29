-- ============================================================================
-- Task B6: Add constraints to SIM table
-- Execute on telco_node_b database
-- ============================================================================

-- Add NOT NULL constraints
ALTER TABLE SIM
    ALTER COLUMN PhoneNumber SET NOT NULL,
    ALTER COLUMN ActivationDate SET NOT NULL,
    ALTER COLUMN Status SET NOT NULL;

-- Add CHECK constraints
ALTER TABLE SIM
    ADD CONSTRAINT chk_phone_format 
        CHECK (PhoneNumber ~ '^\+250[0-9]{9}$'),
    ADD CONSTRAINT chk_activation_date 
        CHECK (ActivationDate <= CURRENT_DATE AND ActivationDate >= '2020-01-01'),
    ADD CONSTRAINT chk_simid_positive 
        CHECK (SimID > 0);

COMMENT ON CONSTRAINT chk_phone_format ON SIM IS 'Phone number must be Rwanda format +250XXXXXXXXX';
COMMENT ON CONSTRAINT chk_activation_date ON SIM IS 'Activation date must be between 2020 and today';
COMMENT ON CONSTRAINT chk_simid_positive ON SIM IS 'SimID must be positive integer';

-- View constraints
SELECT 
    'SIM Constraints' AS Table_Name,
    conname AS Constraint_Name,
    contype AS Constraint_Type,
    pg_get_constraintdef(oid) AS Constraint_Definition
FROM pg_constraint
WHERE conrelid = 'sim'::regclass
ORDER BY contype, conname;
