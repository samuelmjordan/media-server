CREATE TABLE user_ (
   -- Primary identifiers
   id BIGSERIAL PRIMARY KEY,
   user_id TEXT NOT NULL,
   name TEXT NOT NULL,
   email TEXT,

   -- Audit fields
   created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

   -- Constraints to ensure data integrity
   CONSTRAINT user_user_id_unique UNIQUE (user_id),
   CONSTRAINT user_email_unique UNIQUE (email)
);

-- Index for efficient lookups by clerk_id
CREATE INDEX idx_user_user_id ON user_ (user_id);

-- Trigger to automatically update last_updated timestamp
CREATE OR REPLACE FUNCTION update_last_updated_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to maintain last_updated
CREATE TRIGGER update_users_last_updated
   BEFORE UPDATE ON user_
   FOR EACH ROW
   EXECUTE FUNCTION update_last_updated_column();