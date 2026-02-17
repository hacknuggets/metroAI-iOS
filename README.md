# MetroAI

An iOS app for capturing and reporting metro defects with gamification features. Help improve metro infrastructure by photographing defects, tagging them with precise locations and types, and competing on the leaderboard.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-Latest-green.svg)

## Features

### Core Functionality
- **Photo Capture** - Take photos of metro defects with full camera integration
- **GPS Location** - Automatic location detection and nearby station resolution (500m radius)
- **Defect Classification** - Categorized defect types with easy selection
- **Station Tagging** - Link defects to specific metro stations and lines
- **Offline Queue** - Photos saved locally and uploaded when connection available
- **Annotations** - Add notes and details to defect reports

### Gamification
- **Points System** - Earn points for reporting defects
- **Leaderboard** - Compete with other users
- **Statistics** - Track your contributions and progress

### User Experience
- **Secure Authentication** - JWT-based auth with token refresh
- **Offline-First** - Work without internet, sync when online
- **Modern UI** - Clean SwiftUI interface with smooth animations
- **Localization** - Currently supports Russian

## Architecture

MetroAI v2 follows **MVVM architecture** with a clean separation of concerns:

```
metroAIv2/
├── App/
│   ├── metroAIv2App.swift      # App entry point with SwiftData setup
│   └── Config.swift             # Environment configuration
├── Views/
│   ├── RootView.swift           # Auth routing
│   ├── MainTabView.swift        # Main tab navigation
│   ├── CameraView.swift         # Photo capture
│   ├── UploadQueueView.swift    # Upload queue management
│   ├── StatsView.swift          # User statistics
│   └── ...
├── ViewModels/
│   ├── AuthViewModel.swift      # Authentication logic
│   ├── CameraViewModel.swift    # Camera & annotation logic
│   └── QueueViewModel.swift     # Upload queue management
├── Models/
│   ├── Photo.swift              # SwiftData photo model
│   ├── UserStats.swift          # SwiftData stats model
│   ├── Station.swift            # Station data model
│   ├── Defect.swift             # Defect type model
│   └── ...
└── Services/
    ├── APIService.swift         # Network layer
    ├── AuthService.swift        # Authentication service
    ├── BootstrapService.swift   # Reference data caching
    ├── LocationService.swift    # GPS & location
    ├── UploadService.swift      # Photo upload queue
    ├── KeychainService.swift    # Secure token storage
    └── ImageService.swift       # Image processing
```

### Key Design Patterns

- **`@Observable` macro** - Modern Swift concurrency with `@MainActor` isolation
- **`async/await`** - All async operations use structured concurrency (no Combine)
- **Singleton services** - Shared instances accessed via `.shared`
- **SwiftData** - Local persistence for photo queue and user stats
- **24-hour caching** - Bootstrap data cached in UserDefaults for performance

## Requirements

- **Xcode**: 15.0+
- **iOS**: 17.0+
- **Swift**: 6.2
- **macOS**: 14.0+ (for development)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/metroAIv2.git
cd metroAIv2
```

### 2. Install Dependencies

The project uses Swift Package Manager. Dependencies will be resolved automatically when you open the project.

Currently integrated:
- **KeychainAccess** (4.2.2) - Secure token storage

### 3. Configure Backend URL

The default backend URL is configured in `metroAIv2/App/Config.swift`:

```swift
API_BASE_URL = http://147.45.153.120:8000
```

For production, update `Config.xcconfig` or use build configurations.

### 4. Open in Xcode

```bash
open metroAIv2.xcodeproj
```

### 5. Build & Run

**Option A: Using Xcode**
- Select a simulator or device
- Press `⌘R` to build and run

**Option B: Using XcodeBuildMCP Tools**

```bash
# Build for simulator
build_sim

# Build and run
build_run_sim

# Run tests
test_sim
```

**Option C: Using xcodebuild**

```bash
# Build
xcodebuild -scheme metroAIv2 -destination 'platform=iOS Simulator,name=iPhone 17' build

# Test
xcodebuild -scheme metroAIv2 -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Testing

### Debug Features

