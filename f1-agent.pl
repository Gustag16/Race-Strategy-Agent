% AMBIENTE E SENSORES DE PISTA (Cenário configurável)
% Grade Nx4: Linhas 1..N | Faixas 1, 2, 3 (pista) | Faixa 4 (pit lane)

tamanho_pista(8).    % N = 8 posições longitudinais (linha de chegada = 8)
limite_desgaste(6).  % Limite máximo de desgaste dos pneus permitido por segurança

% Obstáculos: cone(Linha, Faixa). retardatario(Linha, Faixa). agua(Linha, Faixa).
cone(3, 2).
cone(6, 3).
retardatario(5, 1).
retardatario(7, 2).
agua(4, 1).
agua(4, 2).
agua(4, 3).
agua(5, 2).
agua(5, 3).

% Configuração do pit lane (coluna 4)
entrada_pit(2).   % linha onde é permitido entrar no box (a partir da faixa 3)
saida_pit(4).     % linha onde o carro retorna do box para a pista

% SENSORES DE PROGRESSO, SEGURANÇA E CUSTO (TEMPO)
% o estado do agente é representado por estado(Linha, Faixa, TipoPneu, Desgaste)

% sensor de progresso (VAI SER ÚTIL PARA O A* NO FUTURO)
distancia_restante(LinhaAtual, Dist) :-
    tamanho_pista(Fim),
    Dist is Fim - LinhaAtual.

% a meta é alcançar a linha de chegada
meta(estado(Linha, Faixa, _, _)) :-
    tamanho_pista(Linha),
    Faixa >= 1, Faixa =< 3. % deve cruzar a chegada na pista, não no pit lane (schumacher 1998)

% sensor de segurança: verifica se uma célula da pista pode ser ocupada
celula_segura(Linha, Faixa) :-
    tamanho_pista(MaxL),
    Linha >= 1, Linha =< MaxL,
    Faixa >= 1, Faixa =< 3,
    \+ cone(Linha, Faixa),
    \+ retardatario(Linha, Faixa).

% cálculo do tempo (custo) ao entrar em uma célula:
% considera o tipo de pneu (seco vs chuva), poças de água e desgaste acumulado
custo_movimento(Linha, Faixa, TipoPneu, Desgaste, CustoTotal) :-
    % custo base do terreno + pneu
    ( agua(Linha, Faixa), TipoPneu == seco  -> CustoPista = 6 ; % Aquaplanagem (muito lento)
      agua(Linha, Faixa), TipoPneu == chuva -> CustoPista = 2 ; % Pneu correto na água
      \+ agua(Linha, Faixa), TipoPneu == seco -> CustoPista = 1 ; % Ideal no seco
      \+ agua(Linha, Faixa), TipoPneu == chuva -> CustoPista = 3   % Pneu de chuva no seco é mais lento
    ),
    % penalidade progressiva se o pneu estiver muito desgastado (desgaste >= 4)
    ( Desgaste >= 4 -> PenalidadeDesgaste = 2 ; PenalidadeDesgaste = 0 ),
    CustoTotal is CustoPista + PenalidadeDesgaste.

% ATUADORES (regras gerais de transição de estados)
% sucessor(EstadoAtual, Acao, CustoTempo, ProximoEstado)

% ATUADOR 1: avancar (mantém a faixa e avança 1 linha)
sucessor(estado(L, F, Pneu, Desg), avancar, Custo, estado(NovaL, F, Pneu, NovoDesg)) :-
    F \= 4,                        % se o carro não está no pit lane
    NovaL is L + 1,
    celula_segura(NovaL, F),       % verificar se a célula é segura
    NovoDesg is Desg + 1,
    limite_desgaste(MaxDesg),
    NovoDesg =< MaxDesg,           % não pode estourar o limite de desgaste do pneu
    custo_movimento(NovaL, F, Pneu, NovoDesg, Custo).

% ATUADOR 2: mudar_faixa (avança 1 linha e vai para faixa adjacente)
sucessor(estado(L, F, Pneu, Desg), mudar_faixa(NovaF), Custo, estado(NovaL, NovaF, Pneu, NovoDesg)) :-
    F \= 4,
    NovaL is L + 1,
    (NovaF is F - 1 ; NovaF is F + 1), % faixa adjacente (esquerda ou direita)
    celula_segura(NovaL, NovaF),
    NovoDesg is Desg + 1,
    limite_desgaste(MaxDesg),
    NovoDesg =< MaxDesg,
    custo_movimento(NovaL, NovaF, Pneu, NovoDesg, CustoBase),
    Custo is CustoBase + 1.   % adicionei +1 de tempo no deslocamento diagonal

