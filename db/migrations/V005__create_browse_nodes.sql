-- ============================================================
-- V005: Árvore de Navegação (browse_nodes)
-- Árvore pública, visível ao consumidor no front-end e nos menus.
-- Define os Browse Nodes — os "departamentos" da vitrine:
--   · Navegação hierárquica do site (breadcrumb visível)
--   · Campanhas e páginas de marketing (ex: "Presentes para Atletas")
--   · SEO: cada nó gera uma landing page indexável
--   · Filtros e facetas na busca
--
-- Esta árvore é curada pela equipe de Marketing e SEO.
-- Sua estrutura pode mudar com frequência (campanhas sazonais,
-- reorganizações de menu) sem impactar as regras fiscais ou de comissão.
-- Um produto pode estar em zero, um ou muitos Browse Nodes.
-- ============================================================

CREATE TABLE IF NOT EXISTS browse_nodes (
    id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    -- Nome público exibido no menu e no breadcrumb do site
    -- Ex: "Fones para Treino", "Presentes para Runners"
    name            VARCHAR(200) NOT NULL,

    -- NULL = nó raiz do menu (departamento de 1º nível)
    parent_id       BIGINT REFERENCES browse_nodes(id) ON DELETE RESTRICT,

    -- TRUE quando é uma folha navegável (gera landing page)
    is_leaf         BOOLEAN NOT NULL DEFAULT FALSE,

    -- Slug para URL pública: /esportes/audio-esportivo/fones-para-treino
    slug            VARCHAR(250) NOT NULL,

    -- Título de SEO da página (pode diferir do name do menu)
    seo_title       VARCHAR(160),

    -- Meta description para mecanismos de busca
    seo_description VARCHAR(320),

    -- Ordem de exibição dentro do mesmo nó pai (para ordenar o menu)
    display_order   SMALLINT NOT NULL DEFAULT 0,

    -- Nó de marketing temporário (ex: campanha de Natal)
    -- Nós temporários podem ser removidos sem ON DELETE RESTRICT
    is_campaign     BOOLEAN NOT NULL DEFAULT FALSE,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Navegar filhos de um nó (renderizar menu no front-end)
CREATE INDEX idx_browse_nodes_parent_id
    ON browse_nodes (parent_id);

-- Ordenação dos itens do menu por nível pai
CREATE INDEX idx_browse_nodes_display_order
    ON browse_nodes (parent_id, display_order);

-- Unicidade: mesmo slug não pode existir duas vezes na árvore
CREATE UNIQUE INDEX uq_browse_nodes_slug
    ON browse_nodes (slug);

-- Unicidade: mesmo nome no mesmo nível pai
CREATE UNIQUE INDEX uq_browse_nodes_parent_name
    ON browse_nodes (COALESCE(parent_id, -1), name);

-- Trigger: mantém updated_at sincronizado
CREATE TRIGGER trg_browse_nodes_updated_at
BEFORE UPDATE ON browse_nodes
FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
