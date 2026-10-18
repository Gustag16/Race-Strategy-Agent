% CaminhoReverso guarda passos da ação mais recente à primeira.

iniciar :-
    EstadoInicial = estado(1, 2, seco, 3),
    writeln('=== RACE STRATEGY AGENT: A* ==='),
    ( astar(EstadoInicial, Plano, Custo, Explorados) ->
        writeln('Plano encontrado:'),
        exibir_relatorio(Plano, 1),
        format('~nCusto total estimado: ~w unidades.~n', [Custo]),
        format('Estados expandidos: ~w~n', [Explorados])
    ; writeln('Nenhuma rota viavel foi encontrada.')
    ).

astar(Inicio, Plano, CustoFinal, Explorados) :-
    heuristica(Inicio, H),
    astar_loop([no(H, 0, Inicio, [])],
               [melhor_custo(Inicio, 0)],
               [], PlanoReverso, CustoFinal, 0, Explorados),
    reverse(PlanoReverso, Plano).

astar_loop([no(_, G, Estado, CaminhoReverso)|_],
           _, _, CaminhoReverso, G, Expandidos, Expandidos) :-
    meta(Estado), !.

astar_loop([no(_, G, Estado, CaminhoReverso)|Fronteira],
           Melhores, Fechados, Plano, CustoFinal, Exp0, ExpFinal) :-
    ( custo_registrado(Estado, MelhorGAtual, Melhores),
      MelhorGAtual < G ->
        % Entrada obsoleta: ja existe caminho melhor para este estado.
        astar_loop(Fronteira, Melhores, Fechados,
                   Plano, CustoFinal, Exp0, ExpFinal)
    ; custo_conhecido_melhor(Estado, G, Fechados) ->
        astar_loop(Fronteira, Melhores, Fechados,
                   Plano, CustoFinal, Exp0, ExpFinal)
    ;
        findall(no(FNovo, GNovo, ProxEstado,
                   [passo(Estado, Acao, ProxEstado, CustoAcao)|CaminhoReverso]),
                ( sucessor(Estado, Acao, CustoAcao, ProxEstado),
                  GNovo is G + CustoAcao,
                  heuristica(ProxEstado, HNovo),
                  FNovo is GNovo + HNovo
                ),
                Sucessores),
        atualizar_fronteira(Sucessores, Fronteira, Melhores,
                            NovaFronteira, NovosMelhores),
        Exp1 is Exp0 + 1,
        astar_loop(NovaFronteira, NovosMelhores,
                   [melhor_custo(Estado, G)|Fechados],
                   Plano, CustoFinal, Exp1, ExpFinal)
    ).

custo_conhecido_melhor(Estado, G, Fechados) :-
    member(melhor_custo(Estado, MelhorG), Fechados),
    MelhorG =< G.

atualizar_fronteira([], Fronteira, Melhores, Fronteira, Melhores).
atualizar_fronteira([no(F, G, E, Caminho)|Resto], Fronteira0, Melhores0,
                    FronteiraFinal, MelhoresFinal) :-
    ( custo_registrado(E, MelhorG, Melhores0), MelhorG =< G ->
        Fronteira1 = Fronteira0,
        Melhores1 = Melhores0
    ;
        substituir_custo(E, G, Melhores0, Melhores1),
        inserir_ordenado(no(F, G, E, Caminho), Fronteira0, Fronteira1)
    ),
    atualizar_fronteira(Resto, Fronteira1, Melhores1,
                        FronteiraFinal, MelhoresFinal).

custo_registrado(E, G, Lista) :-
    member(melhor_custo(E, G), Lista).

substituir_custo(E, G, Lista, [melhor_custo(E, G)|SemE]) :-
    remover_custo_estado(E, Lista, SemE).

remover_custo_estado(_, [], []).
remover_custo_estado(E, [melhor_custo(E0, _)|R], Resto) :-
    E == E0, !,
    remover_custo_estado(E, R, Resto).
remover_custo_estado(E, [X|R], [X|Resto]) :-
    remover_custo_estado(E, R, Resto).

% Insere a fronteira em ordem crescente de F = G + H.
inserir_ordenado(No, [], [No]).
inserir_ordenado(no(F,G,E,C), [no(F0,G0,E0,C0)|R],
                 [no(F,G,E,C),no(F0,G0,E0,C0)|R]) :-
    F =< F0, !.
inserir_ordenado(No, [X|R], [X|R1]) :-
    inserir_ordenado(No, R, R1).

% ---------------- RELATÓRIO EXPLICÁVEL ----------------
exibir_relatorio([], _) :-
    writeln('-> Cruzou a linha de chegada!').
exibir_relatorio([passo(Estado, Acao, ProxEstado, Custo)|Resto], Passo) :-
    format('Passo ~w: ', [Passo]),
    traduzir_acao(Acao),
    ( motivo_acao(Estado, Acao, Motivo) ->
        format('   Motivo: ~w.~n', [Motivo])
    ; format('   Motivo: acao valida segundo as regras; custo ~w.~n', [Custo])
    ),
    format('   Estado resultante: ~w~n', [ProxEstado]),
    ProxPasso is Passo + 1,
    exibir_relatorio(Resto, ProxPasso).

traduzir_acao(avancar) :-
    writeln('Avanca mantendo a faixa atual.').
traduzir_acao(mudar_faixa(F)) :-
    format('Avanca mudando para a faixa ~w.~n', [F]).
traduzir_acao(entrar_pit) :-
    writeln('Entra no Pit Lane (coluna 4).').
traduzir_acao(trocar_pneus(T)) :-
    format('Troca para pneus de ~w (desgaste zerado).~n', [T]).
traduzir_acao(sair_pit(F)) :-
    format('Sai do Pit Lane para a faixa ~w.~n', [F]).
