-- ============================================================
-- V003: Pivot N:N — categorias secundárias (descoberta/SEO)
-- ============================================================

CREATE TABLE IF NOT EXISTS product_secondary_categories (
    product_id   BIGINT NOT NULL REFERENCES products(id)    ON DELETE CASCADE,
    category_id  BIGINT NOT NULL REFERENCES categories(id)  ON DELETE RESTRICT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY  (product_id, category_id)
);

CREATE INDEX idx_psc_category_id ON product_secondary_categories (category_id);
