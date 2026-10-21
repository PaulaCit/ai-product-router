-- ============================================================
-- S003: Árvore da Taxonomia do Sistema (system_taxonomy)
-- 4 níveis: Divisão > Classe > Grupo > Item Type (folha)
--
-- Foco: Eletrônicos (Audio) e Esportes (Wearables)
-- Os Item Types de folha definem NCM e comissão.
-- ============================================================

-- ── Nível 1: Divisões (raiz, parent_id = NULL) ──────────────
INSERT INTO system_taxonomy (name, parent_id, is_leaf, ncm_code, commission_bps, slug) VALUES
    ('Electronics',  NULL, FALSE, NULL, NULL, 'electronics'),   -- id = 1
    ('Sports',       NULL, FALSE, NULL, NULL, 'sports');         -- id = 2

-- ── Nível 2: Classes ─────────────────────────────────────────
INSERT INTO system_taxonomy (name, parent_id, is_leaf, ncm_code, commission_bps, slug) VALUES
    ('Audio',                    1, FALSE, NULL, NULL, 'electronics-audio'),          -- id = 3
    ('Mobile Accessories',       1, FALSE, NULL, NULL, 'electronics-mobile-acc'),     -- id = 4
    ('Sports Electronics',       2, FALSE, NULL, NULL, 'sports-electronics'),         -- id = 5
    ('Fitness Equipment',        2, FALSE, NULL, NULL, 'sports-fitness-equipment');   -- id = 6

-- ── Nível 3: Grupos ──────────────────────────────────────────
INSERT INTO system_taxonomy (name, parent_id, is_leaf, ncm_code, commission_bps, slug) VALUES
    ('Headphones',               3, FALSE, NULL, NULL, 'audio-headphones'),           -- id = 7
    ('Speakers',                 3, FALSE, NULL, NULL, 'audio-speakers'),             -- id = 8
    ('Smartwatches',             5, FALSE, NULL, NULL, 'sports-smartwatches'),        -- id = 9
    ('Heart Rate Monitors',      5, FALSE, NULL, NULL, 'sports-hrm');                 -- id = 10

-- ── Nível 4: Item Types (folhas — is_leaf = TRUE) ────────────
-- NCM 85183000 = Fones de ouvido e seus acessórios (importação/fabricação)
-- NCM 85177099 = Aparelhos de comunicação sem fio (Bluetooth genérico)
-- NCM 91021900 = Relógios de pulso (smartwatches)
INSERT INTO system_taxonomy (name, parent_id, is_leaf, ncm_code, commission_bps, slug) VALUES
    ('True Wireless Earbuds',    7, TRUE, '85183000', 1200, 'item-true-wireless-earbuds'),  -- id = 11 ← usado no produto
    ('Over-Ear Headphones',      7, TRUE, '85183000', 1200, 'item-over-ear-headphones'),    -- id = 12
    ('Sports Earphones',         7, TRUE, '85183000', 1100, 'item-sports-earphones'),       -- id = 13
    ('Bluetooth Speakers',       8, TRUE, '85177099', 1300, 'item-bluetooth-speakers'),     -- id = 14
    ('GPS Smartwatch',           9, TRUE, '91021900',  900, 'item-gps-smartwatch'),         -- id = 15
    ('Fitness Tracker',          9, TRUE, '91021900',  850, 'item-fitness-tracker');        -- id = 16
