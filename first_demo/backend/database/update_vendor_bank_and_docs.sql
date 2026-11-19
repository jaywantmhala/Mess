-- Migration Script: Vendor Bank Details & Document Verification Columns

-- Add Bank Account Columns to `vendors` table if missing
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS bank_name VARCHAR(255) NULL AFTER is_active;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS account_holder_name VARCHAR(255) NULL AFTER bank_name;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS account_number VARCHAR(100) NULL AFTER account_holder_name;
ALTER TABLE vendors ADD COLUMN IF NOT EXISTS ifsc_code VARCHAR(50) NULL AFTER account_number;

-- Verify Document Columns in `hotels` table
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS fssai_number VARCHAR(100) NULL;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS fssai_photo_url TEXT NULL;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS pan_number VARCHAR(100) NULL;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS pan_photo_url TEXT NULL;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS aadhar_number VARCHAR(100) NULL;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS aadhar_photo_url TEXT NULL;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS shop_act_number VARCHAR(100) NULL;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS shop_act_photo_url TEXT NULL;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS udyam_aadhar_number VARCHAR(100) NULL;
ALTER TABLE hotels ADD COLUMN IF NOT EXISTS udyam_aadhar_photo_url TEXT NULL;
