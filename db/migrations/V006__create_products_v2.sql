-- ============================================================
-- V006: Tabela de produtos (v2 — arquitetura duas árvores)
-- Substitui a modelagem anterior de primary_category_id.
--
-- item_type_id → system_taxonomy (obrigatório, nó-folha)
--   Determina: comissão, NCM, campos obrigatórios, logística.
--
-- A associação com browse_nodes é feita via pivot (V007).
-- ============================================================

CREATE TABLE IF NOT EXISTS products_v2 (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Chave de upsert para integração Jitterbit (idempotência)
    external_sku    VARCHAR(80) UNIQUE,

    title           VARCHAR(255) NOT NULL,
    description     TEXT,

    -- Item Type: vínculo com a taxonomia do sistema (regras rígidas)
    -- Deve apontar obrigatoriamente para um nó-folha de system_taxonomy
    item_type_id    BIGINT NOT NULL
                    REFERENCES system_taxonomy(id) ON DELETE RESTRICT,

    -- Preço em centavos (evita imprecisão de ponto flutuante)
    price_cents     INTEGER NOT NULL CHECK (price_cents >= 0),
    currency        CHAR(3)  NOT NULL DEFAULT 'BRL',

    status          VARCHAR(20) NOT NULL DEFAULT 'draft'
                    CHECK (status IN ('draft', 'active', 'paused', 'deleted')),

    -- Rastreabilidade: qual fluxo criou/atualizou o produto por último
    -- 'jitterbit' = ingestão batch | 'dashboard' = cadastro manual
    last_updated_by VARCHAR(20) NOT NULL DEFAULT 'dashboard'
                    CHECK (last_updated_by IN ('jitterbit', 'dashboard', 'ai_engine')),

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Índice de lookup por Item Type (relatórios, validação de comissão)
CREATE INDEX idx_products_v2_item_type
    ON products_v2 (item_type_id);

-- Índice parcial: queries de vitrine sempre filtram por status = 'active'
CREATE INDEX idx_products_v2_active
    ON products_v2 (item_type_id)
    WHERE status = 'active';

CREATE TRIGGER trg_products_v2_updated_at
BEFORE UPDATE ON products_v2
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
