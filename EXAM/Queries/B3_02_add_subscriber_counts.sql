-- ============================================================================
-- Task B8: Add subscriber counts to plans
-- Execute on telco_node_a database
-- ============================================================================

-- Add SubscriberCount column
ALTER TABLE PLAN_TREE
    ADD COLUMN SubscriberCount INT DEFAULT 0;

-- Simulate subscriber distribution (only leaf plans have subscribers)
UPDATE PLAN_TREE SET SubscriberCount = 150 WHERE PlanID = 11; -- Youth Plus
UPDATE PLAN_TREE SET SubscriberCount = 80 WHERE PlanID = 12;  -- Basic Starter
UPDATE PLAN_TREE SET SubscriberCount = 120 WHERE PlanID = 13; -- Data Max
UPDATE PLAN_TREE SET SubscriberCount = 200 WHERE PlanID = 21; -- Business Pro
UPDATE PLAN_TREE SET SubscriberCount = 300 WHERE PlanID = 22; -- Family Bundle
UPDATE PLAN_TREE SET SubscriberCount = 50 WHERE PlanID = 23;  -- Enterprise Elite

-- View updated data
SELECT 
    'Plans with Subscriber Counts' AS Report,
    PlanID,
    PlanName,
    ParentPlanID,
    Level,
    SubscriberCount,
    MonthlyFee_RWF
FROM PLAN_TREE
ORDER BY Level, PlanID;
