# Omakase — backend

A small FastAPI service that streams Gemini-generated social posts to the
iOS app via Server-Sent Events (SSE).

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
