-- ============================================================================
-- TASK 7: TRIGGER TO AUTOMATICALLY CLOSE EXPIRED POLICIES
-- Automatically updates policy status to 'Expired' when EndDate is reached
-- Applies to all Rwandan SACCO insurance policies
-- ============================================================================

-- Create the trigger function
CREATE OR REPLACE FUNCTION fn_AutoExpirePolicy()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the policy has reached or passed its end date
    IF NEW.EndDate <= CURRENT_DATE AND NEW.Status = 'Active' THEN
        NEW.Status := 'Expired';
        
        -- Optional: Log the expiration for Rwandan SACCO records
        RAISE NOTICE 'Policy % for Member % has been automatically expired on %', 
                     NEW.PolicyID, NEW.MemberID, CURRENT_DATE;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION fn_AutoExpirePolicy() IS 'Auto-expires insurance policies for Rwandan SACCO members when EndDate is reached';

-- Create the trigger on INSERT and UPDATE
CREATE TRIGGER trg_AutoExpirePolicy
BEFORE INSERT OR UPDATE ON InsurancePolicy
FOR EACH ROW
EXECUTE FUNCTION fn_AutoExpirePolicy();

COMMENT ON TRIGGER trg_AutoExpirePolicy ON InsurancePolicy IS 'Automatically expires policies when EndDate is reached';

-- ============================================================================
-- Alternative: Scheduled job approach using a stored procedure
-- This can be called periodically (e.g., daily via cron or pg_cron)
-- Useful for batch processing of expired policies in Rwandan SACCO
-- ============================================================================

CREATE OR REPLACE FUNCTION sp_ExpireOldPolicies()
RETURNS TABLE(
    PolicyID INT,
    MemberID INT,
    MemberName VARCHAR,
    PolicyType VARCHAR,
    EndDate DATE,
    OldStatus VARCHAR,
    NewStatus VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    UPDATE InsurancePolicy ip
    SET Status = 'Expired'
    FROM Member m
    WHERE ip.MemberID = m.MemberID
      AND ip.EndDate < CURRENT_DATE 
      AND ip.Status = 'Active'
    RETURNING 
        ip.PolicyID,
        ip.MemberID,
        m.FullName,
        ip.Type,
        ip.EndDate,
        'Active'::VARCHAR AS OldStatus,
        ip.Status AS NewStatus;
    
    -- Log the number of policies expired
    RAISE NOTICE '% policies have been expired for Rwandan SACCO members', 
                 (SELECT COUNT(*) FROM InsurancePolicy WHERE Status = 'Expired' AND EndDate < CURRENT_DATE);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sp_ExpireOldPolicies() IS 'Batch expire old policies for Rwandan SACCO - can be scheduled daily';

-- Execute the stored procedure to expire old policies
SELECT * FROM sp_ExpireOldPolicies();

-- ============================================================================
-- Test the trigger with Rwandan context
-- ============================================================================

-- Insert a policy that should be automatically expired
INSERT INTO InsurancePolicy (MemberID, Type, Premium, StartDate, EndDate, Status)
VALUES (1, 'Health', 180000.00, '2022-01-01', '2023-01-01', 'Active');

-- Verify the trigger worked
SELECT 
    PolicyID, 
    MemberID, 
    Type, 
    TO_CHAR(Premium, 'FML999,999,999') || ' RWF' AS Premium,
    EndDate, 
    Status
FROM InsurancePolicy
WHERE EndDate < CURRENT_DATE
ORDER BY EndDate DESC;
