-- ============================================================================
-- Task A5: Release Lock and Verify Resolution
-- Execute this after Session 1 commits (or to force release)
-- ============================================================================

-- Check if any locks are still held
SELECT 
    'Remaining Locks Check' AS Report,
    COUNT(*) AS ActiveLocks
FROM pg_locks
WHERE relation = 'subscriber'::regclass;

-- View final state of Subscriber table
SELECT 
    'Final Subscriber State' AS Report,
    SubscriberID,
    FullName,
    District,
    RegistrationDate
FROM Subscriber
WHERE SubscriberID = 1;

-- Optional: Reset the District value for re-testing
UPDATE Subscriber
SET District = 'Kigali'
WHERE SubscriberID = 1;

RAISE NOTICE 'District reset to original value for re-testing';

-- View lock history (if you have pg_stat_statements extension)
-- Uncomment if extension is available:
/*
SELECT 
    'Lock Wait Statistics' AS Report,
    query,
    calls,
    total_time,
    mean_time,
    max_time
FROM pg_stat_statements
WHERE query LIKE '%Subscriber%'
ORDER BY total_time DESC
LIMIT 5;
*/
