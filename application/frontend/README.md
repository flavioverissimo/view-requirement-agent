# Front-end Next.js

Esta pasta contem a interface web em Next.js + Tailwind CSS integrada ao
backend FastAPI.

## Como rodar

Entre nesta pasta:

```powershell
cd C:\Users\flavio.lima\Desktop\Projetos\backend\frontend
```

Instale as dependencias:

```powershell
npm install
```

Crie um `.env.local` se quiser apontar para uma URL diferente da API local:

```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:8000/api/v1
```

Suba a aplicacao:

```powershell
npm run dev
```

## Fluxo

1. A pagina carrega a lista fixa de views suportadas pela API.
2. O usuario escolhe a `view_name` e escreve o criterio.
3. O front faz `POST` direto para `POST /api/v1/requirements/interpret`.
4. A resposta estruturada da API e convertida para Markdown no proprio front.
