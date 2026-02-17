# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MetroAI v2 is an iOS app for capturing and reporting metro defects. Users photograph defects, tag them with defect type and station, and upload to a backend API. Includes gamification (points, leaderboard).

## Build & Test

This is an Xcode project (Swift 6.2, iOS 17+, SwiftUI).

**Prefer XcodeBuildMCP tools** over shell commands. Session defaults are persisted in `.xcodebuildmcp/config.yaml` (project: `metroAIv2.xcodeproj`, scheme: `metroAIv2`, simulator: `iPhone 16`, config: `Debug`).

- Build: `build_sim`
- Build & run: `build_run_sim`
- Test: `test_sim`
- Clean: `clean`
- Logs: `launch_app_logs_sim` / `start_sim_log_cap` + `stop_sim_log_cap`
- Screenshots & UI: `screenshot`, `snapshot_ui`

Fallback shell commands if MCP is unavailable:
```
xcodebuild -scheme metroAIv2 -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme metroAIv2 -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Architecture

**MVVM with services layer:**

- `App/` — Entry point (`metroAIv2App`) with SwiftData container setup, and `Config` constants
- `Views/` — SwiftUI views. `RootView` routes based on auth state; `MainTabView` has Camera/Queue/Stats tabs
- `ViewModels/` — `@Observable` view models (currently `AuthViewModel`)
- `Models/` — Codable structs + SwiftData models (`Photo`, `UserStats`). `Bootstrap` combines defect types, stations, lines
- `Services/` — Singleton services: `APIService` (network), `AuthService` (login/register/refresh), `KeychainService` (token storage via KeychainAccess), `BootstrapService` (reference data with 24h cache), `StationService` (nearby station resolution)

**Navigation flow:** `RootView` checks auth → authenticated users see `MainTabView`, unauthenticated see `OnboardingView` → `LoginView`/`RegisterView`.

**Key patterns:**
- `@Observable` macro + `@MainActor` on all ViewModels and services
- `async/await` for all async work — no Combine, no completion handlers
- Singleton services accessed via `.shared` (e.g., `AuthService.shared`)
- SwiftData for local persistence (`Photo` upload queue, `UserStats`)
- KeychainAccess library for secure token storage (service: `com.metroai.tokens`)
- 24-hour cache expiration for bootstrap/station data via UserDefaults

## Backend API

Base URL configured in `Config.swift` (default: `http://147.45.153.120:8000`). Full contracts in `docs/API_CONTRACT.md`, endpoint reference in `docs/API_SPEC.md`.

Key endpoints:
- Auth: `/api/auth/register`, `/api/auth/login`, `/api/auth/refresh`
- Data: `/api/bootstrap` (combined defect types + stations + lines), `/api/stations`, `/api/lines`, `/api/defect-types`
- Photos: `POST /api/photos/upload` (multipart: `file` + `metadata` JSON), `PATCH /api/photos/{id}/annotation`
- User: `/api/user/stats`, `/api/leaderboard`

Photo upload sends `multipart/form-data` with JPEG file and JSON metadata (`latitude`, `longitude`, `station_id`, `defect_id`, `notes`, `captured_at`). Returns updated points on success, 409 on duplicate.

## Dependencies

- **KeychainAccess** (4.2.2) — only external dependency currently integrated via SPM

AGENTS.md lists planned but not-yet-integrated dependencies: Alamofire, swift-openapi-generator, Nuke, SkeletonUI, swift-algorithms.

## Swift Concurrency Settings

The project uses strict concurrency defaults configured in the Xcode project:
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (global actor isolation by default)
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`

## Conventions

- No UIKit unless SwiftUI lacks the capability
- All new views must use `@Observable` macro pattern
- Models use `Codable` with `snake_case` JSON keys (Swift properties are `camelCase`)
- `station_id` is a **string** (from HH metro API), not an integer
- `defect_id` is a **UUID** from the `/api/defect-types` endpoint
