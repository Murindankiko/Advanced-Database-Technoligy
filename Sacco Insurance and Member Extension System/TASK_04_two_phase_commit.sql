-- ============================================================================
-- TASK 4: TWO-PHASE COMMIT SIMULATION
-- ============================================================================
-- Purpose: Demonstrate distributed transaction atomicity using 2PC protocol
-- Ensures all-or-nothing execution across multiple database nodes
-- ============================================================================

-- ============================================================================
-- STEP 1: Understanding Two-Phase Commit (2PC)
-- ============================================================================
-- Phase 1: PREPARE - All participants prepare to commit
-- Phase 2: COMMIT - If all prepared successfully, commit all; else rollback all
-- 
-- PostgreSQL Commands:
-- - BEGIN: Start transaction
-- - PREPARE TRANSACTION 'txn_id': Prepare transaction for commit
-- - COMMIT PREPARED 'txn_id': Commit prepared transaction
-- - ROLLBACK PREPARED 'txn_id': Rollback prepared transaction
-- ============================================================================

-- ============================================================================
-- STEP 2: Check if prepared transactions are enabled
-- ============================================================================

-- Verify max_prepared_transactions setting (must be > 0)
SHOW max_prepared_transactions;

-- If it's 0, you need to set it in postgresql.conf and restart PostgreSQL
-- For this demo, we'll assume it's properly configured

-- View currently prepared transactions
SELECT * FROM pg_prepared_xacts;

-- ============================================================================
-- STEP 3: Scenario - Distributed member registration across branches
-- ============================================================================
-- Business Case: A member wants to register in both Kigali and Musanze branches
-- simultaneously. Both registrations must succeed or both must fail (atomicity).
-- ============================================================================

-- ============================================================================
-- STEP 4: TWO-PHASE COMMIT - Successful scenario
-- ============================================================================

-- Transaction 1: Prepare transaction in Kigali branch
BEGIN;

INSERT INTO branch_kigali.Member (FullName, Gender, Contact, Address, JoinDate, Branch)
VALUES ('Uwera Sandrine Mukeshimana', 'F', '+250788111222', 'Kicukiro, Kigali', CURRENT_DATE, 'Kigali');

-- Get the MemberID for reference
SELECT 'Kigali Member Inserted' AS Status, MemberID, FullName 
FROM branch_kigali.Member 
WHERE Contact = '+250788111222';

-- PREPARE the transaction (Phase 1)
PREPARE TRANSACTION 'kigali_member_txn_001';

-- Transaction 2: Prepare transaction in Musanze branch
BEGIN;

INSERT INTO branch_musanze.Member (FullName, Gender, Contact, Address, JoinDate, Branch)
VALUES ('Uwera Sandrine Mukeshimana', 'F', '+250788111223', 'Musanze Town', CURRENT_DATE, 'Musanze');

-- Get the MemberID for reference
SELECT 'Musanze Member Inserted' AS Status, MemberID, FullName 
FROM branch_musanze.Member 
WHERE Contact = '+250788111223';

-- PREPARE the transaction (Phase 1)
PREPARE TRANSACTION 'musanze_member_txn_001';

-- ============================================================================
-- STEP 5: Check prepared transactions
-- ============================================================================

-- View all prepared transactions
SELECT 
    gid AS transaction_id,
    prepared AS prepare_time,
    owner,
    database
FROM pg_prepared_xacts
WHERE gid IN ('kigali_member_txn_001', 'musanze_member_txn_001');

-- ============================================================================
-- STEP 6: COMMIT both prepared transactions (Phase 2)
-- ============================================================================

-- Commit Kigali transaction
COMMIT PREPARED 'kigali_member_txn_001';

-- Commit Musanze transaction
COMMIT PREPARED 'musanze_member_txn_001';

-- ============================================================================
-- STEP 7: Verify successful distributed commit
-- ============================================================================

-- Check Kigali branch
SELECT 'KIGALI BRANCH' AS Branch, MemberID, FullName, Contact, Branch
FROM branch_kigali.Member
WHERE FullName = 'Uwera Sandrine Mukeshimana';

-- Check Musanze branch
SELECT 'MUSANZE BRANCH' AS Branch, MemberID, FullName, Contact, Branch
FROM branch_musanze.Member
WHERE FullName = 'Uwera Sandrine Mukeshimana';

-- ============================================================================
-- STEP 8: TWO-PHASE COMMIT - Complex scenario with loans
-- ============================================================================
-- Scenario: Transfer a loan from Kigali to Musanze branch
-- Must update both branches atomically
-- ============================================================================

-- Transaction 1: Prepare to update loan status in Kigali
BEGIN;

-- Mark loan as transferred in Kigali
UPDATE branch_kigali.LoanAccount
SET Status = 'Closed'
WHERE LoanID = 1;

SELECT 'Kigali Loan Updated' AS Status, LoanID, Status 
FROM branch_kigali.LoanAccount 
WHERE LoanID = 1;

