CREATE TABLE IF NOT EXISTS catalog.inventory
(
    inventory_id UUID PRIMARY KEY REFERENCES catalog.product_variant (product_variant_id) ON DELETE CASCADE,
    quantity     INT           NOT NULL DEFAULT 0,
    reserved     INT           NOT NULL DEFAULT 0,
    version      INT           NOT NULL DEFAULT 0,
    updated_at   TIMESTAMPTZ   NOT NULL DEFAULT now(),
    CONSTRAINT chk_inventory_quantity CHECK (quantity >= 0),
    CONSTRAINT chk_inventory_reserved CHECK (reserved >= 0),
    CONSTRAINT chk_inventory_reserved_lte_qty CHECK (reserved <= quantity),
    CONSTRAINT chk_inventory_version_nonneg CHECK (version >= 0)
);
