//Diagrama de Sequência para Busca de Veículo Padrão
//
//Este diagrama demonstra a jornada de uma busca, desde a inserção de critérios até a visualização do resultado enriquecido:
//
//Iniciação: O Cliente (Comprador ou Vendedor) insere os filtros de busca na interface.
//
//Consulta: O Sistema de Busca recebe a solicitação e consulta o Banco de Dados para recuperar todos os anúncios e veículos correspondentes.
//
//Enriquecimento (Core Value): O Sistema de Busca aciona o Serviço de Dados (Enriquecimento). É neste ponto que a plataforma calcula o valor de referência da Tabela FIPE e executa a lógica para Identificar Duplicatas em tempo real.
//
//Apresentação: O Sistema de Busca recebe a lista final, formatada e processada, e a envia para a Interface, que exibe ao cli
//
//A Figura XX representa o fluxo de Busca de Veículo Padrão do sistema BusCars. O Cliente (Comprador ou Vendedor) inicia o processo inserindo filtros de busca na Interface do usuário. Esta, por sua vez, envia a solicitação ao Sistema Busca, que consulta o Banco de Dados para recuperar os anúncios e veículos correspondentes. Após a consulta, o Sistema Busca aciona o Serviço de Dados (Enriquecimento), que processa a lista de resultados em tempo real para calcular o valor da Tabela FIPE e identificar duplicatas. O sistema recebe a lista final, formatada e processada, permitindo que o cliente visualize os anúncios unificados e enriquecidos, facilitando a tomada de decisão.
//
@startuml Sequencia_BuscaPadrao
skinparam sequenceMessageAlignment left
title Fluxo de Busca de Veículo Padrão

actor Cliente
participant Interface as UI
participant SistemaBusca as Busca
participant BancoDeDados as BD
participant ServicoDeEnriquecimento as Enriquecimento

Cliente->>UI: 1. Inicia Busca (filtros)
activate UI
UI->>Busca: 2. solicitarBusca(filtros)
activate Busca

Busca->>BD: 3. SELECT Anuncio, Veiculo WHERE filtros
activate BD
BD-->>Busca: 4. Retorna Anuncios Brutos
deactivate BD

Busca->>Enriquecimento: 5. processarEnriquecimento(lista_anuncios)
activate Enriquecimento
Note over Enriquecimento: Calcula FIPE, Identifica Duplicatas
Enriquecimento-->>Busca: 6. Retorna Lista Unificada e Enriquecida
deactivate Enriquecimento

Busca->>UI: 7. exibirResultados(lista_final)
deactivate Busca

UI->>Cliente: 8. Visualiza Anúncios (Unificados)
deactivate UI
@enduml
//
_______________________________________________________________________________________________________________________
//
//Diagrama de Sequência: Visualização Detalhada do Veículo
//
//O fluxo para acesso aos detalhes é crítico para a tomada de decisão do usuário:
//
//Iniciação: O Cliente (ou Vendedor) clica em um resultado de busca, enviando o idAnuncio para o backend.
//
//Consulta Completa: O Sistema de Busca usa o idAnuncio para buscar no Banco de Dados todos os atributos e mídias relacionados ao anúncio e ao veículo.
//
//Enriquecimento Final: Mesmo que os dados tenham sido enriquecidos na busca inicial, o Sistema de Busca aciona o Serviço de Dados (Enriquecimento) para confirmar o valor da Tabela FIPE e o status de duplicação. Isso garante que o usuário receba as informações mais precisas no momento da análise.
//
//Apresentação da Tela: O Sistema de Busca consolida todos os dados — a descrição original, as fotos, o link de origem e as informações enriquecidas — e os envia para a Interface. A Tela de Detalhes Completa é então exibida ao usuário, fornecendo todas as informações necessárias para que ele decida entrar em contato com o vendedor.
//
//A Figura XX representa o fluxo de Visualização Detalhada do Veículo no BusCars, uma etapa crítica para a tomada de decisão do usuário. A jornada se inicia quando o Cliente ou Vendedor clica em um resultado de busca, enviando o idAnuncio para o backend. Em seguida, o Sistema de Busca realiza uma Consulta Completa no Banco de Dados para recuperar todos os atributos e mídias do anúncio e do veículo. Para garantir a precisão da análise, o Sistema de Busca aciona o Serviço de Dados (Enriquecimento), que confirma o valor da Tabela FIPE e o status de duplicação. Por fim, o Sistema de Busca consolida a descrição original, as fotos e todas as informações enriquecidas, enviando-as para a Interface, que exibe a Tela de Detalhes Completa ao usuário.
//
@startuml Sequencia_VisualizacaoDetalhada
skinparam sequenceMessageAlignment left
title Fluxo: Visualização Detalhada do Veículo

actor Cliente
participant Interface as UI
participant SistemaBusca as Busca
participant BancoDeDados as BD
participant ServicoDeDados as Enriquecimento

Cliente->>UI: 1. Clica no Anúncio (idAnuncio)
activate UI
UI->>Busca: 2. solicitarDetalhes(idAnuncio)
activate Busca

Busca->>BD: 3. SELECT * FROM Anuncio, Veiculo
activate BD
BD-->>Busca: 4. Retorna Dados Completos do Anúncio
deactivate BD

Busca->>Enriquecimento: 5. consultarDadosFIPE(idVeiculo)
activate Enriquecimento
Note over Enriquecimento: Confirma valor da FIPE e duplicação
Enriquecimento-->>Busca: 6. Retorna Valor FIPE e Status
deactivate Enriquecimento

