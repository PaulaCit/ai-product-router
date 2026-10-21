-- ============================================================
-- V007: Pivot N:N — produtos × browse_nodes
-- Associa um produto aos nós de navegação onde ele aparece.
--
-- Esta tabela é alimentada por duas fontes:
--   1. Motor de IA (ai_engine): sugere nós com base no conteúdo
--   2. Curadoria manual (dashboard): equipe de categoria refina
--
-- Um produto pode estar em múltiplos Browse Nodes sem que isso
-- afete suas regras fiscais ou de comissão — que são determinadas
-- exclusivamente pelo item_type_id em products_v2.
-- ============================================================

CREATE TABLE IF NOT EXISTS product_browse_nodes (
    product_id      BIGINT NOT NULL REFERENCES products_v2(id)   ON DELETE CASCADE,
    browse_node_id  BIGINT NOT NULL REFERENCES browse_nodes(id)   ON DELETE RESTRICT,

    -- Rastreabilidade: quem criou esta associação
    assigned_by     VARCHAR(20) NOT NULL DEFAULT 'ai_engine'
                    CHECK (assigned_by IN ('ai_engine', 'dashboard', 'jitterbit')),

    -- Confiança do motor de IA (0.00–1.00); NULL se atribuído manualmente
    ai_confidence   NUMERIC(4,3) CHECK (ai_confidence BETWEEN 0 AND 1),

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (product_id, browse_node_id)
);

-- Índice reverso: dado um Browse Node, quais produtos ele contém
-- (usado na listagem de produtos de uma página de categoria)
CREATE INDEX idx_pbn_browse_node_id
    ON product_browse_nodes (browse_node_id);

-- Índice para filtrar associações de alta confiança da IA
CREATE INDEX idx_pbn_ai_confidence
    ON product_browse_nodes (ai_confidence)
    WHERE assigned_by = 'ai_engine';
