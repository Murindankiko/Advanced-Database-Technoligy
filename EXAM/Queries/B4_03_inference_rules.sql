-- B9: Advanced Inference Rules
-- Implements logical inference rules to derive new knowledge

-- Create a view for inferred facts
CREATE OR REPLACE VIEW inferred_knowledge AS

-- Rule 1: Transitive "is_a" (if A is_a B and B is_a C, then A is_a C)
WITH is_a_transitive AS (
    SELECT DISTINCT
        k1.subject,
        'is_a' as predicate,
        k2.object,
        LEAST(k1.confidence, k2.confidence) as confidence,
        'transitive_is_a' as inference_rule
    FROM service_knowledge k1
    JOIN service_knowledge k2 ON k1.object = k2.subject
    WHERE k1.predicate = 'is_a' 
        AND k2.predicate = 'is_a'
        AND k1.subject != k2.object
),

-- Rule 2: Transitive "requires" (if A requires B and B requires C, then A requires C)
requires_transitive AS (
    SELECT DISTINCT
        k1.subject,
        'requires' as predicate,
        k2.object,
        LEAST(k1.confidence, k2.confidence) as confidence,
        'transitive_requires' as inference_rule
    FROM service_knowledge k1
    JOIN service_knowledge k2 ON k1.object = k2.subject
    WHERE k1.predicate = 'requires' 
        AND k2.predicate = 'requires'
        AND k1.subject != k2.object
),

-- Rule 3: Inherited features (if A is_a B and B includes C, then A includes C)
inherited_features AS (
    SELECT DISTINCT
        k1.subject,
        'includes' as predicate,
        k2.object,
        LEAST(k1.confidence, k2.confidence) as confidence,
        'inherited_feature' as inference_rule
    FROM service_knowledge k1
    JOIN service_knowledge k2 ON k1.object = k2.subject
    WHERE k1.predicate = 'is_a' 
        AND k2.predicate = 'includes'
),

-- Rule 4: Transitive compatibility (if A compatible_with B and B compatible_with C, then A compatible_with C)
compatibility_transitive AS (
    SELECT DISTINCT
        k1.subject,
        'compatible_with' as predicate,
        k2.object,
        LEAST(k1.confidence, k2.confidence) * 0.9 as confidence,  -- Reduce confidence for chained compatibility
        'transitive_compatibility' as inference_rule
    FROM service_knowledge k1
    JOIN service_knowledge k2 ON k1.object = k2.subject
    WHERE k1.predicate = 'compatible_with' 
        AND k2.predicate = 'compatible_with'
        AND k1.subject != k2.object
),

-- Rule 5: Dependency chain (if A depends_on B and B depends_on C, then A depends_on C)
dependency_chain AS (
    SELECT DISTINCT
        k1.subject,
        'depends_on' as predicate,
        k2.object,
        LEAST(k1.confidence, k2.confidence) as confidence,
        'transitive_dependency' as inference_rule
    FROM service_knowledge k1
    JOIN service_knowledge k2 ON k1.object = k2.subject
    WHERE k1.predicate = 'depends_on' 
        AND k2.predicate = 'depends_on'
        AND k1.subject != k2.object
)

-- Combine all inferred facts
SELECT * FROM is_a_transitive
UNION ALL
SELECT * FROM requires_transitive
UNION ALL
SELECT * FROM inherited_features
UNION ALL
SELECT * FROM compatibility_transitive
UNION ALL
SELECT * FROM dependency_chain;

-- Query the inferred knowledge
SELECT 
    subject as "Subject",
    predicate as "Relationship",
    object as "Object",
    ROUND(confidence, 2) as "Confidence",
    inference_rule as "Inference Rule"
FROM inferred_knowledge
ORDER BY inference_rule, subject, predicate;