Busca->>UI: 7. exibirTelaDetalhes(DadosFinais)
deactivate Busca

UI->>Cliente: 8. Visualiza Tela de Detalhes Completa
deactivate UI
@enduml
//
_______________________________________________________________________________________________________________________
//
Diagrama de Sequência: Acesso ao Anúncio Original
//
O fluxo de acesso ao anúncio original é um processo de baixa latência, mas crucial para o modelo de negócio do BusCars:
//
Iniciação: O Cliente clica no botão para sair, enviando o ID do anúncio ao backend.
//
Registro Analítico: O Sistema de Busca aciona o Serviço de Redirecionamento. Este serviço não apenas recupera o linkOriginal, mas também registra o clique. Essa etapa é essencial para que o Administrador possa medir o tráfego gerado para os marketplaces.
//
Redirecionamento: O backend retorna a URL original para a Interface do BusCars, que imediatamente executa o comando de redirecionamento HTTP no navegador do usuário.
//
Conclusão: O navegador do usuário acessa a Plataforma Externa (como WebMotors ou iCarros), e o anúncio é carregado, permitindo que o cliente finalize sua análise ou inicie a negociação.
//
A Figura XX representa o fluxo de Acesso ao Anúncio Original, um processo crucial para o modelo de negócio do BusCars. A sequência inicia quando o Cliente clica no botão para sair, enviando o ID do anúncio ao backend. Em seguida, o Sistema de Busca aciona o Serviço de Redirecionamento, que não só recupera o linkOriginal do anúncio, mas também registra o clique para fins de Registro Analítico do Administrador. Após esse registro, o backend retorna a URL original para a Interface do BusCars, que executa o Redirecionamento HTTP no navegador. O fluxo se conclui quando o navegador do usuário acessa a Plataforma Externa (como WebMotors ou iCarros), e o anúncio original é carregado.
//
@startuml Sequencia_AcessoAnuncioOriginal
skinparam sequenceMessageAlignment left
title Fluxo: Acesso ao Anúncio Original

actor Cliente
participant Interface as UI_BusCars
participant SistemaBusca as Busca
participant ServicoDeRedirecionamento as Redirect
participant PlataformaExterna as Marketplace

Cliente->>UI_BusCars: 1. Clica em "Ver Anúncio Original"
activate UI_BusCars
UI_BusCars->>Busca: 2. solicitarLinkOriginal(idAnuncio)
activate Busca

Busca->>Redirect: 3. registrarClick(idAnuncio, idUsuario)
activate Redirect
Note over Redirect: Loga a saída para métricas do Administrador
Redirect-->>Busca: 4. Confirma Registro
deactivate Redirect

Busca-->>UI_BusCars: 5. Retorna linkOriginal (URL)
deactivate Busca

UI_BusCars->>Cliente: 6. Redirecionamento HTTP
deactivate UI_BusCars

Cliente->>Marketplace: 7. Acessa o Anúncio na Fonte Original
activate Marketplace
Marketplace-->>Cliente: 8. Exibe Anúncio
deactivate Marketplace
@enduml
//
_______________________________________________________________________________________________________________________
//
Diagrama de Sequência: Cadastro Direto de Veículo
//
O processo de cadastro é projetado com ênfase na curadoria de conteúdo:
//
Iniciação: O Vendedor preenche o formulário detalhado, que exige informações mais completas do que marketplaces comuns.
//
Validação de Qualidade: O Sistema de Publicação aciona o Serviço de Validação (Validacao). Esta é uma etapa crucial que verifica a conformidade com os padrões BusCars (ex: qualidade das fotos, preenchimento de campos técnicos obrigatórios). Se a validação falhar, o processo retorna um erro imediato ao vendedor.
//
Persistência de Dados: Após a validação, o sistema primeiro insere os dados técnicos na tabela Veiculo e, em seguida, cria o registro na tabela Anuncio, vinculando-os.
//
Conclusão: O sistema notifica o Vendedor sobre o sucesso do envio. O anúncio estará então pronto para a etapa seguinte: a Moderação e Validação de Conteúdo pelo Administrador (UC07) antes de ser publicado.
//
A Figura XX representa o fluxo de Cadastro Direto de Veículo no BusCars, uma funcionalidade futura projetada com forte ênfase na curadoria de conteúdo. O processo se inicia com o Vendedor preenchendo um formulário detalhado, que exige informações mais completas que o padrão do mercado. Em seguida, o Sistema de Publicação aciona o Serviço de Validação, que realiza a Validação de Qualidade (verificando fotos e campos técnicos). Caso a validação falhe, o processo retorna um erro imediato ao vendedor. Se a validação for bem-sucedida, o sistema procede com a Persistência de Dados, inserindo primeiro o registro na tabela Veículo e, logo após, criando o registro do Anúncio, vinculando-o ao veículo. O fluxo é concluído com a notificação de sucesso ao Vendedor, indicando que o anúncio está pronto para a etapa de moderação pelo Administrador antes da publicação final.
//
@startuml Sequencia_CadastroVeiculo
skinparam sequenceMessageAlignment left
title Fluxo: Cadastro Direto de Veículo

actor Vendedor
participant Interface as UI_Form
participant SistemaPublicacao as Publicacao
participant ServicoDeValidacao as Validacao
participant BancoDeDados as BD

