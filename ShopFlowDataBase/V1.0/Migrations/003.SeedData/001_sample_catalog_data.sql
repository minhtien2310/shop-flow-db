-- -----------------------------------------------------------------------------
-- 1) catalog.product_status (120) — IDs 1–3 match API constants (DRAFT/ACTIVE/ARCHIVED)
-- -----------------------------------------------------------------------------
INSERT INTO catalog.product_status (product_status_id, status)
SELECT gs,
       CASE gs
           WHEN 1 THEN 'DRAFT'
           WHEN 2 THEN 'ACTIVE'
           WHEN 3 THEN 'ARCHIVED'
           ELSE 'STATUS_' || lpad(gs::text, 3, '0')
       END
FROM generate_series(1, 120) AS gs
ON CONFLICT (product_status_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2) catalog.category (120); rows 11–120 attach to one of the first 10 parents
-- -----------------------------------------------------------------------------
INSERT INTO catalog.category (category_id, parent_id, name, slug, description, image_url, sort_order, created_by)
SELECT gen_random_uuid(),
       NULL,
       'SF Category ' || lpad(gs::text, 4, '0'),
       'sf-cat-' || lpad(gs::text, 4, '0'),
       'Sample fashion category #' || gs || ' for browsing, filters, and admin lists.',
       'https://cdn.shopflow.local/categories/' || gs || '.webp',
       gs,
       'System'
FROM generate_series(1, 120) AS gs
ON CONFLICT (slug) WHERE deleted_at IS NULL DO NOTHING;

UPDATE catalog.category c
SET parent_id = p.category_id
FROM catalog.category p
WHERE c.sort_order > 10
  AND c.sort_order <= 120
  AND p.sort_order = ((c.sort_order - 1) % 10) + 1
  AND p.sort_order BETWEEN 1 AND 10;

-- -----------------------------------------------------------------------------
-- 3) catalog.product (120)
-- -----------------------------------------------------------------------------
INSERT INTO catalog.product (product_id, category_id, title, slug, description, brand, product_status_id,
                             attributes, version, created_by)
SELECT gen_random_uuid(),
       c.category_id,
       'SF Product ' || lpad(gs::text, 4, '0'),
       'sf-product-' || lpad(gs::text, 4, '0'),
       'Long description for sample product #' || gs || '. Used for listing, detail, and search scenarios.',
       (ARRAY ['UrbanThread','NorthFold','Lumen','VelvetLane','Mono','Atelier9','Stride','Kite','Mesa','Pulse'])[
           ((gs - 1) % 10) + 1],
       ((gs - 1) % 120) + 1,
       jsonb_build_object(
               'department', 'Fashion',
               'season', CASE WHEN gs % 2 = 0 THEN 'SS' ELSE 'FW' END || (2020 + (gs % 6)),
               'gender', (ARRAY ['Women', 'Men', 'Unisex'])[((gs - 1) % 3) + 1],
               'material', (ARRAY ['Cotton', 'Wool', 'Polyester', 'Silk', 'Denim'])[((gs - 1) % 5) + 1]
       ),
       0,
       'System'
FROM generate_series(1, 120) AS gs
         INNER JOIN catalog.category c ON c.sort_order = ((gs - 1) % 120) + 1
ON CONFLICT (slug) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 4) catalog.product_variant (120)
-- -----------------------------------------------------------------------------
INSERT INTO catalog.product_variant (product_variant_id, product_id, sku, barcode, size, color, price_amount,
                                     compare_at_amount, currency, attributes, version, created_by)
SELECT gen_random_uuid(),
       p.product_id,
       'SF-SKU-' || lpad(gs::text, 6, '0'),
       'SF-BC-' || lpad(gs::text, 10, '0'),
       (ARRAY ['XS', 'S', 'M', 'L', 'XL', 'XXL'])[((gs - 1) % 6) + 1],
       (ARRAY ['Black', 'Navy', 'Ivory', 'Olive', 'Burgundy', 'Sand'])[((gs - 1) % 6) + 1],
       (150000 + (gs * 1370))::bigint,
       (180000 + (gs * 1370))::bigint,
       'VND',
       jsonb_build_object(
               'weightGrams', 200 + (gs % 800),
               'hsCode', '6109.10.' || lpad((gs % 99)::text, 2, '0')
       ),
       0,
       'System'
