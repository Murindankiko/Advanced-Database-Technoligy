-- ============================================================================
-- Task B7: Create Trigger Functions (E-C-A Pattern)
-- Event-Condition-Action pattern for balance maintenance
-- Execute on telco_node_a database
-- ============================================================================

-- Function 1: Handle TopUp changes
CREATE OR REPLACE FUNCTION trg_update_balance_topup()
RETURNS TRIGGER AS $$
DECLARE
    v_old_balance NUMERIC(12,2);
    v_new_balance NUMERIC(12,2);
BEGIN
    -- EVENT: TopUp INSERT/UPDATE/DELETE detected
    
    IF TG_OP = 'INSERT' THEN
        -- CONDITION: New TopUp added
        -- ACTION: Increase balance
        
        -- Ensure SimID exists in SUBSCR_BALANCE
        INSERT INTO SUBSCR_BALANCE (SimID)
        VALUES (NEW.SimID)
        ON CONFLICT (SimID) DO NOTHING;
        
        -- Get old balance
        SELECT CurrentBalance_RWF INTO v_old_balance
        FROM SUBSCR_BALANCE
        WHERE SimID = NEW.SimID;
        
        -- Update balance
        UPDATE SUBSCR_BALANCE
        SET 
            TotalTopUps_RWF = TotalTopUps_RWF + NEW.Amount_RWF,
            TopUpCount = TopUpCount + 1,
            LastTopUpDate = NEW.TopUpDate,
            LastUpdated = CURRENT_TIMESTAMP
        WHERE SimID = NEW.SimID;
        
        -- Get new balance
        SELECT CurrentBalance_RWF INTO v_new_balance
        FROM SUBSCR_BALANCE
        WHERE SimID = NEW.SimID;
        
        -- Audit log
        INSERT INTO SUBSCR_BAL_AUDIT (
            SimID, OperationType, SourceTable, SourceRecordID, 
            AmountChange_RWF, OldBalance_RWF, NewBalance_RWF
        ) VALUES (
            NEW.SimID, 'INSERT', 'TopUp', NEW.TopUpID,
            NEW.Amount_RWF, v_old_balance, v_new_balance
        );
        
        RAISE NOTICE '[TRIGGER] TopUp INSERT: SimID %, Amount %, New Balance %', 
            NEW.SimID, NEW.Amount_RWF, v_new_balance;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- CONDITION: TopUp amount changed
        -- ACTION: Adjust balance by difference
        
        IF OLD.Amount_RWF != NEW.Amount_RWF THEN
            SELECT CurrentBalance_RWF INTO v_old_balance
            FROM SUBSCR_BALANCE WHERE SimID = NEW.SimID;
            
            UPDATE SUBSCR_BALANCE
            SET 
                TotalTopUps_RWF = TotalTopUps_RWF - OLD.Amount_RWF + NEW.Amount_RWF,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE SimID = NEW.SimID;
            
            SELECT CurrentBalance_RWF INTO v_new_balance
            FROM SUBSCR_BALANCE WHERE SimID = NEW.SimID;
            
            INSERT INTO SUBSCR_BAL_AUDIT (
                SimID, OperationType, SourceTable, SourceRecordID,
                AmountChange_RWF, OldBalance_RWF, NewBalance_RWF
            ) VALUES (
                NEW.SimID, 'UPDATE', 'TopUp', NEW.TopUpID,
                NEW.Amount_RWF - OLD.Amount_RWF, v_old_balance, v_new_balance
            );
            
            RAISE NOTICE '[TRIGGER] TopUp UPDATE: SimID %, Amount Change %, New Balance %',
                NEW.SimID, NEW.Amount_RWF - OLD.Amount_RWF, v_new_balance;
        END IF;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- CONDITION: TopUp deleted
        -- ACTION: Decrease balance
        
        SELECT CurrentBalance_RWF INTO v_old_balance
        FROM SUBSCR_BALANCE WHERE SimID = OLD.SimID;
        
        UPDATE SUBSCR_BALANCE
        SET 
            TotalTopUps_RWF = TotalTopUps_RWF - OLD.Amount_RWF,
            TopUpCount = TopUpCount - 1,
            LastUpdated = CURRENT_TIMESTAMP
        WHERE SimID = OLD.SimID;
        
        SELECT CurrentBalance_RWF INTO v_new_balance
        FROM SUBSCR_BALANCE WHERE SimID = OLD.SimID;
        
        INSERT INTO SUBSCR_BAL_AUDIT (
            SimID, OperationType, SourceTable, SourceRecordID,
            AmountChange_RWF, OldBalance_RWF, NewBalance_RWF
        ) VALUES (
            OLD.SimID, 'DELETE', 'TopUp', OLD.TopUpID,
            -OLD.Amount_RWF, v_old_balance, v_new_balance
        );
        
        RAISE NOTICE '[TRIGGER] TopUp DELETE: SimID %, Amount %, New Balance %',
            OLD.SimID, OLD.Amount_RWF, v_new_balance;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION trg_update_balance_topup() IS 'E-C-A trigger: Maintains balance on TopUp changes';