Vendedor->>UI_Form: 1. Insere Dados e Mídias
activate UI_Form

UI_Form->>Publicacao: 2. solicitarCadastro(dadosAnuncio)
activate Publicacao

Publicacao->>Validacao: 3. validarDados(dadosAnuncio)
activate Validacao

alt Sucesso na Validação
    Validacao-->>Publicacao: 4. Retorna Confirmação de Sucesso
    deactivate Validacao
    
    Publicacao->>BD: 5. INSERT INTO Veiculo
    activate BD
    BD-->>Publicacao: 6. Retorna idVeiculo
    deactivate BD
    
    Publicacao->>BD: 7. INSERT INTO Anuncio
    activate BD
    BD-->>Publicacao: 8. Confirma Persistência
    deactivate BD
    
    Publicacao->>UI_Form: 9. exibirSucesso("Anúncio Enviado para Aprovação")
else Falha na Validação
    Validacao-->>Publicacao: 4. Retorna Erro (ex: foto de baixa resolução)
    deactivate Validacao
    Publicacao-->>UI_Form: 5. Exibe Mensagem de Erro
end
deactivate Publicacao
deactivate UI_Form
@endumal
//
_______________________________________________________________________________________________________________________
//
Diagrama de Sequência: Acesso a Estatísticas e Dashboards
//
O processo de visualização de métricas envolve a agregação de dados internos e externos:
//
Iniciação: O Administrador acessa a interface de gestão e solicita o dashboard de métricas.
//
Agregação de Dados: O Sistema de Métricas atua como um orquestrador, buscando dados em duas fontes primárias:
//
Banco de Dados: Para dados transacionais e de volume (como o número total de anúncios agregados ou usuários registrados).
//
Serviços de Monitoramento Externo: Para logs operacionais e de saúde do sistema (como a taxa de sucesso das rotinas de scraping e a performance do servidor).
//
Processamento: O Sistema de Métricas consolida as informações brutas em KPIs (Indicadores-Chave de Desempenho), tornando os dados compreensíveis para análise estratégica.
//
Apresentação: O painel formatado é exibido na Interface Admin, permitindo que o administrador tome decisões informadas sobre a necessidade de ajustes na coleta de dados ou otimizações de performance.
//
A Figura XX representa o fluxo de Acesso a Estatísticas e Dashboards no BusCars, uma função essencial para o Administrador. A sequência começa com a Iniciação, onde o Administrador acessa a interface de gestão e solicita o dashboard de métricas. Em seguida, o Sistema de Métricas executa a Agregação de Dados, atuando como um orquestrador ao buscar informações em duas fontes primárias: o Banco de Dados, para dados de volume e transacionais, e os Serviços de Monitoramento Externo, para logs de saúde do sistema e performance. Na etapa de Processamento, o Sistema de Métricas consolida as informações brutas em KPIs (Indicadores-Chave de Desempenho), preparando-as para a análise. O fluxo é finalizado com a Apresentação, onde o painel formatado é exibido na Interface Admin, permitindo ao administrador tomar decisões estratégicas informadas.
//
@startuml Sequencia_AcessoEstatisticas
skinparam sequenceMessageAlignment left
title Fluxo: Acesso a Estatísticas e Dashboards

actor Administrador
participant InterfaceAdmin as UI_Admin
participant SistemaMetricas as Metricas
participant BancoDeDados as BD
participant ServicoExterno as Monitoramento

Administrador->>UI_Admin: 1. Solicita Acesso ao Dashboard
activate UI_Admin
UI_Admin->>Metricas: 2. solicitarMetricasKPIs()
activate Metricas

Metricas->>BD: 3. CONSULTA: Dados Transacionais (Anúncios, Usuários)
activate BD
BD-->>Metricas: 4. Retorna Dados Brutos
deactivate BD

Metricas->>Monitoramento: 5. CONSULTA: Logs/Saúde do Scraper
activate Monitoramento
Monitoramento-->>Metricas: 6. Retorna Status Operacional
deactivate Monitoramento

Note over Metricas: 7. Consolida e formata KPIs
Metricas-->>UI_Admin: 8. Retorna Dashboards Formatados
deactivate Metricas

UI_Admin->>Administrador: 9. Visualiza Estatísticas
deactivate UI_Admin
@endumal
//
_______________________________________________________________________________________________________________________
//
//Diagrama de Sequência: Fluxo de Login
//
//O processo de login é estruturado para ser seguro e eficiente:
//
//Iniciação: O Usuário insere seu e-mail e senha na interface de login.
//
//Validação: O Sistema de Autenticação consulta o Banco de Dados para obter a hash da senha associada ao e-mail fornecido. A validação ocorre no backend, comparando o hash da senha inserida com o valor armazenado, sem nunca expor a senha original.
//
//Resultado:
//
Sucesso: Se as credenciais forem válidas, o sistema gera um token de sessão seguro e informa o tipoUsuario (Cliente, Vendedor ou Administrador) para a interface. O usuário é então redirecionado para a área apropriada.
//
Falha: O sistema retorna uma mensagem de erro genérica ("Credenciais inválidas"), mantendo a segurança ao não informar se foi o e-mail ou a senha que falhou.
//
//A Figura XX representa o fluxo de Login na plataforma BusCars, um processo estruturado para ser seguro e eficiente. O fluxo começa com a Iniciação, onde o Usuário insere seu e-mail e senha na interface de login. Em seguida, o Sistema de Autenticação executa a Validação, consultando o Banco de Dados para obter o hash da senha e compará-lo com a informação fornecida. A senha original jamais é exposta. O processo culmina no Resultado: em caso de Sucesso, o sistema gera um token de sessão e informa o tipoUsuario (Cliente, Vendedor ou Administrador) à interface, redirecionando o usuário para a área apropriada. Em caso de Falha, o sistema retorna uma mensagem de erro genérica ("Credenciais inválidas"), mantendo a segurança do acesso.
//
@startuml Sequencia_FluxoLogin
skinparam sequenceMessageAlignment left
title Fluxo de Login (Autenticação)

