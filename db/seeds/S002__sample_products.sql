-- ============================================================
-- S002: Produto de exemplo com categorização dupla
-- Nó Principal  (id=12): Lavadoras de Alta Pressão
-- Nó Secundário (id=15): Kits de Lavagem Premium
-- ============================================================

INSERT INTO products
    (external_sku, title, description, primary_category_id, price_cents, status)
VALUES (
    'SKU-LAP-2000',
    'Lavadora de Alta Pressão 2000W com Mangueira 5m',
    'Potência de 2000W, pressão de 120 bar, bomba de indução, ideal para lavagem de carros, calçadas e áreas externas.',
    12,
    89900,
    'active'
);

INSERT INTO product_secondary_categories (product_id, category_id)
VALUES (1, 15);
