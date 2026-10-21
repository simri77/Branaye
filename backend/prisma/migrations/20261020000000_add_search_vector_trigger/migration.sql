-- Populate searchVector for existing rows
UPDATE "notes" SET "searchVector" = to_tsvector('english', coalesce("title",'') || ' ' || coalesce("content",''));

-- Trigger function to keep searchVector in sync
CREATE OR REPLACE FUNCTION notes_search_vector_update() RETURNS trigger AS $$
BEGIN
  NEW."searchVector" := to_tsvector('english', coalesce(NEW."title",'') || ' ' || coalesce(NEW."content",''));
  RETURN NEW;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS notes_search_vector_trigger ON "notes";
CREATE TRIGGER notes_search_vector_trigger
  BEFORE INSERT OR UPDATE ON "notes"
  FOR EACH ROW EXECUTE FUNCTION notes_search_vector_update();
