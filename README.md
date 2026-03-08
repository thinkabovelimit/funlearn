# BrainBounce (Flutter + FastAPI)

Reverse quiz app powered by a dataset-backed FastAPI service.

## 1. Configure API URL for Flutter

Update `.env` (for local Chrome run):

```env
API_BASE_URL=http://127.0.0.1:8000
```

## 2. Start FastAPI

From project root:

```bash
cd funlearn
python3 -m pip install -r requirements.txt
uvicorn api.main:app --host 0.0.0.0 --port 8000 --reload
```

Quick check:

```bash
curl http://127.0.0.1:8000/health
curl http://127.0.0.1:8000/topics
```

## 3. Run Flutter on Chrome

In a new terminal:

```bash
cd funlearn
flutter pub get
flutter run -d chrome
```

## Notes

- Keep FastAPI running while using the Flutter app.
- If you change `.env`, do a full app restart (not just hot reload).
