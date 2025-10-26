-- ============================================================================
-- SACCO INSURANCE AND MEMBER EXTENSION SYSTEM - MASTER SETUP SCRIPT
-- Database: sacco
-- DBMS: PostgreSQL (pgAdmin 4)
-- Context: Rwanda
-- 
-- INSTRUCTIONS:
-- 1. Create database: CREATE DATABASE sacco;
-- 2. Connect to sacco database
-- 3. Run this ENTIRE script in one execution
-- 4. This script will create all tables, insert data, create views, and triggers
-- ============================================================================

-- Start transaction to ensure all-or-nothing execution
BEGIN;

-- ============================================================================
-- STEP 1: DROP EXISTING OBJECTS (if any) - Clean slate
-- ============================================================================
DROP TRIGGER IF EXISTS trg_AutoExpirePolicy ON InsurancePolicy;
DROP FUNCTION IF EXISTS fn_AutoExpirePolicy();
DROP FUNCTION IF EXISTS sp_ExpireOldPolicies();

DROP VIEW IF EXISTS vw_MonthlyPremiumCollection;
DROP VIEW IF EXISTS vw_MonthlyPremiumSummary;
DROP VIEW IF EXISTS vw_YearlyPremiumComparison;

DROP TABLE IF EXISTS Payment CASCADE;
DROP TABLE IF EXISTS Claim CASCADE;
DROP TABLE IF EXISTS InsurancePolicy CASCADE;
DROP TABLE IF EXISTS LoanAccount CASCADE;
DROP TABLE IF EXISTS Officer CASCADE;
DROP TABLE IF EXISTS Member CASCADE;

-- ============================================================================
-- STEP 2: CREATE ALL TABLES
-- ============================================================================

-- TABLE 1: Member
CREATE TABLE Member (
    MemberID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F', 'O')),
    Contact VARCHAR(15) NOT NULL UNIQUE,
    Address TEXT,
    JoinDate DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT chk_contact_format CHECK (Contact ~ '^[0-9+\-() ]+$')
);

-- TABLE 2: Officer
CREATE TABLE Officer (
    OfficerID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Branch VARCHAR(50) NOT NULL,
    Contact VARCHAR(15) NOT NULL UNIQUE,
    Role VARCHAR(50) NOT NULL,
    CONSTRAINT chk_officer_contact CHECK (Contact ~ '^[0-9+\-() ]+$')
);

-- TABLE 3: LoanAccount
CREATE TABLE LoanAccount (
    LoanID SERIAL PRIMARY KEY,
    MemberID INT NOT NULL,
    OfficerID INT NOT NULL,
    Amount DECIMAL(12, 2) NOT NULL CHECK (Amount > 0),
    InterestRate DECIMAL(5, 2) NOT NULL CHECK (InterestRate >= 0 AND InterestRate <= 100),
    StartDate DATE NOT NULL DEFAULT CURRENT_DATE,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active' 
        CHECK (Status IN ('Active', 'Closed', 'Defaulted', 'Pending')),
    CONSTRAINT fk_loan_member FOREIGN KEY (MemberID) 
        REFERENCES Member(MemberID) ON DELETE CASCADE,
    CONSTRAINT fk_loan_officer FOREIGN KEY (OfficerID) 
        REFERENCES Officer(OfficerID) ON DELETE RESTRICT
);

-- TABLE 4: InsurancePolicy
CREATE TABLE InsurancePolicy (
    PolicyID SERIAL PRIMARY KEY,
    MemberID INT NOT NULL,
    Type VARCHAR(50) NOT NULL 
        CHECK (Type IN ('Life', 'Health', 'Property', 'Loan Protection', 'Accident')),
    Premium DECIMAL(10, 2) NOT NULL CHECK (Premium > 0),
    StartDate DATE NOT NULL DEFAULT CURRENT_DATE,
    EndDate DATE NOT NULL,
    Status VARCHAR(20) NOT NULL DEFAULT 'Active' 
        CHECK (Status IN ('Active', 'Expired', 'Cancelled', 'Suspended')),
    CONSTRAINT fk_policy_member FOREIGN KEY (MemberID) 
        REFERENCES Member(MemberID) ON DELETE CASCADE,
    CONSTRAINT chk_policy_dates CHECK (EndDate > StartDate)
);

