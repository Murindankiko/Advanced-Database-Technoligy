# Advanced-Database-Technoligy

# Smart Traffic Violation Monitoring System - Rwanda
## SmartTrafficRwandaDB

A comprehensive PostgreSQL database system for managing traffic violations, fines, and payments in Rwanda.

## Database Overview

This system tracks:
- Traffic officers and their stations
- Drivers and their licenses
- Vehicles and their status
- Traffic violations and penalties
- Fines and payment records

## Database Schema

### Tables
1. **Officer** - Traffic police officer information
2. **Driver** - Driver details and license information
3. **Vehicle** - Vehicle registration linked to drivers
4. **Violation** - Traffic violation records
5. **Fine** - Fine details for violations
6. **Payment** - Payment transaction records

### Key Relationships
- Driver → Vehicle (1:N)
- Vehicle → Violation (1:N)
- Officer → Violation (1:N)
- Violation → Fine (1:1) with CASCADE DELETE
- Fine → Payment (1:1)

## Installation & Setup

### Prerequisites
- PostgreSQL 12 or higher
- pgAdmin 4 (recommended)

### Setup Instructions

1. **Create Database**
   \`\`\`sql
   CREATE DATABASE SmartTrafficRwandaDB;
   \`\`\`

2. **Execute Scripts in Order**
   Run the scripts in the `/scripts` folder in numerical order:
   
   - `01-create-schema.sql` - Creates all tables with constraints
   - `02-insert-sample-data.sql` - Inserts sample Rwandan data
   - `03-query-unpaid-fines-by-driver.sql` - Query unpaid fines
   - `04-update-violation-after-payment.sql` - Payment processing
   - `05-query-officers-most-fines.sql` - Officer statistics
   - `06-create-view-penalties-by-city.sql` - City-based views
   - `07-create-trigger-flag-multiple-offenses.sql` - Auto-flagging trigger
   - `08-additional-queries.sql` - Useful reporting queries

## Features

### Automated Features
- **Cascade Deletion**: Deleting a violation automatically removes associated fines
- **Auto-Flagging**: Drivers with 3+ violations are automatically flagged
- **Offense Tracking**: Automatic offense count updates per driver

### Key Queries
- Total unpaid fines by driver
- Officers issuing the most fines
- Penalties summary by city
- Overdue fines report
- Revenue by payment method
- Monthly violation trends

### Views
- `vw_penalties_by_city` - Comprehensive city-based statistics
- `vw_common_violations_by_city` - Most common violations per city

### Functions
- `process_payment()` - Process fine payments
- `recalculate_all_driver_offenses()` - Recalculate offense counts

## Sample Data

The database includes realistic Rwandan context:
- **Cities**: Kigali, Huye, Rubavu, Musanze
- **Plate Numbers**: RAD-123A, RAB-456B format
- **Names**: Rwandan names (Mugabo, Uwase, Niyonzima, etc.)
- **Payment Methods**: Mobile Money, Cash, Bank Transfer, Card

## Usage Examples

### Check Unpaid Fines
\`\`\`sql
SELECT * FROM vw_penalties_by_city;
\`\`\`

### Process a Payment
\`\`\`sql
SELECT process_payment(1, 50000, 'Mobile Money');
\`\`\`

### View Flagged Drivers
\`\`\`sql
SELECT * FROM Driver WHERE IsFlagged = TRUE;
\`\`\`

### Get Officer Statistics
\`\`\`sql
-- Run script 05-query-officers-most-fines.sql
\`\`\`

## Constraints & Validation

- Phone numbers validated with regex pattern
- Penalty amounts must be positive
- Fine status: Unpaid, Paid, Overdue
- Vehicle status: Active, Suspended, Impounded
- Payment methods: Cash, Mobile Money, Bank Transfer, Card

## Performance Optimization

Indexes created on:
- Vehicle.DriverID
- Violation.VehicleID
- Violation.OfficerID
- Violation.Date
- Fine.Status
- Driver.City

## Support

For issues or questions about this database system, please refer to the SQL comments in each script file for detailed explanations.

---
**Database Version**: 1.0  
**Last Updated**: January 2025  
**Compatible with**: PostgreSQL 12+
