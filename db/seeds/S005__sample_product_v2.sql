-- ============================================================
-- S005: Produto de exemplo — "Fone Esportivo Bluetooth"
--
-- item_type_id = 11 (True Wireless Earbuds)
--   → governa: NCM 85183000, comissão 12%, campos obrigatórios
--
-- Browse Nodes:
--   id = 11 (True Wireless)               — atribuído pela IA com 94% de confiança
--   id = 15 (Fones Esportivos à Prova D'água) — atribuído manualmente via Dashboard
-- ============================================================

INSERT INTO products_v2
    (external_sku, title, description, item_type_id, price_cents, status, last_updated_by)
VALUES (
    'SKU-FBT-X200',
    'Fone Esportivo Bluetooth X200 — TWS IPX5 30h',
    'True Wireless com driver de 10mm, cancelamento de ruído híbrido, '
    'resistência IPX5 a água e suor, autonomia de 8h (+ 22h no case) '
    'e latência de 45ms para treinos e jogos.',
    11,       -- item_type_id → "True Wireless Earbuds" (NCM 85183000, comissão 12%)
    24990,    -- R$ 249,90 em centavos
    'active',
    'jitterbit'
);
-- Produto recebe id = 1 (banco limpo)

-- Browse Node #1: atribuído pelo motor de IA com alta confiança
INSERT INTO product_browse_nodes (product_id, browse_node_id, assigned_by, ai_confidence)
VALUES (1, 11, 'ai_engine', 0.940);
-- O produto aparece em: Eletrônicos > Áudio e Fones > Fones Bluetooth > True Wireless

-- Browse Node #2: atribuído manualmente pela equipe de categoria no Dashboard
INSERT INTO product_browse_nodes (product_id, browse_node_id, assigned_by, ai_confidence)
VALUES (1, 15, 'dashboard', NULL);
-- O produto aparece em: Esportes & Fitness > Eletrônicos para Esporte > Fones para Treino > Fones Esportivos à Prova D'água
