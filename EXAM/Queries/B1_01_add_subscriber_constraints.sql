-- ============================================================================
-- Task B6: Declarative Rules Hardening
-- Step 1: Add constraints to Subscriber table
-- Execute on telco_node_b database
-- ============================================================================

-- Add NOT NULL constraints
ALTER TABLE Subscriber
    ALTER COLUMN FullName SET NOT NULL,
    ALTER COLUMN RegistrationDate SET NOT NULL;

-- Add CHECK constraints
ALTER TABLE Subscriber
    ADD CONSTRAINT chk_fullname_length 
        CHECK (LENGTH(TRIM(FullName)) >= 3),
    ADD CONSTRAINT chk_nationalid_format 
        CHECK (NationalID IS NULL OR (LENGTH(NationalID) = 16 AND NationalID ~ '^[0-9]+$')),
    ADD CONSTRAINT chk_district_valid 
        CHECK (District IN ('Kigali', 'Musanze', 'Rubavu', 'Huye', 'Muhanga', 'Nyanza', 'Rusizi', 'Karongi')),
    ADD CONSTRAINT chk_registration_date 
        CHECK (RegistrationDate <= CURRENT_DATE AND RegistrationDate >= '2020-01-01');

COMMENT ON CONSTRAINT chk_fullname_length ON Subscriber IS 'Full name must be at least 3 characters';
COMMENT ON CONSTRAINT chk_nationalid_format ON Subscriber IS 'National ID must be exactly 16 digits';
COMMENT ON CONSTRAINT chk_district_valid ON Subscriber IS 'District must be valid Rwanda district';
COMMENT ON CONSTRAINT chk_registration_date ON Subscriber IS 'Registration date must be between 2020 and today';

-- View constraints
SELECT 
    'Subscriber Constraints' AS Table_Name,
    conname AS Constraint_Name,
    contype AS Constraint_Type,
    pg_get_constraintdef(oid) AS Constraint_Definition
FROM pg_constraint
WHERE conrelid = 'subscriber'::regclass
ORDER BY contype, conname;
