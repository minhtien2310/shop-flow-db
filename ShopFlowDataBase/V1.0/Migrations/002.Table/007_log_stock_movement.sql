CREATE TABLE IF NOT EXISTS log.stock_movement
(
    stock_movement_id UUID PRIMARY KEY    DEFAULT gen_random_uuid(),
    product_variant_id UUID        NOT NULL REFERENCES catalog.product_variant (product_variant_id),
    delta              INT         NOT NULL,
    reason             VARCHAR(50) NOT NULL,
    reference_id       VARCHAR(255),
    created_by         UUID REFERENCES identity."user" (user_id),
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stock_movement_product_variant_created ON log.stock_movement (product_variant_id, created_at DESC);
