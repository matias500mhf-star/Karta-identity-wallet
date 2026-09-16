CREATE TABLE "online_backups" (
  "user_id" UUID PRIMARY KEY REFERENCES "users"("id") ON DELETE CASCADE,
  "payload" BYTEA NOT NULL,
  "size" INTEGER NOT NULL CHECK ("size" > 0 AND "size" <= 50331648),
  "digest" CHAR(64) NOT NULL,
  "updated_at" TIMESTAMP(3) NOT NULL
);
CREATE TABLE "auth_sessions" (
  "id" UUID PRIMARY KEY,
  "user_id" UUID NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
  "expires_at" TIMESTAMP(3) NOT NULL
);
CREATE INDEX "auth_sessions_user_id_idx" ON "auth_sessions"("user_id");
CREATE INDEX "auth_sessions_expires_at_idx" ON "auth_sessions"("expires_at");
