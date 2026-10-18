# Race-Strategy-Agent

O Race Strategy Agent é um agente inteligente desenvolvido para controlar um carro em uma pista de corrida discretizada. O objetivo do agente é completar o percurso com o menor custo possível, gerenciando variáveis como desgaste dos pneus, obstáculos, retardatários e estratégias de pit stop.

## Medida de Desempenho

O objetivo principal é concluir a corrida com o menor tempo estimado, obedecendo rigidamente às restrições de segurança e movimentação. As restrições de segurança são tratadas como regras obrigatórias que invalidam movimentos proibidos, e não como penalidades que o agente possa ignorar.

| Critério | Objetivo |
|---|---|
| **Concluir a corrida** | Alcançar a linha de chegada. |
| **Tempo total** | Minimizar o custo acumulado das ações, incluindo paradas e penalidades. |
| **Segurança** | Nunca atravessar cones nem ocupar posições proibidas. |
| **Gestão de pneus** | Evitar continuar na pista com pneus que atingiram o limite máximo de desgaste. |
| **Estratégia de pit stop** | Realizar trocas de pneus quando o benefício esperado superar o custo da parada. |
| **Eficiência da busca** | Encontrar uma solução explorando uma quantidade razoável de estados. |

## Ambiente

A pista é representada por uma grade discreta de dimensão Nx4:
- **Linhas (1 até N):** Representam as posições longitudinais ao longo do percurso.
- **Colunas 1, 2 e 3:** Representam as faixas disponíveis da pista.
- **Coluna 4:** Representa o pit lane.

### Elementos do Ambiente

| Elemento | Comportamento no Modelo |
|---|---|
| **Pista livre** | Permite a movimentação do carro. |
| **Poça de água** | Pode ser atravessada, com custo de tempo dependente do tipo de pneu utilizado. |
| **Cone** | Bloqueia a célula; o carro é obrigado a desviar. |
| **Retardatário** | Ocupa uma célula e pode bloquear a passagem ou exigir uma manobra de ultrapassagem. |
| **Pit lane** | Permite a realização de paradas e trocas de pneus. |
| **Linha de chegada** | Define o estado objetivo da busca. |

### Propriedades do Ambiente
- **Totalmente observável:** O mapa e os obstáculos são previamente conhecidos pelo agente.
- **Determinístico:** As ações resultam em estados previsíveis.
- **Sequencial:** As decisões atuais afetam as opções futuras.
- **Estático:** Os obstáculos (como cones e retardatários) não se movem durante a execução.
- **Discreto:** Posições, ações e elementos são representados por valores discretos.
- **Conhecido:** As regras de transição e os custos das ações são previamente definidos.

## Atuadores

As ações possíveis de serem executadas pelo agente são:

| Ação | Descrição |
|---|---|
| `avancar` | Avança uma posição longitudinal, mantendo a faixa atual. |
| `mudar_faixa` | Avança uma posição longitudinal e simultaneamente muda para uma faixa adjacente. |
| `entrar_pit` | Desloca-se da pista para o pit lane utilizando uma posição de acesso permitida. |
| `trocar_pneus(Tipo)` | Substitui os pneus por um novo composto, zerando o desgaste e consumindo tempo. |
| `sair_pit(Faixa)` | Retorna do pit lane para uma faixa da pista permitida. |
| `aguardar` | Permanece na posição atual, caso as regras da célula permitam e a espera seja estrategicamente útil. |

**Nota sobre movimentação lateral:** A mudança de faixa é modelada como uma ação combinada com o avanço longitudinal. Essa restrição garante que o carro não se desloque lateralmente por várias faixas de forma instantânea sem consumir o tempo correspondente ao avanço.

## Sensores

O agente obtém informações sobre seu próprio estado e o ambiente através dos seguintes sensores lógicos:

| Sensor Lógico | Informação Fornecida |
|---|---|
| **Sensor de posição** | Linha longitudinal e faixa atuais onde o carro se encontra. |
| **Sensor de pneus** | Tipo de pneu atualmente instalado e seu nível de desgaste acumulado. |
| **Sensor de pista** | Mapeia o terreno, identificando células livres, poças de água e cones. |
| **Sensor de tráfego** | Identifica as posições exatas ocupadas por retardatários na pista. |
| **Sensor de pit lane** | Indica os pontos de entrada permitidos, pontos de saída e a disponibilidade do box. |
| **Sensor de progresso** | Informa a distância restante em linhas até a linha de chegada. |
| **Sensor de estratégia** | Fornece o histórico de paradas realizadas e os custos totais acumulados. |
