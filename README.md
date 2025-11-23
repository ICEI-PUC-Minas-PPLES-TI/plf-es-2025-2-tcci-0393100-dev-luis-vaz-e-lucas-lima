# 🏷️ BusCars - Agregação Inteligente de Veículos ✨

- **Breve descrição:** O BusCars é uma plataforma que **agrega, normaliza e enriquece** anúncios de veículos de múltiplos *marketplaces* em uma **base centralizada**. Seu principal valor é transformar dados fragmentados em inteligência de mercado e eficiência de busca para Vendedores e Clientes.

<table>
  <tr>
    <td width="800px">
      <div align="justify">
        [cite_start]O sistema <b>BusCars</b> é uma plataforma robusta de **agregação e gerenciamento de veículos** concebida para modernizar a pesquisa e a compra no mercado automotivo brasileiro[cite: 39, 42]. [cite_start]Ele resolve a fragmentação de dados ao consolidar informações de diversas fontes, aprimorando a experiência do usuário por meio de uma interface intuitiva[cite: 79, 43]. [cite_start]O projeto atende à necessidade do *stakeholder* **Lucas Amaral Paes Leme Maestro**, um gestor do setor, que precisava de uma **gestão centralizada e eficiente**[cite: 45, 47]. [cite_start]O sistema entrega valor ao **Consolidar** informações de diferentes fontes, **Normalizar e Enriquecer** os dados com o valor da **Tabela FIPE** e análise de preço de mercado, e fornecer ferramentas de **inteligência de mercado**[cite: 82, 83, 48]. [cite_start]O BusCars é um sistema confiável, ágil e de fácil acesso que transforma a maneira como a pesquisa e a compra de veículos são realizadas[cite: 49].
      </div>
    </td>
    <td>
      <div>
        
      </div>
    </td>
  </tr> 
</table>

---

## 🚧 Status do Projeto

### Badges Principais

