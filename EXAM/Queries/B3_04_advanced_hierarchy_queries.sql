-- ============================================================================
-- Task B8: Advanced Hierarchy Queries
-- Execute on telco_node_a database
-- ============================================================================

--------------------------------------------------------------------
-- Query 1: All descendants of a given plan (PlanID = 10)
--------------------------------------------------------------------
WITH RECURSIVE Descendants AS (
    SELECT
        PlanID,
        PlanName,
        ParentPlanID,
        Level,
        0 AS RelativeLevel
    FROM PLAN_TREE
    WHERE PlanID = 10                     -- Prepaid Plans

    UNION ALL

    SELECT
        p.PlanID,
        p.PlanName,
        p.ParentPlanID,
        p.Level,
        d.RelativeLevel + 1 AS RelativeLevel
    FROM PLAN_TREE p
    JOIN Descendants d ON p.ParentPlanID = d.PlanID
)
SELECT
    'All Descendants of Prepaid Plans' AS Report,
    PlanID,
    PlanName,
    Level,
    RelativeLevel,
    REPEAT('  ', RelativeLevel) || PlanName AS IndentedName
FROM Descendants
ORDER BY RelativeLevel, PlanID;


--------------------------------------------------------------------
-- Query 2: Path from a leaf node up to the root (PlanID = 11)
--------------------------------------------------------------------
WITH RECURSIVE PathToRoot AS (
    SELECT
        PlanID,
        PlanName,
        ParentPlanID,
        Level,
        CAST(PlanName AS VARCHAR(200)) AS Path,
        1 AS PathLength
    FROM PLAN_TREE
    WHERE PlanID = 11                     -- Youth Plus

    UNION ALL

    SELECT
        p.PlanID,
        p.PlanName,
        p.ParentPlanID,
        p.Level,
        CAST(p.PlanName || ' > ' || ptr.Path AS VARCHAR(200)) AS Path,
        ptr.PathLength + 1 AS PathLength
    FROM PLAN_TREE p
    JOIN PathToRoot ptr ON p.PlanID = ptr.ParentPlanID
)
SELECT
    'Path from Youth Plus to Root' AS Report,
    Path,
    PathLength
FROM PathToRoot
ORDER BY PathLength DESC
LIMIT 1;


--------------------------------------------------------------------
-- Query 3: Depth of every node (root = 0)
--------------------------------------------------------------------
WITH RECURSIVE NodeDepth AS (
    SELECT
        PlanID,
        PlanName,
        ParentPlanID,
        0 AS Depth
    FROM PLAN_TREE
    WHERE ParentPlanID IS NULL            -- root nodes

    UNION ALL

    SELECT
        p.PlanID,
        p.PlanName,
        p.ParentPlanID,
        nd.Depth + 1 AS Depth
    FROM PLAN_TREE p
    JOIN NodeDepth nd ON p.ParentPlanID = nd.PlanID
)
SELECT
    'Node Depths' AS Report,
    PlanID,
    PlanName,
    Depth,
    REPEAT('  ', Depth) || PlanName AS IndentedName
FROM NodeDepth
ORDER BY Depth, PlanID;


--------------------------------------------------------------------
-- Query 4: Aggregate statistics by Level (bottom-up running totals)
--------------------------------------------------------------------
WITH RECURSIVE PlanStats AS (
    -- Anchor: leaf nodes (no children)
    SELECT
        PlanID,
        PlanName,
        ParentPlanID,
        Level,
        SubscriberCount,
        MonthlyFee_RWF,
        SubscriberCount               AS TotalSubs,
        (MonthlyFee_RWF * SubscriberCount)::NUMERIC(12,2) AS TotalRev
    FROM PLAN_TREE
    WHERE PlanID NOT IN (SELECT DISTINCT ParentPlanID
                         FROM PLAN_TREE
                         WHERE ParentPlanID IS NOT NULL)

    UNION ALL

    -- Recursive: parent = own values + summed child values
    SELECT
        p.PlanID,
        p.PlanName,
        p.ParentPlanID,
        p.Level,
        p.SubscriberCount,
        p.MonthlyFee_RWF,
        p.SubscriberCount + ps.TotalSubs               AS TotalSubs,
        (p.MonthlyFee_RWF * p.SubscriberCount + ps.TotalRev)::NUMERIC(12,2) AS TotalRev
    FROM PLAN_TREE p
    JOIN PlanStats ps ON p.PlanID = ps.ParentPlanID
)
SELECT
    Level,
    COUNT(*)                                          AS PlanCount,
    SUM(TotalSubs)                                    AS TotalSubscribers,
    SUM(TotalRev)                                     AS TotalRevenue_RWF,
    ROUND(AVG(TotalRev), 2)                           AS AvgRevenue_RWF
FROM PlanStats
GROUP BY Level
ORDER BY Level;