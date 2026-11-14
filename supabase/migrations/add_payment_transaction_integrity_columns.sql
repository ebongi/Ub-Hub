-- Adds the columns needed to close the payment-forgery gap:
--   consumed        - marks a successful payment as "spent" so it can only
--                      ever fund one entitlement grant (see
--                      add_payment_grant_functions.sql's _consume_payment).
--   fapshi_trans_id - write-once link from our own payment_ref to Fapshi's
--                      transId, set by the client right after collectPayment
--                      returns, and used by the fapshi-proxy edge function to
--                      find the right row when it reconciles a confirmed
--                      payment (see add_complete_payment_transaction_function.sql).
ALTER TABLE payment_transactions
  ADD COLUMN IF NOT EXISTS consumed BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS fapshi_trans_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_transactions_fapshi_trans_id
  ON payment_transactions(fapshi_trans_id) WHERE fapshi_trans_id IS NOT NULL;
