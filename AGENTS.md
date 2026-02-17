# Project Context

## Build System
- iOS 17+ SwiftUI project targeting Swift 6.2
- Use `BuildProject` MCP tool to compile — don't run shell xcodebuild commands
- SwiftUI previews available via `RenderPreview` MCP tool
- Xcode must be open with this project for MCP bridge tools to work

## Architecture
- MVVM, SwiftData for persistence, async/await throughout
- No UIKit except where SwiftUI doesn't support the feature
- All new views use `@Observable` macro pattern

## Testing
- Unit tests for ViewModels and service layers
- Run via `RunAllTests` or `RunSomeTests` MCP tools
- UI tests record-and-replay via XCUIAutomation

## Key Dependencies
- Alamofire (5.x) — HTTP networking, auth interceptors
- swift-openapi-generator — REST client generation from OpenAPI spec
- KeychainAccess — secure token storage
- Nuke (12.x) — image loading/caching
- SkeletonUI — loading state UI
- swift-algorithms — stdlib extensions

## Product Spec
See PROMPT.md in the project root for full feature spec and architecture decisions.