In debug builds, the Camera tab includes a test button (test tube icon) in the toolbar that opens the annotation form with a generated test image - no camera needed!

### Running Tests

```bash
# Run all tests
xcodebuild test -scheme metroAIv2 -destination 'platform=iOS Simulator,name=iPhone 17'

# Or use XcodeBuildMCP
test_sim
```

## Backend API

Base URL: `http://147.45.153.120:8000/api`

Full API documentation: [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md)

### Key Endpoints

#### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login with credentials
- `POST /api/auth/refresh` - Refresh access token

#### Data
- `GET /api/bootstrap` - Get defect types, stations, and lines (single request)
- `GET /api/stations` - List all metro stations
- `GET /api/defect-types` - Get defect categories and types

#### Photos
- `POST /api/photos/upload` - Upload photo with metadata
  - Multipart form: `file` (JPEG) + `metadata` (JSON)
  - Returns updated user points
- `PATCH /api/photos/{id}/annotation` - Update photo annotation

#### User & Gamification
- `GET /api/user/stats` - Get user points and photo count
- `GET /api/leaderboard` - Get top users (default limit: 10)

## Configuration

### Build Configurations

The project uses `.xcconfig` files for environment-specific settings:

- `Config.xcconfig` - Current configuration
- `Config.xcconfig.example` - Template for team members

**Environment Variables:**
```
API_BASE_URL = http://147.45.153.120:8000
APP_NAME = MetroAI
ENABLE_LOGGING = YES
```

These are read from `Info.plist` and accessed via `Config.apiBaseURL`.

### Xcode Project Settings

Swift concurrency settings:
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`

## Project Structure

```
metroAIv2/
├── metroAIv2.xcodeproj/         # Xcode project
├── metroAIv2/                   # Source code
│   ├── App/                     # Entry point & config
│   ├── Views/                   # SwiftUI views
│   ├── ViewModels/              # View models
│   ├── Models/                  # Data models
│   ├── Services/                # Business logic
│   ├── Assets.xcassets/         # Images & colors
│   └── Info.plist               # App configuration
├── docs/                        # Documentation
│   ├── API_CONTRACT.md          # Detailed API specs
│   └── API_SPEC.md              # Quick API reference
├── Config.xcconfig              # Build configuration
├── CLAUDE.md                    # AI assistant guidance
├── AGENTS.md                    # Development context
└── README.md                    # This file
```

## Code Conventions

### Swift Style
- **No UIKit** unless SwiftUI lacks the capability
- **`@Observable` macro** for all ViewModels and services
- **`@MainActor`** isolation for UI-related code
- **`async/await`** for all async operations

### Naming Conventions
- Swift: `camelCase` for properties and methods
- JSON: `snake_case` for API keys (auto-converted via `Codable`)
- `station_id` is a **string** (from metro API)
- `defect_id` is a **UUID** from `/api/defect-types`

### Architecture Rules
1. Views should be dumb - logic belongs in ViewModels
2. ViewModels coordinate between Views and Services
3. Services handle business logic and API calls
4. Models are pure data structures (Codable + SwiftData)

## Development

### Adding New Features

1. Create models in `Models/`
2. Add service layer in `Services/`
3. Create ViewModel in `ViewModels/`
4. Build UI in `Views/`
5. Wire up in `MainTabView` or navigation flow

### Working with Bootstrap Data

Bootstrap data (stations, lines, defect types) is:
- Fetched from `/api/bootstrap` on app launch
- Cached locally for 24 hours in UserDefaults
- Automatically refreshed when stale

Access via `BootstrapService.shared`:
```swift
let stations = BootstrapService.shared.stations
let defectTypes = BootstrapService.shared.defectTypes
```

### Nearby Station Resolution

Stations within 500m radius are automatically detected:

```swift
let nearby = BootstrapService.shared.nearbyStations(location: location, radius: 500)
```

Uses geodesic distance calculation (Haversine formula) for accuracy.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Message Format

```
type: short description

Longer description if needed
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Metro station data provided by HH Metro API
- Built with SwiftUI and SwiftData
- Uses KeychainAccess for secure storage

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact the development team

---

**Made for improving metro infrastructure**
