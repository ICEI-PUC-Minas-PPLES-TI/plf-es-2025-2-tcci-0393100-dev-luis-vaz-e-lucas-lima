You can see this live editor clicking [here](https://mermaid.live/edit), just copy/paste the code below:

```mmd
flowchart TB
  %% Atores
  subgraph Atores
    C[Cliente]
    V[Vendedor]
    ADM[Administrador]
  end

  %% Edge / Infra
  subgraph Edge
    CF[Cloudflare CDN/WAF]
    NX[Nginx Proxy]
  end

  %% Apresentação
  subgraph UI
    WEB[Interface Web]
  end

  %% Aplicação
  subgraph App["Aplicação (OCaml/Dream)"]
    API[API/Rotas]
    SRV_BUSCA[Serviço de Busca]
    SRV_ENR[Enriquecimento]
    SRV_DEDUP["Deduplicação"]
    SRV_AGREG["Agregação (APIs e scraping)"]
    SRV_ADMIN[Administração]
    SRV_METRICAS[Métricas]
    SRV_REDIRECT[Redirecionamento]
  end

  %% Persistência
  subgraph Persistencia
    PG[(PostgreSQL)]
    RDS[(Redis - Cache/Filas)]
  end

  %% Externos
  subgraph Externos
    MKTS{{Marketplaces}}
    FIPE{{FIPE/Dados externos}}
    PAG{{"Gateway de Pagamento (futuro)"}}
  end

  %% Fluxos
  C --> WEB
  V --> WEB
  ADM --> WEB

  CF --> NX --> WEB
  WEB --> API

  API --> SRV_BUSCA
  SRV_BUSCA --> PG
  SRV_BUSCA --> RDS

  SRV_BUSCA --> SRV_ENR
  SRV_ENR --> FIPE

  SRV_BUSCA --> SRV_DEDUP --> PG

  SRV_AGREG --> MKTS
  SRV_AGREG --> PG
  SRV_AGREG --> RDS

  SRV_ADMIN --> PG
  SRV_ADMIN --> SRV_METRICAS
  SRV_METRICAS --> PG

  SRV_REDIRECT --> MKTS

  API --> PG
  API --> RDS
  API -. "eventos/filas" .-> RDS

  SRV_ADMIN -. "assinaturas (futuro)" .-> PAG
```