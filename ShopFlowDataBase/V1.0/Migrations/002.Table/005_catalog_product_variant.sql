CREATE TABLE IF NOT EXISTS catalog.product_variant
(
    product_variant_id UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    product_id         UUID         NOT NULL REFERENCES catalog.product (product_id) ON DELETE CASCADE,
    sku                VARCHAR(100) NOT NULL,
    barcode            VARCHAR(100),
    size               VARCHAR(50),
    color              VARCHAR(100),
    price_amount       BIGINT       NOT NULL,
    compare_at_amount  BIGINT,
    currency           CHAR(3)      NOT NULL DEFAULT 'VND',
    attributes         JSONB        NOT NULL DEFAULT '{}'::jsonb,
    version            INT          NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT uq_product_variant_sku UNIQUE (sku),
    CONSTRAINT uq_product_variant_barcode UNIQUE (barcode),
    CONSTRAINT chk_product_variant_price_nonneg CHECK (price_amount >= 0),
    CONSTRAINT chk_product_variant_compare CHECK (
        compare_at_amount IS NULL OR compare_at_amount >= price_amount
        ),
    CONSTRAINT chk_product_variant_version_nonneg CHECK (version >= 0)
);

CREATE INDEX IF NOT EXISTS idx_product_variant_product_id ON catalog.product_variant (product_id);
