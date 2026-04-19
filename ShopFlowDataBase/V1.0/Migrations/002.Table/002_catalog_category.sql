CREATE TABLE IF NOT EXISTS catalog.category
(
    category_id UUID PRIMARY KEY    DEFAULT gen_random_uuid(),
    parent_id   UUID REFERENCES catalog.category (category_id),
    name        VARCHAR(255) NOT NULL,
    slug        VARCHAR(255) NOT NULL,
    description TEXT,
    image_url   VARCHAR(500),
    sort_order  INT            NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
    deleted_at  TIMESTAMPTZ,
    CONSTRAINT uq_category_slug UNIQUE (slug)
);

CREATE INDEX IF NOT EXISTS idx_category_parent_id ON catalog.category (parent_id);
CREATE INDEX IF NOT EXISTS idx_category_deleted_at ON catalog.category (deleted_at)
    WHERE deleted_at IS NULL;
