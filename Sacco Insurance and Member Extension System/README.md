# SACCO Insurance and Member Extension System
## Parallel and Distributed Database Implementation

### Project Overview
This project implements a distributed database system for a SACCO (Savings and Credit Cooperative Organization) in Rwanda, demonstrating advanced database management concepts including parallel query execution, distributed transactions, and database optimization.

---

## Table of Contents
1. [System Architecture](#system-architecture)
2. [Database Structure](#database-structure)
3. [Installation Guide](#installation-guide)
4. [Task Descriptions](#task-descriptions)
5. [Execution Instructions](#execution-instructions)
6. [Performance Results](#performance-results)
7. [Deliverables](#deliverables)

---

## System Architecture

### Distributed Database Design
The system uses **horizontal fragmentation** to split data across two branch locations:
- **Kigali Branch** (branch_kigali schema)
- **Musanze Branch** (branch_musanze schema)

### Three-Tier Architecture
\`\`\`
┌─────────────────────────────────┐
│   Presentation Layer            │
│   (Web/Mobile Interface)        │
└─────────────────────────────────┘
              ↕
┌─────────────────────────────────┐
│   Application Layer             │
│   (Business Logic & API)        │
└─────────────────────────────────┘
              ↕
┌─────────────────────────────────┐
│   Database Layer                │
│   (PostgreSQL Distributed)      │
│   - Kigali Branch DB            │
│   - Musanze Branch DB           │
│   - Central Reporting DB        │
└─────────────────────────────────┘
\`\`\`

---

## Database Structure

### Core Tables (per branch)
1. **Member** - SACCO member information
2. **Officer** - Branch officers and staff
3. **LoanAccount** - Loan records and status
4. **InsurancePolicy** - Insurance policies
5. **Claim** - Insurance claims
6. **Payment** - Payment transactions

### Fragmentation Strategy
- **Type**: Horizontal Fragmentation
- **Criterion**: Branch location (Kigali vs Musanze)
- **Benefits**: Data locality, reduced network traffic, improved performance

---

## Installation Guide

### Prerequisites
- PostgreSQL 13 or higher
- psql command-line tool
- Sufficient permissions to create databases and schemas

### Setup Steps

1. **Clone the repository**
\`\`\`bash
git clone <your-repository-url>
cd saccorwanda
\`\`\`

2. **Execute setup scripts in order**
\`\`\`bash
# Connect to PostgreSQL
psql -U postgres -d your_database

# Run scripts in sequence
\i scripts/TASK_01_distributed_schema_fragmentation.sql
\i scripts/TASK_02_database_links_fdw.sql
\i scripts/TASK_03_parallel_query_execution.sql
\i scripts/TASK_04_two_phase_commit.sql
\i scripts/TASK_05_distributed_rollback_recovery.sql
\i scripts/TASK_06_distributed_concurrency_control.sql
\i scripts/TASK_07_parallel_data_loading_etl.sql
\i scripts/TASK_08_three_tier_architecture.sql
\i scripts/TASK_09_distributed_query_optimization.sql
\i scripts/TASK_10_performance_benchmark.sql
\`\`\`

---

## Task Descriptions

### Task 1: Distributed Schema Design and Fragmentation (2 marks)
**Objective**: Split database into two logical nodes using horizontal fragmentation

**Key Features**:
- Separate schemas for Kigali and Musanze branches
- Identical table structures with branch-specific constraints
- Sample data for both branches
- Indexes for performance optimization

**Deliverables**:
- ER diagram showing fragmentation
- SQL scripts creating both schemas
- Verification queries

---

### Task 2: Database Links and Foreign Data Wrappers (2 marks)
**Objective**: Create database links between schemas using postgres_fdw

**Key Features**:
- Foreign data wrapper configuration
- Remote table access
- Distributed joins across branches
- Cross-branch queries

**Deliverables**:
- FDW setup scripts
- Remote SELECT demonstrations
- Distributed join examples

---

### Task 3: Parallel Query Execution (2 marks)
**Objective**: Enable and demonstrate parallel query execution

**Key Features**:
- Parallel worker configuration
- Serial vs parallel performance comparison
- EXPLAIN PLAN analysis
- Execution time measurements

**Deliverables**:
- Parallel execution scripts
- Performance comparison data
- EXPLAIN PLAN outputs

---

### Task 4: Two-Phase Commit Simulation (2 marks)
**Objective**: Demonstrate distributed transaction atomicity

**Key Features**:
- Multi-node transaction coordination
- Prepared transactions
- Commit/rollback across branches
- Transaction state monitoring

**Deliverables**:
- 2PC implementation scripts
- Transaction verification queries
- Atomicity demonstration

---

### Task 5: Distributed Rollback and Recovery (2 marks)
**Objective**: Simulate network failure and recovery procedures

**Key Features**:
- Transaction failure simulation
- Unresolved transaction detection
- Manual recovery procedures
- Rollback force operations

**Deliverables**:
- Failure simulation scripts
- Recovery procedure documentation
- Transaction resolution examples

---

### Task 6: Distributed Concurrency Control (2 marks)
**Objective**: Demonstrate lock conflicts and resolution

**Key Features**:
- Concurrent update scenarios
- Lock monitoring queries
- Deadlock detection
- Optimistic locking implementation

**Deliverables**:
- Concurrency test scripts
- Lock analysis queries
- Deadlock resolution examples

---

### Task 7: Parallel Data Loading / ETL Simulation (2 marks)
**Objective**: Perform parallel data aggregation and loading

**Key Features**:
- Large dataset generation (100,000 records)
- Serial vs parallel ETL comparison
- Batch processing
- Performance metrics collection

**Deliverables**:
- ETL scripts
- Performance comparison data
- Throughput analysis

---

### Task 8: Three-Tier Client-Server Architecture Design (2 marks)
**Objective**: Design and document three-tier architecture

**Key Features**:
- Presentation layer design
- Application layer services
- Database layer structure
- API views and stored procedures

**Deliverables**:
- Architecture diagram
- Data flow documentation
- API implementation examples

---

### Task 9: Distributed Query Optimization (2 marks)
**Objective**: Analyze and optimize distributed queries

**Key Features**:
- EXPLAIN PLAN analysis
- Query optimization techniques
- Index usage evaluation
- Materialized views

**Deliverables**:
- Optimization scripts
- EXPLAIN PLAN outputs
- Performance improvement analysis

---

### Task 10: Performance Benchmark and Report (2 marks)
**Objective**: Compare centralized, parallel, and distributed execution

**Key Features**:
- Three execution modes tested
- Complex query benchmarks
- Resource utilization analysis
- Scalability evaluation

**Deliverables**:
- Benchmark scripts
- Performance comparison tables
- Scalability analysis report

---

## Execution Instructions

### Running Individual Tasks

Each task can be executed independently:

\`\`\`bash
# Example: Run Task 1
psql -U postgres -d your_database -f scripts/TASK_01_distributed_schema_fragmentation.sql
\`\`\`

### Running All Tasks

Execute the master setup script:

\`\`\`bash
psql -U postgres -d your_database -f scripts/00_master_setup.sql
\`\`\`

### Viewing Results

\`\`\`sql
-- Check created schemas
\dn

-- View tables in a schema
\dt branch_kigali.*

-- Query sample data
SELECT * FROM branch_kigali.Member LIMIT 5;

-- View performance benchmarks
SELECT * FROM public.performance_benchmark;
\`\`\`

---

## Performance Results

### Expected Performance Improvements

| Query Type | Centralized | Parallel | Distributed | Best Mode |
|------------|-------------|----------|-------------|-----------|
| Simple Aggregation | 125ms | 45ms | 79ms | Parallel |
| Complex Join | 450ms | 156ms | 234ms | Parallel |
| Cross-Branch Query | 567ms | N/A | 234ms | Distributed |
| Large Dataset Scan | 2500ms | 800ms | 1100ms | Parallel |

### Scalability Analysis

- **Parallel Execution**: 60-70% performance improvement for large datasets
- **Distributed Execution**: 40-50% improvement for cross-branch queries
- **Resource Efficiency**: Parallel uses more CPU but reduces overall time

---

## Deliverables

### 1. SQL Script File ✓
- All 10 tasks in separate files
- Comprehensive comments
- Verification queries included

### 2. Lab Report (PDF) - Template Structure

\`\`\`
1. Cover Page
   - Student Name
   - Student ID
   - Course: Advanced Database Management Systems
   - Topic: Parallel and Distributed Databases
   - Date

2. Table of Contents

3. Introduction
   - Project overview
   - System architecture
   - Technologies used

4. Task Solutions (Tasks 1-10)
   For each task:
   - Question statement
   - SQL code with comments
   - Screenshots of execution
   - Results and analysis

5. ER Diagram
   - Distributed schema design
   - Fragmentation strategy
   - Relationships

6. Three-Tier Architecture Diagram
   - Layer descriptions
   - Data flow
   - Component interactions

7. Performance Comparison Table
   - Centralized vs Parallel vs Distributed
   - Execution times
   - Resource utilization

8. Reflective Note
   - Lessons learned
   - Challenges faced
   - Best practices discovered

9. Conclusion

10. References
\`\`\`

### 3. ER Diagram ✓
See `docs/ER_DIAGRAM.md` for detailed entity-relationship diagram

### 4. Three-Tier Architecture Diagram ✓
See `docs/ARCHITECTURE.md` for architecture documentation

### 5. Performance Comparison Table ✓
See Task 10 results in `scripts/TASK_10_performance_benchmark.sql`

### 6. Reflective Note ✓
See `docs/REFLECTIVE_NOTE.md`

---

## GitHub Repository Structure

\`\`\`
saccorwanda/
├── README.md                          # This file
├── scripts/
│   ├── TASK_01_distributed_schema_fragmentation.sql
│   ├── TASK_02_database_links_fdw.sql
│   ├── TASK_03_parallel_query_execution.sql
│   ├── TASK_04_two_phase_commit.sql
│   ├── TASK_05_distributed_rollback_recovery.sql
│   ├── TASK_06_distributed_concurrency_control.sql
│   ├── TASK_07_parallel_data_loading_etl.sql
│   ├── TASK_08_three_tier_architecture.sql
│   ├── TASK_09_distributed_query_optimization.sql
│   └── TASK_10_performance_benchmark.sql
├── docs/
│   ├── ER_DIAGRAM.md
│   ├── ARCHITECTURE.md
│   ├── REFLECTIVE_NOTE.md
│   └── LAB_REPORT_TEMPLATE.md
└── results/
    ├── screenshots/
    └── performance_data/
\`\`\`

---

## Key Learning Outcomes

By completing this project, you will:

1. ✓ Build and operate a distributed database environment in PostgreSQL
2. ✓ Demonstrate parallel query and DML operations for performance scaling
3. ✓ Implement and analyze distributed transactions (2PC) and recovery
4. ✓ Understand distributed concurrency and global locking
5. ✓ Design and justify a three-tier client-server architecture

---

## Technologies Used

- **Database**: PostgreSQL 13+
- **Extensions**: postgres_fdw
- **Query Optimization**: EXPLAIN ANALYZE, BUFFERS
- **Parallel Execution**: max_parallel_workers_per_gather
- **Transaction Management**: Prepared transactions, 2PC

---

## Contact Information

**Student**: [Your Name]  
**Student ID**: [Your ID]  
**Email**: [Your Email]  
**GitHub**: [Your GitHub Profile]

---

## License

This project is submitted as part of the Advanced Database Management Systems course at the University of Rwanda, African Center of Excellence in Data Science (ACE-DS).

---

## Acknowledgments

- **Instructor**: Rukundo Prince
- **Institution**: University of Rwanda - College of Business and Economics
- **Program**: African Center of Excellence in Data Science (ACE-DS)

---

**GOOD LUCK!**
