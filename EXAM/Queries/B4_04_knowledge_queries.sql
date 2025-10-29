-- ============================================================================
-- B9: Practical Knowledge Base Queries
-- Execute on telco_node_a database
-- ============================================================================

--------------------------------------------------------------------
-- Query 1: All requirements for Premium Plan (direct + transitive)
--------------------------------------------------------------------
WITH RECURSIVE req_chain AS (
    SELECT 
        subject,
        object,
        1 AS depth,
        ARRAY[subject::TEXT, object::TEXT] AS path
    FROM service_knowledge
    WHERE predicate = 'requires' 
      AND subject = 'Premium Plan'

    UNION ALL

    SELECT 
        c.subject,
        k.object,
        c.depth + 1,
        c.path || k.object::TEXT
    FROM req_chain c
    JOIN service_knowledge k ON c.object = k.subject
    WHERE k.predicate = 'requires'
      AND k.object::TEXT <> ALL(c.path)
      AND c.depth < 5
)
SELECT 
    'Premium Plan Requirements' AS query_type,
    object AS requirement,
    depth AS steps_away,
    array_to_string(path, ' to ') AS requirement_chain
FROM req_chain
ORDER BY depth, object;


--------------------------------------------------------------------
-- Query 2: Services that include Internet Access (direct or inherited)
--------------------------------------------------------------------
SELECT DISTINCT
    k1.subject AS service,
    'includes' AS relationship,
    'Internet Access' AS feature,
    CASE 
        WHEN k1.object = 'Internet Access' THEN 'Direct'
        ELSE 'Inherited via ' || k2.subject
    END AS how
FROM service_knowledge k1
LEFT JOIN service_knowledge k2 
    ON k1.object = k2.subject 
   AND k2.predicate = 'includes' 
   AND k2.object = 'Internet Access'
WHERE k1.predicate = 'includes' AND k1.object = 'Internet Access'
   OR k1.predicate = 'is_a' AND k2.object = 'Internet Access'
ORDER BY service;


--------------------------------------------------------------------
-- Query 3: All services that are types of "Telecom Service"
--------------------------------------------------------------------
WITH RECURSIVE service_hierarchy AS (
    SELECT 
        subject,
        object,
        1 AS level
    FROM service_knowledge
    WHERE predicate = 'is_a' 
      AND object = 'Telecom Service'

    UNION ALL

    SELECT 
        k.subject,
        h.object,
        h.level + 1
    FROM service_hierarchy h
    JOIN service_knowledge k ON k.object = h.subject
    WHERE k.predicate = 'is_a'
)
SELECT 
    subject AS "Service Type",
    level AS "Hierarchy Level",
    REPEAT('  ', level - 1) || '└─ ' || subject AS "Tree View"
FROM service_hierarchy
ORDER BY level, subject;


--------------------------------------------------------------------
-- Query 4: Compatibility chain (Service → Device → Network)
--------------------------------------------------------------------
SELECT 
    k1.subject AS "Service",
    k1.object AS "Requires Device",
    k2.object AS "Which Requires Network",
    LEAST(k1.confidence, k2.confidence) AS "Overall Compatibility"
FROM service_knowledge k1
JOIN service_knowledge k2 ON k1.object = k2.subject
WHERE k1.predicate = 'compatible_with'
  AND k2.predicate = 'compatible_with'
ORDER BY k1.subject;


--------------------------------------------------------------------
-- Query 5: Detect circular dependencies (should return 0 rows)
--------------------------------------------------------------------
WITH RECURSIVE dep_check AS (
    SELECT 
        subject,
        object,
        ARRAY[subject::TEXT] AS path,
        1 AS depth
    FROM service_knowledge
    WHERE predicate IN ('requires', 'depends_on')

    UNION ALL

    SELECT 
        d.subject,
        k.object,
        d.path || k.subject::TEXT,
        d.depth + 1
    FROM dep_check d
    JOIN service_knowledge k ON d.object = k.subject
    WHERE k.predicate IN ('requires', 'depends_on')
      AND k.subject::TEXT <> ALL(d.path)
      AND d.depth < 10
)
SELECT 
    subject AS "Circular Dependency Detected",
    object AS "Points Back To",
    array_to_string(path || object::TEXT, ' to ') AS "Cycle Path"
FROM dep_check
WHERE object::TEXT = ANY(path);