-- ============================================================
-- Breadcrumbs completos de um produto (principal + secundários)
-- Uso: psql $DATABASE_URL -v product_id=1 -f breadcrumbs_by_product.sql
-- ============================================================

WITH RECURSIVE

category_path (
    start_category_id,
    id,
    name,
    parent_id,
    depth,
    path_text
) AS (
    SELECT
        c.id AS start_category_id,
        c.id,
        c.name,
        c.parent_id,
        0 AS depth,
        c.name::TEXT AS path_text
    FROM categories c
    WHERE c.id IN (
        SELECT primary_category_id FROM products WHERE id = :product_id
        UNION ALL
        SELECT category_id FROM product_secondary_categories WHERE product_id = :product_id
    )

    UNION ALL

    SELECT
        cp.start_category_id,
        parent.id,
        parent.name,
        parent.parent_id,
        cp.depth + 1,
        parent.name || ' > ' || cp.path_text
    FROM categories parent
    JOIN category_path cp ON cp.parent_id = parent.id
),

final_paths AS (
    SELECT DISTINCT ON (start_category_id)
        start_category_id,
        path_text,
        depth AS total_levels
    FROM category_path
    ORDER BY start_category_id, depth DESC
)

SELECT
    p.id                                          AS product_id,
    p.title                                       AS product_title,
    CASE WHEN fp.start_category_id = p.primary_category_id
         THEN 'principal'
         ELSE 'secundario'
    END                                           AS category_type,
    fp.start_category_id                          AS leaf_category_id,
    fp.path_text                                  AS breadcrumb,
    fp.total_levels
FROM products p
CROSS JOIN final_paths fp
WHERE p.id = :product_id
ORDER BY category_type DESC, fp.start_category_id;