actor Usuario
participant Interface as UI_Login
participant SistemaAutenticacao as Auth
participant BancoDeDados as BD

Usuario->>UI_Login: 1. Insere Credenciais (email, senha)
activate UI_Login
UI_Login->>Auth: 2. solicitarLogin(email, senha)
activate Auth

Auth->>BD: 3. CONSULTA: Buscar senhaHash por email
activate BD
BD-->>Auth: 4. Retorna senhaHash e tipoUsuario
deactivate BD

Note over Auth: 5. Compara senhas (password_verify)

alt Credenciais Válidas (Sucesso)
    Auth-->>UI_Login: 6. Retorna Token de Sessão e tipoUsuario
    UI_Login->>Usuario: 7. Redireciona para Dashboard
else Credenciais Inválidas (Falha)
    Auth-->>UI_Login: 6. Retorna Mensagem de Erro
    UI_Login->>Usuario: 7. Exibe Erro na Tela de Login
end
deactivate Auth
deactivate UI_Login
@enduml
//
_______________________________________________________________________________________________________________________
//
Diagrama de Sequência: Análise de Preço de Mercado (UC07)
//
Este fluxo demonstra como o BusCars transforma dados brutos em inteligência de mercado:
//
Iniciação: A solicitação é iniciada automaticamente ao carregar a página de detalhes do veículo, ou via um clique do Usuário (Vendedor ou Cliente).
//
Consulta de Comparáveis: O Sistema de Análise utiliza as características do veículo (idVeiculo) para consultar o Banco de Dados. O sistema busca todos os Anúncios similares que servem como o dataset de comparação de mercado.
//
Cálculo da Inteligência: Após receber a lista de preços do mercado, o Sistema de Análise executa a lógica central (passo 6). Ele calcula o preço médio do modelo e determina a posição percentual do preço atual do veículo em análise.
//
Apresentação do Resultado: O resultado da análise é então retornado para a Interface, que exibe um painel de fácil compreensão (ex: um gráfico ou uma mensagem) indicando se o carro está bem precificado, caro ou em uma excelente oportunidade.
//
A Figura XX representa o fluxo de Análise de Preço de Mercado no BusCars, que transforma dados brutos em inteligência de mercado para o usuário. A Iniciação da solicitação ocorre automaticamente ao carregar a página de detalhes ou via um clique do Usuário (Vendedor ou Cliente). Em seguida, o Sistema de Análise executa a Consulta de Comparáveis, utilizando o idVeiculo para buscar no Banco de Dados todos os Anúncios similares que servem como dataset de comparação de mercado. Após receber a lista de preços, o sistema procede ao Cálculo da Inteligência, determinando o preço médio e a posição percentual do veículo em análise. O fluxo é finalizado com a Apresentação do Resultado, onde a Interface exibe um painel de fácil compreensão que indica se o preço do carro está justo, caro ou representa uma oportunidade.
//
@startuml Sequencia_AnalisePrecoMercado
skinparam sequenceMessageAlignment left
title Fluxo: Análise de Preço de Mercado

actor Usuario
participant Interface as UI_Detalhes
participant SistemaAnalise as Analise
participant BancoDeDados as BD

Usuario->>UI_Detalhes: 1. Acessa Tela de Detalhes do Veículo
activate UI_Detalhes
Note over UI_Detalhes: 2. Dispara solicitação de Análise de Preço
UI_Detalhes->>Analise: 3. solicitarAnalise(idVeiculo, precoAtual)
activate Analise

Analise->>BD: 4. CONSULTA: Buscar preços de Anúncios Similares
activate BD
Note over BD: Busca por Marca, Modelo e Ano
BD-->>Analise: 5. Retorna Lista de Preços do Mercado
deactivate BD

Note over Analise: 6. Executa cálculo (Média, Posição Percentual)
Analise-->>UI_Detalhes: 7. Retorna Resultado da Análise
deactivate Analise

