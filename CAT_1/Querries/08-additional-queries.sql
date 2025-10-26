-- ============================================
-- Additional Useful Queries for Smart Traffic System
-- ============================================

-- Query 1: Overdue fines report
SELECT 
    d.FullName AS DriverName,
    d.Contact,
    v.PlateNo,
    vl.Type AS ViolationType,
    f.Amount,
    f.DueDate,
    CURRENT_DATE - f.DueDate AS DaysOverdue
FROM 
    Driver d
    INNER JOIN Vehicle v ON d.DriverID = v.DriverID
    INNER JOIN Violation vl ON v.VehicleID = vl.VehicleID
    INNER JOIN Fine f ON vl.ViolationID = f.ViolationID
WHERE 
    f.Status = 'Overdue'
ORDER BY 
    DaysOverdue DESC;

-- Query 2: Revenue report by payment method
SELECT 
    p.Method AS PaymentMethod,
    COUNT(p.PaymentID) AS TotalPayments,
    SUM(p.Amount) AS TotalRevenue,
    ROUND(AVG(p.Amount), 2) AS AvgPaymentAmount
FROM 
    Payment p
GROUP BY 
    p.Method
ORDER BY 
    TotalRevenue DESC;

-- Query 3: Monthly violation trends
SELECT 
    TO_CHAR(Date, 'YYYY-MM') AS Month,
    COUNT(*) AS TotalViolations,
    SUM(Penalty) AS TotalPenalties,
    ROUND(AVG(Penalty), 2) AS AvgPenalty
FROM 
    Violation
GROUP BY 
    TO_CHAR(Date, 'YYYY-MM')
ORDER BY 
    Month DESC;

-- Query 4: Vehicle status summary
SELECT 
    Status,
    COUNT(*) AS VehicleCount,
    ROUND((COUNT(*)::DECIMAL / (SELECT COUNT(*) FROM Vehicle) * 100), 2) AS Percentage
FROM 
    Vehicle
GROUP BY 
    Status
ORDER BY 
    VehicleCount DESC;

-- Query 5: Top violation types
SELECT 
    Type AS ViolationType,
    COUNT(*) AS ViolationCount,
    SUM(Penalty) AS TotalPenalties,
    ROUND(AVG(Penalty), 2) AS AvgPenalty,
    COUNT(CASE WHEN Status = 'Paid' THEN 1 END) AS PaidCount,
    COUNT(CASE WHEN Status = 'Pending' THEN 1 END) AS PendingCount
FROM 
    Violation
GROUP BY 
    Type
ORDER BY 
    ViolationCount DESC;

-- Query 6: Driver compliance report
SELECT 
    d.DriverID,
    d.FullName,
    d.City,
    d.OffenseCount,
    d.IsFlagged,
    COUNT(f.FineID) AS TotalFines,
    COUNT(CASE WHEN f.Status = 'Paid' THEN 1 END) AS PaidFines,
    COUNT(CASE WHEN f.Status IN ('Unpaid', 'Overdue') THEN 1 END) AS UnpaidFines,
    CASE 
        WHEN COUNT(f.FineID) > 0 THEN
            ROUND((COUNT(CASE WHEN f.Status = 'Paid' THEN 1 END)::DECIMAL / COUNT(f.FineID) * 100), 2)
        ELSE 0
    END AS ComplianceRate
FROM 
    Driver d
    LEFT JOIN Vehicle v ON d.DriverID = v.DriverID
    LEFT JOIN Violation vl ON v.VehicleID = vl.VehicleID
    LEFT JOIN Fine f ON vl.ViolationID = f.ViolationID
GROUP BY 
    d.DriverID, d.FullName, d.City, d.OffenseCount, d.IsFlagged
HAVING 
    COUNT(f.FineID) > 0
ORDER BY 
    ComplianceRate ASC, d.OffenseCount DESC;

-- Query 7: Station performance report
SELECT 
    o.Station,
    COUNT(DISTINCT o.OfficerID) AS TotalOfficers,
    COUNT(v.ViolationID) AS TotalViolations,
    SUM(v.Penalty) AS TotalPenaltiesIssued,
    ROUND(AVG(v.Penalty), 2) AS AvgPenalty
FROM 
    Officer o
    LEFT JOIN Violation v ON o.OfficerID = v.OfficerID
GROUP BY 
    o.Station
ORDER BY 
    TotalViolations DESC;
