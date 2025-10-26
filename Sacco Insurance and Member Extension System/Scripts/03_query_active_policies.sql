-- ============================================================================
-- TASK 3: RETRIEVE ALL ACTIVE INSURANCE POLICIES
-- Shows policy details for Rwandan SACCO members
-- ============================================================================

SELECT 
    ip.PolicyID,
    m.MemberID,
    m.FullName AS MemberName,
    m.Contact,
    ip.Type AS PolicyType,
    TO_CHAR(ip.Premium, 'FML999,999,999') || ' RWF' AS Premium,
    ip.StartDate,
    ip.EndDate,
    ip.Status,
    EXTRACT(YEAR FROM AGE(ip.EndDate, ip.StartDate)) * 12 + 
    EXTRACT(MONTH FROM AGE(ip.EndDate, ip.StartDate)) AS DurationMonths
FROM 
    InsurancePolicy ip
INNER JOIN 
    Member m ON ip.MemberID = m.MemberID
WHERE 
    ip.Status = 'Active'
ORDER BY 
    ip.StartDate DESC;

-- Alternative query with Rwandan context details
SELECT 
    ip.PolicyID,
    m.FullName AS MemberName,
    m.Address AS Location,
    ip.Type,
    TO_CHAR(ip.Premium, 'FML999,999,999') || ' RWF' AS AnnualPremium,
    TO_CHAR(ip.StartDate, 'DD-Mon-YYYY') AS StartDate,
    TO_CHAR(ip.EndDate, 'DD-Mon-YYYY') AS EndDate,
    CASE 
        WHEN ip.EndDate < CURRENT_DATE THEN 'Expired (Update Needed)'
        WHEN ip.EndDate <= CURRENT_DATE + INTERVAL '30 days' THEN 'Expiring Soon'
        ELSE 'Active'
    END AS PolicyHealth
FROM 
    InsurancePolicy ip
INNER JOIN 
    Member m ON ip.MemberID = m.MemberID
WHERE 
    ip.Status = 'Active';
