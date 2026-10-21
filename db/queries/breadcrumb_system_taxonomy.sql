-- ============================================================
-- QUERY 1: Caminho do Sistema (invisível ao consumidor)
-- Retorna o Item Type e seu caminho completo na system_taxonomy.
-- Usado internamente para: aplicar comissão, validar NCM,
-- determinar campos obrigatórios e regras logísticas.
--
-- Parâmetro: :product_id
-- ============================================================

WITH RECURSIVE system_path (
    node_id,
    node_name,
    parent_id,
    depth,
    path_text
) AS (

    -- Caso base: parte do Item Type vinculado ao produto
    SELECT
        st.id,
        st.name,
        st.parent_id,
        0                   AS depth,
        st.name::TEXT       AS path_text
    FROM products_v2 p
    JOIN system_taxonomy st ON st.id = p.item_type_id
    WHERE p.id = :product_id

    UNION ALL

    -- Caso recursivo: sobe para o nó pai acumulando o caminho
    SELECT
        parent.id,
        parent.name,
        parent.parent_id,
        sp.depth + 1,
        parent.name || ' > ' || sp.path_text   -- constrói "Raiz > ... > Item Type"
    FROM system_taxonomy parent
    JOIN system_path sp ON sp.parent_id = parent.id
)

-- Seleciona apenas o caminho mais longo (da raiz até o Item Type)
SELECT
    p.id                        AS product_id,
    p.external_sku,
    p.title                     AS product_title,
    sp.path_text                AS system_breadcrumb,
    st.ncm_code,
    st.commission_bps,
    ROUND(st.commission_bps / 100.0, 2) || '%' AS commission_rate
FROM system_path sp
JOIN products_v2 p      ON p.id = :product_id
JOIN system_taxonomy st ON st.id = p.item_type_id
WHERE sp.parent_id IS NULL   -- somente o nó raiz: garante que o caminho está completo
ORDER BY p.id;
