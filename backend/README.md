# Omakase — Backend

A modular FastAPI service that streams Gemini-generated culture posts to the
iOS app via Server-Sent Events (SSE), protected by Firebase ID token verification
and per-user sliding-window rate limiting.

## Architecture (`backend/`)

```text
backend/
├── app/
│   ├── config.py                  # Env vars, CORS origins, Gemini client & safety settings
│   ├── security.py                # Firebase ID token auth, rate limiter & input sanitizers
│   ├── schemas.py                 # Pydantic request schemas & validators
│   ├── prompts.py                 # System instructions, 12 rotating post formats & prompt builders
│   ├── routers/
│   │   ├── feed.py                # POST /feed/stream, POST /feed/deep-dive
│   │   ├── interests.py           # POST /interests/suggest, POST /interests/expand-category
│   │   └── letterboxd.py          # POST /letterboxd/films
│   └── services/
│       ├── gemini_service.py      # SSE token streaming engine & suggestion generator
│       └── letterboxd_service.py  # Hardened Letterboxd RSS fetcher & XML parser
├── main.py                        # FastAPI app factory & router registration (uvicorn main:app)
├── Dockerfile                     # Cloud Run container (unprivileged appuser)
└── requirements.txt
```

## Quickstart

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# edit .env and paste your key from https://aistudio.google.com/app/apikey

uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Sanity check:

```bash
curl http://127.0.0.1:8000/health
```

Stream a post from the CLI:

```bash
curl -N -X POST http://127.0.0.1:8000/feed/stream \
  -H 'Content-Type: application/json' \
  -d '{"interests":["David Fincher","Aftersun","Secret Hitler"],"seen_count":0}'
```

## Endpoints

### `POST /feed/stream`

Streams one generated post.

Request body:

```json
{ "interests": ["..."], "seen_count": 0 }
```

Response: `text/event-stream` with these events:

| event  | data                  | meaning                 |
|--------|-----------------------|-------------------------|
| start  | `{"id": "<uuid>"}`    | a new post is starting  |
| token  | `{"text": "<delta>"}` | next chunk of Gemini output |
| done   | `{"id": "<uuid>"}`    | post finished           |
| error  | `{"message": "..."}`  | something went wrong    |

## Pointing the iOS app at your backend

The iOS `FeedViewModel` reads `OMAKASE_API_URL` from the app's Info.plist,
falling back to `http://127.0.0.1:8000` which works for the iOS Simulator.

For a physical device, set it to your Mac's LAN IP (e.g.
`http://192.168.1.42:8000`). You can either edit the default string in
`FeedViewModel.swift` or add `OMAKASE_API_URL` as a string in the target's
Info tab.

## Troubleshooting

### `404 models/gemini-1.5-flash is not found`

That model id is no longer available for `generateContent` on the current API.
Set `GEMINI_MODEL=gemini-2.5-flash` in `.env` (or another id from
[Models](https://ai.google.dev/gemini-api/docs/models/gemini)), then restart
`uvicorn`.