UI_Detalhes->>Usuario: 8. Exibe Painel de Análise de Preço
deactivate UI_Detalhes
@enduml
//
_______________________________________________________________________________________________________________________
//
//Diagrama de Sequência: Validação de Conteúdo ????????????
//
//O fluxo de validação reflete o papel do Administrador como o curador da plataforma:
//
//Revisão de Conteúdo: O Administrador utiliza a Interface Admin para acessar os detalhes do anúncio. Essa interface deve exibir informações cruciais de segurança e consistência (ex: preço muito abaixo da FIPE, descrição incoerente, imagens suspeitas).
//
//Consulta: O Sistema de Validação busca os dados completos do Anúncio e do Veículo no Banco de Dados para que o administrador tenha todas as informações necessárias para sua decisão.
//
//Tomada de Decisão: Após a análise humana, o Administrador envia a Ação final (Aprovar ou Remover) para o backend.
//
//Atualização da Base: O Sistema de Validação persiste a decisão no Banco de Dados, alterando o status do Anuncio. Apenas anúncios com status Aprovado (ou similar) devem ser visíveis para os Clientes e Vendedores. Esta etapa é vital para manter a confiança na plataforma.
//
//A Figura XX representa o fluxo de Validação de Conteúdo no BusCars, que reflete o papel do Administrador como curador da plataforma. O processo começa com a Revisão de Conteúdo, onde o Administrador acessa a Interface Admin para analisar os detalhes do anúncio, buscando informações cruciais de segurança e consistência. Em seguida, o Sistema de Validação executa uma Consulta no Banco de Dados para buscar os dados completos do Anúncio e do Veículo, fornecendo o contexto total para a Tomada de Decisão. Após a análise humana, o Administrador envia a Ação final (Aprovar ou Remover) para o backend. O fluxo é concluído com a Atualização da Base, onde o Sistema de Validação altera o status do Anúncio no Banco de Dados, garantindo que apenas conteúdos aprovados sejam visíveis aos Clientes e Vendedores.
//
@startuml Sequencia_ValidacaoConteudo
skinparam sequenceMessageAlignment left
title Fluxo: Validação de Conteúdo

actor Administrador
participant InterfaceAdmin as UI_Admin
participant SistemaValidacao as Validacao
participant BancoDeDados as BD

Administrador->>UI_Admin: 1. Acessa Fila de Moderação
activate UI_Admin
Administrador->>UI_Admin: 2. Seleciona Anúncio para Revisão (idAnuncio)

UI_Admin->>Validacao: 3. solicitarDetalhes(idAnuncio)
activate Validacao

Validacao->>BD: 4. CONSULTA: Obter dados completos do Anúncio
activate BD
BD-->>Validacao: 5. Retorna Dados para Revisão
deactivate BD

Validacao-->>UI_Admin: 6. Exibe Dados e Opções de Ação

Administrador->>UI_Admin: 7. Envia Decisão (Aprovar / Remover)

alt Ação: Aprovar Conteúdo
    UI_Admin->>Validacao: 8. confirmarAprovacao(idAnuncio)
    Validacao->>BD: 9. UPDATE Anuncio SET status='Aprovado'
    activate BD
    BD-->>Validacao: 10. Confirmação
    deactivate BD
else Ação: Remover/Bloquear
    UI_Admin->>Validacao: 8. confirmarRemocao(idAnuncio)
    Validacao->>BD: 9. UPDATE Anuncio SET status='Removido'
    activate BD
    BD-->>Validacao: 10. Confirmação
    deactivate BD
end

Validacao-->>UI_Admin: 11. Notificação de Ação Completa
deactivate Validacao
deactivate UI_Admin
@endumal
//
_______________________________________________________________________________________________________________________
//
Diagrama de Sequência: Monitoramento da Coleta de Dados
//
O processo de monitoramento é a chave para a confiabilidade do BusCars como agregador:
//
Iniciação: O Administrador acessa uma seção específica na interface de administração para solicitar o relatório de saúde da coleta.
//
Consulta de Status: O Sistema de Monitoramento consulta o Banco de Dados para extrair o estado atual (statusColeta) e o histórico de execução de todas as entradas da tabela FonteDeDados.
//
Análise e Formatação: O sistema formata os dados brutos em um relatório legível, indicando claramente quais fontes tiveram sucesso em sua última execução e quais apresentaram falha (ex: bloqueio de IP ou mudança na estrutura do site).
//
Ação Corretiva: O Administrador visualiza o relatório. Se houver falhas, ele pode tomar medidas imediatas (Passo 8), como reajustar a rotina de scraping ou reexecutar a coleta para a fonte específica, garantindo que o sistema esteja sempre atualizado.
//
A Figura XX representa o fluxo de Monitoramento da Coleta de Dados no BusCars, um processo essencial para a confiabilidade da plataforma como agregador. A sequência inicia com a Iniciação, onde o Administrador acessa uma seção específica da Interface Admin para solicitar o relatório de saúde. Em seguida, o Sistema de Monitoramento executa a Consulta de Status no Banco de Dados, extraindo o estado e o histórico de execução de todas as entradas da tabela Fonte de Dados. O sistema realiza a Análise e Formatação, convertendo os dados brutos em um relatório legível que indica quais fontes tiveram sucesso ou apresentaram falha. Por fim, o fluxo é concluído com a Ação Corretiva, onde o Administrador visualiza o relatório e pode tomar medidas imediatas, como reajustar a rotina de scraping para garantir que o sistema permaneça sempre atualizado.
//
@startuml Sequencia_MonitoramentoColeta
skinparam sequenceMessageAlignment left
title Fluxo: Monitoramento da Coleta de Dados

actor Administrador
participant InterfaceAdmin as UI_Monitor
participant SistemaMonitoramento as Monitor
participant BancoDeDados as BD
participant FonteDeDados as Fontes

Administrador->>UI_Monitor: 1. Solicita "Status da Coleta"
activate UI_Monitor
UI_Monitor->>Monitor: 2. solicitarRelatorioDeStatus()
activate Monitor

Monitor->>BD: 3. CONSULTA: Obter status e logs das FontesDeDados
activate BD
BD-->>Monitor: 4. Retorna (nomeFonte, statusColeta, ultimaData)
deactivate BD

Note over Monitor: 5. Formata dados em dashboard (KPIs de saúde)

Monitor-->>UI_Monitor: 6. Retorna Relatório de Monitoramento
deactivate Monitor

