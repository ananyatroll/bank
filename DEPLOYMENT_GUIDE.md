# Supabase Deployment Guide for TeleBank

## Step 1: Create Supabase Project
1. Go to https://supabase.com → New Project
2. Name: `telebank`, save the DB password, pick nearest region
3. Wait ~2 min for provisioning

## Step 2: Run SQL Schema
Go to SQL Editor → paste this → Run:

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT UNIQUE NOT NULL CHECK (char_length(username) >= 3 AND char_length(username) <= 20),
    pin_hash TEXT NOT NULL,
    balance DECIMAL(15,2) DEFAULT 0.00 CHECK (balance >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transactions table
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES users(id),
    receiver_id UUID REFERENCES users(id),
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    type TEXT NOT NULL CHECK (type IN ('send', 'request', 'airtime', 'bill', 'cashout', 'merchant', 'deposit')),
    description TEXT,
    reference TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_txn_sender ON transactions(sender_id);
CREATE INDEX idx_txn_receiver ON transactions(receiver_id);
CREATE INDEX idx_txn_created ON transactions(created_at DESC);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- Transfer money RPC function (atomic)
CREATE OR REPLACE FUNCTION transfer_money(
    p_sender_id UUID,
    p_receiver_id UUID,
    p_amount DECIMAL,
    p_type TEXT,
    p_desc TEXT
) RETURNS VOID AS $$
DECLARE
    sender_bal DECIMAL;
BEGIN
    -- Lock sender row
    SELECT balance INTO sender_bal FROM users WHERE id = p_sender_id FOR UPDATE;
    IF sender_bal < p_amount THEN
        RAISE EXCEPTION 'Insufficient balance';
    END IF;
    
    -- Update balances
    UPDATE users SET balance = balance - p_amount WHERE id = p_sender_id;
    UPDATE users SET balance = balance + p_amount WHERE id = p_receiver_id;
    
    -- Record transaction
    INSERT INTO transactions (sender_id, receiver_id, amount, type, description)
    VALUES (p_sender_id, p_receiver_id, p_amount, p_type, p_desc);
END;
$$ LANGUAGE plpgsql;

-- Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Everyone can read users (needed for username lookup)
CREATE POLICY "read_users" ON users FOR SELECT USING (true);

-- Everyone can read transactions (for demo; restrict in production)
CREATE POLICY "read_transactions" ON transactions FOR SELECT USING (true);

-- Allow inserts
CREATE POLICY "insert_users" ON users FOR INSERT WITH CHECK (true);
CREATE POLICY "insert_transactions" ON transactions FOR INSERT WITH CHECK (true);
CREATE POLICY "update_users" ON users FOR UPDATE USING (true);
```

## Step 3: Get Credentials
Project Settings → API:
- **Project URL**: `https://xxxxx.supabase.co`
- **anon/public key**: `eyJhbGci...`

## Step 4: Update Flutter Code
Open `lib/services/supabase_service.dart` and replace:
```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

## Step 5: Test with curl
```bash
# Check Supabase is alive
curl https://YOUR_PROJECT.supabase.co/rest/v1/users -H "apikey: YOUR_ANON_KEY" -H "Authorization: Bearer YOUR_ANON_KEY"
# Should return: []

# Test register (via Supabase REST API)
curl -X POST https://YOUR_PROJECT.supabase.co/rest/v1/users \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d '{"username":"testuser","pin_hash":"abc123","balance":100.00}'
```

## Step 6: Flutter Testing Checklist
- [ ] App opens, asks for PIN setup
- [ ] Create username (e.g., @alice)
- [ ] See balance (should be ETB 100.00 sign-up bonus)
- [ ] Create second account on another device (@bob)
- [ ] Send ETB 10 from @alice to @bob
- [ ] Verify @alice balance = 90, @bob balance = 110
- [ ] Check transaction history shows on both accounts

## Troubleshooting
| Error | Fix |
|-------|-----|
| `Invalid username/pin` | Check supabaseUrl and supabaseAnonKey |
| `Connection refused` | Check internet, Supabase project is active |
| `R LS policy violation` | Run the SQL policies again in Supabase |
| `transfer_money function not found` | Run the SQL schema again |
| `Username already taken` | Supabase works! Try a different username |