-- TABLE 5: Claim
CREATE TABLE Claim (
    ClaimID SERIAL PRIMARY KEY,
    PolicyID INT NOT NULL,
    DateFiled DATE NOT NULL DEFAULT CURRENT_DATE,
    AmountClaimed DECIMAL(12, 2) NOT NULL CHECK (AmountClaimed > 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'Pending' 
        CHECK (Status IN ('Pending', 'Approved', 'Rejected', 'Settled')),
    CONSTRAINT fk_claim_policy FOREIGN KEY (PolicyID) 
        REFERENCES InsurancePolicy(PolicyID) ON DELETE CASCADE
);

-- TABLE 6: Payment (with ON DELETE CASCADE from Claim)
CREATE TABLE Payment (
    PaymentID SERIAL PRIMARY KEY,
    ClaimID INT NOT NULL UNIQUE,
    Amount DECIMAL(12, 2) NOT NULL CHECK (Amount > 0),
    PaymentDate DATE NOT NULL DEFAULT CURRENT_DATE,
    Method VARCHAR(30) NOT NULL 
        CHECK (Method IN ('Bank Transfer', 'Cheque', 'Cash', 'Mobile Money', 'Direct Deposit')),
    CONSTRAINT fk_payment_claim FOREIGN KEY (ClaimID) 
        REFERENCES Claim(ClaimID) ON DELETE CASCADE
);

-- Create indexes
CREATE INDEX idx_loan_member ON LoanAccount(MemberID);
CREATE INDEX idx_loan_officer ON LoanAccount(OfficerID);
CREATE INDEX idx_policy_member ON InsurancePolicy(MemberID);
CREATE INDEX idx_policy_status ON InsurancePolicy(Status);
CREATE INDEX idx_claim_policy ON Claim(PolicyID);
CREATE INDEX idx_claim_status ON Claim(Status);
CREATE INDEX idx_payment_claim ON Payment(ClaimID);

-- Add comments
COMMENT ON DATABASE sacco IS 'SACCO Insurance and Member Extension System - Operating in Rwanda';
COMMENT ON TABLE Member IS 'Stores SACCO member profile information';
COMMENT ON TABLE Officer IS 'Stores SACCO officer details';
COMMENT ON TABLE LoanAccount IS 'Tracks member loan accounts';
COMMENT ON TABLE InsurancePolicy IS 'Stores insurance policy information';
COMMENT ON TABLE Claim IS 'Records insurance claims filed by members';
COMMENT ON TABLE Payment IS 'Records payments for settled claims';

-- ============================================================================
-- STEP 3: INSERT SAMPLE DATA (Rwandan Context)
-- ============================================================================

-- Insert 5 Members
INSERT INTO Member (FullName, Gender, Contact, Address, JoinDate) VALUES
('Nshuti Alice Uwase', 'F', '+250788123456', 'KG 15 Ave, Kigali City', '2020-03-15'),
('Hirwa Jean Claude Mugabo', 'M', '+250788234567', 'Musanze District, Northern Province', '2019-08-20'),
('Uwase Ange Marie Mukamana', 'F', '+250788345678', 'Huye District, Southern Province', '2021-05-10'),
('Niyonzima Patrick Habimana', 'M', '+250788456789', 'Rubavu District, Western Province', '2018-12-05'),
('Mutesi Grace Ingabire', 'F', '+250788567890', 'Nyagatare District, Eastern Province', '2022-01-28');

-- Insert 5 Officers
INSERT INTO Officer (FullName, Branch, Contact, Role) VALUES
('Kamanzi Eric Nkurunziza', 'Kigali', '+250788678901', 'Loan Officer'),
('Mukamana Diane Uwera', 'Musanze', '+250788789012', 'Insurance Manager'),
('Nsengimana Robert Bizimana', 'Huye', '+250788890123', 'Claims Officer'),
('Uwimana Claudine Mukamazimpaka', 'Rubavu', '+250788901234', 'Branch Manager'),
('Habimana Samuel Niyitegeka', 'Nyagatare', '+250788012345', 'Customer Service Officer');

-- Insert 5 Loan Accounts
INSERT INTO LoanAccount (MemberID, OfficerID, Amount, InterestRate, StartDate, Status) VALUES
(1, 1, 5000000.00, 12.50, '2023-02-10', 'Active'),
(2, 1, 7500000.00, 11.00, '2023-04-15', 'Active'),
(3, 3, 3000000.00, 13.00, '2022-11-20', 'Closed'),
(4, 4, 10000000.00, 10.50, '2023-06-01', 'Active'),
(5, 5, 4500000.00, 12.00, '2023-09-10', 'Active');

-- Insert 5 Insurance Policies
INSERT INTO InsurancePolicy (MemberID, Type, Premium, StartDate, EndDate, Status) VALUES
(1, 'Life', 150000.00, '2023-01-01', '2024-12-31', 'Active'),
(1, 'Loan Protection', 80000.00, '2023-02-10', '2025-02-10', 'Active'),
(2, 'Health', 200000.00, '2023-03-01', '2024-03-01', 'Active'),
(3, 'Property', 250000.00, '2022-07-15', '2023-07-15', 'Expired'),
(4, 'Accident', 120000.00, '2023-05-01', '2024-05-01', 'Active');

-- Insert 5 Claims
INSERT INTO Claim (PolicyID, DateFiled, AmountClaimed, Status) VALUES
(1, '2023-09-15', 1000000.00, 'Approved'),
(2, '2023-10-20', 500000.00, 'Settled'),
(3, '2023-08-10', 750000.00, 'Pending'),
(4, '2023-07-05', 1500000.00, 'Rejected'),
(5, '2023-11-01', 800000.00, 'Settled');

-- Insert 5 Payments (each references unique ClaimID for 1:1 relationship)
INSERT INTO Payment (ClaimID, Amount, PaymentDate, Method) VALUES
(1, 1000000.00, '2023-12-01', 'Bank Transfer'),
(2, 500000.00, '2023-11-05', 'Mobile Money'),
(3, 750000.00, '2023-12-10', 'Direct Deposit'),
(4, 1500000.00, '2023-12-15', 'Bank Transfer'),
(5, 800000.00, '2023-11-15', 'Mobile Money');

-- ============================================================================
-- STEP 4: CREATE VIEWS
-- ============================================================================

-- View 1: Monthly Premium Collection
CREATE VIEW vw_MonthlyPremiumCollection AS
SELECT 
    EXTRACT(YEAR FROM ip.StartDate) AS Year,
    EXTRACT(MONTH FROM ip.StartDate) AS Month,
    TO_CHAR(ip.StartDate, 'Month YYYY') AS MonthYear,
    COUNT(ip.PolicyID) AS TotalPolicies,
    COUNT(DISTINCT ip.MemberID) AS UniqueMembersInsured,
    SUM(ip.Premium) AS TotalPremiumCollected,
    AVG(ip.Premium) AS AveragePremium,
    MIN(ip.Premium) AS MinimumPremium,
    MAX(ip.Premium) AS MaximumPremium,
    STRING_AGG(DISTINCT ip.Type, ', ') AS PolicyTypes
FROM 
    InsurancePolicy ip
WHERE 
    ip.Status IN ('Active', 'Expired')
GROUP BY 
    EXTRACT(YEAR FROM ip.StartDate),
    EXTRACT(MONTH FROM ip.StartDate),
    TO_CHAR(ip.StartDate, 'Month YYYY')
ORDER BY 
    Year DESC, Month DESC;

-- View 2: Monthly Premium Summary
CREATE VIEW vw_MonthlyPremiumSummary AS
SELECT 
    TO_CHAR(ip.StartDate, 'YYYY-MM') AS YearMonth,
    TO_CHAR(ip.StartDate, 'Month YYYY') AS Period,
    COUNT(ip.PolicyID) AS PoliciesIssued,
    SUM(ip.Premium) AS TotalPremium,
    AVG(ip.Premium) AS AvgPremium,
    ROUND(
        (SUM(ip.Premium) * 100.0 / 
        SUM(SUM(ip.Premium)) OVER ()), 2
    ) AS PercentageOfTotal
FROM 
    InsurancePolicy ip
WHERE 
    ip.Status IN ('Active', 'Expired')
GROUP BY 
    TO_CHAR(ip.StartDate, 'YYYY-MM'),
    TO_CHAR(ip.StartDate, 'Month YYYY')
ORDER BY 
    YearMonth DESC;

-- View 3: Yearly Premium Comparison
CREATE VIEW vw_YearlyPremiumComparison AS
SELECT 
    EXTRACT(YEAR FROM ip.StartDate) AS Year,
    COUNT(ip.PolicyID) AS TotalPolicies,
    SUM(ip.Premium) AS TotalPremium,
    AVG(ip.Premium) AS AveragePremium,
    COUNT(DISTINCT ip.MemberID) AS UniqueMembers
FROM 
    InsurancePolicy ip
GROUP BY 
    EXTRACT(YEAR FROM ip.StartDate)
ORDER BY 
    Year DESC;

-- ============================================================================
-- STEP 5: CREATE TRIGGER FOR AUTO-EXPIRING POLICIES
-- ============================================================================

-- Create trigger function
CREATE OR REPLACE FUNCTION fn_AutoExpirePolicy()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.EndDate <= CURRENT_DATE AND NEW.Status = 'Active' THEN
        NEW.Status := 'Expired';
        RAISE NOTICE 'Policy % for Member % has been automatically expired on %', 
                     NEW.PolicyID, NEW.MemberID, CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
CREATE TRIGGER trg_AutoExpirePolicy
BEFORE INSERT OR UPDATE ON InsurancePolicy
FOR EACH ROW
EXECUTE FUNCTION fn_AutoExpirePolicy();

-- Create stored procedure for batch expiration
CREATE OR REPLACE FUNCTION sp_ExpireOldPolicies()
RETURNS TABLE(
    PolicyID INT,
    MemberID INT,
    PolicyType VARCHAR,
    EndDate DATE,
    OldStatus VARCHAR,
    NewStatus VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    UPDATE InsurancePolicy ip
    SET Status = 'Expired'
    WHERE ip.EndDate < CURRENT_DATE 
      AND ip.Status = 'Active'
    RETURNING 
        ip.PolicyID,
        ip.MemberID,
        ip.Type,
        ip.EndDate,
        'Active'::VARCHAR AS OldStatus,
        ip.Status AS NewStatus;
END;
$$ LANGUAGE plpgsql;

-- Commit transaction
COMMIT;

-- ============================================================================
-- VERIFICATION: Display record counts
-- ============================================================================
SELECT 'DATA INSERTION VERIFICATION' AS Status;

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

SELECT 'SETUP COMPLETE - All tables, data, views, and triggers created successfully!' AS Status;
