# API Specification

Endpoint reference. Keep in sync with implementation.

Base URL: `/api` (e.g. `http://localhost:8000/api`)

Protected endpoints require `Authorization: Bearer <access_token>`.

## Auth

| Method | Path | Description |
|--------|------|-------------|
| POST | /api/auth/register | Register user, return tokens |
| POST | /api/auth/login | Login, return tokens |
| POST | /api/auth/refresh | Exchange refresh token for new tokens |

## Health

| Method | Path | Description |
|--------|------|-------------|
| GET | /health | Health check. Returns `{"status": "ok"}` |

## Stations

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/stations | List all stations (id, name, line_id, line_name, geo_lat, geo_lon, is_closed). No auth. Use id (string from HH API) as station_id in upload metadata. |

## Lines

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/lines | List all metro lines (id, name, hex_color). No auth. |

## Defect types

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/defect-types | Categories and defects (slug -> { name, defects: [{ id, name }] }). No auth. Use defect id as defect_id in upload and PATCH. |

## Bootstrap

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/bootstrap | Return defect types, stations, and lines in one payload for mobile app initialization. No auth. See [API_CONTRACT.md](API_CONTRACT.md). |

## Photo Management

| Method | Path | Description |
|--------|------|-------------|
| POST | /api/photos/upload | Single upload: `file` + `metadata` (JSON with location + defect_id, notes, station_id). defect_id from GET /api/defect-types. station_id (string) from GET /api/stations. Auth required. Returns current user points after successful upload. See [API_CONTRACT.md](API_CONTRACT.md). |
| PATCH | /api/photos/{photo_id}/annotation | Update annotation for a photo. Body: optional defect_id, notes, location/station fields. Photo owner only; 403 otherwise. Auth required. |

## Annotations

Annotation is created only with photo upload. No separate POST. Use PATCH /api/photos/{photo_id}/annotation to update.

## User & Gamification

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/user/stats | User stats (points, photos_uploaded). Auth required. |

## Leaderboard

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/leaderboard | Top users by points. Query: limit (default 10), offset (default 0). No auth. |

## Data Export

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/export/dataset | Dataset export. Auth required. Query: format (csv/json), include_images. Returns CSV, JSON, or ZIP. See [API_CONTRACT.md](API_CONTRACT.md). |

## Defect types

See `GET /api/defect-types` for categories and defects (each with id and name). Use defect id as `defect_id` in upload and PATCH.
