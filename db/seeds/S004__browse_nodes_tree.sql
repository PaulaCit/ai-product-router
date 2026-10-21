-- ============================================================
-- S004: Árvore de Navegação (browse_nodes)
-- 4 níveis: Departamento > Seção > Subsecção > Página Folha
--
-- Duas vertentes: Eletrônicos e Esportes & Fitness
-- Inclui um nó de campanha sazonal (is_campaign = TRUE)
-- ============================================================

-- ── Nível 1: Departamentos (raiz) ────────────────────────────
INSERT INTO browse_nodes
    (name, parent_id, is_leaf, slug, seo_title, seo_description, display_order) VALUES
    ('Eletrônicos',       NULL, FALSE, 'eletronicos',
     'Eletrônicos | Loja', 'Os melhores eletrônicos com entrega rápida.', 1),  -- id = 1

    ('Esportes & Fitness', NULL, FALSE, 'esportes-e-fitness',
     'Esportes & Fitness | Loja', 'Equipamentos e acessórios para sua performance.', 2); -- id = 2

-- ── Nível 2: Seções ──────────────────────────────────────────
INSERT INTO browse_nodes
    (name, parent_id, is_leaf, slug, seo_title, display_order) VALUES
    ('Áudio e Fones',         1, FALSE, 'audio-e-fones',
     'Fones de Ouvido e Caixas de Som', 1),                   -- id = 3

    ('Smartphones e Acessórios', 1, FALSE, 'smartphones-e-acessorios',
     'Acessórios para Smartphones', 2),                        -- id = 4

    ('Eletrônicos para Esporte', 2, FALSE, 'eletronicos-para-esporte',
     'Tecnologia para Atletas', 1),                            -- id = 5

    ('Musculação e Treino',   2, FALSE, 'musculacao-e-treino',
     'Equipamentos de Musculação', 2);                         -- id = 6

-- ── Nível 3: Subseções ───────────────────────────────────────
INSERT INTO browse_nodes
    (name, parent_id, is_leaf, slug, seo_title, display_order) VALUES
    ('Fones Bluetooth',       3, FALSE, 'fones-bluetooth',
     'Fones de Ouvido Bluetooth sem Fio', 1),                  -- id = 7

    ('Caixas de Som',         3, FALSE, 'caixas-de-som',
     'Caixas de Som Bluetooth e Portáteis', 2),                -- id = 8

    ('Smartwatches',          5, FALSE, 'smartwatches',
     'Smartwatches e Relógios Inteligentes', 1),               -- id = 9

    ('Fones para Treino',     5, FALSE, 'fones-para-treino',
     'Fones de Ouvido para Academia e Corrida', 2);            -- id = 10

-- ── Nível 4: Páginas Folha (is_leaf = TRUE) ──────────────────
INSERT INTO browse_nodes
    (name, parent_id, is_leaf, slug, seo_title, seo_description, display_order) VALUES

    ('True Wireless',         7, TRUE, 'fones-true-wireless',
     'Melhores Fones True Wireless de 2025',
     'Fones sem fio com cancelamento de ruído, autonomia de bateria e qualidade de som premium.', 1),
                                                               -- id = 11 ← browse node #1 do produto

    ('Fones Over-Ear',        7, TRUE, 'fones-over-ear',
     'Fones Over-Ear para Home Office e Estúdio', NULL, 2),    -- id = 12

    ('Fones In-Ear com Fio',  7, TRUE, 'fones-in-ear-com-fio',
     'Fones In-Ear com Fio de Alta Fidelidade', NULL, 3),      -- id = 13

    ('Smartwatches de Corrida', 9, TRUE, 'smartwatches-de-corrida',
     'Smartwatches com GPS para Corrida e Trilha', NULL, 1),   -- id = 14

    ('Fones Esportivos à Prova D''água', 10, TRUE, 'fones-esportivos-a-prova-dagua',
     'Fones para Treino à Prova D''água IPX5+',
     'Fones resistentes à água e suor, ideais para academia, corrida e natação.', 1),
                                                               -- id = 15 ← browse node #2 do produto

    ('Presentes para Corredores', 5, TRUE, 'presentes-para-corredores',
     'Presentes para Corredores — Guia 2025', NULL, 99);       -- id = 16

-- Nó de campanha sazonal (is_campaign = TRUE) — pode ser removido sem impacto nas regras
UPDATE browse_nodes SET is_campaign = TRUE WHERE id = 16;
