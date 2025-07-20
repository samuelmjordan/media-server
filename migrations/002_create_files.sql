CREATE TABLE file_ (
   -- Primary identifiers
   id BIGSERIAL PRIMARY KEY,
   file_id TEXT NOT NULL,

   -- Data
   path TEXT NOT NULL,
   name TEXT NOT NULL,
   is_directory BOOLEAN NOT NULL,
   is_video BOOLEAN NOT NULL,
   size_bytes BIGINT NOT NULL,

   -- Audit fields
   created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

   -- Constraints to ensure data integrity
   CONSTRAINT file_file_id_unique UNIQUE (file_id)
);

CREATE INDEX idx_file_file_id ON file_ (file_id);

-- Trigger to automatically update last_updated timestamp
CREATE OR REPLACE FUNCTION update_last_updated_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to maintain last_updated
CREATE TRIGGER update_file_last_updated
   BEFORE UPDATE ON file_
   FOR EACH ROW
   EXECUTE FUNCTION update_last_updated_column();