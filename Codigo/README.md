# BusCars - Plataforma de Busca de Veículos

Plataforma de marketplace de veículos para o mercado brasileiro, inspirada no Auto Tempest mas projetada especificamente para o Brasil. Combina funcionalidades de busca avançada com apresentação detalhada de veículos.

## 🚀 Quick Start

### Usando Docker Compose (Recomendado)

```bash
# Build e executar todos os serviços
docker-compose up --build

# Ou executar em background
docker-compose up -d --build

# Ver logs
docker-compose logs -f

# Parar serviços
docker-compose down
```

### Acessar a Aplicação

- **Frontend**: http://localhost:9003
- **Backend API**: http://localhost:9004
- **PostgreSQL**: localhost:5433
- **Redis**: localhost:6380

## 📐 Arquitetura do Sistema

### Visão Geral

```mermaid
graph TB
    subgraph "Client Layer"
        Browser[🌐 Navegador]
    end
    
    subgraph "Frontend Service"
        Frontend[Frontend<br/>Dream + OCaml<br/>Port: 9003]
    end
    
    subgraph "Backend Service"
        Backend[Backend API<br/>Dream + OCaml<br/>Port: 9004]
        Auth[🔐 Auth Module]
        Cache[💾 Cache Module]
        Repo[📦 Repository]
    end
    
    subgraph "Data Layer"
        Postgres[(PostgreSQL<br/>Port: 5433)]
        Redis[(Redis Cache<br/>Port: 6380)]
    end
    
    subgraph "External Services"
        FIPE[FIPE API<br/>Preços de Veículos]
        Scrapers[🕷️ Scrapers<br/>Localiza, iCarros]
    end
    
    Browser -->|HTTP| Frontend
    Frontend -->|HTTP/REST| Backend
    Backend --> Auth
    Backend --> Cache
    Backend --> Repo
    Repo --> Postgres
    Cache --> Redis
    Backend -->|API Calls| FIPE
    Scrapers -->|Bulk Import| Backend
    
    style Frontend fill:#4A90E2
    style Backend fill:#50C878
    style Postgres fill:#336791
    style Redis fill:#DC382D
    style FIPE fill:#FFA500
```

### Fluxo de Dados

```mermaid
sequenceDiagram
    participant U as Usuário
    participant F as Frontend
    participant B as Backend
    participant C as Redis Cache
    participant D as PostgreSQL
    participant E as FIPE API
    
    U->>F: Requisição HTTP
    F->>B: API Call
    
    alt Cache Hit
        B->>C: Buscar cache
        C-->>B: Dados em cache
        B-->>F: Resposta
    else Cache Miss
        B->>D: Query database
        D-->>B: Dados
        B->>C: Salvar no cache
        B-->>F: Resposta
    end
    
    F-->>U: HTML/JSON
    
    Note over B,E: Consulta FIPE (com cache de 7 dias)
    B->>E: Buscar preço FIPE
    E-->>B: Preço FIPE
    B->>C: Cachear resultado
```

### Componentes Principais

```mermaid
graph LR
    subgraph "Frontend"
        FT[Frontend Templates]
        FC[Frontend API Client]
        FH[Frontend Handlers]
    end
    
    subgraph "Backend"
        BH[Backend Handlers]
        VC[Vehicle Commands]
        REPO[Repository]
        AUTH[Authentication]
        FIPE_CLIENT[FIPE Client]
    end
    
    subgraph "Scrapers"
        ORCH[Orchestrator]
        LOCALIZA[Localiza Scraper]
        ICARROS[iCarros Scraper]
    end
    
    FT --> FC
    FC --> FH
    FH -->|HTTP| BH
    BH --> VC
    BH --> REPO
    BH --> AUTH
    BH --> FIPE_CLIENT
    ORCH --> LOCALIZA
    ORCH --> ICARROS
    ORCH -->|Import| VC
```

## 🏗️ Estrutura do Projeto

```
buscar-mockup/
├── frontend/              # Servidor web frontend
│   ├── bin/
│   │   └── buscar.ml      # Servidor Dream + rotas
│   ├── lib/
│   │   ├── templates.ml    # Templates HTML
│   │   ├── api_client.ml # Cliente API backend
│   │   └── types.ml      # Tipos compartilhados
│   └── static/           # Assets estáticos
│
├── backend/              # API REST backend
│   ├── bin/
│   │   └── main.ml       # Servidor Dream + handlers
│   ├── lib/
│   │   ├── database.ml   # Queries Caqti
│   │   ├── cache.ml      # Cache Redis
│   │   ├── repository.ml # Camada de repositório
│   │   ├── vehicle_commands.ml # Comandos de veículos
│   │   ├── fipe.ml       # Cliente FIPE API
│   │   └── auth.ml       # Autenticação
│   └── db/
│       ├── schema.sql    # Schema PostgreSQL
│       └── seed.sql      # Dados iniciais
│
├── app-scrappers/        # Aplicação de scrapers
│   ├── lib/
│   │   ├── orchestrator.ml # Orquestrador de scrapers
│   │   └── scrapers/
│   │       ├── localiza.ml
│   │       └── icarros.ml
│   └── bin/
│       └── main.ml       # Entry point
│
└── docker-compose.yml    # Orquestração Docker
```

## 🔄 Fluxo de Scraping

```mermaid
graph TD
    START[Orchestrator Inicia] --> CHECK{É hora de<br/>manutenção?}
    CHECK -->|Sim| MAINT[Desativar veículos<br/>antigos]
    CHECK -->|Não| JOBS[Buscar jobs ativos]
    MAINT --> JOBS
    JOBS --> GROUP[Agrupar por provider]
    GROUP --> RUN[Executar scrapers<br/>em paralelo]
    RUN --> SCRAPE[Scraper busca veículos]
    SCRAPE --> IMPORT[Importar em lote]
    IMPORT --> UPDATE[Atualizar estatísticas]
    UPDATE --> WAIT[Aguardar delay]
    WAIT --> CHECK
```

## 🚀 Deploy

### Desenvolvimento
```bash
docker-compose up --build
```

### Produção
```bash
# Usar profile production
docker-compose --profile production up -d

# Inclui:
# - Cloudflare Tunnel
# - Nginx Proxy
# - Scrapers
```