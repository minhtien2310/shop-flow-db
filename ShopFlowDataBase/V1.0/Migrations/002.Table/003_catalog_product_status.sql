CREATE TABLE IF NOT EXISTS catalog.product_status
(
    product_status_id  INTEGER PRIMARY KEY,
    status       VARCHAR(500) NOT NULL,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);
