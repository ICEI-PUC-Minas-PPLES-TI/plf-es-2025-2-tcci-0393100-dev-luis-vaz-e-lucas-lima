You can see this live editor clicking [here](), just copy/paste the code below:

```mmd
flowchart TB
  %% Clientes
  subgraph Clientes
    UB["Usuário (navegador)"]
    ADMB["Administrador (navegador)"]
  end

  %% Borda / Edge
  subgraph Edge["Borda/Edge"]
    CF2[Cloudflare CDN/WAF]
  end

  %% Host / Compose
  subgraph Host["Servidor de Aplicação"]
    subgraph Net["Rede interna (Docker Compose)"]
      NGINX[(Container Nginx)]
      APP[(Container App OCaml/Dream)]
      WORK[(Container Workers de coleta)]
      PG2[(Container PostgreSQL)]
      RDS2[(Container Redis)]
    end
  end

  %% Externos
  subgraph Externos["Serviços Externos"]
    MKTS2((Marketplaces/APIs/HTML))
    FIPE2((FIPE))
    MON((Monitoramento externo))
    PAG2((Gateway de pagamento - futuro))
  end

  %% Conexões
  UB --> CF2 --> NGINX
  ADMB --> CF2 --> NGINX
  NGINX --> APP
  APP --> PG2
  APP --> RDS2
  WORK --> MKTS2
  WORK --> PG2
  WORK --> RDS2
  APP --> FIPE2
  APP --> MKTS2
  NGINX --> MON
  APP --> MON
  RDS2 --> MON
  APP -. "opcional" .-> PAG2
```