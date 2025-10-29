-- ============================================================================
-- Task B8: Recursive CTE for Hierarchy Roll-Up
-- Compute aggregated subscriber counts and revenue up the hierarchy
-- Execute on telco_node_a database
-- ============================================================================

-- =======================================================================
-- PART 1: Hierarchical Roll-Up (Subscriber Counts) – SAFE FOR POSTGRES
-- =======================================================================
WITH RECURSIVE PlanHierarchy AS (
    -- Anchor: Start from leaf nodes (no children)
    SELECT 
        PlanID,
        PlanName,
        ParentPlanID,
        Level,
        SubscriberCount,
        MonthlyFee_RWF,
        DataAllowance_MB,
        SubscriberCount AS TotalSubscribers,
        CAST(PlanName AS VARCHAR(200)) AS Path,
        1 AS Depth
    FROM PLAN_TREE
    WHERE PlanID NOT IN (
        SELECT DISTINCT ParentPlanID 
        FROM PLAN_TREE 
        WHERE ParentPlanID IS NOT NULL
    )

    UNION ALL

    -- Recursive: Move up to parent, carry forward sum
    SELECT 
        p.PlanID,
        p.PlanName,
        p.ParentPlanID,
        p.Level,
        p.SubscriberCount,
        p.MonthlyFee_RWF,
        p.DataAllowance_MB,
        p.SubscriberCount + ph.TotalSubscribers AS TotalSubscribers,
        CAST(p.PlanName || ' > ' || ph.Path AS VARCHAR(200)) AS Path,
        ph.Depth + 1 AS Depth
    FROM PLAN_TREE p
    INNER JOIN PlanHierarchy ph ON p.PlanID = ph.ParentPlanID
)
SELECT 
    'Hierarchical Roll-Up' AS Report,
    PlanID,
    PlanName,
    Level,
    SubscriberCount AS DirectSubscribers,
    TotalSubscribers AS TotalIncludingChildren,
    MonthlyFee_RWF,
    REPEAT('  ', Level - 1) || PlanName AS IndentedName,
    Path
FROM PlanHierarchy
ORDER BY Level DESC, PlanID;

-- =======================================================================
-- PART 2: Revenue Roll-Up (Bottom-Up Aggregation) – SAFE FOR POSTGRES
-- =======================================================================
WITH RECURSIVE PlanRollup AS (
    -- Anchor: Leaf nodes
    SELECT 
        PlanID,
        PlanName,
        ParentPlanID,
        Level,
        SubscriberCount,
        MonthlyFee_RWF,
        SubscriberCount AS TotalSubscribers,
        (MonthlyFee_RWF * SubscriberCount)::NUMERIC(12,2) AS TotalRevenue_RWF
    FROM PLAN_TREE
    WHERE PlanID NOT IN (
        SELECT DISTINCT ParentPlanID 
        FROM PLAN_TREE 
        WHERE ParentPlanID IS NOT NULL
    )

    UNION ALL

    -- Recursive: Aggregate children into parent
    SELECT 
        p.PlanID,
        p.PlanName,
        p.ParentPlanID,
        p.Level,
        p.SubscriberCount,
        p.MonthlyFee_RWF,
        p.SubscriberCount + pr.TotalSubscribers AS TotalSubscribers,
        (p.MonthlyFee_RWF * p.SubscriberCount + pr.TotalRevenue_RWF)::NUMERIC(12,2) AS TotalRevenue_RWF
    FROM PLAN_TREE p
    INNER JOIN PlanRollup pr ON p.PlanID = pr.ParentPlanID
)
SELECT 
    'Revenue Roll-Up by Plan Category' AS Report,
    PlanID,
    PlanName,
    Level,
    TotalSubscribers,
    TotalRevenue_RWF,
    CASE 
        WHEN TotalSubscribers > 0 
        THEN ROUND(TotalRevenue_RWF / TotalSubscribers, 2)
        ELSE 0 
    END AS AvgRevenuePerSubscriber_RWF,
    REPEAT('  ', Level - 1) || PlanName AS IndentedName
FROM PlanRollup
ORDER BY Level DESC, PlanID;