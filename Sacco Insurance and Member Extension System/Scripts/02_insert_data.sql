-- ============================================================================
-- TASK 2: INSERT SAMPLE DATA - RWANDAN CONTEXT
-- All data reflects realistic Rwandan names, locations, and contact information
-- ============================================================================

-- ============================================================================
-- Clear existing data to prevent duplicate key errors
-- Delete in reverse order of dependencies (child tables first)
-- ============================================================================
DELETE FROM Payment;
DELETE FROM Claim;
DELETE FROM InsurancePolicy;
DELETE FROM LoanAccount;
DELETE FROM Officer;
DELETE FROM Member;

-- Reset sequences to start from 1
ALTER SEQUENCE member_memberid_seq RESTART WITH 1;
ALTER SEQUENCE officer_officerid_seq RESTART WITH 1;
ALTER SEQUENCE loanaccount_loanid_seq RESTART WITH 1;
ALTER SEQUENCE insurancepolicy_policyid_seq RESTART WITH 1;
ALTER SEQUENCE claim_claimid_seq RESTART WITH 1;
ALTER SEQUENCE payment_paymentid_seq RESTART WITH 1;

-- ============================================================================
-- Insert 5 Members with Rwandan names and addresses
-- Phone numbers follow Rwanda format: +250 7XX XXX XXX
-- ============================================================================
INSERT INTO Member (FullName, Gender, Contact, Address, JoinDate) VALUES
('Nshuti Alice Uwase', 'F', '+250788123456', 'KG 15 Ave, Kigali City', '2020-03-15'),
('Hirwa Jean Claude Mugabo', 'M', '+250788234567', 'Musanze District, Northern Province', '2019-08-20'),
('Uwase Ange Marie Mukamana', 'F', '+250788345678', 'Huye District, Southern Province', '2021-05-10'),
('Niyonzima Patrick Habimana', 'M', '+250788456789', 'Rubavu District, Western Province', '2018-12-05'),
('Mutesi Grace Ingabire', 'F', '+250788567890', 'Nyagatare District, Eastern Province', '2022-01-28');

-- ============================================================================
-- Insert 5 Officers with Rwandan names and branch locations
-- Branches represent major Rwandan cities and districts
-- ============================================================================
INSERT INTO Officer (FullName, Branch, Contact, Role) VALUES
('Kamanzi Eric Nkurunziza', 'Kigali', '+250788678901', 'Loan Officer'),
('Mukamana Diane Uwera', 'Musanze', '+250788789012', 'Insurance Manager'),
('Nsengimana Robert Bizimana', 'Huye', '+250788890123', 'Claims Officer'),
('Uwimana Claudine Mukamazimpaka', 'Rubavu', '+250788901234', 'Branch Manager'),
('Habimana Samuel Niyitegeka', 'Nyagatare', '+250788012345', 'Customer Service Officer');

-- ============================================================================
-- Insert 5 Loan Accounts
-- Amounts in Rwandan Francs (RWF) - typical loan ranges
-- ============================================================================
INSERT INTO LoanAccount (MemberID, OfficerID, Amount, InterestRate, StartDate, Status) VALUES
(1, 1, 5000000.00, 12.50, '2023-02-10', 'Active'),
(2, 1, 7500000.00, 11.00, '2023-04-15', 'Active'),
(3, 3, 3000000.00, 13.00, '2022-11-20', 'Closed'),
(4, 4, 10000000.00, 10.50, '2023-06-01', 'Active'),
(5, 5, 4500000.00, 12.00, '2023-09-10', 'Active');

-- ============================================================================
-- Insert 5 Insurance Policies
-- Premium amounts in RWF appropriate for Rwandan context
-- ============================================================================
INSERT INTO InsurancePolicy (MemberID, Type, Premium, StartDate, EndDate, Status) VALUES
(1, 'Life', 150000.00, '2023-01-01', '2024-12-31', 'Active'),
(1, 'Loan Protection', 80000.00, '2023-02-10', '2025-02-10', 'Active'),
(2, 'Health', 200000.00, '2023-03-01', '2024-03-01', 'Active'),
(3, 'Property', 250000.00, '2022-07-15', '2023-07-15', 'Expired'),
(4, 'Accident', 120000.00, '2023-05-01', '2024-05-01', 'Active');

-- ============================================================================
-- Insert 5 Claims
-- Claim amounts in RWF
-- ============================================================================
INSERT INTO Claim (PolicyID, DateFiled, AmountClaimed, Status) VALUES
(1, '2023-09-15', 1000000.00, 'Approved'),
(2, '2023-10-20', 500000.00, 'Settled'),
(3, '2023-08-10', 650000.00, 'Pending'),      -- Fixed: was PolicyID 6, now 3
(4, '2023-07-05', 9000000.00, 'Rejected'),    -- Fixed: was PolicyID 7, now 4
(5, '2023-11-01', 800000.00, 'Settled');

-- ============================================================================
-- Insert 5 Payments
-- Payment amounts in RWF with methods common in Rwanda
-- NOTE: ClaimID must be unique (1:1 relationship between Claim and Payment)
-- Fixed duplicate ClaimID error - each payment now references a unique claim
-- ============================================================================
INSERT INTO Payment (ClaimID, Amount, PaymentDate, Method) VALUES
(1, 1000000.00, '2023-12-01', 'Bank Transfer'),
(2, 500000.00, '2023-11-05', 'Mobile Money'),
(3, 650000.00, '2023-12-10', 'Direct Deposit'),   -- Fixed: was ClaimID 6, now 3
(4, 9000000.00, '2023-12-15', 'Bank Transfer'),   -- Fixed: was ClaimID 7, now 4
(5, 800000.00, '2023-11-15', 'Mobile Money');

-- ============================================================================
-- Verify data insertion
-- ============================================================================
SELECT 'Members' AS Table_Name, COUNT(*) AS Record_Count FROM Member
UNION ALL
SELECT 'Officers', COUNT(*) FROM Officer
UNION ALL
SELECT 'LoanAccounts', COUNT(*) FROM LoanAccount
UNION ALL
SELECT 'InsurancePolicies', COUNT(*) FROM InsurancePolicy
UNION ALL
SELECT 'Claims', COUNT(*) FROM Claim
UNION ALL
SELECT 'Payments', COUNT(*) FROM Payment;
