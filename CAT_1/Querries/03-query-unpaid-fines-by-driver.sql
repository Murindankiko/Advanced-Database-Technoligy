-- ============================================
-- Query: Total Unpaid Fines by Driver
-- Retrieves drivers with unpaid fines and total amounts
-- ============================================

SELECT 
    d.DriverID,
    d.FullName AS DriverName,
    d.LicenseNo,
    d.City,
    COUNT(f.FineID) AS UnpaidFineCount,
    SUM(f.Amount) AS TotalUnpaidAmount
FROM 
    Driver d
    INNER JOIN Vehicle v ON d.DriverID = v.DriverID
    INNER JOIN Violation vl ON v.VehicleID = vl.VehicleID
    INNER JOIN Fine f ON vl.ViolationID = f.ViolationID
WHERE 
    f.Status IN ('Unpaid', 'Overdue')
GROUP BY 
    d.DriverID, d.FullName, d.LicenseNo, d.City
ORDER BY 
    TotalUnpaidAmount DESC;

-- Additional query: Show details of unpaid fines
SELECT 
    d.FullName AS DriverName,
    v.PlateNo,
    vl.Type AS ViolationType,
    vl.Date AS ViolationDate,
    f.Amount,
    f.Status,
    f.DueDate
FROM 
    Driver d
    INNER JOIN Vehicle v ON d.DriverID = v.DriverID
    INNER JOIN Violation vl ON v.VehicleID = vl.VehicleID
    INNER JOIN Fine f ON vl.ViolationID = f.ViolationID
WHERE 
    f.Status IN ('Unpaid', 'Overdue')
ORDER BY 
    d.FullName, vl.Date DESC;
