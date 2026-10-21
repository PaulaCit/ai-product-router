-- ============================================================
-- QUERY 2: Caminhos de Marketing (Browse Nodes visíveis)
-- Retorna todos os caminhos de navegação onde o produto aparece.
-- Cada linha = um Browse Node com seu breadcrumb completo.
-- Usado por: front-end (breadcrumb visível), sitemap, SEO.
--
-- Parâmetro: :product_id
-- ============================================================

WITH RECURSIVE browse_path (
    start_node_id,      -- mantém o Browse Node de entrada da recursão
    node_id,
    node_name,
    parent_id,
    depth,
    path_text,
    path_slugs          -- caminho de slugs para montar a URL pública
) AS (

    -- Caso base: parte de cada Browse Node associado ao produto
    SELECT
        bn.id               AS start_node_id,
        bn.id,
        bn.name,
        bn.parent_id,
        0                   AS depth,
        bn.name::TEXT       AS path_text,
        bn.slug::TEXT       AS path_slugs
    FROM product_browse_nodes pbn
    JOIN browse_nodes bn ON bn.id = pbn.browse_node_id
    WHERE pbn.product_id = :product_id

    UNION ALL

    -- Caso recursivo: sobe para o nó pai acumulando nome e slug
    SELECT
        bp.start_node_id,
        parent.id,
        parent.name,
        parent.parent_id,
        bp.depth + 1,
        parent.name || ' > ' || bp.path_text,
        parent.slug || '/' || bp.path_slugs
    FROM browse_nodes parent
    JOIN browse_path bp ON bp.parent_id = parent.id
),

-- Pega apenas a linha de maior profundidade (caminho completo) por Browse Node
final_paths AS (
    SELECT DISTINCT ON (start_node_id)
        start_node_id,
        path_text,
        path_slugs,
        depth       AS total_levels
    FROM browse_path
    ORDER BY start_node_id, depth DESC
)

SELECT
    p.id                        AS product_id,
    p.title                     AS product_title,
    bn.id                       AS browse_node_id,
    bn.name                     AS browse_node_name,
    fp.path_text                AS navigation_breadcrumb,
    '/' || fp.path_slugs        AS public_url_path,
    fp.total_levels,
    pbn.assigned_by,
    pbn.ai_confidence
FROM products_v2 p
JOIN product_browse_nodes pbn ON pbn.product_id = p.id
JOIN browse_nodes bn          ON bn.id = pbn.browse_node_id
JOIN final_paths fp           ON fp.start_node_id = bn.id
WHERE p.id = :product_id
ORDER BY pbn.assigned_by DESC, bn.id;