FROM generate_series(1, 120) AS gs
         INNER JOIN catalog.product p ON p.slug = 'sf-product-' || lpad(gs::text, 4, '0')
ON CONFLICT (sku) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 5) catalog.inventory (120) — inventory_id = product_variant_id
-- -----------------------------------------------------------------------------
INSERT INTO catalog.inventory (inventory_id, quantity, reserved, version, created_by)
SELECT v.product_variant_id,
       q.qty,
       LEAST(q.res, q.qty),
       0,
       'System'
FROM catalog.product_variant v
         INNER JOIN generate_series(1, 120) AS gs ON v.sku = 'SF-SKU-' || lpad(gs::text, 6, '0')
         CROSS JOIN LATERAL (
    SELECT (50 + (gs::int % 200)) AS qty,
           (gs::int % 30) AS res
    ) AS q
ON CONFLICT (inventory_id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 6) log.stock_movement (120) — reasons per CatalogConstants.MovementReasons (max 50 chars)
-- -----------------------------------------------------------------------------
INSERT INTO log.stock_movement (stock_movement_id, product_variant_id, delta, reason, reference_id, created_by)
SELECT gen_random_uuid(),
       v.product_variant_id,
       CASE ((gs - 1) % 6)
           WHEN 0 THEN i.quantity
           WHEN 1 THEN -LEAST(3, i.quantity)
           WHEN 2 THEN -1
           WHEN 3 THEN 10
           WHEN 4 THEN -LEAST(2, i.quantity)
           ELSE LEAST(2, i.quantity)
           END,
       (ARRAY ['PURCHASE', 'RETURN', 'DAMAGE', 'ADJUSTMENT', 'RESERVE', 'RELEASE'])[((gs - 1) % 6) + 1],
       'SAMPLE-SF-MV-' || lpad(gs::text, 6, '0'),
       'System'
FROM generate_series(1, 120) AS gs
         INNER JOIN catalog.product_variant v ON v.sku = 'SF-SKU-' || lpad(gs::text, 6, '0')
         INNER JOIN catalog.inventory i ON i.inventory_id = v.product_variant_id;

-- -----------------------------------------------------------------------------
-- 7) catalog.product_image (120)
-- -----------------------------------------------------------------------------
INSERT INTO catalog.product_image (product_image_id, product_id, url, alt, position, created_by)
SELECT gen_random_uuid(),
       p.product_id,
       'https://cdn.shopflow.local/products/' || gs || '/image-1.webp',
       'SF Product ' || lpad(gs::text, 4, '0') || ' — hero image',
       1,
       'System'
FROM generate_series(1, 120) AS gs
         INNER JOIN catalog.product p ON p.slug = 'sf-product-' || lpad(gs::text, 4, '0');

-- -----------------------------------------------------------------------------
-- 8) identity.user
-- -----------------------------------------------------------------------------
INSERT INTO identity."user" (user_id, email, password_hash, role, created_date, updated_by, updated_date)
VALUES ('b885f42e-9265-4b1f-bb86-8b55498c1f70'::uuid,
        'admin@gmail.com',
        chr(36) || '2a' || chr(36) || '11' || chr(36)
            || '5LMCcawIyU/KiCe1yg.1XOBRu2Mo2QFhhSUNOOCrHRO2cPO/JFuGK',
        'Admin',
        '2026-04-20 11:26:32.361937',
        NULL,
        NULL),
       ('29599505-b886-477d-b9e9-db3696210401'::uuid,
        'user@gmail.com',
        chr(36) || '2a' || chr(36) || '11' || chr(36)
            || 'rkHWq8pg9qFH/EGE9mZG/OW91C/ju0ovPR.B2WAB3DizNvWZ0E5Le',
        'User',
        '2026-04-20 11:26:42.860227',
        NULL,
        NULL)
ON CONFLICT (email) DO NOTHING;
