CREATE TABLE "bulk" (
  "id" SERIAL PRIMARY KEY,
  "updated_at" varchar NOT NULL,
  "download_uri" varchar NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT (now()),
  "status" varchar NOT NULL
);
