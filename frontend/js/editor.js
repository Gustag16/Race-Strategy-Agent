/* Editor da pista e gerenciamento do estado da interface. */
(() => {
  const $ = id => document.getElementById(id);
  const state = {
    tool: "cone",
    obstacles: [
      { row: 3, lane: 2, type: "cone" },
      { row: 6, lane: 3, type: "cone" },
      { row: 4, lane: 1, type: "agua" },
      { row: 4, lane: 2, type: "agua" },
      { row: 4, lane: 3, type: "agua" },
      { row: 5, lane: 1, type: "retardatario" }
    ],
    path: [],
    lastResult: null
  };

  const symbols = { cone: "🚧", retardatario: "🚗", agua: "💧" };
  const toolButtons = [...document.querySelectorAll("[data-tool]")];

  function getConfig() {
    const length = Number($("trackLength").value);
    const startRow = Number($("startRow").value);
    const startLane = Number($("startLane").value);
    const finishLane = Number($("finishLane").value);
    if (!Number.isInteger(length) || length < 4 || length > 30) throw new Error("A pista deve ter de 4 a 30 linhas.");
    if (startRow < 1 || startRow > length) throw new Error("A linha inicial precisa estar dentro da pista.");
    const finishRow = length;
    return {
      pista: {
        comprimento: length,
        faixas_corrida: 3,
        faixa_pit: 4,
        obstaculos: state.obstacles.filter(o => o.row <= length).map(o => ({
          linha: o.row, faixa: o.lane, tipo: o.type
        })),
        clima: $("weather").value,
        limite_desgaste: Number($("wearLimit").value)
      },
      estado_inicial: {
        linha: startRow,
        faixa: startLane,
        pneus: $("initialTire").value,
        desgaste: Number($("initialWear").value)
      },
      objetivo: { linha: finishRow, faixa: finishLane },
      opcoes: {
        mostrar_custos: $("showCosts").checked,
        animar_rota: $("animatePath").checked
      }
    };
  }

  function renderGrid() {
    const grid = $("trackGrid");
    const length = Number($("trackLength").value) || 8;
    const startRow = Number($("startRow").value) || 1;
    const startLane = Number($("startLane").value) || 2;
    const finishRow = length;
    const finishLane = Number($("finishLane").value) || 1;
    grid.replaceChildren();

    const blank = document.createElement("div");
    blank.className = "grid-label";
    blank.textContent = "L";
    grid.appendChild(blank);
    ["F1", "F2", "F3", "PIT"].forEach(label => {
      const el = document.createElement("div");
      el.className = "grid-label";
      el.textContent = label;
      grid.appendChild(el);
    });

    for (let row = length; row >= 1; row--) {
      const rowLabel = document.createElement("div");
      rowLabel.className = "grid-label";
      rowLabel.textContent = row;
      grid.appendChild(rowLabel);
      for (let lane = 1; lane <= 4; lane++) {
        const cell = document.createElement("button");
        cell.type = "button";
        cell.className = "track-cell";
        cell.setAttribute("aria-label", `Linha ${row}, faixa ${lane}`);
        if (lane === 4) {
          cell.classList.add("pit");
          cell.textContent = "⇵";
          cell.title = "Pit lane";
        } else {
          const obstacle = state.obstacles.find(o => o.row === row && o.lane === lane);
          if (row === startRow && lane === startLane) {
            cell.classList.add("start"); cell.textContent = "🟢"; cell.title = "Estado inicial";
          } else if (row === finishRow && lane === finishLane) {
            cell.classList.add("finish"); cell.textContent = "🏁"; cell.title = "Chegada";
          } else if (obstacle) {
            cell.classList.add(obstacle.type); cell.textContent = symbols[obstacle.type]; cell.title = obstacle.type;
          }
          cell.addEventListener("click", () => editCell(row, lane));
        }
        grid.appendChild(cell);
      }
    }
    if (state.path.length) drawPath(state.path);
  }

  function editCell(row, lane) {
    const tool = state.tool;
    if (tool === "start") {
      $("startRow").value = row;
      $("startLane").value = lane;
    } else if (tool === "finish") {
      $("finishLane").value = lane;
      if (row !== Number($("trackLength").value)) {
        alert("A chegada fica na última linha da pista. Para alterar a linha de chegada, altere o comprimento.");
      }
    } else if (tool === "erase") {
      state.obstacles = state.obstacles.filter(o => !(o.row === row && o.lane === lane));
    } else {
      state.obstacles = state.obstacles.filter(o => !(o.row === row && o.lane === lane));
      state.obstacles.push({ row, lane, type: tool });
    }
    state.path = [];
    renderGrid();
  }

  function drawPath(path) {
    const grid = $("trackGrid");
    const cells = [...grid.querySelectorAll(".track-cell")];
    const length = Number($("trackLength").value);
    path.forEach((step, index) => {
      const s = step.estado_resultante || step.to || step.state || step;
      const row = Number(s.linha ?? s.row ?? s[0]);
      const lane = Number(s.faixa ?? s.lane ?? s[1]);
      if (!row || !lane || lane > 4) return;
      const visualRowIndex = length - row;
      const cellIndex = visualRowIndex * 4 + (lane - 1);
      const cell = cells[cellIndex];
      if (cell) {
        cell.classList.add("path");
        cell.dataset.step = String(index + 1);
      }
    });
  }

  function loadExample() {
    $("trackLength").value = 8;
    $("startRow").value = 1;
    $("startLane").value = 2;
    $("initialWear").value = 3;
    $("initialTire").value = "seco";
    $("weather").value = "variavel";
    $("wearLimit").value = 6;
    $("finishLane").value = 1;
    state.obstacles = [
      { row: 3, lane: 2, type: "cone" },
      { row: 6, lane: 3, type: "cone" },
      { row: 4, lane: 1, type: "agua" },
      { row: 4, lane: 2, type: "agua" },
      { row: 4, lane: 3, type: "agua" },
      { row: 5, lane: 1, type: "retardatario" }
    ];
    state.path = [];
    state.lastResult = null;
    renderGrid();
    if (window.RaceResults) RaceResults.clear();
  }

  toolButtons.forEach(button => button.addEventListener("click", () => {
    state.tool = button.dataset.tool;
    toolButtons.forEach(b => b.classList.toggle("active", b === button));
  }));
  $("trackLength").addEventListener("change", () => {
    const n = Number($("trackLength").value);
    $("startRow").max = n;
    if (Number($("startRow").value) > n) $("startRow").value = n;
    state.obstacles = state.obstacles.filter(o => o.row <= n);
    state.path = [];
    renderGrid();
  });
  ["startRow", "startLane", "finishLane"].forEach(id => $(id).addEventListener("change", renderGrid));
  $("clearTrackBtn").addEventListener("click", () => { state.obstacles = []; state.path = []; renderGrid(); });
  $("exampleBtn").addEventListener("click", loadExample);

  $("configForm").addEventListener("submit", async event => {
    event.preventDefault();
    const button = $("runBtn");
    try {
      const payload = getConfig();
      $("requestPreview").textContent = JSON.stringify(payload, null, 2);
      button.disabled = true;
      button.textContent = "Buscando...";
      $("apiStatus").className = "status status-neutral";
      $("apiStatus").textContent = `Enviando requisição para ${RaceAPI.API_BASE}/buscar`;
      const result = await RaceAPI.runSearch(payload);
      state.lastResult = result;
      state.path = result.plano || result.plan || result.steps || [];
      renderGrid();
      RaceResults.render(result);
      $("apiStatus").className = "status status-good";
      $("apiStatus").textContent = "Busca concluída pelo servidor.";
    } catch (error) {
      $("apiStatus").className = "status status-bad";
      $("apiStatus").textContent = `Não foi possível executar: ${error.message}`;
      RaceResults.showError(error.message);
    } finally {
      button.disabled = false;
      button.textContent = "▶ Executar A*";
    }
  });

  $("exportBtn").addEventListener("click", () => {
    if (!state.lastResult) return;
    const blob = new Blob([JSON.stringify(state.lastResult, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url; a.download = "resultado-astar.json"; a.click();
    URL.revokeObjectURL(url);
  });

  window.RaceEditor = { getConfig, renderGrid, getState: () => state };
  renderGrid();
  RaceAPI.checkHealth().then(() => {
    $("apiStatus").className = "status status-good";
    $("apiStatus").textContent = "Servidor Prolog conectado.";
  }).catch(() => {
    $("apiStatus").className = "status status-neutral";
    $("apiStatus").textContent = "Servidor não detectado. Inicie o back-end Prolog e confira js/api.js.";
  });
})();
