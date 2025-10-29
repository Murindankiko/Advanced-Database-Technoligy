-- B4:1 Mini Knowledge Base with Transitive Inference
-- Creates a knowledge base for telecom service relationships with transitive closure

-- Create the knowledge base table for service relationships
CREATE TABLE IF NOT EXISTS service_knowledge (
    id SERIAL PRIMARY KEY,
    subject VARCHAR(64) NOT NULL,
    predicate VARCHAR(64) NOT NULL,
    object VARCHAR(64) NOT NULL,
    confidence DECIMAL(3,2) DEFAULT 1.00 CHECK (confidence BETWEEN 0 AND 1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(subject, predicate, object)
);

-- Insert base facts about telecom services
INSERT INTO service_knowledge (subject, predicate, object, confidence) VALUES
    -- Service hierarchy
    ('Premium Plan', 'is_a', 'Data Plan', 1.00),
    ('Data Plan', 'is_a', 'Mobile Service', 1.00),
    ('Mobile Service', 'is_a', 'Telecom Service', 1.00),
    
    -- Service requirements
    ('Premium Plan', 'requires', 'Active SIM', 1.00),
    ('Active SIM', 'requires', 'Valid ID', 1.00),
    ('Data Plan', 'requires', 'Network Coverage', 1.00),
    
    -- Service features
    ('Premium Plan', 'includes', 'Unlimited Data', 1.00),
    ('Premium Plan', 'includes', 'International Roaming', 1.00),
    ('Data Plan', 'includes', 'Internet Access', 1.00),
    
    -- Service compatibility
    ('4G Service', 'compatible_with', '4G Device', 1.00),
    ('4G Device', 'compatible_with', '4G Network', 1.00),
    ('5G Service', 'compatible_with', '5G Device', 0.95),
    
    -- Service dependencies
    ('Video Streaming', 'depends_on', 'High Speed Data', 1.00),
    ('High Speed Data', 'depends_on', '4G Service', 0.90),
    ('Cloud Backup', 'depends_on', 'Data Plan', 1.00)
ON CONFLICT (subject, predicate, object) DO NOTHING;

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_knowledge_subject ON service_knowledge(subject);
CREATE INDEX IF NOT EXISTS idx_knowledge_predicate ON service_knowledge(predicate);
CREATE INDEX IF NOT EXISTS idx_knowledge_object ON service_knowledge(object);

SELECT 'Knowledge base created with ' || COUNT(*) || ' facts' as status
FROM service_knowledge;
