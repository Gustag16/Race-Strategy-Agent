/* Renderização do relatório retornado pela API. */
const RaceResults = (() => {
  const $ = id => document.getElementById(id);

  function first(...values) { return values.find(v => v !== undefined && v !== null); }
  function formatState(state) {
    if (state === undefined || state === null) return "Estado não informado pela API.";
    if (typeof state === "string") return state;
    if (Array.isArray(state)) return state.join(", ");
    if (typeof state === "object") {
      return Object.entries(state).map(([k, v]) => `${k}: ${v}`).join(" · ");
    }
    return String(state);
  }

  function render(result) {
    const plan = first(result.plano, result.plan, result.steps, []);
    const success = first(result.sucesso, result.success, result.found, true);
    $("resultBadge").textContent = success ? "Plano encontrado" : "Sem rota viável";
    $("resultBadge").className = `badge ${success ? "success" : "error"}`;
    $("resultMessage").className = `result-message ${success ? "success" : "error"}`;
    $("resultMessage").textContent = first(result.mensagem, result.message,
      success ? "O agente encontrou um plano. Confira a sequência de ações abaixo." : "Nenhuma rota viável foi encontrada.");
    $("totalCost").textContent = first(result.custo_total, result.cost, result.custo, "—");
    $("expandedStates").textContent = first(result.estados_expandidos, result.expanded_states, result.explorados, "—");
    $("stepCount").textContent = Array.isArray(plan) ? plan.length : "—";
    const list = $("stepsList");
    list.replaceChildren();
    if (!Array.isArray(plan) || !plan.length) {
      const empty = document.createElement("div");
      empty.className = "empty-state";
      empty.textContent = success ? "A API não retornou passos detalhados." : "Tente alterar os obstáculos ou os parâmetros da pista.";
      list.appendChild(empty);
    } else {
      plan.forEach((step, index) => {
        const card = document.createElement("article"); card.className = "step-card";
        const number = document.createElement("div"); number.className = "step-number"; number.textContent = index + 1;
        const body = document.createElement("div");
        const title = document.createElement("p"); title.className = "step-title";
        title.textContent = first(step.acao_texto, step.acao, step.action, step.tipo, `Passo ${index + 1}`);
        const reason = document.createElement("p"); reason.className = "step-reason";
        reason.textContent = first(step.motivo, step.reason, step.explicacao, "Ação retornada pelo agente de busca.");
        body.append(title, reason);
        const nextState = first(step.estado_resultante, step.prox_estado, step.to, step.state);
        if (nextState !== undefined) {
          const state = document.createElement("div"); state.className = "step-state";
          state.textContent = `Estado resultante: ${formatState(nextState)}`;
          body.appendChild(state);
        }
        card.append(number, body); list.appendChild(card);
      });
    }
    $("exportBtn").disabled = false;
  }

  function showError(message) {
    $("resultBadge").textContent = "Falha na busca";
    $("resultBadge").className = "badge error";
    $("resultMessage").className = "result-message error";
    $("resultMessage").textContent = `A busca não foi executada. ${message}. O front-end depende da API Prolog; ele não substitui o motor de inferência.`;
  }

  function clear() {
    $("resultBadge").textContent = "Aguardando execução";
    $("resultBadge").className = "badge";
    $("resultMessage").className = "result-message";
    $("resultMessage").textContent = "Configure a pista e pressione Executar A*. A busca real será realizada pelo back-end Prolog quando a API estiver conectada.";
    $("totalCost").textContent = "—";
    $("expandedStates").textContent = "—";
    $("stepCount").textContent = "—";
    $("stepsList").innerHTML = '<div class="empty-state">Nenhum plano disponível.</div>';
    $("exportBtn").disabled = true;
    $("requestPreview").textContent = "{}";
  }

  return { render, showError, clear };
})();
