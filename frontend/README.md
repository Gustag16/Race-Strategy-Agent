# Race Strategy — Front-end

Interface web para configurar uma pista e visualizar os resultados de um agente de busca A* implementado em Prolog. O projeto não utiliza aprendizado de máquina.

## Conteúdo

- `index.html`: estrutura da aplicação.
- `css/style.css`: layout responsivo e estilos.
- `js/editor.js`: grade editável, parâmetros e envio da configuração.
- `js/api.js`: comunicação HTTP com o servidor Prolog.
- `js/resultado.js`: exibição do plano e métricas da busca.

## Executar o front-end

Não abra o arquivo por `file://`, pois os navegadores podem bloquear a comunicação HTTP. Sirva a pasta por um servidor local. Por exemplo, dentro da pasta `frontend`:

```bash
python -m http.server 5500
```

Depois acesse `http://localhost:5500`.

O front-end espera um back-end em `http://localhost:8080/api`. Altere `API_BASE` em `js/api.js` se necessário.

## Contrato esperado da API

### `GET /api/health`

Retorno sugerido:

```json
{"status":"ok"}
```

### `POST /api/buscar`

Exemplo de requisição:

```json
{
  "pista": {
    "comprimento": 8,
    "faixas_corrida": 3,
    "faixa_pit": 4,
    "obstaculos": [
      {"linha": 3, "faixa": 2, "tipo": "cone"},
      {"linha": 4, "faixa": 1, "tipo": "agua"}
    ],
    "clima": "variavel",
    "limite_desgaste": 6
  },
  "estado_inicial": {
    "linha": 1,
    "faixa": 2,
    "pneus": "seco",
    "desgaste": 3
  },
  "objetivo": {"linha": 8, "faixa": 1},
  "opcoes": {"mostrar_custos": true, "animar_rota": false}
}
```

Resposta sugerida quando há plano:

```json
{
  "sucesso": true,
  "mensagem": "Plano encontrado.",
  "custo_total": 12,
  "estados_expandidos": 48,
  "plano": [
    {
      "acao": "avancar",
      "acao_texto": "Avança mantendo a faixa atual",
      "motivo": "Faixa livre à frente",
      "estado_resultante": {
        "linha": 2,
        "faixa": 2,
        "pneus": "seco",
        "desgaste": 4
      }
    }
  ]
}
```

Resposta sem rota:

```json
{
  "sucesso": false,
  "mensagem": "Nenhuma rota viável foi encontrada.",
  "custo_total": null,
  "estados_expandidos": 27,
  "plano": []
}
```

O front-end aceita alguns nomes alternativos de campos para facilitar a integração, mas recomenda-se padronizar a resposta conforme os exemplos.

## Observações importantes para integração

1. O código Prolog compartilhado até agora contém o núcleo de A* e a impressão do relatório, mas depende de predicados como `sucessor/4`, `heuristica/2` e `meta/1`. A API só funcionará quando o servidor e as regras do domínio estiverem implementados.
2. O back-end deve transformar o JSON recebido em configuração de ambiente e executar o predicado de busca com esse ambiente. Evite alterar fatos globais com `assertz/1` sem isolamento entre requisições.
3. A convenção visual usa linhas crescentes em direção à chegada, faixas 1–3 e pit lane na faixa 4. Ajuste-a para coincidir com o seu modelo Prolog.
4. A chegada é representada na última linha e a faixa é configurável. Se a sua regra `meta/1` usar outro critério, altere a interface e o contrato.
5. As células de água são obstáculos/condições do ambiente, não necessariamente bloqueios absolutos. O significado deve ser determinado por `sucessor/4` e pelos custos no Prolog.
6. Para desenvolvimento local, mantenha o front-end e a API em portas distintas e configure CORS no servidor Prolog, ou sirva os arquivos estáticos pelo próprio servidor Prolog.

## Próximos passos

- Implementar `server.pl` usando `library(http/thread_httpd)`, `library(http/http_dispatch)`, `library(http/http_json)`.
- Criar uma representação dinâmica e segura do ambiente.
- Definir um serializador para os termos Prolog de estado e ação em objetos JSON.
- Testar com pistas pequenas e comparar o custo retornado com casos conhecidos.
