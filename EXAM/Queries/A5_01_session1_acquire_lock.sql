-- ============================================================================
-- Task A5: Distributed Lock Conflict
-- Session 1: Acquire lock on Subscriber row
-- Execute this in Query Tool Window #1 on telco_node_a database
-- ============================================================================

-- Start transaction and acquire lock
DO $$
DECLARE
    rec RECORD;
BEGIN
    -- Start transaction and acquire lock
    RAISE NOTICE '=== SESSION 1: Acquiring Lock ===';
    RAISE NOTICE 'Timestamp: %', CURRENT_TIMESTAMP;

    -- Lock the row
    SELECT SubscriberID, FullName, District, pg_backend_pid() AS SessionPID
    INTO rec
    FROM Subscriber
    WHERE SubscriberID = 1
    FOR UPDATE;

    RAISE NOTICE 'Lock acquired on Subscriber ID 1';
    RAISE NOTICE 'Session PID: %', pg_backend_pid();
    RAISE NOTICE 'Lock Type: ROW EXCLUSIVE (FOR UPDATE)';
    RAISE NOTICE '';
    RAISE NOTICE 'This session will hold the lock for 30 seconds...';
    RAISE NOTICE 'Now run Session 2 script in another Query Tool window';
    RAISE NOTICE '';

    -- Hold the lock
    PERFORM pg_sleep(30);

    RAISE NOTICE 'Lock held for 30 seconds';
    RAISE NOTICE 'Committing transaction and releasing lock...';
END $$;

-- Transaction commits automatically at end of DO block
DO $$
BEGIN
    RAISE NOTICE '=== SESSION 1: Lock Released ===';
END $$;