[![Versão](https://img.shields.io/badge/Versão-v5.0-blue)](<link-para-a-release-5.0>)
[![Última Revisão](https://img.shields.io/badge/Data%20Revisão-23%2F11%2F25-lightgrey)](<link-para-o-commit-23-11-25>)
[![Linguagem Core](https://img.shields.io/badge/Linguagem-OCaml-red?style=for-the-badge&logo=ocaml&logoColor=white)](<link-para-ocaml>)
[![Banco de Dados](https://img.shields.io/badge/PostgreSQL-16-blue?style=for-the-badge&logo=postgresql&logoColor=white)](<link-para-postgres>)
[![Containerização](https://img.shields.io/badge/Containerização-Docker%20Compose-blue?style=for-the-badge&logo=docker&logoColor=white)](<link-para-docker>)

---

## 📚 Índice
- [Links Úteis](#-links-úteis)
- [Sobre o Projeto](#-sobre-o-projeto)
- [Funcionalidades Principais](#-funcionalidades-principais)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Arquitetura](#-arquitetura)
- [Documentação de Casos de Uso](#-documentação-de-casos-de-uso)
  - [Contratos de Operação (DSS)](#contratos-de-operação-dss)
  - [Casos de Teste Mínimos (N3)](#casos-de-teste-mínimos-n3)
- [Interfaces do Sistema](#-interfaces-do-sistema)
- [Post Mortem (Lições Aprendidas)](#-post-mortem-lições-aprendidas)
- [Instalação e Execução](#-instalação-e-execução)
- [Autores](#-autores)
- [Licença](#-licença)

---

## 🔗 Links Úteis
* 🌐 **Demo Online:** [Acesse a Aplicação Web](https://buscar-demo.rastrian.dev/)
  > 💻 **Descrição:** Link para a aplicação em ambiente de produção. Para ver o swagger [clique aqui](https://buscar-demo.rastrian.dev/api/docs#/).
* 📖 **Documentação Oficial:** [Leia o TCC-Doc-Projeto-BusCars.pdf](https://github.com/ICEI-PUC-Minas-PPLES-TI/plf-es-2025-2-tcci-0393100-dev-luis-vaz-e-lucas-lima/blob/main/Artefatos/DocumentoDeProjeto/TCC-Doc-Projeto-BusCars.pdf)
  > [cite_start]📚 **Descrição:** Acesso à documentação técnica completa do projeto[cite: 39].
* 📖 **Repositório GitHub:** [Código Fonte da Aplicação BusCars](https://github.com/ICEI-PUC-Minas-PPLES-TI/plf-es-2025-2-tcci-0393100-dev-luis-vaz-e-lucas-lima/tree/main/Codigo)
  > [cite_start]📚 **Descrição:** Repositório oficial contendo o código-fonte (`frontend`, `backend`, `app-scrappers`)[cite: 560].

---

## 📝 Sobre o Projeto
[cite_start]O sistema **BusCars** foi idealizado para modernizar a gestão interna do serviço de compra e venda de veículos e impulsionar o crescimento do negócio[cite: 49]. [cite_start]Ele existe para resolver a **fragmentação de dados** no mercado automotivo, onde a consulta manual de diversas plataformas exige tempo e é ineficiente[cite: 47]. [cite_start]O projeto atende à necessidade do *stakeholder* **Lucas Amaral Paes Leme Maestro**, um gestor do setor, que precisava de uma **gestão centralizada**[cite: 45, 47]. [cite_start]O sistema entrega valor ao **Consolidar** informações de diferentes fontes, **Normalizar e Enriquecer** os dados com o valor da **Tabela FIPE** e análise de preço de mercado, e fornecer ferramentas de **inteligência de mercado**[cite: 82, 83, 48]. [cite_start]O BusCars é um sistema confiável, ágil e de fácil acesso que transforma a maneira como a pesquisa e a compra de veículos são realizadas[cite: 49].

---

## ✨ Funcionalidades Principais
Liste as funcionalidades de forma clara e objetiva.

* [cite_start]🔎 **Busca Inteligente (UC01):** Permite ao Cliente e Vendedor buscar veículos utilizando filtros avançados em uma **base unificada**[cite: 81, 95, 96].
* [cite_start]📊 **Análise de Preço (UC05):** Enriquecimento dos anúncios com o valor de referência da **Tabela FIPE** e cálculo da posição percentual contra a média do mercado[cite: 82, 102, 137, 138].
* [cite_start]👁️ **Visualização Unificada (UC03):** Exibe anúncios de múltiplas fontes em uma única tela e formato **padronizado**, facilitando a comparação[cite: 79, 99, 100].
* [cite_start]🛠️ **Curadoria de Conteúdo (UC07, UC06):** Permite ao Administrador **Validar Conteúdo** [cite: 105] [cite_start]e **Identificar Duplicatas** [cite: 104] [cite_start]para manter a base de dados limpa e crível[cite: 88].
* [cite_start]⚙️ **Monitoramento (UC08, UC09):** Dashboard administrativo para **Monitorar a Coleta de Dados** [cite: 106] [cite_start]e **Visualizar Métricas de Desempenho** [cite: 107] do sistema.

---

## 🛠 Tecnologias Utilizadas

[cite_start]A escolha da *stack* tecnológica se baseou na necessidade de equilibrar **desempenho, confiabilidade e facilidade de manutenção**[cite: 291].

### 🖥️ Back-end e Core

* [cite_start]**Linguagem:** **OCaml** [cite: 293] [cite_start](Tipagem forte e estática para robustez e segurança [cite: 294]).
* [cite_start]**Framework:** **Dream** [cite: 293] [cite_start](Para construção de aplicações *web* e camada de aplicação [cite: 314, 313]).
* [cite_start]**Banco de Dados:** **PostgreSQL** [cite: 297] [cite_start](Para persistência estruturada, suporta dados semi-estruturados e indexação avançada [cite: 298, 317]).
* [cite_start]**Cache/Filas:** **Redis** [cite: 300] [cite_start](Para *cache* de alta frequência, sessões e coordenação de processos assíncronos [cite: 301, 319, 320]).

### 💻 Front-end

* [cite_start]**Framework:** **Dream** (Utilizado para renderização de HTML e gerenciamento da camada de apresentação [cite: 313]).
* [cite_start]**Estilização:** **HTML e CSS**[cite: 313].

### ⚙️ Infraestrutura & DevOps

* [cite_start]**Containerização:** **Docker** e **Docker Compose** [cite: 302] [cite_start](Para padronizar e orquestrar todos os serviços [cite: 303, 325]).
* [cite_start]**Proxy Reverso:** **Nginx** [cite: 305, 322] (Para roteamento interno e balanceamento de carga).
* [cite_start]**Segurança/CDN:** **Cloudflare** [cite: 306, 323] [cite_start](Camada de segurança, distribuição de conteúdo, resiliência e proteção contra DDoS [cite: 307, 324]).

---

## 🏗 Arquitetura

[cite_start]O BusCars adota uma arquitetura **baseada em camadas**, concebida para garantir **separação clara de responsabilidades** e **manutenibilidade**[cite: 311]. [cite_start]O sistema é, essencialmente, um *Backend Distributed System* (Figura 24) que divide as responsabilidades entre um **Core System** e um **Scrapping System**[cite: 309].

1.  [cite_start]**Backend (Núcleo):** Camada de aplicação que processa a lógica de negócio, incluindo **agregação, normalização, deduplicação e cálculo de indicadores**[cite: 316].
2.  [cite_start]**Persistência:** O **PostgreSQL** é a camada de persistência central [cite: 317][cite_start], e o **Redis** gerencia o *cache* e as filas para processos assíncronos[cite: 319, 320].
3.  [cite_start]**Infraestrutura (Edge):** **Nginx** e **Cloudflare** atuam como a linha de frente para segurança e roteamento[cite: 322, 324].

### Exemplos de diagramas

Os modelos de projeto documentam a estrutura do sistema.

| Diagrama de Arquitetura | Detalhe da Arquitetura |
| :---: | :---: |
| **Arquitetura Lógica (Macro)** | **Fluxo de Busca de Veículo** |
|  |  |
| **Modelo de Dados (Entidades)** | **Fluxo de Login** |
|  |  |
| **Infraestrutura (Implantação)** | **Fluxo de Validação de Conteúdo** |
|  |  |

---

## 📝 Documentação de Casos de Uso

### Contratos de Operação (DSS)

| Contrato | Detalhamento |
| :--- | :--- |
| **Referência** | US15(04,3) / **UC04** (Buscar Oportunidade) |
| **Operação** | `solicitarPainelAuditoriaEnriquecimento()` |
| **Pré-condições** | 1. O ator deve estar autenticado e possuir o perfil de **Administrador**. 2. [cite_start]O *Serviço de Enriquecimento* deve ter executado o cálculo e persistido as métricas (FIPE/Desvio Padrão) no Banco de Dados[cite: 132]. |
| **Pós-condições** | 1. O painel de auditoria é exibido na interface do Administrador. 2. [cite_start]A interface apresenta a lista de modelos, o valor de referência FIPE e o Desvio Padrão calculado para cada um, permitindo a **auditoria visual**[cite: 132]. |

### Casos de Teste Mínimos (N3)

Definição: **N3TA** refere-se a **Teste de Aceitação** para a Necessidade 3 (Detalhes do Veículo). **N3TI** refere-se a **Teste de Integração**.

| Identificador | Necessidade | Caso de Teste | Ações Chave | Resultados Esperados |
| :--- | :--- | :--- | :--- | :--- |
| **N3TA1** | Detalhes do Veículo | Acessar detalhes do veículo (Caminho Feliz) | [cite_start]Realizar busca, clicar em resultado, validar campos[cite: 465]. | [cite_start]Ficha técnica exibida com dados consolidados e normalizados[cite: 465]. |
| **N3TA2** | Detalhes do Veículo | Exibição de Dados Enriquecidos | [cite_start]Acessar detalhes, localizar seção Análise de Preço, verificar formatação[cite: 467]. | [cite_start]Exibição do Valor FIPE e do Painel de Análise de Preço formatado, sem dados brutos[cite: 468]. |
| **N3TI1** | Detalhes do Veículo | Detalhes ↔ Enriquecimento (FIPE) | [cite_start]Consulta por ID, API interna entre serviços e chamada HTTP FIPE[cite: 508]. | [cite_start]Ficha traz campos enriquecidos (valor FIPE) de forma consistente e resiliente[cite: 508]. |
| **N3TI2** | Detalhes do Veículo | Resiliência: Falha na API Externa (FIPE) | [cite_start]Simulação de **Timeout ou 500** na FIPE[cite: 510]. | [cite_start]O Serviço de Enriquecimento deve tratar a falha externa, retornando campos FIPE como vazios, permitindo que o Serviço de Detalhes prossiga e retorne ao *frontend* apenas os dados principais do veículo, sem interrupção[cite: 511]. |

---

## 💻 Interfaces do Sistema

### Telas Comuns (Cliente/Vendedor)

* [cite_start]**Tela de Login/Acesso (Figura 30):** É o ponto de autenticação central do BusCars, sendo a **pré-condição** para acessar funcionalidades protegidas e dar início ao **UC01 (Buscar carros)**[cite: 366]. [cite_start]A tela exige a inserção de e-mail e senha, e links para recuperação e cadastro de novo usuário[cite: 369].
* [cite_start]**Tela de Listagem de Resultados (Figura 32):** O coração da experiência de busca[cite: 375]. [cite_start]Exibe os resultados da pesquisa em cards com informações-chave de forma unificada e padronizada, independentemente da fonte original[cite: 377]. [cite_start]Atende diretamente ao **UC03 (Visualizar anúncios unificados)**[cite: 379].
* [cite_start]**Tela de Detalhes do Veículo (Figura 34):** Fornece a página de detalhes completos e aprofundados[cite: 385]. [cite_start]O sistema enriquece o conteúdo com informações adicionais, como o valor de referência da Tabela FIPE, ajudando o comprador a ter uma visão completa e segura[cite: 387]. [cite_start]Realiza a funcionalidade **UC02 (Acessar detalhes e informações)**[cite: 388].

### Telas do Vendedor

* [cite_start]**Tela de Escopo do Dashboard (Figura 35):** Serve como o **painel de gestão** dos anúncios e veículos atrelados diretamente à conta do Vendedor[cite: 393]. [cite_start]Exibe uma lista completa dos carros cadastrados e possui **filtros de seleção** que permitem ao Vendedor analisar e refinar seu próprio estoque[cite: 394, 396]. [cite_start]Relaciona-se à **US02.1** e **US03.1** aplicadas ao seu portfólio[cite: 396].
* [cite_start]**Tela de Cadastro de Novo Veículo (Figura 36):** É o ponto onde o Vendedor inicia o *onboarding* de um carro em seu inventário[cite: 398]. [cite_start]Coleta **informações gerais** (Marca, Modelo, Ano, Preço), utilizando **listas canônicas** para orientar a inserção de dados e garantir a normalização[cite: 399, 400]. [cite_start]Após a submissão, o sistema executa a **validação de conteúdo** (relacionada ao UC07)[cite: 402].
* [cite_start]**Tela de Códigos de Acesso (Figura 37):** Interface designada para que o Vendedor visualize e gerencie apenas as chaves de acesso atreladas diretamente à sua conta[cite: 404]. [cite_start]Permite o controle sobre **códigos de convite** que ele possa ter recebido para distribuição, apoiando o crescimento da plataforma[cite: 406, 408].

### Telas do Administrador

* [cite_start]**Tela de Controle de Anúncios (Figura 38):** Interface restrita que centraliza o poder de **moderação** e **administração** de todas as informações[cite: 413]. [cite_start]Relaciona-se diretamente aos casos de uso de **Validar Conteúdo (UC07)** e **Identificar Duplicatas (UC06)**[cite: 414]. [cite_start]Permite **editar e aprovar** anúncios pendentes e **remover** registros repetidos[cite: 416].
* [cite_start]**Tela de Controle de Usuários (Figura 39):** Interface essencial para a gestão e manutenção da base de usuários[cite: 419]. [cite_start]Permite ao Administrador **desativar contas**, **modificar perfis** e **remover usuários** [cite: 422][cite_start], sendo vital para a segurança e integridade dos dados[cite: 423].
* [cite_start]**Tela de Controle de Acesso e Usuários (Figura 40):** Ferramenta de alta criticidade para gerenciar as **permissões** e a **entrada de novos atores**[cite: 425]. [cite_start]Permite a **promoção/rebaixamento de perfis** e a **geração e distribuição de novos códigos de acesso**, assegurando um controle de qualidade na expansão da base[cite: 426, 428, 429].

---

## 📰 Post Mortem (Lições Aprendidas)

### 8.1 Experiências Positivas
[cite_start]O sucesso foi marcado pela entrega do núcleo da proposta de valor, validando a ideia de consolidar e enriquecer dados[cite: 540, 541]. [cite_start]Arquitetonicamente, a **concepção em camadas** e o uso do **Framework Dream (OCaml)** garantiram a separação de responsabilidades e a manutenibilidade[cite: 542]. [cite_start]O uso estratégico do **PostgreSQL** e **Redis** para *cache* e filas resultou em **performance otimizada** para buscas[cite: 543]. [cite_start]A infraestrutura via **Docker Compose, Nginx e Cloudflare** assegurou resiliência e controle sobre a escalabilidade[cite: 544].

### 8.2 Experiências Negativas
[cite_start]O projeto enfrentou desafios na **automação de Testes de Integração (TI)** contra APIs externas (FIPE, *Scrapers*), resultando em um **débito técnico**[cite: 548]. [cite_start]Outra dificuldade significativa foi a complexidade e o tempo gasto na **Normalização dos Dados**, pois padronizar campos de fontes inconsistentes exigiu mais esforço do que o previsto[cite: 549]. [cite_start]Funcionalidades avançadas de escala, como **alertas de oportunidades**, ficaram com escopo reduzido[cite: 550].

### 8.3 Lições Aprendidas
[cite_start]O desenvolvimento evidenciou que é imperativo **priorizar a automação de Testes de Resiliência (TI)** em sistemas de agregação[cite: 553, 554]. [cite_start]Fica o aprendizado de que a fase de **Transformação de Dados (Normalização)** deve ser tratada como um módulo de *software* de missão crítica, recomendando-se investir em *frameworks* de ETL robustos desde o início[cite: 555, 556]. [cite_start]Por fim, é essencial definir e monitorar **KPIs de qualidade de dados** ativamente para manter a credibilidade da plataforma[cite: 557, 558].

---

## 🔧 Instalação e Execução

[cite_start]O BusCars é executado usando **Docker Compose** para orquestrar os serviços (Frontend, Backend, Redis, PostgreSQL) e garantir a consistência do ambiente[cite: 325].

### Pré-requisitos
* [cite_start]**Docker** e **Docker Compose**[cite: 302].
* **Git**.

### 🐳 Execução Local Completa com Docker Compose

1.  **Clone o Repositório:**

```bash
git clone [https://github.com/ICEI-PUC-Minas-PPLES-TI/plf-es-2025-2-tcci-0393100-dev-luis-vaz-e-lucas-lima](https://github.com/ICEI-PUC-Minas-PPLES-TI/plf-es-2025-2-tcci-0393100-dev-luis-vaz-e-lucas-lima)
cd plf-es-2025-2-tcci-0393100-dev-luis-vaz-e-lucas-lima
```