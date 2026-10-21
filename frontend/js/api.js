/* Integração HTTP com o back-end SWI-Prolog.
   Ajuste API_BASE para a URL e porta configuradas em prolog/server.pl. */
const RaceAPI = (() => {
  const API_BASE = "http://localhost:8080/api";

  async function runSearch(payload) {
    const response = await fetch(`${API_BASE}/buscar`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    const body = await response.json().catch(() => ({}));
    if (!response.ok) {
      throw new Error(body.error || body.message || `Servidor respondeu HTTP ${response.status}`);
    }
    return body;
  }

  async function checkHealth() {
    const response = await fetch(`${API_BASE}/health`, { method: "GET" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  }

  return { runSearch, checkHealth, API_BASE };
})();
