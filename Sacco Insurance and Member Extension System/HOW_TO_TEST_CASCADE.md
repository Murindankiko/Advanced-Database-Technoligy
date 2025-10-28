# How to Test CASCADE DELETE (Simple Guide for Beginners)

## What is CASCADE DELETE?

When you delete a **Claim**, its related **Payment** is automatically deleted too.

This happens because of the `ON DELETE CASCADE` constraint.

---

## How to Test

### Step 1: Open pgAdmin 4
1. Connect to your `sacco` database
2. Open the Query Tool

### Step 2: Run the Test Script
1. Open file: `scripts/test_cascade_simple.sql`
2. Click the **Execute** button (▶️)

### Step 3: Watch the Results

You will see:

**BEFORE DELETION:**
- Claim 1 has a Payment
- Claim 2 has a Payment

**AFTER TEST 1:**
- Claim 1 is deleted
- ✓ Payment for Claim 1 is **automatically deleted** (CASCADE worked!)

**AFTER TEST 2:**
- Claim 2 is deleted
- ✓ Payment for Claim 2 is **automatically deleted** (CASCADE worked!)

---

## What You Should See

\`\`\`
=== BEFORE DELETION ===
ClaimID | AmountClaimed | PaymentID | PaymentAmount
   1    |   100000.00   |     3     |   100000.00
   2    |    50000.00   |     1     |    50000.00

=== TEST 1: Deleting Claim 1 ===
✓ CASCADE WORKED: Payment for Claim 1 was automatically deleted

=== TEST 2: Deleting Claim 2 ===
✓ CASCADE WORKED: Payment for Claim 2 was automatically deleted

=== FINAL SUMMARY ===
Claims Remaining: 3
Payments Remaining: 3
\`\`\`

---

## Why Does This Happen?

In the **Payment** table definition:

\`\`\`sql
CONSTRAINT fk_payment_claim FOREIGN KEY (ClaimID) 
    REFERENCES Claim(ClaimID) ON DELETE CASCADE
\`\`\`

The `ON DELETE CASCADE` means:
- When a Claim is deleted
- Its Payment is **automatically** deleted
- You don't need to delete the Payment manually

---

## Important Notes

⚠️ **Before running the test:**
- Make sure you have run `00_master_setup.sql` first
- This test will delete Claims 1 and 2 permanently

💡 **To reset the data:**
- Run `00_master_setup.sql` again to restore all sample data

---

## Summary

✅ **2 DELETE queries** are provided in the test script  
✅ Both demonstrate **CASCADE DELETE** in action  
✅ Messages show when CASCADE works correctly  
✅ Simple and easy to understand for beginners
