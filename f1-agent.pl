% AMBIENTE E SENSORES DE PISTA (cenário configurável)
% grade Nx4: linhas 1..N | faixas 1, 2, 3 (pista) | faixa 4 (pit lane)

tamanho_pista(8).    % N = 8 posições longitudinais (linha de chegada = 8)
limite_desgaste(6).  % limite máximo de desgaste dos pneus permitido por segurança

% obstáculos: cone(Linha, Faixa). retardatario(Linha, Faixa). agua(Linha, Faixa).
cone(3, 2).
cone(3, 3).
cone(6, 3).
retardatario(5, 1).
retardatario(7, 2).
agua(4, 1).
agua(4, 2).
agua(4, 3).
agua(5, 2).
agua(5, 3).

% configuração do pit lane (coluna 4)
entrada_pit(2).   % linha onde é permitido entrar no box (a partir da faixa 3)
saida_pit(5).     % linha onde o carro retorna do box para a pista

% SENSORES DE PROGRESSO, SEGURANÇA E CUSTO (TEMPO)
% o estado do agente é representado por estado(Linha, Faixa, TipoPneu, Desgaste)

% sensor de progresso (útil para o A*)
distancia_restante(LinhaAtual, Dist) :-
    tamanho_pista(Fim),
    Dist is Fim - LinhaAtual.

% estima o menor tempo possível até a chegada
heuristica(estado(LinhaAtual, _, _, _), H) :-
    distancia_restante(LinhaAtual, Dist),
    H is Dist * 1.

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

% ATUADOR EXTRA: avancar_pit (permite percorrer um Pit Lane de comprimento maior que 2)
sucessor(estado(L, 4, Pneu, Desg), avancar_pit, 2, estado(NovaL, 4, Pneu, Desg)) :-
    NovaL is L + 1,
    saida_pit(LinhaSaida),
    NovaL < LinhaSaida. % Avança pela coluna 4 até chegar na linha anterior à saída

% MOTOR DE BUSCA A*
% estrutura do nó na fila: no(F, G, EstadoAtual, CaminhoReverso)

% Prepara as listas iniciais do A* e desvira o caminho encontrado no final
astar(Inicio, Plano, CustoFinal, Explorados) :-
    heuristica(Inicio, H),
    % começa com apenas o estado inicial na Fronteira (G = 0, F = H)
    astar_loop([no(H, 0, Inicio, [])],
               [melhor_custo(Inicio, 0)], % lista 'Melhores': menor G já visto para cada estado
               [],                        % lista 'Fechados': estados já expandidos
               PlanoReverso, CustoFinal, 0, Explorados),
    reverse(PlanoReverso, Plano).         % inverte a lista para mostrar do passo 1 ao último

% CONDIÇÃO DE PARADA DO A*: o primeiro nó da fonteira (menor F) é a meta
astar_loop([no(_, G, Estado, CaminhoReverso)|_],
           _, _, CaminhoReverso, G, Expandidos, Expandidos) :-
    meta(Estado), !.

% PASSO RECURSIVO DO A*: retira o melhor nó do topo da fronteira e o avalia
astar_loop([no(_, G, Estado, CaminhoReverso)|Fronteira],
           Melhores, Fechados, Plano, CustoFinal, Exp0, ExpFinal) :-
    (   % caso 1: já achamos um caminho mais rápido para este mesmo estado antes -> ignora
        custo_registrado(Estado, MelhorGAtual, Melhores),
        MelhorGAtual < G ->
        astar_loop(Fronteira, Melhores, Fechados,
                   Plano, CustoFinal, Exp0, ExpFinal);
        % caso 2: este estado já foi totalmente expandido antes com custo menor ou igual -> ignora
        custo_conhecido_melhor(Estado, G, Fechados) ->
        astar_loop(Fronteira, Melhores, Fechados,
                   Plano, CustoFinal, Exp0, ExpFinal);
        % caso 3: é um estado inédito ou melhor. Vamos gerar todos os movimentos possíveis (sucessores)
        findall(no(FNovo, GNovo, ProxEstado,
                   [passo(Estado, Acao, ProxEstado, CustoAcao)|CaminhoReverso]),
                ( sucessor(Estado, Acao, CustoAcao, ProxEstado), % chama os seus atuadores
                  GNovo is G + CustoAcao,                        % soma o tempo gasto até aqui
                  heuristica(ProxEstado, HNovo),                 % calcula o tempo estimado restante
                  FNovo is GNovo + HNovo                         % calcula a prioridade F = G + H
                ),
                Sucessores),
        % insere os novos estados na fila ordenados pelo menor F
        atualizar_fronteira(Sucessores, Fronteira, Melhores,
                            NovaFronteira, NovosMelhores),
        Exp1 is Exp0 + 1, % Soma 1 no contador de estados analisados
        % continua o loop anotando o Estado atual na lista de 'Fechados'
        astar_loop(NovaFronteira, NovosMelhores,
                   [melhor_custo(Estado, G)|Fechados],
                   Plano, CustoFinal, Exp1, ExpFinal)
    ).

