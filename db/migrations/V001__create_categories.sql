-- ============================================================
-- V001: Tabela de categorias (Adjacency List)
-- ============================================================

CREATE TABLE IF NOT EXISTS categories (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(120) NOT NULL,
    parent_id       BIGINT REFERENCES categories(id) ON DELETE RESTRICT,
    is_leaf         BOOLEAN NOT NULL DEFAULT FALSE,
    slug            VARCHAR(150) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX uq_categories_parent_name
    ON categories (COALESCE(parent_id, -1), name);

CREATE INDEX idx_categories_parent_id ON categories (parent_id);

CREATE UNIQUE INDEX uq_categories_slug ON categories (slug);

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END; $$;

CREATE TRIGGER trg_categories_updated_at
BEFORE UPDATE ON categories
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