UI_Monitor->>Administrador: 7. Visualiza Status (OK/Falha)
deactivate UI_Monitor

Administrador->>Fontes: 8. (Ação) Inicia Correção ou Reexecuta Rotina
@enduml
//

-----------------------------------------------------------------------------------------------------------------------------------------------

1. Contrato: Busca de Veículos (US01, US04)

Este contrato formaliza a ação inicial de pesquisa para Clientes e Vendedores.
Snippet de código

@startuml Sequencia_BuscaPadrao
actor Usuario
participant Sistema as BusCars

Usuario->Sistema: iniciarBusca(filtros)
activate Sistema
note over Sistema: Consulta BD, Enriquecimento (FIPE, Duplicatas)
Sistema-->Usuario: exibirResultados(lista_unificada)
deactivate Sistema
@enduml

Contrato	Operação
Referência	US01, US04
Operação	iniciarBusca(filtros: Mapa<String, String>)
Pré-condições	O usuário deve estar na área de busca.
Pós-condições	1. O sistema retorna uma lista de objetos Anuncio e Veiculo que atendem aos filtros. 2. A lista de resultados é processada pelo Serviço de Enriquecimento.

Detalhes do Diagrama e Tabela do Caso:

O SSD ilustra a simplicidade da busca para o Usuário. A Pós-condição garante que os resultados (seja para o Vendedor buscando oportunidades ou para o Cliente buscando um carro) sejam sempre processados pelo Serviço de Enriquecimento antes de serem exibidos, cumprindo o valor central da plataforma.

_______________________________________________________________________________________________________________________

2. Contrato: Acesso a Detalhes do Veículo (US02, US05)

Este contrato formaliza a visualização aprofundada de um anúncio selecionado.
Snippet de código

@startuml Sequencia_AcessoDetalhes
actor Usuario
participant Sistema as BusCars

Usuario->Sistema: acessarDetalhes(idAnuncio)
activate Sistema
note over Sistema: Confirma dados de enriquecimento (FIPE)
Sistema-->Usuario: exibirDetalhesCompletos(dados_enriquecidos)
deactivate Sistema
@endumal

Contrato	Operação
Referência	US02, US05
Operação	acessarDetalhes(idAnuncio)
Pré-condições	O idAnuncio deve ser válido e o anúncio deve estar com status "Ativo".
Pós-condições	1. O sistema retorna todos os atributos e mídias do Anuncio e do Veiculo. 2. Os dados de enriquecimento (FIPE) são confirmados e exibidos ao usuário.

Detalhes do Diagrama e Tabela do Caso:

O SSD mostra o fluxo direto de acesso à informação. O contrato garante que a Pós-condição de retorno inclua os dados de enriquecimento, essenciais para que o Vendedor tome decisões informadas de compra ou para que o Cliente avalie a seriedade do anúncio.

_______________________________________________________________________________________________________________________

3. Contrato: Visualização Unificada (US03, US06)

Este contrato formaliza o resultado da busca, que é o principal diferencial do BusCars.
Snippet de código

@startuml Sequencia_VisualizacaoUnificada
actor Usuario
participant Sistema as BusCars

Usuario->Sistema: iniciarBusca(filtros)
activate Sistema
note over Sistema: Executa Normalização e Consolidação
Sistema-->Usuario: exibirResultados(lista_unificada)
deactivate Sistema
@endumal

Contrato	Operação
Referência	US03, US06
Operação	retornarAnunciosUnificados(listaResultadosBrutos)
Pré-condições	A busca deve ter retornado resultados válidos.
Pós-condições	1. Os dados de todos os anúncios são normalizados e padronizados em um único formato de exibição. 2. A interface apresenta a lista de forma comparativa e eficiente.

Detalhes do Diagrama e Tabela do Caso:

Este fluxo (implícito na busca inicial) garante que a Pós-condição de padronização seja executada no backend, cumprindo a promessa de visualização unificada, poupando tempo do usuário.

_______________________________________________________________________________________________________________________

4. Contrato: Análise de Preço do Cliente (Comparativo) (US07)

Este contrato formaliza a funcionalidade de inteligência de mercado para o Cliente.
Snippet de código

@startuml Sequencia_AnalisePrecoCliente
actor Cliente
participant Sistema as BusCars

Cliente->BusCars: solicitarAnalisePreco(idVeiculo, precoAtual)
activate BusCars
note over BusCars: Busca comparáveis e calcula Posição Percentual
BusCars-->Cliente: exibirAnalise(dados_comparativos)
deactivate BusCars
@endumal

Contrato	Operação
Referência	US07
Operação	analisarPrecoMercado(idVeiculo, precoAtual)
Pré-condições	O idVeiculo deve ser válido e o sistema deve ter dataset de comparação suficiente.
Pós-condições	1. O sistema calcula o preço médio e a posição percentual do precoAtual contra o mercado. 2. O resultado da análise de preço é exibido ao Cliente.

Detalhes do Diagrama e Tabela do Caso:

O SSD mostra o fluxo de solicitação de análise. O contrato garante que o sistema execute o Cálculo da Inteligência para suportar a decisão do Cliente.

_______________________________________________________________________________________________________________________

5. Contrato: Análise Média de Preço (Gestão) (US08)

Este contrato formaliza a operação de gestão (Administrador) que suporta o enriquecimento.
Snippet de código

@startuml Sequencia_CalibragemPreco
actor Administrador
participant Sistema as BusCars

