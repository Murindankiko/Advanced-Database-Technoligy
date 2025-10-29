-- ============================================================================
-- Task B7: Create Triggers
-- Attach trigger functions to tables
-- Execute on telco_node_a database
-- ============================================================================

-- Trigger on TopUp table
CREATE TRIGGER trg_topup_balance_update
    AFTER INSERT OR UPDATE OR DELETE ON TopUp
    FOR EACH ROW
    EXECUTE FUNCTION trg_update_balance_topup();

COMMENT ON TRIGGER trg_topup_balance_update ON TopUp IS 
    'Automatically updates SUBSCR_BALANCE when TopUp changes';

-- Trigger on CDR_A table
CREATE TRIGGER trg_cdr_balance_update
    AFTER INSERT OR UPDATE OR DELETE ON CDR_A
    FOR EACH ROW
    EXECUTE FUNCTION trg_update_balance_cdr();

COMMENT ON TRIGGER trg_cdr_balance_update ON CDR_A IS 
    'Automatically updates SUBSCR_BALANCE when CDR_A changes';

-- Verify triggers are created
SELECT 
    'Triggers Created' AS Status,
    tgname AS TriggerName,
    tgrelid::regclass AS TableName,
    tgtype AS TriggerType,
    tgenabled AS Enabled,
    pg_get_triggerdef(oid) AS TriggerDefinition
FROM pg_trigger
WHERE tgname LIKE 'trg_%balance%'
ORDER BY tgrelid, tgname;