-- Function 2: Handle CDR changes
CREATE OR REPLACE FUNCTION trg_update_balance_cdr()
RETURNS TRIGGER AS $$
DECLARE
    v_old_balance NUMERIC(12,2);
    v_new_balance NUMERIC(12,2);
BEGIN
    -- EVENT: CDR INSERT/UPDATE/DELETE detected
    
    IF TG_OP = 'INSERT' THEN
        -- CONDITION: New call record added
        -- ACTION: Decrease balance (charge applied)
        
        INSERT INTO SUBSCR_BALANCE (SimID)
        VALUES (NEW.SimID)
        ON CONFLICT (SimID) DO NOTHING;
        
        SELECT CurrentBalance_RWF INTO v_old_balance
        FROM SUBSCR_BALANCE WHERE SimID = NEW.SimID;
        
        UPDATE SUBSCR_BALANCE
        SET 
            TotalCharges_RWF = TotalCharges_RWF + NEW.Charge,
            CallCount = CallCount + 1,
            LastCallDate = NEW.CallDate,
            LastUpdated = CURRENT_TIMESTAMP
        WHERE SimID = NEW.SimID;
        
        SELECT CurrentBalance_RWF INTO v_new_balance
        FROM SUBSCR_BALANCE WHERE SimID = NEW.SimID;
        
        INSERT INTO SUBSCR_BAL_AUDIT (
            SimID, OperationType, SourceTable, SourceRecordID,
            AmountChange_RWF, OldBalance_RWF, NewBalance_RWF
        ) VALUES (
            NEW.SimID, 'INSERT', 'CDR_A', NEW.CdrID,
            -NEW.Charge, v_old_balance, v_new_balance
        );
        
        RAISE NOTICE '[TRIGGER] CDR INSERT: SimID %, Charge %, New Balance %',
            NEW.SimID, NEW.Charge, v_new_balance;
        
    ELSIF TG_OP = 'UPDATE' THEN
        -- CONDITION: Charge amount changed
        -- ACTION: Adjust balance
        
        IF OLD.Charge != NEW.Charge THEN
            SELECT CurrentBalance_RWF INTO v_old_balance
            FROM SUBSCR_BALANCE WHERE SimID = NEW.SimID;
            
            UPDATE SUBSCR_BALANCE
            SET 
                TotalCharges_RWF = TotalCharges_RWF - OLD.Charge + NEW.Charge,
                LastUpdated = CURRENT_TIMESTAMP
            WHERE SimID = NEW.SimID;
            
            SELECT CurrentBalance_RWF INTO v_new_balance
            FROM SUBSCR_BALANCE WHERE SimID = NEW.SimID;
            
            INSERT INTO SUBSCR_BAL_AUDIT (
                SimID, OperationType, SourceTable, SourceRecordID,
                AmountChange_RWF, OldBalance_RWF, NewBalance_RWF
            ) VALUES (
                NEW.SimID, 'UPDATE', 'CDR_A', NEW.CdrID,
                -(NEW.Charge - OLD.Charge), v_old_balance, v_new_balance
            );
            
            RAISE NOTICE '[TRIGGER] CDR UPDATE: SimID %, Charge Change %, New Balance %',
                NEW.SimID, NEW.Charge - OLD.Charge, v_new_balance;
        END IF;
        
    ELSIF TG_OP = 'DELETE' THEN
        -- CONDITION: Call record deleted
        -- ACTION: Reverse charge
        
        SELECT CurrentBalance_RWF INTO v_old_balance
        FROM SUBSCR_BALANCE WHERE SimID = OLD.SimID;
        
        UPDATE SUBSCR_BALANCE
        SET 
            TotalCharges_RWF = TotalCharges_RWF - OLD.Charge,
            CallCount = CallCount - 1,
            LastUpdated = CURRENT_TIMESTAMP
        WHERE SimID = OLD.SimID;
        
        SELECT CurrentBalance_RWF INTO v_new_balance
        FROM SUBSCR_BALANCE WHERE SimID = OLD.SimID;
        
        INSERT INTO SUBSCR_BAL_AUDIT (
            SimID, OperationType, SourceTable, SourceRecordID,
            AmountChange_RWF, OldBalance_RWF, NewBalance_RWF
        ) VALUES (
            OLD.SimID, 'DELETE', 'CDR_A', OLD.CdrID,
            OLD.Charge, v_old_balance, v_new_balance
        );
        
        RAISE NOTICE '[TRIGGER] CDR DELETE: SimID %, Charge %, New Balance %',
            OLD.SimID, OLD.Charge, v_new_balance;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION trg_update_balance_cdr() IS 'E-C-A trigger: Maintains balance on CDR changes';
