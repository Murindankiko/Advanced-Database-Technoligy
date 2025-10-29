-- ============================================================================
-- Task A2: Database Link & Cross-Node Join
-- Step 1: Import additional foreign tables from Node B
-- Execute this script while connected to telco_node_a database
-- ============================================================================

-- Import Subscriber and SIM tables from Node B
IMPORT FOREIGN SCHEMA public
    LIMIT TO (Subscriber, SIM)
    FROM SERVER node_b_server
    INTO public;

-- Verify foreign table imports
SELECT 
    'Foreign Tables Imported' AS Status,
    COUNT(*) AS TableCount
FROM information_schema.foreign_tables
WHERE foreign_server_name = 'node_b_server';

-- List all foreign tables
SELECT 
    foreign_table_schema,
    foreign_table_name,
    foreign_server_name
FROM information_schema.foreign_tables
WHERE foreign_server_name = 'node_b_server'
ORDER BY foreign_table_name;