PREPARE TRANSACTION 'kigali_loan_transfer_001';

-- Transaction 2: Prepare to create new loan in Musanze
BEGIN;

-- Create corresponding loan in Musanze
INSERT INTO branch_musanze.LoanAccount (MemberID, OfficerID, Amount, InterestRate, StartDate, Status)
VALUES (1, 1, 5000000.00, 12.50, CURRENT_DATE, 'Active');

SELECT 'Musanze Loan Created' AS Status, LoanID, Amount, Status 
FROM branch_musanze.LoanAccount 
WHERE MemberID = 1 AND Amount = 5000000.00;

PREPARE TRANSACTION 'musanze_loan_transfer_001';

-- Check prepared transactions
SELECT gid, prepared, database 
FROM pg_prepared_xacts 
WHERE gid LIKE '%loan_transfer%';

-- Commit both transactions
COMMIT PREPARED 'kigali_loan_transfer_001';
COMMIT PREPARED 'musanze_loan_transfer_001';

-- Verify the distributed transaction
SELECT 'KIGALI - Loan Closed' AS Status, LoanID, Status 
FROM branch_kigali.LoanAccount WHERE LoanID = 1
UNION ALL
SELECT 'MUSANZE - New Loan Created', LoanID, Status 
FROM branch_musanze.LoanAccount WHERE Amount = 5000000.00 AND MemberID = 1;

-- ============================================================================
-- STEP 9: Demonstrate transaction atomicity with multiple operations
-- ============================================================================

-- Scenario: Bulk insurance policy creation across branches
BEGIN;

-- Insert multiple policies in Kigali
INSERT INTO branch_kigali.InsurancePolicy (MemberID, Type, Premium, StartDate, EndDate, Status)
VALUES 
    (1, 'Health', 180000.00, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', 'Active'),
    (2, 'Life', 220000.00, CURRENT_DATE, CURRENT_DATE + INTERVAL '2 years', 'Active');

SELECT 'Kigali Policies Prepared' AS Status, COUNT(*) AS Policy_Count
FROM branch_kigali.InsurancePolicy
WHERE Premium IN (180000.00, 220000.00);

PREPARE TRANSACTION 'kigali_bulk_policy_001';

-- Insert multiple policies in Musanze
BEGIN;

INSERT INTO branch_musanze.InsurancePolicy (MemberID, Type, Premium, StartDate, EndDate, Status)
VALUES 
    (1, 'Property', 300000.00, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', 'Active'),
    (2, 'Accident', 150000.00, CURRENT_DATE, CURRENT_DATE + INTERVAL '1 year', 'Active');

SELECT 'Musanze Policies Prepared' AS Status, COUNT(*) AS Policy_Count
FROM branch_musanze.InsurancePolicy
WHERE Premium IN (300000.00, 150000.00);

PREPARE TRANSACTION 'musanze_bulk_policy_001';

-- View prepared transactions
SELECT gid, prepared FROM pg_prepared_xacts WHERE gid LIKE '%bulk_policy%';

-- Commit all prepared transactions
COMMIT PREPARED 'kigali_bulk_policy_001';
COMMIT PREPARED 'musanze_bulk_policy_001';

-- Verify distributed commit
SELECT 'TOTAL POLICIES CREATED' AS Status, 
       (SELECT COUNT(*) FROM branch_kigali.InsurancePolicy WHERE Premium IN (180000.00, 220000.00)) +
       (SELECT COUNT(*) FROM branch_musanze.InsurancePolicy WHERE Premium IN (300000.00, 150000.00)) AS Total_Count;

-- ============================================================================
-- STEP 10: Cleanup and verification
-- ============================================================================

-- Check for any remaining prepared transactions
SELECT 
    gid AS transaction_id,
    prepared AS prepare_time,
    owner,
    database,
    CURRENT_TIMESTAMP - prepared AS age
FROM pg_prepared_xacts
ORDER BY prepared DESC;

-- ============================================================================
-- TWO-PHASE COMMIT SUMMARY
-- ============================================================================
-- Two-Phase Commit Protocol ensures:
-- 1. ATOMICITY - All nodes commit or all rollback
-- 2. CONSISTENCY - Database remains in valid state
-- 3. ISOLATION - Transactions don't interfere
-- 4. DURABILITY - Committed changes persist
-- 
-- PostgreSQL 2PC Commands:
-- - PREPARE TRANSACTION 'id' - Phase 1: Prepare to commit
-- - COMMIT PREPARED 'id' - Phase 2: Commit if all prepared
-- - ROLLBACK PREPARED 'id' - Phase 2: Rollback if any failed
-- 
-- Use Cases:
-- - Distributed transactions across multiple databases
-- - Cross-branch operations requiring atomicity
-- - Multi-node data synchronization
-- - Ensuring data consistency in distributed systems
-- ============================================================================
