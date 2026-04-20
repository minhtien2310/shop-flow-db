CREATE TABLE IF NOT EXISTS log.stock_movement
(
    stock_movement_id UUID PRIMARY KEY    DEFAULT gen_random_uuid(),
    product_variant_id UUID        NOT NULL REFERENCES catalog.product_variant (product_variant_id),
    delta              INT         NOT NULL,
    reason             VARCHAR(50) NOT NULL,
    reference_id       VARCHAR(255),
    created_by  VARCHAR(100) NOT NULL,
    created_date  TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by    VARCHAR(100),
    updated_date  TIMESTAMP
);
