-- ============================================
-- Trigger: Automatically Flag Drivers with Multiple Offenses
-- Updates driver record when they accumulate multiple violations
-- ============================================

-- Function to update driver offense count and flag status
CREATE OR REPLACE FUNCTION update_driver_offense_status()
RETURNS TRIGGER AS $$
DECLARE
    v_driver_id INT;
    v_offense_count INT;
BEGIN
    -- Get the driver ID from the vehicle
    SELECT DriverID INTO v_driver_id
    FROM Vehicle
    WHERE VehicleID = NEW.VehicleID;
    
    -- Count total violations for this driver
    SELECT COUNT(*) INTO v_offense_count
    FROM Violation v
    INNER JOIN Vehicle ve ON v.VehicleID = ve.VehicleID
    WHERE ve.DriverID = v_driver_id;
    
    -- Update driver offense count
    UPDATE Driver
    SET OffenseCount = v_offense_count
    WHERE DriverID = v_driver_id;
    
    -- Flag driver if they have 3 or more offenses
    IF v_offense_count >= 3 THEN
        UPDATE Driver
        SET IsFlagged = TRUE
        WHERE DriverID = v_driver_id;
        
        RAISE NOTICE 'Driver ID % has been flagged with % offenses', v_driver_id, v_offense_count;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on Violation table
DROP TRIGGER IF EXISTS trg_flag_multiple_offenses ON Violation;

CREATE TRIGGER trg_flag_multiple_offenses
AFTER INSERT ON Violation
FOR EACH ROW
EXECUTE FUNCTION update_driver_offense_status();

-- ============================================
-- Test the trigger
-- ============================================

-- Check current driver status
SELECT 
    DriverID,
    FullName,
    OffenseCount,
    IsFlagged
FROM Driver
ORDER BY OffenseCount DESC;

-- The trigger will automatically update when new violations are inserted
-- Example: Insert a new violation and see the driver get flagged
-- (Uncomment to test)
/*
INSERT INTO Violation (VehicleID, OfficerID, Date, Type, Penalty, Status)
VALUES (1, 1, CURRENT_TIMESTAMP, 'Test Violation', 50000, 'Pending');

-- Check updated driver status
SELECT 
    DriverID,
    FullName,
    OffenseCount,
    IsFlagged
FROM Driver
WHERE DriverID = 1;
*/

-- ============================================
-- Additional: Function to manually recalculate all driver offense counts
-- ============================================
CREATE OR REPLACE FUNCTION recalculate_all_driver_offenses()
RETURNS VOID AS $$
DECLARE
    driver_record RECORD;
    v_offense_count INT;
BEGIN
    FOR driver_record IN SELECT DriverID FROM Driver LOOP
        -- Count violations for this driver
        SELECT COUNT(*) INTO v_offense_count
        FROM Violation v
        INNER JOIN Vehicle ve ON v.VehicleID = ve.VehicleID
        WHERE ve.DriverID = driver_record.DriverID;
        
        -- Update driver record
        UPDATE Driver
        SET 
            OffenseCount = v_offense_count,
            IsFlagged = (v_offense_count >= 3)
        WHERE DriverID = driver_record.DriverID;
    END LOOP;
    
    RAISE NOTICE 'All driver offense counts recalculated';
END;
$$ LANGUAGE plpgsql;

-- Run initial recalculation
SELECT recalculate_all_driver_offenses();

-- View flagged drivers
SELECT 
    d.DriverID,
    d.FullName,
    d.LicenseNo,
    d.City,
    d.OffenseCount,
    d.IsFlagged,
    COUNT(v.ViolationID) AS TotalViolations,
    SUM(f.Amount) AS TotalFines
FROM 
    Driver d
    LEFT JOIN Vehicle ve ON d.DriverID = ve.DriverID
    LEFT JOIN Violation v ON ve.VehicleID = v.VehicleID
    LEFT JOIN Fine f ON v.ViolationID = f.ViolationID
WHERE 
    d.IsFlagged = TRUE
GROUP BY 
    d.DriverID, d.FullName, d.LicenseNo, d.City, d.OffenseCount, d.IsFlagged
ORDER BY 
    d.OffenseCount DESC;
