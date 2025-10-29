

ADVANCED DATABASE PROJECT-BASED EXAM
Module Code: DSM6235
School/Centre: African Centre of Excellence in Data Science
Maurice MURINDANKIKO (220000459) 
Date: 28 Octobr 2025


Question 36: TELECOM SUBSCRIBER & CDR BILLING/ANALYTICS

Overview
This document summarizes all 36 tasks from Section A (Distributed Systems) and Section B (Advanced Triggers & Analytics).
Everything was built on PostgreSQL 12, using horizontal fragmentation, foreign data wrappers, two-phase commit, triggers, recursive hierarchies, and real-time business alerts.

SECTION A: Distributed Database

A1: Creating tables to perfom Horizontal Fragmentation & Recombination
- Goal: Split CDR data by SimID parity to telco_node_a (even), telco_node_b (odd).
- Action done:
  - Created two databases.
  - CDR_A (even SimID) + CDR_B (odd SimID) with CHECK constraints.
  - Sample data: 5 rows each.
- Result:  
  - CDR_ALL view via postgres_fdw to 10 rows total, checksum = 25, 2 nodes detected.
  - Fragmentation correct: even to Node A, odd to Node B.
-------------------------------------------------------------------------------------
A2: Cross-Node Joins via FDW
- Goal: Import Subscriber, SIM from Node B into Node A.
- Action done:
  - IMPORT FOREIGN SCHEMA to SIM, Subscriber now queryable in Node A.
  - Added even SimIDs to SIM on Node B for full coverage.
- Result:  
  - All 6 SIMs visible.  
  - Joins between CDR_A and remote SIM work seamlessly.
-------------------------------------------------------------------------------------
A3: Parallel vs Serial Aggregation
- Goal: Compare performance of GROUP BY on CDR_ALL.
- Done:
  - Serial: max_parallel_workers_per_gather = 0 to 0.70 ms
  - Parallel: = 4 to 0.60 ms, 2 workers launched
- Result:  
  - 14.3% faster with parallel execution.  
  - Buffers & timing captured in Performance_Comparison table.
-------------------------------------------------------------------------------------
A4: Two-Phase Commit and Recovery (2 rows named 2PC)
- Goal: Safely update across nodes using PREPARE TRANSACTION.
- Activity dine:
  - Clean 2PC: TopUp (Node A) + CDR update (Node B) to committed.
  - Failure simulation: Network drop to IN-DOUBT to rolled back.
- Result:  
  - pg_prepared_xacts shows in-doubt to recovered via ROLLBACK PREPARED.
-------------------------------------------------------------------------------------
A5: Distributed Lock Conflicts
- Goal: Demonstrate row-level locking across sessions.
- Activities done:
  - Part 1: FOR UPDATE on SubscriberID=1 to holds 30s.
  - Part 2: Blocked to waits to updates after release.
  - Part 3: pg_locks + pg_stat_activity to shows blocking PID.
- Result:  
  - Lock diagnostics 100% accurate – blocker & blocked identified.

			*****END OF SECTION A*****
===================================================================================================================
SECTION B: Advanced Triggers & Analytics

B1: Declarative Constraints Hardening
- Goal: Enforce data quality on Subscriber & SIM.
- Acrivity done:
  - FullName >= 3 chars, NationalID = 16 digits, valid districts.
  - Inserting PhoneNumber ~ ^\+250[0-9]{9}$, SimID > 0.
- Result:  
  - All 12 test cases passed – invalid inserts rejected with correct errors.
-------------------------------------------------------------------------------------
B2: E-C-A Trigger for Denormalized Balance
- Goal: Auto-update SUBSCR_BALANCE on TopUp/CDR changes.
-Activity done:
  - Triggers on INSERT/UPDATE/DELETE of TopUp & CDR_A.
  - Audit trail in SUBSCR_BAL_AUDIT.
- Result:  
  - Balance updates real-time.  
  - Audit log shows +10000 to -750 to +2000 to +750 to correct.
-------------------------------------------------------------------------------------
B3: Recursive Plan Hierarchy Roll-Up
- Goal: Aggregate subscribers & revenue up the plan tree.
- Activity done:
  - PLAN_TREE with 3 levels: Root to Category to Plan.
  - Recursive CTE to 900 total subscribers, RWF 139,500,000 revenue.
- Result:  
  - Prepaid Plans: 350 subs, RWF 1.435M  
  - Postpaid Plans: 550 subs, RWF 138.065M  
  - Indented tree view works perfectly.
-------------------------------------------------------------------------------------
B4: Knowledge Base with Transitive Inference
- Goal: Creating TRIPLES for Model telecom service rules to infer new facts.
- Activity done:
  - service_knowledge table + 15 facts.
  - Inferred:  
    - Premium Plan is_a Telecom Service  
    - Premium Plan requires Valid ID  
    - Premium Plan includes Internet Access (inherited)
- Result:  
  - 18 inferred facts, confidence >= 0.90.  
  - No circular dependencies.
-------------------------------------------------------------------------------------
B5 : Real-Time Business Alert System
- Goal: Auto-detect violations to log alerts + actions.
- Done:
  - Tables: business_limits, business_alerts, alert_actions.
  - 4 triggers on cdr_fact + subscriber_balance_summary.
  - Safe creation: only if tables exist to no errors.
- Result:  
  | Test | Triggered? | Alert |
  |------|------------|-------|
  | Daily Data > 5000 MB | Yes | Warning |
  | Call > 120 min | Yes | Warning |
  | Monthly Spend > 50,000 RWF | Yes | Critical |
  | Balance < 0 | Yes | Critical + suspend |
