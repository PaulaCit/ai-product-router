-- ============================================================
-- V002: Tabela de produtos
-- ============================================================

CREATE TABLE IF NOT EXISTS products (
    id                   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    external_sku         VARCHAR(80) UNIQUE,
    title                VARCHAR(255) NOT NULL,
    description          TEXT,
    primary_category_id  BIGINT NOT NULL REFERENCES categories(id) ON DELETE RESTRICT,
    price_cents          INTEGER NOT NULL CHECK (price_cents >= 0),
    currency             CHAR(3) NOT NULL DEFAULT 'BRL',
    status               VARCHAR(20) NOT NULL DEFAULT 'draft'
                         CHECK (status IN ('draft', 'active', 'paused', 'deleted')),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_products_primary_category ON products (primary_category_id);

CREATE INDEX idx_products_status ON products (status) WHERE status = 'active';

CREATE TRIGGER trg_products_updated_at
BEFORE UPDATE ON products
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
