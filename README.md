# S2S Translator — Flutter App

A mobile app for English → French / Twi speech-to-speech translation.

## Screens
- **Home** — Dashboard with stats, language selector, recent translations
- **Translate** — Mic recording, text input, or file upload
- **History** — All past translations, filterable, swipe to delete
- **Phrases** — Common phrasebook by category (Essentials, Emergency, Dining, etc.)
- **Settings** — Language, audio, app preferences, sign out

## Setup

### 1. Install Flutter
Download from https://flutter.dev and follow the Windows setup guide.

### 2. Extract this project
Extract the zip anywhere, e.g.:
```
C:\Users\Enoch Quayson\Downloads\s2s_flutter\
```

### 3. Install dependencies
```cmd
cd "C:\Users\Enoch Quayson\Downloads\s2s_flutter"
flutter pub get
```

### 4. Make sure your API server is running
```cmd
cd "C:\Users\Enoch Quayson\Downloads\s2s_translator\api"
python -m uvicorn main:app --reload
```

### 5. Run the app
```cmd
# For Android (connect phone via USB with USB debugging on)
flutter run

# Or run on Chrome to preview
flutter run -d chrome
```

### 6. Configure API URL
In the app → Settings → API Server → change to your machine's IP if running on a real phone:
```
http://192.168.x.x:8000
```
(Find your IP with `ipconfig` in Command Prompt)

## API Endpoints Used
- `POST /users/register` — Register
- `POST /users/login` — Login
- `GET /users/me` — Profile
- `GET /users/me/stats` — Stats
- `POST /translate/text` — Text translation
- `POST /translate/audio` — Audio translation
- `POST /translate/file` — File translation
- `GET /history/` — Translation history
- `DELETE /history/{id}` — Delete entry
- `GET /health/` — Server health check
