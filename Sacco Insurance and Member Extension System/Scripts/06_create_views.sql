-- ============================================================================
-- TASK 6: CREATE VIEW - TOTAL PREMIUMS COLLECTED PER MONTH
-- Aggregates premium collection by month and year for Rwandan SACCO
-- All amounts displayed in Rwandan Francs (RWF)
-- ============================================================================

CREATE OR REPLACE VIEW vw_MonthlyPremiumCollection AS
SELECT 
    EXTRACT(YEAR FROM ip.StartDate) AS Year,
    EXTRACT(MONTH FROM ip.StartDate) AS Month,
    TO_CHAR(ip.StartDate, 'Month YYYY') AS MonthYear,
    COUNT(ip.PolicyID) AS TotalPolicies,
    COUNT(DISTINCT ip.MemberID) AS UniqueMembersInsured,
    SUM(ip.Premium) AS TotalPremiumCollected,
    AVG(ip.Premium) AS AveragePremium,
    MIN(ip.Premium) AS MinimumPremium,
    MAX(ip.Premium) AS MaximumPremium,
    STRING_AGG(DISTINCT ip.Type, ', ') AS PolicyTypes
FROM 
    InsurancePolicy ip
WHERE 
    ip.Status IN ('Active', 'Expired')
GROUP BY 
    EXTRACT(YEAR FROM ip.StartDate),
    EXTRACT(MONTH FROM ip.StartDate),
    TO_CHAR(ip.StartDate, 'Month YYYY')
ORDER BY 
    Year DESC, Month DESC;

COMMENT ON VIEW vw_MonthlyPremiumCollection IS 'Monthly premium collection summary for Rwandan SACCO operations';

-- Query the view with RWF formatting
SELECT 
    MonthYear,
    TotalPolicies,
    UniqueMembersInsured,
    TO_CHAR(TotalPremiumCollected, 'FML999,999,999') || ' RWF' AS TotalPremium,
    TO_CHAR(AveragePremium, 'FML999,999,999') || ' RWF' AS AvgPremium,
    PolicyTypes
FROM vw_MonthlyPremiumCollection;

-- Additional view with formatted output for Rwandan context
CREATE OR REPLACE VIEW vw_MonthlyPremiumSummary AS
SELECT 
    TO_CHAR(ip.StartDate, 'YYYY-MM') AS YearMonth,
    TO_CHAR(ip.StartDate, 'Month YYYY') AS Period,
    COUNT(ip.PolicyID) AS PoliciesIssued,
    TO_CHAR(SUM(ip.Premium), 'FML999,999,999') || ' RWF' AS TotalPremium,
    TO_CHAR(AVG(ip.Premium), 'FML999,999,999') || ' RWF' AS AvgPremium,
    ROUND(
        (SUM(ip.Premium) * 100.0 / 
        SUM(SUM(ip.Premium)) OVER ()), 2
    ) AS PercentageOfTotal
FROM 
    InsurancePolicy ip
WHERE 
    ip.Status IN ('Active', 'Expired')
GROUP BY 
    TO_CHAR(ip.StartDate, 'YYYY-MM'),
    TO_CHAR(ip.StartDate, 'Month YYYY')
ORDER BY 
    YearMonth DESC;

COMMENT ON VIEW vw_MonthlyPremiumSummary IS 'Formatted monthly premium summary with RWF currency for Rwanda';

-- Query the summary view
SELECT * FROM vw_MonthlyPremiumSummary;

-- View showing year-over-year comparison for Rwandan operations
CREATE OR REPLACE VIEW vw_YearlyPremiumComparison AS
SELECT 
    EXTRACT(YEAR FROM ip.StartDate) AS Year,
    COUNT(ip.PolicyID) AS TotalPolicies,
    SUM(ip.Premium) AS TotalPremium,
    AVG(ip.Premium) AS AveragePremium,
    COUNT(DISTINCT ip.MemberID) AS UniqueMembers
FROM 
    InsurancePolicy ip
GROUP BY 
    EXTRACT(YEAR FROM ip.StartDate)
ORDER BY 
    Year DESC;

COMMENT ON VIEW vw_YearlyPremiumComparison IS 'Year-over-year premium comparison for Rwandan SACCO';

SELECT 
    Year,
    TotalPolicies,
    TO_CHAR(TotalPremium, 'FML999,999,999') || ' RWF' AS TotalPremium,
    TO_CHAR(AveragePremium, 'FML999,999,999') || ' RWF' AS AvgPremium,
    UniqueMembers
FROM vw_YearlyPremiumComparison;
