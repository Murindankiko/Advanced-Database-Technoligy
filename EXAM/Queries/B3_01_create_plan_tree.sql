-- ============================================================================
-- Task B8: Recursive Hierarchy Roll-Up
-- Step 1: Create hierarchical plan structure
-- Execute on telco_node_a database
-- ============================================================================

-- Create PLAN_TREE table with self-referencing hierarchy
CREATE TABLE PLAN_TREE (
    PlanID INT PRIMARY KEY,
    PlanName VARCHAR(50) NOT NULL,
    ParentPlanID INT REFERENCES PLAN_TREE(PlanID),
    MonthlyFee_RWF NUMERIC(10,2) DEFAULT 0,
    DataAllowance_MB INT DEFAULT 0,
    VoiceMinutes INT DEFAULT 0,
    SMSCount INT DEFAULT 0,
    Level INT,
    CONSTRAINT chk_no_self_reference CHECK (PlanID != ParentPlanID)
);

COMMENT ON TABLE PLAN_TREE IS 'Hierarchical telecom plan structure for Rwanda Telco';
COMMENT ON COLUMN PLAN_TREE.ParentPlanID IS 'NULL for root plans, references parent for sub-plans';

-- Insert 3-level hierarchy (10 rows total)
-- Level 1: Root plans (no parent)
INSERT INTO PLAN_TREE (PlanID, PlanName, ParentPlanID, MonthlyFee_RWF, DataAllowance_MB, VoiceMinutes, SMSCount, Level) VALUES
(1, 'All Plans', NULL, 0, 0, 0, 0, 1);

-- Level 2: Main categories
INSERT INTO PLAN_TREE (PlanID, PlanName, ParentPlanID, MonthlyFee_RWF, DataAllowance_MB, VoiceMinutes, SMSCount, Level) VALUES
(10, 'Prepaid Plans', 1, 0, 0, 0, 0, 2),
(20, 'Postpaid Plans', 1, 0, 0, 0, 0, 2);

-- Level 3: Specific plans
INSERT INTO PLAN_TREE (PlanID, PlanName, ParentPlanID, MonthlyFee_RWF, DataAllowance_MB, VoiceMinutes, SMSCount, Level) VALUES
(11, 'Youth Plus', 10, 2000, 1024, 100, 200, 3),
(12, 'Basic Starter', 10, 1000, 512, 50, 100, 3),
(13, 'Data Max', 10, 5000, 5120, 200, 500, 3),
(21, 'Business Pro', 20, 15000, 10240, 1000, 1000, 3),
(22, 'Family Bundle', 20, 20000, 20480, 2000, 2000, 3),
(23, 'Enterprise Elite', 20, 50000, 51200, 5000, 5000, 3);

-- Create index for hierarchy traversal
CREATE INDEX idx_plan_parent ON PLAN_TREE(ParentPlanID);

-- View the hierarchy
SELECT 
    'Plan Hierarchy' AS Report,
    PlanID,
    PlanName,
    ParentPlanID,
    Level,
    MonthlyFee_RWF,
    DataAllowance_MB
FROM PLAN_TREE
ORDER BY Level, PlanID;
