-- ============================================================================
-- BONUS QUERIES FOR COMPREHENSIVE SYSTEM ANALYSIS - RWANDAN CONTEXT
-- All queries formatted with RWF currency and Rwandan location details
-- ============================================================================

-- 1. Member Portfolio Summary for Rwandan SACCO
SELECT 
    m.MemberID,
    m.FullName,
    m.Address AS Location,
    m.JoinDate,
    COUNT(DISTINCT la.LoanID) AS TotalLoans,
    COALESCE(TO_CHAR(SUM(la.Amount), 'FML999,999,999'), '0') || ' RWF' AS TotalLoanAmount,
    COUNT(DISTINCT ip.PolicyID) AS TotalPolicies,
    COALESCE(TO_CHAR(SUM(ip.Premium), 'FML999,999,999'), '0') || ' RWF' AS TotalPremiums,
    COUNT(DISTINCT c.ClaimID) AS TotalClaims,
    COALESCE(TO_CHAR(SUM(c.AmountClaimed), 'FML999,999,999'), '0') || ' RWF' AS TotalClaimedAmount
FROM 
    Member m
LEFT JOIN LoanAccount la ON m.MemberID = la.MemberID
LEFT JOIN InsurancePolicy ip ON m.MemberID = ip.MemberID
LEFT JOIN Claim c ON ip.PolicyID = c.PolicyID
GROUP BY 
    m.MemberID, m.FullName, m.Address, m.JoinDate
ORDER BY 
    TotalPolicies DESC, TotalLoans DESC;

-- 2. Officer Performance Report across Rwandan branches
SELECT 
    o.OfficerID,
    o.FullName,
    o.Branch AS RwandanBranch,
    o.Role,
    COUNT(la.LoanID) AS LoansManaged,
    TO_CHAR(SUM(la.Amount), 'FML999,999,999') || ' RWF' AS TotalLoanValue,
    TO_CHAR(AVG(la.InterestRate), 'FM99.99') || '%' AS AvgInterestRate
FROM 
    Officer o
LEFT JOIN LoanAccount la ON o.OfficerID = la.OfficerID
GROUP BY 
    o.OfficerID, o.FullName, o.Branch, o.Role
ORDER BY 
    TotalLoanValue DESC NULLS LAST;

-- 3. Claims Settlement Analysis for Rwandan SACCO
SELECT 
    c.Status,
    COUNT(c.ClaimID) AS TotalClaims,
    TO_CHAR(SUM(c.AmountClaimed), 'FML999,999,999') || ' RWF' AS TotalAmountClaimed,
    TO_CHAR(AVG(c.AmountClaimed), 'FML999,999,999') || ' RWF' AS AvgClaimAmount,
    COUNT(p.PaymentID) AS ClaimsPaid,
    COALESCE(TO_CHAR(SUM(p.Amount), 'FML999,999,999'), '0') || ' RWF' AS TotalAmountPaid,
    ROUND(
        (COUNT(p.PaymentID)::NUMERIC / NULLIF(COUNT(c.ClaimID), 0)) * 100, 2
    ) || '%' AS SettlementRate
FROM 
    Claim c
LEFT JOIN Payment p ON c.ClaimID = p.ClaimID
GROUP BY 
    c.Status
ORDER BY 
    TotalClaims DESC;

-- 4. Policy Type Distribution in Rwanda
SELECT 
    Type AS PolicyType,
    COUNT(*) AS TotalPolicies,
    COUNT(CASE WHEN Status = 'Active' THEN 1 END) AS ActivePolicies,
    TO_CHAR(SUM(Premium), 'FML999,999,999') || ' RWF' AS TotalPremiumValue,
    TO_CHAR(AVG(Premium), 'FML999,999,999') || ' RWF' AS AveragePremium,
    ROUND(
        (COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM InsurancePolicy)) * 100, 2
    ) || '%' AS PercentageOfTotal
FROM 
    InsurancePolicy
GROUP BY 
    Type
ORDER BY 
    TotalPolicies DESC;

-- 5. Payment Method Analysis for Rwandan SACCO
SELECT 
    Method AS PaymentMethod,
    COUNT(*) AS TransactionCount,
    TO_CHAR(SUM(Amount), 'FML999,999,999') || ' RWF' AS TotalAmount,
    TO_CHAR(AVG(Amount), 'FML999,999,999') || ' RWF' AS AverageAmount,
    TO_CHAR(MIN(Amount), 'FML999,999,999') || ' RWF' AS MinAmount,
    TO_CHAR(MAX(Amount), 'FML999,999,999') || ' RWF' AS MaxAmount
FROM 
    Payment
GROUP BY 
    Method
ORDER BY 
    TotalAmount DESC;

-- 6. Branch Performance Analysis across Rwanda
SELECT 
    o.Branch AS RwandanBranch,
    COUNT(DISTINCT o.OfficerID) AS TotalOfficers,
    COUNT(DISTINCT la.LoanID) AS TotalLoans,
    TO_CHAR(COALESCE(SUM(la.Amount), 0), 'FML999,999,999') || ' RWF' AS TotalLoanValue,
    COUNT(DISTINCT la.MemberID) AS UniqueBorrowers
FROM 
    Officer o
LEFT JOIN LoanAccount la ON o.OfficerID = la.OfficerID
GROUP BY 
    o.Branch
ORDER BY 
    TotalLoanValue DESC;
