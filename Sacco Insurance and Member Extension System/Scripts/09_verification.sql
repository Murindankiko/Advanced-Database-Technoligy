-- ============================================================================
-- VERIFICATION SCRIPT - RUN THIS TO VERIFY ALL TASKS
-- Confirms all structures and data for Rwandan SACCO system
-- ============================================================================

-- Check table structures
SELECT 
    table_name,
    (SELECT COUNT(*) 
     FROM information_schema.columns 
     WHERE table_name = t.table_name) AS column_count
FROM 
    information_schema.tables t
WHERE 
    table_schema = 'public'
    AND table_type = 'BASE TABLE'
ORDER BY 
    table_name;

-- Check foreign key relationships
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM
    information_schema.table_constraints AS tc
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
    JOIN information_schema.referential_constraints AS rc
      ON rc.constraint_name = tc.constraint_name
WHERE 
    tc.constraint_type = 'FOREIGN KEY'
ORDER BY 
    tc.table_name;

-- Verify ON DELETE CASCADE for Payment → Claim
SELECT
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS references_table,
    rc.delete_rule
FROM
    information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu
      ON ccu.constraint_name = tc.constraint_name
    JOIN information_schema.referential_constraints rc
      ON rc.constraint_name = tc.constraint_name
WHERE
    tc.table_name = 'payment'
    AND tc.constraint_type = 'FOREIGN KEY';

-- Check all views
SELECT 
    table_name AS view_name
FROM 
    information_schema.views
WHERE 
    table_schema = 'public'
ORDER BY 
    table_name;

-- Check all triggers
SELECT 
    trigger_name,
    event_object_table AS table_name,
    action_timing,
    event_manipulation
FROM 
    information_schema.triggers
WHERE 
    trigger_schema = 'public'
ORDER BY 
    event_object_table, trigger_name;

-- Final data count verification for Rwandan SACCO
SELECT 'FINAL DATA VERIFICATION - RWANDA SACCO' AS Report;
SELECT 'Members' AS Entity, COUNT(*) AS Count FROM Member
UNION ALL
SELECT 'Officers', COUNT(*) FROM Officer
UNION ALL
SELECT 'Loan Accounts', COUNT(*) FROM LoanAccount
UNION ALL
SELECT 'Insurance Policies', COUNT(*) FROM InsurancePolicy
UNION ALL
SELECT 'Claims', COUNT(*) FROM Claim
UNION ALL
SELECT 'Payments', COUNT(*) FROM Payment;

-- Verify Rwandan context data
SELECT 'RWANDAN CONTEXT VERIFICATION' AS Report;
SELECT 'Sample Member Names' AS Category, STRING_AGG(FullName, ', ') AS Data
FROM (SELECT FullName FROM Member LIMIT 3) AS sample_members
UNION ALL
SELECT 'Sample Branches', STRING_AGG(DISTINCT Branch, ', ')
FROM Officer
UNION ALL
SELECT 'Phone Format Check', 
       CASE WHEN COUNT(*) = (SELECT COUNT(*) FROM Member WHERE Contact LIKE '+2507%')
            THEN 'All contacts use Rwanda format (+2507...)'
            ELSE 'Some contacts may not use Rwanda format'
       END
FROM Member;
