# ecommerce-taxonomy-engine — Etapa 2: Arquitetura de Duas Árvores

Documentação técnica da modelagem de banco de dados baseada na separação entre **Taxonomia do Sistema** e **Árvore de Navegação**, inspirada na arquitetura interna da Amazon.

---

## Índice

- [Visão Geral do Projeto](#visão-geral-do-projeto)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Guia de Execução](#guia-de-execução)
- [Decisões Arquitetônicas e de Negócio](#decisões-arquitetônicas-e-de-negócio)

---

## Visão Geral do Projeto

O **ecommerce-taxonomy-engine** é o motor central de categorização de um ecossistema de e-commerce omnichannel. Ele é responsável por classificar cada produto em dois contextos distintos e independentes:

1. **Contexto de regras** — o que o produto *é* do ponto de vista fiscal, logístico e financeiro
2. **Contexto de descoberta** — onde o produto *aparece* para o consumidor na vitrine e nos mecanismos de busca

Essa separação resolve um problema estrutural comum em marketplaces: a necessidade de reorganizar menus e campanhas de marketing sem afetar as regras de comissão ou a emissão de notas fiscais — e vice-versa.

### Escopo desta etapa

Esta etapa cobre a fundação de dados do motor:

- Modelagem das duas árvores (`system_taxonomy` e `browse_nodes`)
- Tabela de produtos com vínculo ao Item Type do sistema
- Pivot de associação produto × Browse Node
- Seeds de exemplo e queries recursivas de breadcrumb
- Infraestrutura Docker para desenvolvimento local

Etapas futuras cobrirão a API de categorização por IA, o pipeline Jitterbit e o Dashboard do Vendedor.

---

## Estrutura do Repositório

```
ecommerce-taxonomy-engine/
│
├── infra/
│   └── docker-compose.yml                    # PostgreSQL 16 + pgAdmin (profile tools)
│
├── db/
│   ├── migrations/
│   │   ├── V001__create_categories.sql       # [Etapa 1] Adjacency List legado
│   │   ├── V002__create_products.sql         # [Etapa 1] Tabela products legado
│   │   ├── V003__create_pivot_table.sql      # [Etapa 1] Pivot legado
│   │   ├── V004__create_system_taxonomy.sql  # Árvore do Sistema (Item Types)
│   │   ├── V005__create_browse_nodes.sql     # Árvore de Navegação (menus/SEO)
│   │   ├── V006__create_products_v2.sql      # Tabela products_v2 com item_type_id
│   │   └── V007__create_product_browse_nodes.sql  # Pivot N:N produto × Browse Node
│   │
│   ├── seeds/
│   │   ├── S001__categories_tree.sql         # [Etapa 1] Seed legado
│   │   ├── S002__sample_products.sql         # [Etapa 1] Seed legado
│   │   ├── S003__system_taxonomy_tree.sql    # Árvore do sistema (Electronics + Sports)
│   │   ├── S004__browse_nodes_tree.sql       # Árvore de navegação (Eletrônicos + Esportes)
│   │   └── S005__sample_product_v2.sql       # Produto "Fone Esportivo Bluetooth"
│   │
│   ├── queries/
│   │   ├── breadcrumb_system_taxonomy.sql    # WITH RECURSIVE: caminho do sistema
│   │   └── breadcrumb_browse_nodes.sql       # WITH RECURSIVE: caminhos de marketing
│   │
│   └── breadcrumbs_by_product.sql            # [Etapa 1] Query legada
│
├── api/
│   ├── routes/                               # Endpoints REST (implementação futura)
│   ├── services/                             # Lógica de negócio
│   └── integrations/
│       └── jitterbitAdapter.js               # Adaptador batch → upsert idempotente
│
├── docs/
│   └── ETAPA-2-DUAS-ARVORES.md              # Este documento
│
├── scratchpad/
│   └── ecommerce-db-stage1.html             # Referência visual interativa
│
├── .env.example
├── .gitignore
└── README.md
```

### Responsabilidade de cada arquivo novo

| Arquivo | Responsabilidade |
|---|---|
| `V004` — `system_taxonomy` | Define a taxonomia interna com NCM, comissão e restrições por Item Type. Invisível ao consumidor. |
| `V005` — `browse_nodes` | Define a árvore de navegação pública com slugs e metadados de SEO. Curada por marketing. |
| `V006` — `products_v2` | Tabela de produtos vinculada ao Item Type via `item_type_id`. Inclui rastreabilidade do fluxo de origem. |
| `V007` — `product_browse_nodes` | Pivot N:N com rastreabilidade de quem atribuiu cada nó (IA, Dashboard ou Jitterbit) e confiança do modelo. |
| `S003` — seed sistema | 16 nós em 4 níveis (Electronics + Sports). Folhas com NCM real e comissão em basis points. |
| `S004` — seed navegação | 16 nós em 4 níveis (Eletrônicos + Esportes & Fitness). Inclui nó de campanha sazonal. |
| `S005` — produto exemplo | Fone Esportivo Bluetooth X200 com Item Type e dois Browse Nodes (IA + manual). |
| `breadcrumb_system_taxonomy.sql` | Retorna caminho interno + NCM + taxa de comissão para uso do backend. |
| `breadcrumb_browse_nodes.sql` | Retorna todos os caminhos de navegação + URLs públicas para o front-end. |

---

## Guia de Execução

### Pré-requisitos

- Docker (Docker Desktop **ou** [Colima](https://github.com/abiosoft/colima) no macOS)

> **macOS Intel com Colima:**
> ```bash
> colima start --cpu 2 --memory 2 --arch x86_64
> ```

### 1. Configure o ambiente

```bash
cp .env.example .env
```

### 2. Suba o PostgreSQL

```bash
docker compose -f infra/docker-compose.yml up -d postgres
```

Aguarde o healthcheck (≈10s):

```bash
docker compose -f infra/docker-compose.yml ps
# STATUS deve exibir: Up X seconds (healthy)
```

### 3. Aplique as migrations em ordem

> Se você já executou a Etapa 1 (V001–V003), pule para o V004.

```bash
# [Etapa 1 — pule se já aplicado]
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/migrations/V001__create_categories.sql
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/migrations/V002__create_products.sql
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/migrations/V003__create_pivot_table.sql

# [Etapa 2 — duas árvores]
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/migrations/V004__create_system_taxonomy.sql
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/migrations/V005__create_browse_nodes.sql
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/migrations/V006__create_products_v2.sql
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/migrations/V007__create_product_browse_nodes.sql
```

### 4. Popule com os seeds

```bash
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/seeds/S003__system_taxonomy_tree.sql
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/seeds/S004__browse_nodes_tree.sql
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db < db/seeds/S005__sample_product_v2.sql
```

### 5. Valide com as queries recursivas

**Caminho do sistema (invisível — regras de negócio):**

```bash
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db \
  -v product_id=1 --expanded \
  < db/queries/breadcrumb_system_taxonomy.sql
```

Resultado esperado:

```
product_title    | Fone Esportivo Bluetooth X200 — TWS IPX5 30h
system_breadcrumb| Electronics > Audio > Headphones > True Wireless Earbuds
ncm_code         | 85183000
commission_rate  | 12.00%
```

**Caminhos de navegação (visíveis — marketing e SEO):**

```bash
docker exec -i ecommerce_postgres psql -U ecommerce -d ecommerce_db \
  -v product_id=1 --expanded \
  < db/queries/breadcrumb_browse_nodes.sql
```

Resultado esperado:

```
-[ RECORD 1 ]--------+-----------------------------------------------------------------------
navigation_breadcrumb| Eletrônicos > Áudio e Fones > Fones Bluetooth > True Wireless
public_url_path      | /eletronicos/audio-e-fones/fones-bluetooth/fones-true-wireless
assigned_by          | ai_engine
ai_confidence        | 0.940

-[ RECORD 2 ]--------+-----------------------------------------------------------------------
navigation_breadcrumb| Esportes & Fitness > Eletrônicos para Esporte > Fones para Treino > Fones Esportivos à Prova D'água
public_url_path      | /esportes-e-fitness/eletronicos-para-esporte/fones-para-treino/fones-esportivos-a-prova-dagua
assigned_by          | dashboard
ai_confidence        | null
```

### 6. Interface visual (opcional)

```bash
docker compose -f infra/docker-compose.yml --profile tools up -d pgadmin
# Acesse: http://localhost:5050
# Login: admin@local.dev / admin
# Servidor: host=postgres, port=5432, db=ecommerce_db, user=ecommerce, pass=secret
```

---

## Decisões Arquitetônicas e de Negócio

### A separação em duas árvores

A Amazon opera internamente com essa separação há mais de duas décadas. A razão é simples: as necessidades de **quem administra regras de negócio** e de **quem administra a vitrine** são opostas.

A equipe fiscal quer estabilidade — o NCM de um fone de ouvido não muda com as estações. A equipe de marketing quer agilidade — criar uma seção "Presentes para Corredores" para o Dia dos Pais e removê-la na semana seguinte. Se as duas responsabilidades compartilhassem a mesma árvore, qualquer reorganização do menu colocaria em risco a integridade fiscal do catálogo.

---

### Árvore 1: `system_taxonomy` — a árvore das regras

É a espinha dorsal do negócio. Invisível ao consumidor, ela define o **Item Type** de cada produto — a unidade que governa:

| Atributo | Onde é usado |
|---|---|
| `ncm_code` | Emissão de NF-e pelo seller, cálculo de impostos |
| `commission_bps` | Taxa de comissão cobrada pelo marketplace (em basis points) |
| Campos obrigatórios | Validados no cadastro — ex: tensão em Eletro, composição em Vestuário |
| Regras logísticas | Dimensões máximas, restrições de transporte (ex: baterias de lítio) |

**Características:**
- Cresce lentamente e com governança rígida (alterações precisam de aprovação)
- Apenas nós-folha (`is_leaf = TRUE`) podem ser associados a produtos
- A constraint `chk_leaf_requires_ncm` impede que uma folha seja criada sem NCM e comissão — garantindo integridade a nível de banco

```
system_taxonomy (4 níveis):
Electronics
└── Audio
    └── Headphones
        └── True Wireless Earbuds  ← Item Type (is_leaf=TRUE, NCM=85183000, comissão=12%)
```

---

### Árvore 2: `browse_nodes` — a árvore da vitrine

É a experiência do consumidor. Curada pela equipe de Marketing e SEO, ela define onde o produto **aparece** na navegação do site:

| Atributo | Onde é usado |
|---|---|
| `slug` | URL pública da página de categoria |
| `seo_title` / `seo_description` | Meta tags do `<head>` da landing page |
| `display_order` | Ordem dos itens no menu de navegação |
| `is_campaign` | Nós temporários de campanha que podem ser removidos livremente |

**Características:**
- Muda com frequência (campanhas sazonais, testes A/B de menu, rebranding)
- Um produto pode estar em **zero, um ou muitos** Browse Nodes
- Nós de campanha (`is_campaign = TRUE`) podem ser deletados sem `ON DELETE RESTRICT`
- Reorganizar essa árvore não afeta NCM, comissão ou qualquer regra de negócio

```
browse_nodes (4 níveis — Exemplo 1):
Eletrônicos
└── Áudio e Fones
    └── Fones Bluetooth
        └── True Wireless  ← Browse Node folha (gera URL pública)

browse_nodes (4 níveis — Exemplo 2):
Esportes & Fitness
└── Eletrônicos para Esporte
    └── Fones para Treino
        └── Fones Esportivos à Prova D'água  ← mesmo produto, caminho diferente
```

---

### A tabela pivot `product_browse_nodes`

Conecta o produto às suas posições de vitrine com rastreabilidade de origem:

```sql
product_id | browse_node_id | assigned_by | ai_confidence
-----------+----------------+-------------+--------------
         1 |             11 | ai_engine   | 0.940
         1 |             15 | dashboard   | NULL
```

O campo `assigned_by` registra se a associação veio do **motor de IA**, de uma **curadoria manual no Dashboard** ou de uma **ingestão via Jitterbit**. O campo `ai_confidence` permite que a equipe de categoria filtre e revise sugestões de baixa confiança antes de publicar.

---

### Como o motor de IA alimenta as duas árvores

O fluxo opera em duas etapas independentes:

**Etapa A — Classificação no sistema (via Jitterbit, batch):**

O Jitterbit envia um payload com os atributos do produto (título, descrição, atributos técnicos). O motor de IA recebe esse payload, classifica o produto no Item Type correto da `system_taxonomy` e executa um `INSERT … ON CONFLICT (external_sku) DO UPDATE` em `products_v2`. O `item_type_id` resultante determina imediatamente a comissão e o NCM — sem intervenção humana.

```
ERP → Jitterbit → AI Engine → products_v2.item_type_id = 11 (True Wireless Earbuds)
                                                           ↓
                                              comissão = 12% | NCM = 85183000
```

**Etapa B — Sugestão de Browse Nodes (assíncrona):**

Após a classificação, o motor de IA sugere Browse Nodes candidatos com um score de confiança (`ai_confidence`) e os insere em `product_browse_nodes` com `assigned_by = 'ai_engine'`. Sugestões acima de um threshold configurável (ex: 0.90) são publicadas automaticamente. Abaixo do threshold, ficam em fila de revisão para a equipe de categoria no Dashboard.

```
AI Engine → product_browse_nodes (ai_confidence = 0.94) → publicado automaticamente
AI Engine → product_browse_nodes (ai_confidence = 0.61) → fila de revisão manual
```

Essa separação garante que um erro de sugestão do modelo de IA afete apenas a visibilidade do produto na vitrine — **nunca suas regras fiscais ou comissão**.

---

### Breadcrumbs com `WITH RECURSIVE`

Ambas as queries seguem o mesmo padrão: partem do nó-folha associado ao produto e sobem a árvore concatenando nomes até chegar à raiz.

```sql
-- Caso base: nó-folha (profundidade 0)
SELECT id, name, parent_id, name::TEXT AS path_text FROM <tabela> WHERE id = <id_folha>

UNION ALL

-- Caso recursivo: sobe ao pai, acumula o nome
SELECT parent.id, parent.name, parent.parent_id,
       parent.name || ' > ' || path_text
FROM <tabela> parent
JOIN cte ON cte.parent_id = parent.id
```

A recursão termina quando `parent_id IS NULL` (nó raiz). A linha com `depth` máximo contém o caminho completo — é a que o `DISTINCT ON` seleciona.

A query de Browse Nodes acumula também o caminho de slugs (`path_slugs`) em paralelo, gerando a URL pública completa sem nenhuma concatenação adicional na aplicação.
