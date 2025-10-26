-- ============================================
-- View: Penalties Summary by City
-- Provides comprehensive statistics of violations and fines by city
-- ============================================

CREATE OR REPLACE VIEW vw_penalties_by_city AS
SELECT 
    d.City,
    COUNT(DISTINCT d.DriverID) AS TotalDrivers,
    COUNT(v.ViolationID) AS TotalViolations,
    SUM(v.Penalty) AS TotalPenalties,
    COUNT(CASE WHEN f.Status = 'Paid' THEN 1 END) AS PaidFines,
    COUNT(CASE WHEN f.Status = 'Unpaid' THEN 1 END) AS UnpaidFines,
    COUNT(CASE WHEN f.Status = 'Overdue' THEN 1 END) AS OverdueFines,
    SUM(CASE WHEN f.Status = 'Paid' THEN f.Amount ELSE 0 END) AS TotalPaidAmount,
    SUM(CASE WHEN f.Status IN ('Unpaid', 'Overdue') THEN f.Amount ELSE 0 END) AS TotalUnpaidAmount,
    ROUND(
        (COUNT(CASE WHEN f.Status = 'Paid' THEN 1 END)::DECIMAL / 
         NULLIF(COUNT(f.FineID), 0) * 100), 2
    ) AS PaymentComplianceRate
FROM 
    Driver d
    INNER JOIN Vehicle v ON d.DriverID = v.DriverID
    INNER JOIN Violation vl ON v.VehicleID = vl.VehicleID
    INNER JOIN Fine f ON vl.ViolationID = f.ViolationID
GROUP BY 
    d.City
ORDER BY 
    TotalPenalties DESC;

-- Query the view
SELECT * FROM vw_penalties_by_city;

-- Additional view: Most common violations by city
CREATE OR REPLACE VIEW vw_common_violations_by_city AS
SELECT 
    d.City,
    v.Type AS ViolationType,
    COUNT(*) AS ViolationCount,
    SUM(v.Penalty) AS TotalPenalty,
    ROUND(AVG(v.Penalty), 2) AS AvgPenalty
FROM 
    Driver d
    INNER JOIN Vehicle ve ON d.DriverID = ve.DriverID
    INNER JOIN Violation v ON ve.VehicleID = v.VehicleID
GROUP BY 
    d.City, v.Type
ORDER BY 
    d.City, ViolationCount DESC;

-- Query the view
SELECT * FROM vw_common_violations_by_city;
