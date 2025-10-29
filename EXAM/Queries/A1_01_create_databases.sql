-- ============================================================================
-- Task A1: Fragment & Recombine Main Fact
-- Step 1: Create two databases for horizontal fragmentation
-- ============================================================================

-- Updated collation to English_Rwanda.1252 to match system configuration
-- Create Node A database
CREATE DATABASE telco_node_a
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_Rwanda.1252'
    LC_CTYPE = 'English_Rwanda.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    TEMPLATE = template0;

COMMENT ON DATABASE telco_node_a IS 'Rwanda Telco Analytics - Node A (Even SimID)';

-- Create Node B database
CREATE DATABASE telco_node_b
    WITH 
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_Rwanda.1252'
    LC_CTYPE = 'English_Rwanda.1252'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    TEMPLATE = template0;

COMMENT ON DATABASE telco_node_b IS 'Rwanda Telco Analytics - Node B (Odd SimID)';
