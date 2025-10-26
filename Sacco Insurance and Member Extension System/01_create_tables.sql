-- ============================================================================
-- SACCO INSURANCE AND MEMBER EXTENSION SYSTEM - RWANDA
-- Database: sacco
-- DBMS: PostgreSQL (pgAdmin 4)
-- Context: This SACCO operates in Rwanda, serving members across multiple branches
-- ============================================================================

-- Create the database (run this separately if needed)
-- CREATE DATABASE sacco;

-- Connect to the sacco database before running the following scripts
-- \c sacco

-- Add database comment indicating Rwandan context
COMMENT ON DATABASE sacco IS 'SACCO Insurance and Member Extension System operating in Rwanda';

-- ============================================================================
-- TABLE 1: Member
-- Stores member profile information for Rwandan SACCO members
-- ============================================================================
CREATE TABLE Member (
    MemberID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Gender CHAR(1) CHECK (Gender IN ('M', 'F', 'O')),
    Contact VARCHAR(15) NOT NULL UNIQUE,
    Address TEXT,
    JoinDate DATE NOT NULL DEFAULT CURRENT_DATE,
    CONSTRAINT chk_contact_format CHECK (Contact ~ '^[0-9+\-() ]+$')
);

-- ============================================================================
-- TABLE 2: Officer
-- Stores SACCO officer information across Rwandan branches
-- ============================================================================
CREATE TABLE Officer (
    OfficerID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Branch VARCHAR(50) NOT NULL,
    Contact VARCHAR(15) NOT NULL UNIQUE,
    Role VARCHAR(50) NOT NULL,
    CONSTRAINT chk_officer_contact CHECK (Contact ~ '^[0-9+\-() ]+$')
);

-- ============================================================================
-- TABLE 3: LoanAccount
-- Tracks loan accounts linked to members and officers
-- ============================================================================
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

-- ============================================================================
-- TABLE 4: InsurancePolicy
-- Stores insurance policy details for Rwandan SACCO members
-- ============================================================================
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

-- ============================================================================
-- TABLE 5: Claim
-- Tracks insurance claims filed by Rwandan SACCO members
-- ============================================================================
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

-- ============================================================================
-- TABLE 6: Payment
-- Records payments made for settled claims
-- ON DELETE CASCADE: When a claim is deleted, its payment is also deleted
-- ============================================================================
CREATE TABLE Payment (
    PaymentID SERIAL PRIMARY KEY,
    ClaimID INT NOT NULL UNIQUE, -- 1:1 relationship with Claim
    Amount DECIMAL(12, 2) NOT NULL CHECK (Amount > 0),
    PaymentDate DATE NOT NULL DEFAULT CURRENT_DATE,
    Method VARCHAR(30) NOT NULL 
        CHECK (Method IN ('Bank Transfer', 'Cheque', 'Cash', 'Mobile Money', 'Direct Deposit')),
    CONSTRAINT fk_payment_claim FOREIGN KEY (ClaimID) 
        REFERENCES Claim(ClaimID) ON DELETE CASCADE
);

-- ============================================================================
-- Create indexes for better query performance
-- ============================================================================
CREATE INDEX idx_loan_member ON LoanAccount(MemberID);
CREATE INDEX idx_loan_officer ON LoanAccount(OfficerID);
CREATE INDEX idx_policy_member ON InsurancePolicy(MemberID);
CREATE INDEX idx_policy_status ON InsurancePolicy(Status);
CREATE INDEX idx_claim_policy ON Claim(PolicyID);
CREATE INDEX idx_claim_status ON Claim(Status);
CREATE INDEX idx_payment_claim ON Payment(ClaimID);

-- ============================================================================
-- Add table comments for Rwandan context
-- ============================================================================
COMMENT ON TABLE Member IS 'Stores SACCO member profile information - Rwanda operations';
COMMENT ON TABLE Officer IS 'Stores SACCO officer details across Rwandan branches';
COMMENT ON TABLE LoanAccount IS 'Tracks member loan accounts in Rwandan Francs (RWF)';
COMMENT ON TABLE InsurancePolicy IS 'Stores insurance policy information for Rwandan members';
COMMENT ON TABLE Claim IS 'Records insurance claims filed by Rwandan SACCO members';
COMMENT ON TABLE Payment IS 'Records payments for settled claims in RWF';