Administrador->BusCars: calcularPrecoMedioGlobal(filtros)
activate BusCars
note over BusCars: Executa agregação estatística no BD
BusCars-->Administrador: retornarValorMedio()
deactivate BusCars
@endumal

Contrato	Operação
Referência	US08
Operação	calcularPrecoMedioGlobal(filtros)
Pré-condições	O Administrador deve estar autenticado.
Pós-condições	1. O sistema executa uma agregação estatística para calcular o preço médio de um Veiculo específico. 2. O valor médio é registrado e/ou utilizado para calibrar o Serviço de Enriquecimento (FIPE/Comparativo).

Detalhes do Diagrama e Tabela do Caso:

O contrato define essa operação como uma função de calibração do sistema (Administrador), essencial para manter a precisão do Serviço de Enriquecimento (Pós-condição 2).

_______________________________________________________________________________________________________________________

6. Contrato: Identificar Duplicatas (Rotina Interna) (US09)

Este contrato formaliza a ação de manutenção de dados, que é disparada internamente.
Snippet de código

@startuml Sequencia_IdentificarDuplicatas
object SistemaInterno
participant Sistema as BusCars

SistemaInterno->Sistema: identificarDuplicatas(novoAnuncio)
activate Sistema
note over Sistema: Algoritmo de comparação de atributos
Sistema-->SistemaInterno: confirmarAtualizacao()
deactivate Sistema
@endumal

Contrato	Operação
Referência	US09
Operação	identificarDuplicatas(novoAnuncio)
Pré-condições	Um novo Anuncio deve ter sido coletado e persistido no sistema.
Pós-condições	1. O sistema executa um algoritmo de comparação contra o banco de dados. 2. O Anuncio e seus pares são atualizados, definindo a flag isDuplicado como TRUE.

Detalhes do Diagrama e Tabela do Caso:

O SSD ilustra uma interação do SistemaInterno. O contrato define a Pós-condição de manutenção de dados: o algoritmo de comparação é executado, garantindo a unicidade e a qualidade do dataset.

_______________________________________________________________________________________________________________________

7. Contrato: Validar Conteúdo (Curadoria) (US10)

Este contrato formaliza a ação de curadoria essencial do Administrador.
Snippet de código

@startuml Sequencia_ValidacaoConteudo
actor Administrador
participant Sistema as BusCars

Administrador->Sistema: validarAnuncio(idAnuncio, decisao)
activate Sistema
alt Decisão: Aprovar
    note over Sistema: UPDATE status='Ativo'
else Decisão: Remover
    note over Sistema: UPDATE status='Removido'
end
Sistema-->Administrador: confirmarAtualizacao(status)
deactivate Sistema
@endumal

Contrato	Operação
Referência	US10
Operação	validarAnuncio(idAnuncio, decisao)
Pré-condições	O Administrador deve estar autenticado. O idAnuncio deve estar no status "Pendente" ou "Sinalizado".
Pós-condições	1. O status do Anuncio é alterado para "Ativo" (se aprovado) ou "Removido" (se rejeitado). 2. Se "Ativo", o anúncio passa a ser visível nas buscas para todos os usuários.

Detalhes do Diagrama e Tabela do Caso:

O SSD mostra a decisão do Administrador. O contrato garante que a Pós-condição de atualização do status defina a visibilidade do anúncio, cumprindo o requisito de credibilidade da plataforma.

_______________________________________________________________________________________________________________________

8. Contrato: Monitoramento da Coleta de Dados (US11)

Este contrato formaliza a gestão da saúde do sistema (Administrador).
Snippet de código

@startuml Sequencia_MonitoramentoColeta
actor Administrador
participant Sistema as BusCars

Administrador->Sistema: solicitarRelatorioDeColeta()
activate Sistema
note over Sistema: Consulta status de todas as FontesDeDados
Sistema-->Administrador: exibirRelatorio(status_das_fontes)
deactivate Sistema
@endumal

Contrato	Operação
Referência	US11
Operação	solicitarRelatorioDeColeta()
Pré-condições	O Administrador deve estar autenticado. A rotina de coleta deve ter sido executada recentemente.
Pós-condições	1. O sistema consulta o statusColeta de cada FonteDeDados. 2. Um RelatorioDeColeta (data/status/falhas) é gerado e exibido na interface de administração. 3. O relatório indica quais fontes exigem Ação Corretiva (reajuste de scraper).

Detalhes do Diagrama e Tabela do Caso:

O contrato garante que o sistema retorne um relatório que é um insumo para a Ação Corretiva, detalhando o status de saúde de cada fonte externa (Pós-condição 3).

_______________________________________________________________________________________________________________________

9. Contrato: Visualização de Métricas de Desempenho (US12)

Este contrato formaliza a função de inteligência administrativa.
Snippet de código

@startuml Sequencia_VisualizacaoMetricas
actor Administrador
participant Sistema as BusCars

Administrador->Sistema: visualizarPerformance(periodo)
activate Sistema
note over Sistema: Agrega dados de Métricas e Logs
Sistema-->Administrador: exibirDashboard(KPIs)
deactivate Sistema
@endumal

Contrato	Operação
Referência	US12
Operação	visualizarPerformance(periodo)
Pré-condições	O Administrador deve estar autenticado. O sistema deve ter dados registrados na classe Metrica.
Pós-condições	1. O sistema agrega e calcula dados de logs e eventos para o periodo solicitado. 2. Um dashboard visual (KPIs como volume de anúncios, usuários ativos) é gerado e exibido na interface de administração.