% ATUADOR 3: entrar_pit (da faixa 3 para o pit lane na coluna 4)
sucessor(estado(L, 3, Pneu, Desg), entrar_pit, 3, estado(NovaL, 4, Pneu, NovoDesg)) :-
    entrada_pit(L),      % só pode entrar na posição permitida pelo sensor de pit
    NovaL is L + 1,
    NovoDesg is Desg + 1,
    limite_desgaste(MaxDesg),
    NovoDesg =< MaxDesg.

% ATUADOR 4: trocar_pneus(Tipo) (dentro do pit lane, zera desgaste e escolhe composto)
sucessor(estado(L, 4, PneuAtual, Desg), trocar_pneus(NovoPneu), 8, estado(L, 4, NovoPneu, 0)) :-
    (Desg > 0 ; PneuAtual \= NovoPneu), % só faz a parada se houver desgaste ou troca de composto
    member(NovoPneu, [seco, chuva]). % prolog escolhe o seco primeiro (se der ruim futuramente ele troca pra chuva)

% ATUADOR 5: sair_pit(Faixa) (volta da coluna 4 para a 3)
sucessor(estado(L, 4, Pneu, Desg), sair_pit(3), 2, estado(NovaL, 3, Pneu, NovoDesg)) :-
    NovaL is L + 1,
    saida_pit(NovaL),  % sai exatamente na linha de saída do pit
    celula_segura(NovaL, 3),
    NovoDesg is Desg + 1,
    limite_desgaste(MaxDesg),
    NovoDesg =< MaxDesg.

% ATUADOR 6: aguardar (permanece na posição atual consumindo tempo)
sucessor(estado(L, F, Pneu, Desg), aguardar, 3, estado(L, F, Pneu, Desg)) :-
    F \= 4.

% BUSCA INICIAL E SAÍDA EM LINGUAGEM NATURAL

% busca simples evitando ciclos (VAI SER SUBSTITUÍDA PELO A* NUM PRÓXIMO COMMIT)
busca(Estado, _, [], 0) :- 
    meta(Estado), !.

busca(EstadoAtual, Visitados, [Acao | RestoAcoes], CustoTotal) :-
    sucessor(EstadoAtual, Acao, CustoAcao, ProxEstado),
    \+ member(ProxEstado, Visitados), % evita entrar em loop (inclusive no 'aguardar')
    busca(ProxEstado, [ProxEstado | Visitados], RestoAcoes, CustoResto),
    CustoTotal is CustoAcao + CustoResto.

% tradução das ações para linguagem natural
exibir_relatorio([], _) :-
    writeln('-> Cruzou a linha de chegada!').
exibir_relatorio([Acao | Resto], Passo) :-
    format('Passo ~w: ', [Passo]),
    traduzir_acao(Acao),
    ProxPasso is Passo + 1,
    exibir_relatorio(Resto, ProxPasso).

traduzir_acao(avancar) :- writeln('Avanca mantendo a faixa atual.').
traduzir_acao(mudar_faixa(F)) :- format('Avanca mudando para a faixa ~w.~n', [F]).
traduzir_acao(entrar_pit) :- writeln('Entra no Pit Lane (Coluna 4).').
traduzir_acao(trocar_pneus(T)) :- format('Realiza Pit Stop: troca para pneus de ~w (desgaste zerado).~n', [T]).
traduzir_acao(sair_pit(F)) :- format('Sai do Pit Lane retornando para a faixa ~w.~n', [F]).
traduzir_acao(aguardar) :- writeln('Aguarda na posicao atual.').

% predicado principal para testar no SWI-Prolog: ?- iniciar.
iniciar :-
    EstadoInicial = estado(1, 2, seco, 3), % Linha 1, Faixa 2, Pneu Seco, Desgaste 3
    writeln('=== INICIANDO SIMULACAO RACE STRATEGY AGENT ==='),
    busca(EstadoInicial, [EstadoInicial], PlanoDeAcoes, TempoTotal),
    exibir_relatorio(PlanoDeAcoes, 1),
    format('~nTempo Total Estimado (Custo): ~w unidades de tempo.~n', [TempoTotal]).