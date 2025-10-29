-- ============================================================================
-- Task A1: Node B Schema & Data
-- Execute this script while connected to telco_node_b database
-- ============================================================================

-- Create CDR_B table (holds records where MOD(SimID, 2) = 1)
CREATE TABLE CDR_B (
    CdrID SERIAL PRIMARY KEY,
    SimID INT NOT NULL,
    CallType VARCHAR(20) NOT NULL CHECK (CallType IN ('Voice', 'SMS', 'Data')),
    CallDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Duration INT,
    Charge NUMERIC(10,2) NOT NULL,
    DestinationNumber VARCHAR(15),
    CONSTRAINT chk_simid_odd CHECK (MOD(SimID, 2) = 1)
);

COMMENT ON TABLE CDR_B IS 'Call Detail Records - Node B (Odd SimID via horizontal fragmentation)';

-- Create Subscriber table for later tasks
CREATE TABLE Subscriber (
    SubscriberID SERIAL PRIMARY KEY,
    FullName VARCHAR(100) NOT NULL,
    NationalID VARCHAR(16) UNIQUE,
    District VARCHAR(50),
    RegistrationDate DATE DEFAULT CURRENT_DATE
);

COMMENT ON TABLE Subscriber IS 'Subscriber master data for Rwanda Telco';

-- Create SIM table for later tasks
CREATE TABLE SIM (
    SimID INT PRIMARY KEY,
    SubscriberID INT REFERENCES Subscriber(SubscriberID),
    PhoneNumber VARCHAR(15) UNIQUE NOT NULL,
    ActivationDate DATE DEFAULT CURRENT_DATE,
    Status VARCHAR(20) DEFAULT 'Active' CHECK (Status IN ('Active', 'Suspended', 'Deactivated'))
);

COMMENT ON TABLE SIM IS 'SIM card inventory';

-- Insert sample data into CDR_B (5 rows with odd SimID)
INSERT INTO CDR_B (SimID, CallType, CallDate, Duration, Charge, DestinationNumber) VALUES
(1001, 'Voice', '2025-01-15 08:00:00', 240, 600.00, '+250788111222'),
(1003, 'Data', '2025-01-15 09:30:00', 1024, 2400.00, NULL),
(1005, 'SMS', '2025-01-15 12:00:00', 1, 50.00, '+250788222333'),
(1007, 'Voice', '2025-01-15 13:45:00', 420, 1050.00, '+250788333444'),
(1009, 'Data', '2025-01-15 15:30:00', 256, 600.00, NULL);

-- Insert sample Subscriber data
INSERT INTO Subscriber (FullName, NationalID, District, RegistrationDate) VALUES
('Uwase Marie', '1198780012345678', 'Kigali', '2024-01-10'),
('Mugisha Jean', '1199085023456789', 'Musanze', '2024-02-15'),
('Mukamana Grace', '1198990034567890', 'Rubavu', '2024-03-20');

-- Insert sample SIM data
INSERT INTO SIM (SimID, SubscriberID, PhoneNumber, ActivationDate, Status) VALUES
(1001, 1, '+250788111222', '2024-01-11', 'Active'),
(1003, 2, '+250788222333', '2024-02-16', 'Active'),
(1005, 3, '+250788333444', '2024-03-21', 'Active');

-- Verification query
SELECT 
    'Node B' AS Node,
    COUNT(*) AS RowCount,
    SUM(MOD(CdrID, 97)) AS Checksum,
    MIN(SimID) AS MinSimID,
    MAX(SimID) AS MaxSimID
FROM CDR_B;
