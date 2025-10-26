-- ============================================
-- Query: Officers Issuing the Most Fines
-- Identifies most active officers and their violation statistics
-- ============================================

SELECT 
    o.OfficerID,
    o.FullName AS OfficerName,
    o.Station,
    o.BadgeNo,
    COUNT(v.ViolationID) AS TotalViolationsIssued,
    SUM(v.Penalty) AS TotalPenaltiesIssued,
    COUNT(CASE WHEN f.Status = 'Paid' THEN 1 END) AS PaidFines,
    COUNT(CASE WHEN f.Status = 'Unpaid' THEN 1 END) AS UnpaidFines,
    COUNT(CASE WHEN f.Status = 'Overdue' THEN 1 END) AS OverdueFines
FROM 
    Officer o
    INNER JOIN Violation v ON o.OfficerID = v.OfficerID
    INNER JOIN Fine f ON v.ViolationID = f.ViolationID
GROUP BY 
    o.OfficerID, o.FullName, o.Station, o.BadgeNo
ORDER BY 
    TotalViolationsIssued DESC, TotalPenaltiesIssued DESC;

-- Additional query: Breakdown by violation type per officer
SELECT 
    o.FullName AS OfficerName,
    v.Type AS ViolationType,
    COUNT(*) AS ViolationCount,
    SUM(v.Penalty) AS TotalPenalty
FROM 
    Officer o
    INNER JOIN Violation v ON o.OfficerID = v.OfficerID
GROUP BY 
    o.FullName, v.Type
ORDER BY 
    o.FullName, ViolationCount DESC;
