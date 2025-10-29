-- ============================================================================
-- Task A5: Diagnose Lock Conflicts
-- Session 3: Monitor locks and blocking relationships
-- Execute this in Query Tool Window #3 WHILE Sessions 1 & 2 are running
-- ============================================================================

RAISE NOTICE '=== LOCK DIAGNOSTICS ===';
RAISE NOTICE 'Timestamp: %', CURRENT_TIMESTAMP;
RAISE NOTICE '';

-- Query 1: View all current locks
SELECT 
    'Current Locks' AS Report,
    locktype,
    database,
    relation::regclass AS table_name,
    page,
    tuple,
    virtualxid,
    transactionid,
    mode,
    granted,
    pid AS session_pid
FROM pg_locks
WHERE relation = 'subscriber'::regclass
   OR locktype = 'transactionid'
ORDER BY granted DESC, pid;

-- Query 2: Identify blocking relationships
SELECT 
    'Blocking Relationships' AS Report,
    blocked_locks.pid AS blocked_pid,
    blocked_activity.usename AS blocked_user,
    blocking_locks.pid AS blocking_pid,
    blocking_activity.usename AS blocking_user,
    blocked_activity.query AS blocked_query,
    blocking_activity.query AS blocking_query,
    blocked_activity.state AS blocked_state,
    blocking_activity.state AS blocking_state
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity 
    ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.database IS NOT DISTINCT FROM blocked_locks.database
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity 
    ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

-- Query 3: Simplified lock wait view
SELECT 
    'Lock Waits Summary' AS Report,
    waiting.pid AS waiting_pid,
    waiting.query AS waiting_query,
    waiting.state AS waiting_state,
    waiting.wait_event_type,
    waiting.wait_event,
    blocker.pid AS blocker_pid,
    blocker.query AS blocker_query,
    blocker.state AS blocker_state
FROM pg_stat_activity waiting
JOIN pg_locks waiting_locks ON waiting.pid = waiting_locks.pid
JOIN pg_locks blocker_locks ON waiting_locks.locktype = blocker_locks.locktype
    AND waiting_locks.database = blocker_locks.database
    AND waiting_locks.relation = blocker_locks.relation
    AND waiting_locks.pid != blocker_locks.pid
JOIN pg_stat_activity blocker ON blocker.pid = blocker_locks.pid
WHERE NOT waiting_locks.granted
  AND blocker_locks.granted
  AND waiting.wait_event_type = 'Lock';

-- Query 4: Active sessions and their locks
SELECT 
    'Active Sessions' AS Report,
    pid,
    usename,
    application_name,
    state,
    wait_event_type,
    wait_event,
    query_start,
    state_change,
    LEFT(query, 100) AS query_preview
FROM pg_stat_activity
WHERE state != 'idle'
  AND pid != pg_backend_pid()
ORDER BY query_start;
