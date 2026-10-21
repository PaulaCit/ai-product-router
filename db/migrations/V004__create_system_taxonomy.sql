-- ============================================================
-- V004: Taxonomia do Sistema (system_taxonomy)
-- Árvore interna e invisível ao consumidor final.
-- Define Item Types — a unidade que governa regras de negócio:
--   · Taxas de comissão por categoria
--   · NCM fiscal para emissão de NF-e
--   · Campos obrigatórios de conteúdo (atributos do produto)
--   · Regras logísticas (dimensões máximas, restrições de envio)
--
-- Esta árvore é mantida pela equipe de Categoria do marketplace.
-- Sellers e consumidores nunca a veem diretamente.
-- ============================================================

CREATE TABLE IF NOT EXISTS system_taxonomy (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Nome interno do nó (ex: "Headphones", "True Wireless Earbuds")
    name            VARCHAR(150) NOT NULL,

    -- NULL = nó raiz (divisão de 1º nível, ex: "Electronics")
    parent_id       BIGINT REFERENCES system_taxonomy(id) ON DELETE RESTRICT,

    -- TRUE quando não possui filhos; representa o Item Type final
    -- Somente nós-folha (Item Types) podem ser associados a produtos
    is_leaf         BOOLEAN NOT NULL DEFAULT FALSE,

    -- Código NCM de 8 dígitos para este Item Type (obrigatório nas folhas)
    -- Ex: '85183000' = Fones de ouvido
    ncm_code        CHAR(8),

    -- Taxa de comissão em pontos percentuais (ex: 1250 = 12,50%)
    -- Armazenado como INTEGER para evitar aritmética de ponto flutuante
    commission_bps  INTEGER CHECK (commission_bps BETWEEN 0 AND 10000),

    -- Slug interno para referência na API e no painel de admin
    slug            VARCHAR(200) NOT NULL,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Regra: NCM e comissão são obrigatórios somente no nó-folha (Item Type)
    CONSTRAINT chk_leaf_requires_ncm
        CHECK (NOT is_leaf OR (ncm_code IS NOT NULL AND commission_bps IS NOT NULL))
);

-- Navegar filhos de um nó (browse da árvore no painel admin)
CREATE INDEX idx_system_taxonomy_parent_id
    ON system_taxonomy (parent_id);

-- Unicidade: mesmo nome não pode aparecer duas vezes no mesmo nível
CREATE UNIQUE INDEX uq_system_taxonomy_parent_name
    ON system_taxonomy (COALESCE(parent_id, -1), name);

-- Lookup por slug (API interna e Jitterbit)
CREATE UNIQUE INDEX uq_system_taxonomy_slug
    ON system_taxonomy (slug);

-- Apenas nós-folha podem receber produtos; índice parcial otimiza o JOIN
CREATE INDEX idx_system_taxonomy_leaves
    ON system_taxonomy (id)
    WHERE is_leaf = TRUE;

-- Trigger: mantém updated_at sincronizado
CREATE TRIGGER trg_system_taxonomy_updated_at
BEFORE UPDATE ON system_taxonomy
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
