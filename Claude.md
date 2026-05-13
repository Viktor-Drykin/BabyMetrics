# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Operations

### Building & Development
- Build: open `BabyMetrics.xcodeproj` in Xcode and build the `BabyMetrics` target
- Run preview in Simulator: Click the Preview button in Xcode
- No external dependencies — uses only Apple frameworks (SwiftUI, Combine, Charts)

### Testing
- Run unit tests: `xcodebuild test -scheme BabyMetricsTests -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'`
- Key test files: `BabyMetricsTests/BreastFeedingTests.swift` — tests persistence and CSV generation
- Test isolation strategy: Uses unique UserDefaults suites per test to avoid conflicts

### Code Quality
- Swift code follows Combine + async/await patterns
- Domain layer contains pure business logic
- Data layer uses UserDefaults with JSON encoding/decoding
- Presentation layer uses SwiftUI with ViewModel architecture

## Architecture Overview

The codebase follows a layered pattern with clear separation of concerns:

1. **Domain Layer** (`BabyMetrics/Domain/`)
   - Entities: `FeedingEntry`, `SleepEntry`, `GrowthEntry`, `DiaperEntry`
   - Use cases: `FeedingUseCases`, `SleepUseCases`, `GrowthUseCases`, `DiaperUseCases` (structs of closures)
   - Repository protocols: `FeedingRepository`, `SleepRepository`, `GrowthRepository`, `DiaperRepository`

2. **Data Layer** (`BabyMetrics/Data/Repositories/`)
   - `UserDefaultsFeedingRepository` — persists feeding entries as JSON
   - `UserDefaultsSleepRepository` — persists sleep entries + active sleep state as JSON
   - `UserDefaultsGrowthRepository` — persists growth measurement entries as JSON
   - `UserDefaultsDiaperRepository` — persists diaper entries as JSON
   - All repositories are `@MainActor`, `@Published`, sorted descending by date

3. **Presentation Layer** (`BabyMetrics/Presentation/`)
   - SwiftUI views with corresponding `@MainActor ObservableObject` ViewModels
   - Structured around feature modules (see Tabs section below)

## Tabs

| Tab | Label | View | Description |
|-----|-------|------|-------------|
| 1 | Годування | `RecordFeedingView` | Quick breastfeeding entry (time + side) |
| 2 | Підгузки | `RecordDiaperView` | Log a diaper change (Wet / Dirty / Mixed) with optional weight |
| 3 | Сон | `SleepTrackerView` | Start/stop sleep with custom time pickers |
| 4 | Ріст | `GrowthView` | Log weight/height/head circumference with chart |
| 5 | Разом | `CombinedTimelineView` | All events grouped by day (Events / Days mode) |
| 6 | Історія | `CombinedHistoryView` | Feeding / Sleep / Diaper history tabs with list and bar chart |

## Key Patterns

- **Architecture**: VIPER-inspired with SwiftUI
- **State Management**: `ObservableObject` + Combine publishers
- **Persistence**: UserDefaults with automatic syncing, JSON codec
- **Use Cases**: Structs of closures injected at app startup (`BreastFeedingApp.swift`)
- **Charts**: SwiftUI Charts framework, bar charts only, grouped by day

## Feature Notes

### Sleep Tracker
- Supports custom start/end times via `DatePicker` (defaults to current time)
- Active sleep state persisted separately from completed entries
- Timeline splits overnight sleep entries at midnight so each day shows only its portion

### Growth Measurements (`GrowthEntry`)
- Fields: `date`, `weightKg?`, `heightCm?`, `headCm?` — all measurements optional
- Line chart shows selected metric (weight / height / head) over time with value annotations
- Keyboard dismisses on scroll swipe (`.scrollDismissesKeyboard(.interactively)`)
- CSV format: `date,weight_kg,height_cm,head_cm` (date as `yyyy-MM-dd`)

### Diaper (`DiaperEntry`)
- Fields: `date`, `type` (`wet` / `dirty` / `mixed`), `weightGrams?`
- Recording UI lives in its own tab (`RecordDiaperView`); history is a sub-tab of `CombinedHistoryView`

### History Charts
- Feeding chart: bar chart showing left/right feeding counts per day
- Sleep chart: bar chart showing total sleep hours per day
- Diaper chart: bar chart showing diaper counts per day, grouped by type
- All support List / Chart display mode toggle and filter (All / Today / Week / Month)
- Charts can be exported as PNG via share button

### CSV Import / Export
- Feeding: `date,side` format (`yyyy-MM-dd HH:mm:ss`, side as `Left`/`Right`)
- Sleep: `start_date,end_date,duration_minutes` format
- Growth: `date,weight_kg,height_cm,head_cm` format (empty fields for nil values)
- Diaper: `date,type[,weight_g]` format (`yyyy-MM-dd HH:mm:ss`, type as `Wet`/`Dirty`/`Mixed`)
- All four support import via file picker and export via ShareLink

## Important Files

- `BabyMetrics/BreastFeedingApp.swift` — app entry point, dependency injection root
- `BabyMetrics/ContentView.swift` — tab structure, all view models instantiated here
- `BabyMetrics/Domain/UseCases/FeedingUseCases.swift` — canonical use case pattern
- `BabyMetrics/Data/Repositories/UserDefaultsFeedingRepository.swift` — canonical repository pattern
- `BabyMetrics/Presentation/Timeline/CombinedTimelineViewModel.swift` — most complex VM; handles midnight sleep splitting