Detalhes do Diagrama e Tabela do Caso:

O contrato garante que o sistema faça o Processamento dos dados brutos de logs e eventos para gerar um dashboard estratégico (Pós-condição 2), fornecendo a inteligência necessária.

-------------------------------------------------------------------------------------------------------------------------------------------

Diagrama de Comunicação: Busca e Análise de Veículos (UC01, UC02, UC07)

@startuml
package "Usuários" {
    object Usuario
}

package "Arquitetura Principal" {
    object UI
    object Controller
    object Service
    object Repository
}

package "Dados e Enriquecimento" {
    object BD
    object Enriquecimento
}

Usuario ---> UI : 1: iniciarBusca(filtros)
UI ---> Controller : 1.1: buscar(filtros)
Controller ---> Service : 1.2: processarBusca(filtros)
Service ---> Repository : 1.3: consultarAnuncios(filtros)
Repository ---> BD : 1.3.1: SELECT Anuncios
BD ---> Repository : 1.3.2: retornarDadosBrutos()
Repository ---> Service : 1.4: retornarAnuncios()
Service ---> Enriquecimento : 1.5: solicitarAnaliseMercado(lista)
Enriquecimento ---> Enriquecimento : 1.5.1: calcularFIPE_Media()
Enriquecimento ---> Service : 1.6: retornarDadosEnriquecidos()
Service ---> Controller : 1.7: retornarResultados()
Controller ---> UI : 1.8: exibirResultados()
UI ---> Usuario : 1.9: Visualizar Lista Unificada
Usuario ---> UI : 2: clicarNoAnuncio(id)
UI ---> Controller : 2.1: acessarDetalhes(id)
Controller ---> Service : 2.2: obterDetalhesCompletos(id)
Service ---> Repository : 2.3: consultarDetalhes(id)
Repository ---> Service : 2.4: retornarDetalhes()
Service ---> Controller : 2.5: retornarDetalhes()
Controller ---> UI : 2.6: exibirTelaDetalhes()
UI ---> Usuario : 2.7: Visualizar Detalhes

@endumal
@enduml

_______________________________________________________________________________________________________________________
Diagrama de Comunicação: Gestão e Curadoria (UC07, UC08, UC09, UC10)

@startuml Comunicacao_GestaoCuradoria

package "Usuários" {
    object Administrador
}

package "Sistemas de Gestão" {
    object InterfaceAdmin
    object AdminController
    object AdminService
    object AnuncioRepository
}

package "Fontes de Dados e Logs" {
    object BancoDeDados
    object ServicoMonitoramento
}

Administrador ---> InterfaceAdmin : 1: solicitarAcessoAdmin()
InterfaceAdmin ---> AdminController : 1.1: solicitarDashboard()
AdminController ---> AdminService : 2: processarAcao(acao: Moderar ou Monitorar)
AdminService ---> ServicoMonitoramento : 3: consultarSaudeScrapers()
ServicoMonitoramento ---> AdminService : 4: retornarLogsEStatus()
AdminService ---> AnuncioRepository : 5: buscarAnuncioParaValidar(id)
AnuncioRepository ---> BancoDeDados : 5.1: SELECT Anuncio
BancoDeDados ---> AnuncioRepository : 5.2: retornarDados()
AnuncioRepository ---> AdminService : 5.3: retornarAnuncio()
AdminService ---> InterfaceAdmin : 6: exibirAnuncioParaDecisao()
InterfaceAdmin ---> Administrador : 6.1: aguardaDecisao()
Administrador ---> InterfaceAdmin : 7: enviarDecisao(Aprovar/Remover)
InterfaceAdmin ---> AdminService : 7.1: atualizarStatus(id, novoStatus)
AdminService ---> AnuncioRepository : 8: persistirDecisao(id, novoStatus)
AnuncioRepository ---> BancoDeDados : 8.1: UPDATE Anuncio
BancoDeDados ---> AnuncioRepository : 8.2: Confirmação()
AnuncioRepository ---> AdminService : 8.3: Sucesso()
AdminService ---> InterfaceAdmin : 9: confirmarAcao()
InterfaceAdmin ---> Administrador : 10: exibirNotificacaoFinal()

@endumal

_______________________________________________________________________________________________________________________
Diagrama de Comunicação: Agregação de Dados (UC11)

@startuml Comunicacao_AgregacaoDeDados

package "Sistemas de Agregação" {
    object Job
    object Controller
    object Service
}

package "Fontes e Persistência" {
    object FonteExterna
    object BD
    object Monitor
}


Job ---> Controller : 1: iniciarColetaGeral()
Controller ---> Service : 1.1: orquestrarColeta()
Service ---> Marketplace : 2: chamarAPI_WebScraper()
Marketplace ---> Service : 2.1: retornarDadosBrutos(lista)
Service ---> Service : 2.2: processarNormalizarDados()
Service ---> BD : 3: persistirAnuncios(dadosNormalizados)
BD ---> Service : 3.1: ConfirmaPersistencia()
Service ---> Monitor : 4: registrarStatus(Sucesso/Falha)
Monitor ---> BD : 4.1: LogarExecucao()
BD ---> Monitor : 4.2: Confirmação()
Service ---> Controller : 5: retornarResumoExecucao()
Controller ---> Job : 5.1: NotificarFimDoJob()


@endumal