% verifica se o estado já foi expandido antes com um custo G menor ou igual
custo_conhecido_melhor(Estado, G, Fechados) :-
    member(melhor_custo(Estado, MelhorG), Fechados),
    MelhorG =< G.

% percorre cada estado gerado pelo findall e decide se ele entra na fronteira
atualizar_fronteira([], Fronteira, Melhores, Fronteira, Melhores).
atualizar_fronteira([no(F, G, E, Caminho)|Resto], Fronteira0, Melhores0,
                    FronteiraFinal, MelhoresFinal) :-
    ( custo_registrado(E, MelhorG, Melhores0), MelhorG =< G ->
        % se já existe caminho melhor ou igual registrado, descarta este nó
        Fronteira1 = Fronteira0,
        Melhores1 = Melhores0
    ;
        % se este caminho é melhor, atualiza o recorde de custo e insere na fila ordenada
        substituir_custo(E, G, Melhores0, Melhores1),
        inserir_ordenado(no(F, G, E, Caminho), Fronteira0, Fronteira1)
    ),
    atualizar_fronteira(Resto, Fronteira1, Melhores1,
                        FronteiraFinal, MelhoresFinal).

% consulta na lista 'Melhores' qual é o menor custo G conhecido para o estado E
custo_registrado(E, G, Lista) :-
    member(melhor_custo(E, G), Lista).

% atualiza o melhor custo G de um estado E (remove o registro antigo e põe o novo)
substituir_custo(E, G, Lista, [melhor_custo(E, G)|SemE]) :-
    remover_custo_estado(E, Lista, SemE).

remover_custo_estado(_, [], []).
remover_custo_estado(E, [melhor_custo(E0, _)|R], Resto) :-
    E == E0, !,
    remover_custo_estado(E, R, Resto).
remover_custo_estado(E, [X|R], [X|Resto]) :-
    remover_custo_estado(E, R, Resto).

% fila de prioridade: insere o nó na Fronteira mantendo o menor F sempre na frente
inserir_ordenado(No, [], [No]).
inserir_ordenado(no(F,G,E,C), [no(F0,G0,E0,C0)|R],
                 [no(F,G,E,C),no(F0,G0,E0,C0)|R]) :-
    F =< F0, !.
inserir_ordenado(No, [X|R], [X|R1]) :-
    inserir_ordenado(No, R, R1).

%  SAÍDA EM LINGUAGEM NATURAL
motivo_acao(estado(_, _, _, Desg), entrar_pit, 'Desgaste elevado ou necessidade de troca estrategica de pneus') :-
    Desg >= 3, !.
motivo_acao(estado(_, 4, _, _), trocar_pneus(chuva), 'Previsao de setores alagados a frente; evita aquaplanagem') :- !.
motivo_acao(estado(_, 4, _, _), trocar_pneus(seco), 'Renovacao de composto para pista seca') :- !.

exibir_relatorio([], _) :-
    writeln('-> Cruzou a linha de chegada!').
exibir_relatorio([passo(Estado, Acao, ProxEstado, Custo)|Resto], Passo) :-
    format('Passo ~w: ', [Passo]),
    traduzir_acao(Acao),
    ( motivo_acao(Estado, Acao, Motivo) ->
        format('   Motivo: ~w (custo ~w).~n', [Motivo, Custo])
    ; format('   Motivo: acao valida segundo as regras; custo ~w.~n', [Custo])
    ),
    format('   Estado resultante: ~w~n', [ProxEstado]),
    ProxPasso is Passo + 1,
    exibir_relatorio(Resto, ProxPasso).

traduzir_acao(avancar) :- writeln('Avanca mantendo a faixa atual.').
traduzir_acao(mudar_faixa(F)) :- format('Avanca mudando para a faixa ~w.~n', [F]).
traduzir_acao(entrar_pit) :- writeln('Entra no Pit Lane (Coluna 4).').
traduzir_acao(trocar_pneus(T)) :- format('Realiza Pit Stop: troca para pneus de ~w (desgaste zerado).~n', [T]).
traduzir_acao(sair_pit(F)) :- format('Sai do Pit Lane retornando para a faixa ~w.~n', [F]).
traduzir_acao(aguardar) :- writeln('Aguarda na posicao atual.').
traduzir_acao(avancar_pit) :- writeln('Avanca pelo Pit Lane (coluna 4).').

% predicado principal para testar no SWI-Prolog: ?- iniciar.
iniciar :-
    EstadoInicial = estado(1, 2, seco, 3), % Linha 1, Faixa 2, Pneu Seco, Desgaste 3
    ( astar(EstadoInicial, Plano, Custo, Explorados) ->
        writeln('Plano encontrado:'),
        exibir_relatorio(Plano, 1),
        format('~nCusto total estimado: ~w unidades.~n', [Custo]),
        format('Estados expandidos: ~w~n', [Explorados])
    ; writeln('Nenhuma rota viavel foi encontrada.')
    ).