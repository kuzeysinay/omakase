# Omakase

A real-time, native-iOS social feed where every post is generated on the fly
by Gemini, tailored to the user's interests, and delivered as a live typing
stream over Server-Sent Events.

```
┌──────────────┐   SSE (text/event-stream)   ┌──────────────┐   Gemini stream
│  SwiftUI app │ ◀────────────────────────── │   FastAPI    │ ◀─────────────
│  (iOS 26+)   │          POST body           │   (main.py)  │
└──────────────┘ ──────────────────────────▶ └──────────────┘
```

Repo layout:

```
omakase/
├── backend/        # FastAPI service that streams from Gemini
│   ├── main.py
│   ├── requirements.txt
│   ├── .env.example
│   └── README.md
└── omakase/        # Xcode project (`omakase.xcodeproj` + sources)
    └── omakase/
        ├── Models/Post.swift
        ├── Networking/SSEClient.swift
        ├── Onboarding/OnboardingView.swift
        ├── Feed/FeedView.swift
        ├── Feed/FeedViewModel.swift
        ├── ContentView.swift
        └── omakaseApp.swift
```

## 1. Run the backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env      # then paste your Gemini key
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Verify: `curl http://127.0.0.1:8000/health` → `{"status":"ok",...}`.

## 2. Run the iOS app

Open `omakase/omakase.xcodeproj` in Xcode 26, pick the **omakase** scheme, and
run on the **iOS Simulator**. The first launch shows `OnboardingView` — add
a few interests, tap **Start my feed**, then tap **Serve next post** to watch
text stream in live.

### One-time ATS setup (iOS blocks plain HTTP by default)

The simulator talks to `http://127.0.0.1:8000`, which ATS will refuse unless
you opt in. In Xcode, select the **omakase** target → **Info** tab and add:

- `App Transport Security Settings` → `Allow Local Networking` = `YES`

(or, equivalently, add the dictionary to the generated Info.plist with
`NSAllowsLocalNetworking = true`). No exception is needed for a device on
the same Wi-Fi network as long as you point `OMAKASE_API_URL` at a `https://`
endpoint; for LAN-IP HTTP testing add an `NSExceptionDomains` entry.

### Pointing the app at a different backend

The iOS app reads `OMAKASE_API_URL` from its Info.plist, defaulting to
`http://127.0.0.1:8000`. To target a backend on your LAN (for a real device),
add a string entry in the target's Info tab:

- Key: `OMAKASE_API_URL`
- Value: e.g. `http://192.168.1.42:8000`

## How it works

1. **Onboarding** (`OnboardingView`) collects free-form interests and saves them
   as a comma-separated string via `@AppStorage("omakase.interests")`. It also
   sets `@AppStorage("omakase.hasOnboarded") = true` which flips
   `ContentView` to the feed.
2. **Feed** (`FeedView` + `FeedViewModel`) appends an empty `Post`, then opens
   an SSE request to `POST /feed/stream`. Each `token` event appends a delta
   to `post.text`; because `Post` is inside a `@Observable` view model, SwiftUI
   re-renders the card on every mutation, producing the real-time typing
   effect. A blinking `▌` cursor runs while `isComplete == false`.
3. **Backend** (`main.py`) configures `google-generativeai`, calls
   `generate_content(..., stream=True)` in a worker thread, and bridges each
   chunk into an async generator. The generator yields SSE-framed events
   (`start`, `token`, `done`, `error`) which FastAPI's `StreamingResponse`
   flushes to the client immediately (buffering is disabled via
   `X-Accel-Buffering: no`).
4. **SSE parsing** (`SSEClient`) uses `URLSession.shared.bytes(for:)` to expose
   the response as an async byte stream, splits it into lines, and dispatches
   `SSEEvent` values whenever a blank line terminates a frame. It hands back
   an `AsyncThrowingStream` that cancels cleanly when the consumer stops
   iterating.
