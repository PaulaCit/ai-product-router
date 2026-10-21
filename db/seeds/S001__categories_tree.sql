-- ============================================================
-- S001: Árvore de categorias — 4 níveis
-- Nível 1: Departamento  | Nível 2: Categoria
-- Nível 3: Subcategoria  | Nível 4: Nó Folha (is_leaf = TRUE)
-- ============================================================

-- Nível 1: Departamentos (raiz)
INSERT INTO categories (name, parent_id, is_leaf, slug) VALUES
    ('Casa e Jardim', NULL, FALSE, 'casa-e-jardim'),
    ('Automotivo',    NULL, FALSE, 'automotivo');

-- Nível 2: Categorias
INSERT INTO categories (name, parent_id, is_leaf, slug) VALUES
    ('Limpeza e Organização', 1, FALSE, 'limpeza-e-organizacao'),
    ('Jardim e Área Externa', 1, FALSE, 'jardim-e-area-externa'),
    ('Cuidado do Veículo',    2, FALSE, 'cuidado-do-veiculo'),
    ('Acessórios Externos',   2, FALSE, 'acessorios-externos');

-- Nível 3: Subcategorias
INSERT INTO categories (name, parent_id, is_leaf, slug) VALUES
    ('Lavadoras e Aspiradores', 3, FALSE, 'lavadoras-e-aspiradores'),
    ('Vassouras e Rodos',       3, FALSE, 'vassouras-e-rodos'),
    ('Mangueiras e Irrigação',  4, FALSE, 'mangueiras-e-irrigacao'),
    ('Lavagem de Veículos',     5, FALSE, 'lavagem-de-veiculos'),
    ('Capas e Proteção',        6, FALSE, 'capas-e-protecao');

-- Nível 4: Nós Folha (is_leaf = TRUE)
INSERT INTO categories (name, parent_id, is_leaf, slug) VALUES
    ('Lavadoras de Alta Pressão', 7,  TRUE, 'lavadoras-de-alta-pressao'),
    ('Aspiradores de Pó',         7,  TRUE, 'aspiradores-de-po'),
    ('Mangueiras Retráteis',      9,  TRUE, 'mangueiras-retrateis'),
    ('Kits de Lavagem Premium',   10, TRUE, 'kits-de-lavagem-premium'),
    ('Cobertores de Carro',       11, TRUE, 'cobertores-de-carro');
