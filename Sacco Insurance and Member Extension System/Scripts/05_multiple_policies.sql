-- ============================================================================
-- TASK 5: IDENTIFY MEMBERS WITH MULTIPLE INSURANCE POLICIES
-- Lists Rwandan SACCO members who have more than one insurance policy
-- ============================================================================

-- Basic query showing members with multiple policies
SELECT 
    m.MemberID,
    m.FullName,
    m.Contact,
    m.Address AS Location,
    COUNT(ip.PolicyID) AS TotalPolicies,
    TO_CHAR(SUM(ip.Premium), 'FML999,999,999') || ' RWF' AS TotalPremiumAmount,
    STRING_AGG(ip.Type, ', ' ORDER BY ip.Type) AS PolicyTypes
FROM 
    Member m
INNER JOIN 
    InsurancePolicy ip ON m.MemberID = ip.MemberID
GROUP BY 
    m.MemberID, m.FullName, m.Contact, m.Address
HAVING 
    COUNT(ip.PolicyID) > 1
ORDER BY 
    TotalPolicies DESC, m.FullName;

-- Detailed query with policy breakdown for Rwandan context
SELECT 
    m.MemberID,
    m.FullName,
    m.Gender,
    m.Contact,
    m.Address AS Location,
    m.JoinDate,
    COUNT(ip.PolicyID) AS TotalPolicies,
    COUNT(CASE WHEN ip.Status = 'Active' THEN 1 END) AS ActivePolicies,
    COUNT(CASE WHEN ip.Status = 'Expired' THEN 1 END) AS ExpiredPolicies,
    TO_CHAR(SUM(ip.Premium), 'FML999,999,999') || ' RWF' AS TotalAnnualPremium,
    STRING_AGG(
        ip.Type || ' (' || ip.Status || ')', 
        ', ' 
        ORDER BY ip.StartDate DESC
    ) AS PolicyDetails
FROM 
    Member m
INNER JOIN 
    InsurancePolicy ip ON m.MemberID = ip.MemberID
GROUP BY 
    m.MemberID, m.FullName, m.Gender, m.Contact, m.Address, m.JoinDate
HAVING 
    COUNT(ip.PolicyID) > 1
ORDER BY 
    TotalPolicies DESC;

-- Members with multiple active policies only
SELECT 
    m.MemberID,
    m.FullName,
    m.Address AS Location,
    COUNT(ip.PolicyID) AS ActivePoliciesCount,
    ARRAY_AGG(ip.Type ORDER BY ip.Type) AS ActivePolicyTypes,
    TO_CHAR(SUM(ip.Premium), 'FML999,999,999') || ' RWF' AS TotalActivePremium
FROM 
    Member m
INNER JOIN 
    InsurancePolicy ip ON m.MemberID = ip.MemberID
WHERE 
    ip.Status = 'Active'
GROUP BY 
    m.MemberID, m.FullName, m.Address
HAVING 
    COUNT(ip.PolicyID) > 1
ORDER BY 
    ActivePoliciesCount DESC;
