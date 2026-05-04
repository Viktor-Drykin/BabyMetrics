# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Operations

### Building & Development
- Build the project in Xcode: `swift package resolve && cd BabyMetrics && xcodebuild build`
- Run preview in Simulator: Click the Preview button in Xcode
- Manage dependencies via Swift Package Manager (no external dependencies listed in README)

### Testing
- Run unit tests: `xcodebuild test -scheme BreastFeedingTests -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'`
- Key test files: 
  - `BreastFeedingTests/BreastFeedingTests.swift` - Tests persistence and CSV generation 
  - `BreastFeedingUIXTests/...` - UI tests (if any exist)
- Test isolation strategy: Uses unique UserDefaults suites per test to avoid conflicts

### Code Quality
- Swift code follows Combine + async/await patterns
- Domain layer contains pure business logic (e.g., `FeedingUseCases`)
- Data layer uses UserDefaults with JSON encoding/decoding
- Presentation layer uses SwiftUI with ViewModel architecture

## Architecture Overview

The codebase follows a layered pattern with clear separation of concerns:

1. **Domain Layer** (`BreastFeeding/Domain/`)
   - Contains use cases (e.g., `FeedingUseCases` in `UseCases/`)
   - Defines repositories and entity interfaces
   - Pure business logic with no iOS dependencies

2. **Data Layer** (`BreastFeeding/Data/Repositories/`)
   - Implements repository patterns (e.g., `UserDefaultsFeedingRepository`)
   - Handles persistence via UserDefaults with JSON encoding
   - Provides publishers for reactive updates

3. **Presentation Layer** (`BreastFeeding/Presentation/`)
   - SwiftUI views with corresponding ViewModels
   - Handles UI state and event propagation
   - Structured around screen modules (Record, SleepHistory, Timeline)

## Key Patterns

- **Architecture**: VIPER-inspired with SwiftUI
- **State Management**: ObservableObject + Combine publishers
- **Persistence**: UserDefaults with automatic syncing
- **Testing**: Pure domain logic separation enables clean unit testing

## Important Files to Understand First

- `BreastFeeding/Domain/UseCases/FeedingUseCases.swift` - Defines business operations
- `BreastFeeding/Data/Repositories/UserDefaultsFeedingRepository.swift` - Data persistence implementation
- `BreastFeeding/Presentation/SleepHistory/SleepHistoryView.swift` - Example SwiftUI view structure

These files demonstrate the complete cycle from domain logic → data storage → UI rendering.