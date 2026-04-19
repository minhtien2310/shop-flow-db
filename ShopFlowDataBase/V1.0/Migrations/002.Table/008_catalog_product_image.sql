CREATE TABLE IF NOT EXISTS catalog.product_image
(
    product_image_id UUID PRIMARY KEY    DEFAULT gen_random_uuid(),
    product_id       UUID         NOT NULL REFERENCES catalog.product (product_id) ON DELETE CASCADE,
    url              VARCHAR(1000) NOT NULL,
    alt              VARCHAR(255),
    position         INT           NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ   NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_product_image_product_id ON catalog.product_image (product_id);
