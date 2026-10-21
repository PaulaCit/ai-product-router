# ecommerce-taxonomy-engine

Motor de categorização omnichannel para e-commerce, responsável por classificar produtos de forma inteligente via IA, suportando integrações massivas via **Jitterbit** (batch) e inserções manuais via **Dashboard do Vendedor**.

---

## Índice

- [Visão Geral do Projeto](#visão-geral-do-projeto)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Guia de Execução](#guia-de-execução)
- [Decisões Arquitetônicas e de Negócio](#decisões-arquitetônicas-e-de-negócio)

---

## Visão Geral do Projeto

O **ecommerce-taxonomy-engine** é um monorepo que centraliza toda a lógica de categorização de produtos de um ecossistema de e-commerce inspirado na Amazon. Seu papel é garantir que cada produto seja classificado com precisão dentro de uma árvore hierárquica de categorias, independente de como esse produto chega ao sistema — seja por uma integração automática de ERP via Jitterbit ou pelo cadastro manual de um vendedor no Dashboard.

A categorização correta é crítica porque ela determina:

- **Regras fiscais** (NCM e alíquotas por departamento)
- **Comissões do marketplace** (cada categoria tem uma taxa diferente)
- **Campos obrigatórios de conteúdo** (um produto em Eletrônicos exige voltagem; em Vestuário, composição do tecido)
- **Descoberta e SEO** (onde o produto aparece na navegação e nos mecanismos de busca)

### Escopo da Etapa 1

Esta etapa cobre exclusivamente a **fundação de dados**: modelagem do banco de dados relacional, definição da taxonomia de categorias e os scripts de infraestrutura necessários para que qualquer desenvolvedor suba o ambiente em minutos.

Etapas futuras cobrirão a API de categorização por IA, o pipeline Jitterbit e a interface do Dashboard.

---

## Estrutura do Repositório

```
ecommerce-taxonomy-engine/
│
├── infra/
│   └── docker-compose.yml          # Orquestração local: PostgreSQL 16 + pgAdmin
│
├── db/
│   ├── migrations/
│   │   ├── V001__create_categories.sql     # DDL: tabela categories (Adjacency List)
│   │   ├── V002__create_products.sql       # DDL: tabela products
│   │   └── V003__create_pivot_table.sql    # DDL: product_secondary_categories (N:N)
│   │
│   ├── seeds/
│   │   ├── S001__categories_tree.sql       # Árvore de 4 níveis (Casa e Jardim + Automotivo)
│   │   └── S002__sample_products.sql       # Produto de exemplo com categorização dupla
│   │
│   └── breadcrumbs_by_product.sql          # Query WITH RECURSIVE para breadcrumbs
│
├── api/
│   ├── routes/                     # Endpoints REST (implementação futura)
│   ├── services/                   # Lógica de negócio
│   └── integrations/
│       └── jitterbitAdapter.js     # Mapeamento de payload batch → upsert no banco
│
├── scratchpad/
│   └── ecommerce-db-stage1.html    # Documentação técnica interativa (referência visual)
│
├── .env.example                    # Template de variáveis de ambiente
├── .gitignore
└── README.md
```

### O que faz cada parte

| Caminho | Responsabilidade |
|---|---|
| `infra/docker-compose.yml` | Sobe PostgreSQL 16 com volume persistente e pgAdmin no profile `tools`. Não requer Docker Desktop — compatível com Colima. |
| `db/migrations/V001` | Cria a tabela `categories` com Adjacency List, índices de navegação e trigger de `updated_at`. |
| `db/migrations/V002` | Cria a tabela `products` com o campo `primary_category_id` (nó principal) e `external_sku` para upsert idempotente via Jitterbit. |
| `db/migrations/V003` | Cria a tabela pivot `product_secondary_categories` — relação N:N entre produtos e seus nós de descoberta. |
| `db/seeds/S001` | Popula 16 nós em 4 níveis hierárquicos: Departamento → Categoria → Subcategoria → Nó Folha. |
| `db/seeds/S002` | Insere um produto de exemplo ("Lavadora de Alta Pressão") com nó principal em Casa e Jardim e nó secundário em Automotivo. |
| `db/breadcrumbs_by_product.sql` | Consulta recursiva que retorna o caminho completo de texto (breadcrumb) de todos os nós de um produto. |
| `api/integrations/jitterbitAdapter.js` | Referência de implementação do adaptador que recebe o payload do Jitterbit e executa o upsert idempotente no banco. |

> **Convenção de migrations:** o prefixo `V<NNN>` é compatível com Flyway e Liquibase. Execute sempre em ordem numérica crescente. Nunca edite uma migration já aplicada — crie uma nova.

---

## Guia de Execução

### Pré-requisitos

- [Docker](https://docs.docker.com/get-docker/) (Docker Desktop **ou** [Colima](https://github.com/abiosoft/colima) no macOS)
- `git`

> **macOS com Colima (Intel):** substitua o passo de subir o Docker Desktop por:
> ```bash
> colima start --cpu 2 --memory 2 --arch x86_64
> ```

### 1. Clone e configure o ambiente

```bash
git clone https://github.com/PaulaCit/ai-product-router.git
cd ai-product-router

cp .env.example .env
# Edite .env se quiser alterar as credenciais padrão
```

### 2. Suba o PostgreSQL

```bash
docker compose -f infra/docker-compose.yml up -d postgres
```

Aguarde o healthcheck ficar `healthy` (cerca de 10 segundos):

```bash
docker compose -f infra/docker-compose.yml ps
```

A coluna `STATUS` deve exibir `Up X seconds (healthy)`.

### 3. Aplique as migrations

Execute as migrations em ordem. Cada comando cria uma tabela no banco:

```bash
# Tabela de categorias (Adjacency List)
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db \
  < db/migrations/V001__create_categories.sql

# Tabela de produtos
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db \
  < db/migrations/V002__create_products.sql

# Tabela pivot N:N (categorias secundárias)
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db \
  < db/migrations/V003__create_pivot_table.sql
```

Saída esperada para cada migration:

```
CREATE TABLE
CREATE INDEX
CREATE TRIGGER
```

### 4. Popule o banco com os seeds

```bash
# Árvore de categorias (16 nós em 4 níveis)
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db \
  < db/seeds/S001__categories_tree.sql

# Produto de exemplo com categorização dupla
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db \
  < db/seeds/S002__sample_products.sql
```

> **Atenção:** seeds são exclusivos para desenvolvimento e staging. Nunca execute em produção.

### 5. Valide a instalação

Execute a query de breadcrumbs para confirmar que tudo foi criado corretamente:

```bash
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db \
  -v product_id=1 --expanded \
  < db/breadcrumbs_by_product.sql
```

Resultado esperado:

```
-[ RECORD 1 ]----+------------------------------------------------------------------------
category_type    | principal
breadcrumb       | Casa e Jardim > Limpeza e Organização > Lavadoras e Aspiradores > Lavadoras de Alta Pressão

-[ RECORD 2 ]----+------------------------------------------------------------------------
category_type    | secundario
breadcrumb       | Automotivo > Cuidado do Veículo > Lavagem de Veículos > Kits de Lavagem Premium
```

### 6. Interface visual (opcional)

Para inspecionar os dados visualmente via pgAdmin:

```bash
docker compose -f infra/docker-compose.yml --profile tools up -d pgadmin
```

Acesse **http://localhost:5050** com as credenciais `admin@local.dev` / `admin`.

Registre o servidor com:

| Campo | Valor |
|---|---|
| Host | `postgres` |
| Port | `5432` |
| Database | `ecommerce_db` |
| Username | `ecommerce` |
| Password | `secret` |

---

## Decisões Arquitetônicas e de Negócio

### Padrão Adjacency List para a tabela `categories`

A tabela `categories` implementa o padrão **Adjacency List**: cada linha armazena uma referência direta ao seu nó pai via `parent_id`. Nós raiz (departamentos de primeiro nível) têm `parent_id = NULL`.

```
id | name                      | parent_id | is_leaf
---|---------------------------|-----------|--------
 1 | Casa e Jardim             | NULL      | false   ← Departamento (raiz)
 3 | Limpeza e Organização     | 1         | false   ← Categoria
 7 | Lavadoras e Aspiradores   | 3         | false   ← Subcategoria
12 | Lavadoras de Alta Pressão | 7         | true    ← Nó Folha
```

**Por que Adjacency List e não Nested Sets ou Closure Table?**

O projeto tem dois fluxos de escrita intensivos: inserções em batch via Jitterbit e cadastros manuais via Dashboard. O Adjacency List tem o menor custo de DML entre os três padrões — um `INSERT` ou `UPDATE` afeta apenas a linha do nó em questão. Nested Sets e Closure Table exigem recalcular múltiplas linhas a cada inserção, o que se torna um gargalo em operações de batch.

A desvantagem do Adjacency List — exigir recursão para navegar a árvore completa — é resolvida com `WITH RECURSIVE` no PostgreSQL, que performa bem até ~10.000 categorias.

A flag `is_leaf` evita a recursão desnecessária em nós terminais, otimizando as queries de leitura mais frequentes (browse e autocomplete de categorias).

---

### Nó Principal vs. Nós Secundários

Esta é a decisão de modelagem mais importante da Etapa 1. Um produto pode ser encontrado em múltiplos pontos da árvore de categorias, mas **precisa ter exatamente um nó que define suas regras de negócio**.

#### Nó Principal — `products.primary_category_id`

Cardinalidade **1:1** com o produto. Determina:

- **Comissão do marketplace:** cada categoria tem uma taxa definida (ex: Limpeza = 12%, Automotivo = 8%)
- **Código NCM:** usado na emissão da NF-e pelo seller
- **Campos obrigatórios de conteúdo:** validados no cadastro via Dashboard e na API do Jitterbit
- **URL canônica do produto:** `/lavadoras-de-alta-pressao/lavadora-2000w`
- **Atribuição de GMV em relatórios:** a receita é contabilizada no departamento do nó principal

#### Nós Secundários — `product_secondary_categories`

Cardinalidade **N:N** via tabela pivot. Determinam:

- **Buscabilidade cross-departamento:** o produto aparece na listagem de Automotivo sem que isso afete sua comissão
- **SEO:** URLs alternativas e sitemap de múltiplas categorias
- **Campanhas segmentadas:** um nó secundário pode ser alvo de uma promoção sem impactar o nó principal

**Regra de integridade:** o mesmo nó não pode ser principal e secundário simultaneamente. Essa restrição é aplicada em dois níveis independentes — na constraint do banco (`db/migrations/V003`) e na camada de serviço da API (`api/services/productService.js`).

```
products
└── primary_category_id → categories.id   (1 nó: regras, comissão, NF-e)

product_secondary_categories
└── (product_id, category_id)             (N nós: descoberta, SEO, campanhas)
```

---

### Breadcrumbs com `WITH RECURSIVE`

A consulta em `db/breadcrumbs_by_product.sql` usa uma **CTE recursiva** para percorrer o Adjacency List de baixo para cima — do nó-folha até a raiz — e montar o caminho completo em texto.

**Como funciona:**

```sql
WITH RECURSIVE category_path AS (

  -- Caso base: parte do nó-folha do produto
  SELECT id, name, parent_id, name::TEXT AS path_text
  FROM categories
  WHERE id = <id_do_no_folha>

  UNION ALL

  -- Caso recursivo: sobe para o nó pai, acumulando o nome
  SELECT parent.id, parent.name, parent.parent_id,
         parent.name || ' > ' || cp.path_text
  FROM categories parent
  JOIN category_path cp ON cp.parent_id = parent.id

)
-- Seleciona apenas a linha com profundidade máxima (caminho completo)
SELECT path_text FROM category_path ORDER BY depth DESC LIMIT 1;
```

A recursão termina quando `parent_id IS NULL` (chegou à raiz). A concatenação `parent.name || ' > ' || cp.path_text` constrói o breadcrumb na ordem correta: `Raiz > ... > Folha`.

A query final executa essa lógica para **todos os nós do produto de uma vez** — nó principal e todos os secundários — em uma única passagem pelo banco, retornando uma linha por caminho com a coluna `category_type` distinguindo qual é qual.

---

## Variáveis de Ambiente

| Variável | Padrão | Descrição |
|---|---|---|
| `POSTGRES_USER` | `ecommerce` | Usuário do banco de dados |
| `POSTGRES_PASSWORD` | `secret` | Senha do banco de dados |
| `POSTGRES_DB` | `ecommerce_db` | Nome do banco de dados |
| `DATABASE_URL` | — | URL completa de conexão para a API |

Copie `.env.example` para `.env` e ajuste os valores antes de subir o ambiente.

---

## Próximas Etapas

| Etapa | Descrição |
|---|---|
| **Etapa 2** | API REST de categorias — endpoints de browse, busca por slug e sugestão por IA |
| **Etapa 3** | Adaptador Jitterbit — pipeline de ingestão batch com upsert idempotente e validação de nó principal |
| **Etapa 4** | Dashboard do Vendedor — interface de categorização manual com autocomplete e validação em tempo real |
