-- ============================================
-- Smart Traffic Violation Monitoring System
-- Sample Data Insertion Script
-- Rwandan Context: Cities, Names, and Plate Numbers
-- ============================================

-- ============================================
-- Insert Officers
-- ============================================
INSERT INTO Officer (FullName, Station, BadgeNo, Contact) VALUES
('Jean Paul Mugabo', 'Kigali Central Police Station', 'RNP-001', '+250788123456'),
('Marie Claire Uwase', 'Huye District Police', 'RNP-002', '+250788234567'),
('Eric Niyonzima', 'Rubavu Border Police', 'RNP-003', '+250788345678'),
('Grace Mukamana', 'Musanze Traffic Unit', 'RNP-004', '+250788456789'),
('Patrick Habimana', 'Kigali Highway Patrol', 'RNP-005', '+250788567890');

-- ============================================
-- Insert Drivers
-- ============================================
INSERT INTO Driver (FullName, LicenseNo, Contact, City) VALUES
('Innocent Kamanzi', 'RW-DL-2020-001', '+250788111222', 'Kigali'),
('Claudine Uwimana', 'RW-DL-2019-045', '+250788222333', 'Huye'),
('David Nsabimana', 'RW-DL-2021-089', '+250788333444', 'Rubavu'),
('Esperance Mukeshimana', 'RW-DL-2018-123', '+250788444555', 'Musanze'),
('Joseph Nkurunziza', 'RW-DL-2022-067', '+250788555666', 'Kigali'),
('Angelique Uwera', 'RW-DL-2020-234', '+250788666777', 'Kigali'),
('Emmanuel Bizimana', 'RW-DL-2019-178', '+250788777888', 'Huye'),
('Francine Mutesi', 'RW-DL-2021-456', '+250788888999', 'Rubavu');

-- ============================================
-- Insert Vehicles
-- ============================================
INSERT INTO Vehicle (DriverID, PlateNo, Type, Status) VALUES
(1, 'RAD-123A', 'Sedan', 'Active'),
(2, 'RAB-456B', 'SUV', 'Active'),
(3, 'RAC-789C', 'Motorcycle', 'Active'),
(4, 'RAD-234D', 'Truck', 'Active'),
(5, 'RAE-567E', 'Sedan', 'Active'),
(6, 'RAF-890F', 'Minibus', 'Active'),
(7, 'RAG-123G', 'Sedan', 'Suspended'),
(8, 'RAH-456H', 'SUV', 'Active'),
(1, 'RAI-789I', 'Motorcycle', 'Active');

-- ============================================
-- Insert Violations
-- ============================================
INSERT INTO Violation (VehicleID, OfficerID, Date, Type, Penalty, Status) VALUES
(1, 1, '2025-01-15 10:30:00', 'Speeding (80km/h in 50km/h zone)', 50000, 'Pending'),
(2, 2, '2025-01-18 14:20:00', 'Running Red Light', 30000, 'Pending'),
(3, 3, '2025-01-20 09:15:00', 'No Helmet', 20000, 'Paid'),
(4, 4, '2025-01-22 16:45:00', 'Overloading', 100000, 'Pending'),
(5, 5, '2025-01-25 11:00:00', 'Drunk Driving', 150000, 'Pending'),
(6, 1, '2025-02-01 08:30:00', 'Illegal Parking', 15000, 'Paid'),
(7, 2, '2025-02-05 13:20:00', 'Driving Without License', 200000, 'Pending'),
(8, 3, '2025-02-08 15:40:00', 'Using Phone While Driving', 25000, 'Pending'),
(1, 1, '2025-02-10 10:00:00', 'Illegal Overtaking', 40000, 'Pending'),
(9, 4, '2025-02-12 12:30:00', 'No Reflective Vest', 10000, 'Pending'),
(5, 5, '2025-02-15 17:00:00', 'Speeding (100km/h in 60km/h zone)', 75000, 'Pending'),
(1, 2, '2025-02-18 09:45:00', 'Reckless Driving', 120000, 'Pending');

-- ============================================
-- Insert Fines
-- ============================================
INSERT INTO Fine (ViolationID, Amount, Status, DueDate) VALUES
(1, 50000, 'Unpaid', '2025-02-15'),
(2, 30000, 'Unpaid', '2025-02-18'),
(3, 20000, 'Paid', '2025-02-20'),
(4, 100000, 'Unpaid', '2025-02-22'),
(5, 150000, 'Unpaid', '2025-02-25'),
(6, 15000, 'Paid', '2025-03-01'),
(7, 200000, 'Overdue', '2025-02-10'),
(8, 25000, 'Unpaid', '2025-03-08'),
(9, 40000, 'Unpaid', '2025-03-10'),
(10, 10000, 'Unpaid', '2025-03-12'),
(11, 75000, 'Unpaid', '2025-03-15'),
(12, 120000, 'Unpaid', '2025-03-18');

-- ============================================
-- Insert Payments (for paid fines)
-- ============================================
INSERT INTO Payment (FineID, Amount, PaymentDate, Method) VALUES
(3, 20000, '2025-01-25 10:00:00', 'Mobile Money'),
(6, 15000, '2025-02-03 14:30:00', 'Mobile Money');

-- Success message
SELECT 'Sample data inserted successfully!' AS status;
SELECT 'Officers: 5, Drivers: 8, Vehicles: 9, Violations: 12, Fines: 12, Payments: 2' AS summary;
