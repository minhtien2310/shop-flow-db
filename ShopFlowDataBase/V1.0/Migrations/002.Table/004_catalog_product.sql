CREATE TABLE IF NOT EXISTS catalog.product
(
    product_id  UUID PRIMARY KEY                DEFAULT gen_random_uuid(),
    category_id UUID         NOT NULL REFERENCES catalog.category (category_id),
    title       VARCHAR(500) NOT NULL,
    slug        VARCHAR(500) NOT NULL,
    description TEXT,
    brand       VARCHAR(255),
    product_status_id      INTEGER NOT NULL REFERENCES catalog.product_status (product_status_id),
    attributes  JSONB        NOT NULL DEFAULT '{}'::jsonb,
    version     INT          NOT NULL DEFAULT 0,
    created_by  VARCHAR(100) NOT NULL,
    created_date  TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by    VARCHAR(100),
    updated_date  TIMESTAMP,
    deleted_at  TIMESTAMP,
    CONSTRAINT uq_product_slug UNIQUE (slug),
    CONSTRAINT chk_product_version_nonneg CHECK (version >= 0)
);

CREATE INDEX idx_product_slug ON catalog.product (slug);
CREATE INDEX idx_product_attributes_gin ON catalog.product USING GIN (attributes);
CREATE INDEX idx_product_deleted_at ON catalog.product (deleted_at)
    WHERE deleted_at IS NULL;
