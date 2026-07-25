# FastAPI backend

## Instalacao

```bash
pip install -r requirements.txt
```

## Execucao

```bash
uvicorn main:app --reload
```

## Endpoint principal

`POST /api/v1/requirements/interpret`

Exemplo de payload:

```json
{
  "view_name": "DBpedia Artist Exported View",
  "criterion": "Musical artists should have good homepage coverage."
}
```

Tambem sao aceitos os aliases `input_view` e `input_criterion`.

## Variaveis de ambiente

- `OPENAI_MODEL`: obrigatorio para inicializar a API.
- `CORS_ALLOWED_ORIGINS`: lista separada por virgula com as origens do front-end.
- `CORS_ALLOW_CREDENTIALS`: `true` ou `false`.
- `CORS_ALLOW_METHODS`: lista separada por virgula. Padrao: `GET,POST,OPTIONS`.
- `CORS_ALLOW_HEADERS`: lista separada por virgula. Padrao: `Authorization,Content-Type`.
- `RATE_LIMIT_MAX_REQUESTS`: maximo de requisicoes por janela. Padrao: `10`.
- `RATE_LIMIT_WINDOW_SECONDS`: tamanho da janela do rate limit. Padrao: `60`.
