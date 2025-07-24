CREATE TABLE media_metadata_ (
   -- Primary identifiers
   id BIGSERIAL PRIMARY KEY,
   file_id TEXT NOT NULL,

   -- Data
   adult BOOLEAN NOT NULL,
   backdrop_path TEXT NOT NULL,
   tmdb_id BIGINT NOT NULL,
   original_language TEXT NOT NULL,
   original_title TEXT NOT NULL,
   overview TEXT NOT NULL,
   popularity NUMERIC NOT NULL,
   poster_path TEXT NOT NULL,
   release_date DATE NOT NULL,
   title TEXT NOT NULL,
   video BOOLEAN NOT NULL,

   -- Audit fields
   created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
   last_updated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

   -- Constraints
   CONSTRAINT fk_file_media_metadata_file_id FOREIGN KEY(file_id) REFERENCES file_(file_id) ON DELETE CASCADE
);

-- Trigger for media_metadata_ table (not file_)
CREATE TRIGGER update_media_metadata_last_updated
   BEFORE UPDATE ON media_metadata_
   FOR EACH ROW
   EXECUTE FUNCTION update_last_updated_column();