CREATE TABLE IF NOT EXISTS catalog.category
(
    category_id UUID PRIMARY KEY    DEFAULT gen_random_uuid(),
    parent_id   UUID REFERENCES catalog.category (category_id),
    name        VARCHAR(255) NOT NULL,
    slug        VARCHAR(255) NOT NULL,
    description TEXT,
    image_url   VARCHAR(500),
    sort_order  INT            NOT NULL DEFAULT 0,
    created_by  VARCHAR(100) NOT NULL,
    created_date  TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by    VARCHAR(100),
    updated_date  TIMESTAMP,
    deleted_at  TIMESTAMP
);

-- Slug unique only among active rows (soft delete): same slug allowed after delete.
CREATE UNIQUE INDEX IF NOT EXISTS uq_category_slug_active ON catalog.category (slug)
    WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_category_parent_id ON catalog.category (parent_id);
CREATE INDEX IF NOT EXISTS idx_category_deleted_at ON catalog.category (deleted_at)
    WHERE deleted_at IS NULL;
