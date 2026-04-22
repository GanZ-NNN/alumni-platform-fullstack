# alumni-platform-fullstack

Incremental alumni platform with a Dart Shelf backend and Flutter frontend.

## Environment setup

### Backend

1. Copy `backend/.env.example` to `backend/.env`.
2. Update `JWT_SECRET`, DB credentials, and `ALLOWED_ORIGINS`.
3. For production-like runs, set `APP_ENV=production` and a strong `JWT_SECRET`.

### Frontend

Set the API base URL at build/run time:

- Flutter run:
  - `flutter run --dart-define=API_BASE_URL=http://localhost:8080`
- Flutter build:
  - `flutter build apk --dart-define=API_BASE_URL=https://api.example.com`

If not provided, frontend defaults to `http://localhost:8080`.

## Migration baseline

Schema bootstrap currently runs from backend startup and can also be triggered explicitly:

- `cd backend`
- `dart run tool/migrate.dart`

This provides a minimal migration entrypoint while keeping current schema behavior intact.

## Docker Compose notes

`docker-compose.yml` is for local development defaults. For production-safe usage:

- Do not commit real secrets in Compose files.
- Prefer environment variable injection (`.env` in deployment environment, CI secrets, or orchestrator secrets).
- Change default DB credentials before deployment.
- Restrict exposed ports to only what is required.

## CI baseline

GitHub Actions workflow at `.github/workflows/ci.yml` runs:

- Backend: format, analyze, test
- Frontend: format, analyze, test

## Logging note

Request logging is applied by backend middleware in `backend/lib/main.dart`.
After middleware changes, restart the running backend process to apply the updated log format.