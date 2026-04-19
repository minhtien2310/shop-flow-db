CREATE TABLE IF NOT EXISTS platform.idempotency_key
(
    idempotency_key_id UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    client_key         VARCHAR(255) NOT NULL,
    endpoint           VARCHAR(255) NOT NULL,
    request_hash       VARCHAR(64)  NOT NULL,
    response_body      TEXT,
    status_code        INT          NOT NULL,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    expires_at         TIMESTAMPTZ  NOT NULL,
    CONSTRAINT uq_idempotency_key_client_key UNIQUE (client_key)
);

CREATE INDEX IF NOT EXISTS idx_idempotency_key_expires_at ON platform.idempotency_key (expires_at);
