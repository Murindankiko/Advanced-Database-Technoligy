-- ============================================================================
-- Task A1: Create Database Link (Foreign Data Wrapper)
-- Execute this script while connected to telco_node_a database
-- ============================================================================

-- Install postgres_fdw extension if not already installed
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create foreign server pointing to Node B
CREATE SERVER node_b_server
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'localhost', port '5432', dbname 'telco_node_b');

-- Create user mapping (adjust credentials as needed)
CREATE USER MAPPING FOR postgres
    SERVER node_b_server
    OPTIONS (user 'postgres', password 'your_password_here');

-- Import foreign table CDR_B from Node B
IMPORT FOREIGN SCHEMA public
    LIMIT TO (CDR_B)
    FROM SERVER node_b_server
    INTO public;

-- Verify foreign table access
SELECT 'Foreign CDR_B' AS Source, COUNT(*) AS RowCount
FROM CDR_B;
