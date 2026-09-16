-- Add secure, expiring document shares.
CREATE TABLE "document_shares" (
    "id" UUID NOT NULL,
    "document_id" UUID NOT NULL,
    "created_by_id" UUID NOT NULL,
    "token_hash" CHAR(64) NOT NULL,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "revoked_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "document_shares_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "document_shares_token_hash_key" ON "document_shares"("token_hash");
CREATE INDEX "document_shares_document_id_idx" ON "document_shares"("document_id");
CREATE INDEX "document_shares_expires_at_idx" ON "document_shares"("expires_at");

ALTER TABLE "document_shares"
  ADD CONSTRAINT "document_shares_document_id_fkey"
  FOREIGN KEY ("document_id") REFERENCES "documents"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "document_shares"
  ADD CONSTRAINT "document_shares_created_by_id_fkey"
  FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
