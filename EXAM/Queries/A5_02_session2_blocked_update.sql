-- ============================================================================
-- Task A5: Distributed Lock Conflict
-- Session 2: Attempt to update locked row (will be blocked)
-- Execute in Query Tool Window #2 on telco_node_a database
-- IMPORTANT: Run this WHILE Session 1 is still holding the lock
-- ============================================================================

-- Step 1: Log the attempt (runs immediately)
DO $$
BEGIN
    RAISE NOTICE '=== SESSION 2: Attempting Update ===';
    RAISE NOTICE 'Timestamp: %', CURRENT_TIMESTAMP;
    RAISE NOTICE 'Session PID: %', pg_backend_pid();
    RAISE NOTICE '';
    RAISE NOTICE 'Attempting to update Subscriber ID 1...';
    RAISE NOTICE 'This will BLOCK until Session 1 releases the lock';
    RAISE NOTICE '';
END $$;

-- Step 2: The actual blocking update (run this separately!)
BEGIN;

UPDATE Subscriber
SET District = 'Musanze_Updated'
WHERE SubscriberID = 1;

-- This runs only AFTER the lock is released
DO $$
BEGIN
    RAISE NOTICE 'Update successful! Lock was released by Session 1';
    RAISE NOTICE 'New District value: Musanze_Updated';
END $$;

COMMIT;

-- Final confirmation
DO $$
BEGIN
    RAISE NOTICE '=== SESSION 2: Update Complete ===';
END $$;