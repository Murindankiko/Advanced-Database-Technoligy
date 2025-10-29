-- ============================================================================
-- B4:2 Transitive Inference Queries
-- Demonstrates recursive queries to infer new knowledge
-- Execute on telco_node_a database
-- ============================================================================

-- 1. Transitive closure for "is_a" relationships
WITH RECURSIVE is_a_closure AS (
    -- Base case: direct relationships
    SELECT 
        subject,
        object,
        1 AS depth,
        ARRAY[subject::TEXT, object::TEXT] AS path,  -- Force TEXT[]
        confidence
    FROM service_knowledge
    WHERE predicate = 'is_a'
    
    UNION
    
    -- Recursive case: transitive relationships
    SELECT 
        c.subject,
        k.object,
        c.depth + 1,
        c.path || k.object::TEXT,                    -- Append as TEXT
        LEAST(c.confidence, k.confidence) AS confidence
    FROM is_a_closure c
    JOIN service_knowledge k ON c.object = k.subject
    WHERE k.predicate = 'is_a'
      AND k.object::TEXT <> ALL(c.path)           -- Prevent cycles
      AND c.depth < 10
)
SELECT 
    subject AS "Service",
    object AS "Is A Type Of",
    depth AS "Relationship Depth",
    array_to_string(path, ' to ') AS "Inference Path",
    ROUND(confidence, 2) AS "Confidence"
FROM is_a_closure
ORDER BY subject, depth;


-- 2. Transitive closure for "requires" relationships
WITH RECURSIVE requires_closure AS (
    -- Base case
    SELECT 
        subject,
        object,
        1 AS depth,
        ARRAY[subject::TEXT, object::TEXT] AS path,
        confidence
    FROM service_knowledge
    WHERE predicate = 'requires'
    
    UNION
    
    -- Recursive
    SELECT 
        c.subject,
        k.object,
        c.depth + 1,
        c.path || k.object::TEXT,
        LEAST(c.confidence, k.confidence)
    FROM requires_closure c
    JOIN service_knowledge k ON c.object = k.subject
    WHERE k.predicate = 'requires'
      AND k.object::TEXT <> ALL(c.path)
      AND c.depth < 10
)
SELECT 
    subject AS "Service",
    object AS "Ultimately Requires",
    depth AS "Dependency Depth",
    array_to_string(path, ' to ') AS "Dependency Chain",
    ROUND(confidence, 2) AS "Confidence"
FROM requires_closure
ORDER BY subject, depth;


-- 3. Find all features of a service (including inherited)
WITH RECURSIVE service_features AS (
    -- Direct features
    SELECT 
        subject AS service,
        object AS feature,
        'direct'::TEXT AS feature_type,
        confidence
    FROM service_knowledge
    WHERE predicate = 'includes'
    
    UNION
    
    -- Inherited features via is_a
    SELECT 
        child.subject AS service,
        pf.object AS feature,
        'inherited'::TEXT AS feature_type,
        LEAST(child.confidence, pf.confidence) AS confidence
    FROM service_knowledge child
    JOIN service_knowledge pf ON child.object = pf.subject
    WHERE child.predicate = 'is_a'
      AND pf.predicate = 'includes'
)
SELECT 
    service AS "Service",
    feature AS "Feature",
    feature_type AS "Feature Type",
    ROUND(confidence, 2) AS "Confidence"
FROM service_features
WHERE service = 'Premium Plan'
ORDER BY feature_type, feature;