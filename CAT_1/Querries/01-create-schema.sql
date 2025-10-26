-- ============================================
-- Smart Traffic Violation Monitoring System
-- Database: SmartTrafficRwandaDB
-- PostgreSQL Schema Creation Script
-- ============================================

-- Drop existing tables if they exist (for clean setup)
DROP TABLE IF EXISTS Payment CASCADE;
DROP TABLE IF EXISTS Fine CASCADE;
DROP TABLE IF EXISTS Violation CASCADE;
DROP TABLE IF EXISTS Vehicle CASCADE;
DROP TABLE IF EXISTS Driver CASCADE;
DROP TABLE IF EXISTS Officer CASCADE;

-- ============================================
-- Table: Officer
-- Stores traffic police officer information
-- ============================================
CREATE TABLE Officer (
    OfficerID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    Station VARCHAR(100) NOT NULL,
    BadgeNo VARCHAR(20) UNIQUE NOT NULL,
    Contact VARCHAR(15) NOT NULL,
    CONSTRAINT chk_officer_contact CHECK (Contact ~ '^\+?[0-9]{10,15}$')
);

-- ============================================
-- Table: Driver
-- Stores driver information and license details
-- ============================================
CREATE TABLE Driver (
    DriverID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    LicenseNo VARCHAR(20) UNIQUE NOT NULL,
    Contact VARCHAR(15) NOT NULL,
    City VARCHAR(50) NOT NULL,
    OffenseCount INT DEFAULT 0,
    IsFlagged BOOLEAN DEFAULT FALSE,
    CONSTRAINT chk_driver_contact CHECK (Contact ~ '^\+?[0-9]{10,15}$'),
    CONSTRAINT chk_offense_count CHECK (OffenseCount >= 0)
);

-- ============================================
-- Table: Vehicle
-- Stores vehicle information linked to drivers
-- Relationship: Driver → Vehicle (1:N)
-- ============================================
CREATE TABLE Vehicle (
    VehicleID SERIAL PRIMARY KEY,
    DriverID INT NOT NULL,
    PlateNo VARCHAR(20) UNIQUE NOT NULL,
    Type VARCHAR(50) NOT NULL,
    Status VARCHAR(20) DEFAULT 'Active',
    CONSTRAINT fk_vehicle_driver FOREIGN KEY (DriverID) 
        REFERENCES Driver(DriverID) ON DELETE CASCADE,
    CONSTRAINT chk_vehicle_status CHECK (Status IN ('Active', 'Suspended', 'Impounded'))
);

-- ============================================
-- Table: Violation
-- Records traffic violations
-- Relationships: Vehicle → Violation (1:N), Officer → Violation (1:N)
-- ============================================
CREATE TABLE Violation (
    ViolationID SERIAL PRIMARY KEY,
    VehicleID INT NOT NULL,
    OfficerID INT NOT NULL,
    Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Type VARCHAR(100) NOT NULL,
    Penalty DECIMAL(10, 2) NOT NULL,
    Status VARCHAR(20) DEFAULT 'Pending',
    CONSTRAINT fk_violation_vehicle FOREIGN KEY (VehicleID) 
        REFERENCES Vehicle(VehicleID) ON DELETE CASCADE,
    CONSTRAINT fk_violation_officer FOREIGN KEY (OfficerID) 
        REFERENCES Officer(OfficerID) ON DELETE CASCADE,
    CONSTRAINT chk_penalty CHECK (Penalty > 0),
    CONSTRAINT chk_violation_status CHECK (Status IN ('Pending', 'Paid', 'Overdue'))
);

-- ============================================
-- Table: Fine
-- Stores fine details for violations
-- Relationship: Violation → Fine (1:1) with CASCADE DELETE
-- ============================================
CREATE TABLE Fine (
    FineID SERIAL PRIMARY KEY,
    ViolationID INT UNIQUE NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    Status VARCHAR(20) DEFAULT 'Unpaid',
    DueDate DATE NOT NULL,
    CONSTRAINT fk_fine_violation FOREIGN KEY (ViolationID) 
        REFERENCES Violation(ViolationID) ON DELETE CASCADE,
    CONSTRAINT chk_fine_amount CHECK (Amount > 0),
    CONSTRAINT chk_fine_status CHECK (Status IN ('Unpaid', 'Paid', 'Overdue'))
);

-- ============================================
-- Table: Payment
-- Records payment transactions for fines
-- Relationship: Fine → Payment (1:1)
-- ============================================
CREATE TABLE Payment (
    PaymentID SERIAL PRIMARY KEY,
    FineID INT UNIQUE NOT NULL,
    Amount DECIMAL(10, 2) NOT NULL,
    PaymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Method VARCHAR(50) NOT NULL,
    CONSTRAINT fk_payment_fine FOREIGN KEY (FineID) 
        REFERENCES Fine(FineID) ON DELETE CASCADE,
    CONSTRAINT chk_payment_amount CHECK (Amount > 0),
    CONSTRAINT chk_payment_method CHECK (Method IN ('Cash', 'Mobile Money', 'Bank Transfer', 'Card'))
);

-- ============================================
-- Create Indexes for Performance
-- ============================================
CREATE INDEX idx_vehicle_driver ON Vehicle(DriverID);
CREATE INDEX idx_violation_vehicle ON Violation(VehicleID);
CREATE INDEX idx_violation_officer ON Violation(OfficerID);
CREATE INDEX idx_violation_date ON Violation(Date);
CREATE INDEX idx_fine_status ON Fine(Status);
CREATE INDEX idx_driver_city ON Driver(City);

-- Success message
SELECT 'Schema created successfully!' AS status;

