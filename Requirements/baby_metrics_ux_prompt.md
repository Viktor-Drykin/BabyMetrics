# Baby Metrics iOS App — SwiftUI UX/UI Implementation Prompt

Use this prompt with an AI coding assistant (Claude Code, Cursor, Copilot, etc.) to implement the full UX/UI redesign of the Baby Metrics app in SwiftUI.

---

## Context

You are implementing a complete UX/UI redesign for a **Baby Metrics iOS application** built with **Swift and SwiftUI**. The app tracks a baby's daily activities: sleep, feeding, growth measurements, diapers, exercises, massages, and tummy time. The design follows **iOS Human Interface Guidelines**, uses **SwiftData** for persistence, and targets **iOS 17+**.

The redesign has the following goals:
- One-tap logging — never more than 2 taps to start a timer or log an entry
- Glanceable daily summaries visible immediately on the home screen
- Color-coded modules so each section is instantly recognizable
- Calm, parent-friendly aesthetic: soft purples, teals, blues — no harsh colors

---

## Design system

### Color palette

Define these as a `Color` extension in `Colors.swift`:

```swift
extension Color {
    // Module identity colors
    static let moduleSleep    = Color(hex: "#7F77DD")  // purple
    static let moduleFeeding  = Color(hex: "#1D9E75")  // teal
    static let moduleGrowth   = Color(hex: "#378ADD")  // blue
    static let moduleDiapers  = Color(hex: "#BA7517")  // amber
    static let moduleActivity = Color(hex: "#D4537E")  // pink
    static let moduleTummy    = Color(hex: "#639922")  // green

    // Dark header variants (for NavigationStack headers)
    static let sleepDark      = Color(hex: "#3C3489")
    static let feedingDark    = Color(hex: "#0F6E56")
    static let growthDark     = Color(hex: "#185FA5")
    static let activityDark   = Color(hex: "#72243E")
    static let diapersDark    = Color(hex: "#854F0B")

    // Light fill variants (for cards and backgrounds)
    static let sleepLight     = Color(hex: "#EEEDFE")
    static let feedingLight   = Color(hex: "#E1F5EE")
    static let growthLight    = Color(hex: "#E6F1FB")
    static let activityLight  = Color(hex: "#FBEAF0")
    static let diapersLight   = Color(hex: "#FAEEDA")
    static let tummyLight     = Color(hex: "#EAF3DE")
}
```

### Typography

Use **SF Pro** (system font) throughout. Never use custom fonts. Apply these text styles consistently:

| Role | SwiftUI style | Weight |
|------|--------------|--------|
| Screen title | `.title2` | `.semibold` |
| Section heading | `.subheadline` | `.semibold` |
| Card value | `.title3` | `.semibold` |
| Body / label | `.caption` | `.regular` |
| Timestamp / meta | `.caption2` | `.regular` |

### Corner radii

```swift
enum AppRadius {
    static let card: CGFloat = 16
    static let pill: CGFloat = 12
    static let button: CGFloat = 22
    static let tag: CGFloat = 8
}
```

### Spacing

Use multiples of 4pt. Standard horizontal padding: `16pt`. Card internal padding: `12pt`. Gap between cards in a grid: `8pt`.

---

## App architecture

### Navigation

Use a `TabView` at the root with five tabs:

```swift
TabView(selection: $selectedTab) {
    HomeView()
        .tabItem { Label("Home", systemImage: "house.fill") }
        .tag(0)
    StatsView()
        .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
        .tag(1)
    QuickLogView()
        .tabItem { Label("Log", systemImage: "plus.circle.fill") }
        .tag(2)
    HistoryView()
        .tabItem { Label("History", systemImage: "calendar") }
        .tag(3)
    SettingsView()
        .tabItem { Label("Settings", systemImage: "gearshape") }
        .tag(4)
}
.tint(.moduleSleep)
```

Each module (Sleep, Feeding, Growth, Diapers, Activities) is a `NavigationStack` pushed from the home grid.

### Data layer

Use **SwiftData** with the following models:

```swift
@Model class Baby {
    var name: String
    var birthDate: Date
    var photoData: Data?
}

@Model class SleepSession {
    var baby: Baby
    var startTime: Date
    var endTime: Date?       // nil = currently sleeping
    var type: SleepType      // enum: night, nap
}

@Model class FeedingSession {
    var baby: Baby
    var startTime: Date
    var endTime: Date?
    var side: BreastSide     // enum: left, right, both
    var durationSeconds: Int
}

@Model class GrowthEntry {
    var baby: Baby
    var date: Date
    var weightKg: Double?
    var heightCm: Double?
    var headCircumferenceCm: Double?
    var notes: String?
    var source: String?      // e.g. "Doctor's visit"
}

@Model class DiaperEntry {
    var baby: Baby
    var timestamp: Date
    var type: DiaperType     // enum: wet, dirty, both
    var weightGrams: Double?
}

@Model class ActivitySession {
    var baby: Baby
    var startTime: Date
    var endTime: Date?
    var type: ActivityType   // enum: exercise, massage, tummyTime
    var durationSeconds: Int
}
```

Use a shared `ModelContainer` injected via `.modelContainer(sharedContainer)` at the `App` level.

---

## Screen specifications

### 1. Home screen (`HomeView`)

**Layout:**
- Colored header (`moduleSleep` / purple) with baby name, age badge ("3 months 12 days old"), and today's date
- Horizontal `HStack` of three quick-stat pills: today's total sleep duration, number of feedings, number of diapers
- "Quick access" label + 2-column `LazyVGrid` of six `CategoryCard` components
- Bottom `TabView` tab bar

**`CategoryCard` component:**

```swift
struct CategoryCard: View {
    let title: String
    let subtitle: String   // last entry description, e.g. "Last: 45 min ago"
    let icon: String       // SF Symbol name
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card))
        }
        .buttonStyle(.plain)
    }
}
```

**SF Symbol mapping:**

| Module | SF Symbol |
|--------|-----------|
| Sleep | `moon.fill` |
| Feeding | `drop.fill` |
| Growth | `chart.line.uptrend.xyaxis` |
| Diapers | `basket.fill` |
| Activities | `figure.mixed.cardio` |
| Tummy time | `figure.roll` |

---

### 2. Sleep tracker (`SleepView`)

**Layout:**
- Dark purple header (`sleepDark`) with title and back chevron
- Centered timer ring: a `ZStack` with `Circle()` stroke and a `VStack` showing `HH:MM:SS` and "sleeping" label
- "Start sleep" / "Stop sleep" primary button (pill shape, `moduleSleep` fill)
- "Today's log" section with a `List` of past sessions (name, time range, duration in purple)

**Timer ring implementation:**

```swift
struct SleepTimerRing: View {
    let elapsed: TimeInterval
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.sleepLight, lineWidth: 4)
            Circle()
                .trim(from: 0, to: isActive ? min(elapsed / 3600, 1.0) : 0)
                .stroke(Color.moduleSleep, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: elapsed)
            VStack(spacing: 2) {
                Text(formatDuration(elapsed))
                    .font(.title3).fontWeight(.semibold)
                    .foregroundStyle(Color.sleepDark)
                Text("sleeping")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 120, height: 120)
    }
}
```

**Timer logic:**

Use a `@StateObject` view model with `Timer.publish(every: 1, on: .main, in: .common)` to tick elapsed seconds. Persist the `startTime` to SwiftData immediately on tap so a background kill doesn't lose the session.

---

### 3. Feeding tracker (`FeedingView`)

**Layout:**
- Dark teal header (`feedingDark`)
- Two side-selector cards (Left breast / Right breast) in an `HStack`. The recommended side (not used last) has a `teal` border highlight. Each card shows: arrow icon, label, "Last: X min ago" in caption2.
- A white card showing the live timer value for the current session and the active side label beneath it
- Two action buttons: "Pause" (secondary) and "Finish" (primary teal)
- Session log below

**Side selector logic:** Query the most recent `FeedingSession`, get its `.side`, and highlight the *other* side with a `2pt` colored border. When neither side was used in the last 12 hours, highlight left by default.

**Session form fields (sheet):** Side, start time (DatePicker), duration (if logging past session), notes.

---

### 4. Growth metrics (`GrowthView`)

**Layout:**
- Blue header (`growthDark`)
- Three metric summary cards in an `HStack`: Weight (kg), Height (cm), Head circumference (cm). Each shows the latest logged value.
- A bar chart (`Swift Charts` — `import Charts`) showing weight over the last 7 entries
- "Log new measurement" button (blue, full width)
- Recent measurements list with date, source, and value

**Chart implementation:**

```swift
Chart(weightEntries) { entry in
    BarMark(
        x: .value("Date", entry.date, unit: .day),
        y: .value("Weight", entry.weightKg ?? 0)
    )
    .foregroundStyle(Color.moduleGrowth)
    .cornerRadius(4)
}
.frame(height: 80)
.chartXAxis(.hidden)
.chartYAxis(.hidden)
```

**Log sheet fields:** Weight (kg with decimal), height (cm), head circumference (cm), date, source/notes. All fields are optional — allow partial entries.

---

### 5. Diapers (`DiaperView`)

**Layout:**
- Amber header (`diapersDark`)
- Two summary stat cards: "Today's count" and "Total weight today (g)"
- Large "+ Add diaper" button (amber, full width, rounded)
- Scrollable log of today's diaper entries with type badge and optional weight

**Add diaper sheet fields:**
- Type: segmented picker — Wet / Dirty / Both
- Weight (grams) — optional, numeric keyboard
- Time — DatePicker defaulting to now

**Type badge colors:**

```swift
func diaperBadgeColor(_ type: DiaperType) -> Color {
    switch type {
    case .wet:   return .moduleGrowth  // blue
    case .dirty: return .moduleDiapers // amber
    case .both:  return .moduleActivity // pink
    }
}
```

---

### 6. Activities (`ActivitiesView`)

**Layout:**
- Dark pink header (`activityDark`)
- Three activity rows — Exercise, Massage, Tummy Time — each as a card with:
  - Colored icon in a rounded square
  - Activity name + subtitle (last session info or live timer if active)
  - "Start" button (light colored background) or live timer readout if in progress
- In-progress card gets a `2pt` colored border and shows a pulsing dot + elapsed time in the subtitle
- Today's completed sessions listed below

**Active session indicator:**

```swift
if session.isActive {
    HStack(spacing: 4) {
        Circle()
            .fill(Color.moduleActivity)
            .frame(width: 6, height: 6)
            .scaleEffect(pulsing ? 1.3 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulsing)
        Text("In progress · \(formatDuration(elapsed))")
            .font(.caption2)
            .foregroundStyle(Color.moduleActivity)
    }
}
```

---

## Shared components to build

### `QuickStatPill`
White rounded card with a bold value and a small muted label beneath. Used in the home screen's stats row.

### `SessionLogRow`
Reusable list row: left side has title + subtitle (time range), right side has a colored duration or value string. Used across Sleep, Feeding, and Activities logs.

### `SectionHeader`
`HStack` with a bold `.subheadline` label on the left and an optional "See all" tappable link on the right. Consistent 16pt horizontal padding.

### `ModuleHeaderView`
Colored header banner (full bleed) with the module's dark color. Contains a title, optional subtitle, and supports a trailing action slot. Extends under the status bar using `.ignoresSafeArea(edges: .top)` with internal top padding of `safeAreaInsets.top + 12`.

### `TimerViewModel`
`@MainActor @Observable` class that holds `startTime: Date?`, `elapsed: TimeInterval`, and a Combine timer subscription. Exposes `start()`, `pause()`, `stop() -> TimeInterval`.

### `EntrySheet`
Generic `.sheet` wrapper using `.presentationDetents([.medium, .large])` and `.presentationDragIndicator(.visible)`. Used for all log-entry forms across modules.

---

## UX behaviour rules

1. **Auto-suggest next action.** If no feeding has been logged in 3+ hours, show a soft banner on the home screen: "Time for a feed? Last feeding was 3h ago."
2. **Smart side switching.** In the Feeding screen, always pre-select the breast that was *not* used in the last session.
3. **Sleep type inference.** Sessions started between 19:00–06:00 are labelled "Night sleep"; others are labelled "Nap". Allow manual override.
4. **Live timer persistence.** When a timer is started, immediately write the `startTime` to SwiftData. On app launch, check for any session with a `nil` endTime — resume its timer automatically.
5. **Haptics.** Use `UIImpactFeedbackGenerator(style: .medium)` when starting a timer and `UINotificationFeedbackGenerator` (success type) when saving an entry.
6. **Empty states.** Each log section shows a friendly empty state illustration (use SF Symbol with `.font(.system(size: 44))` in a muted color) and a short prompt like "No sleep logged today. Tap the moon to start tracking."
7. **Swipe to delete.** All log rows support `.onDelete` to remove entries, with a confirmation alert for entries older than 1 hour.
8. **Quick Log tab.** The center tab (+) presents a bottom sheet listing all six categories. Tapping one opens the relevant entry form inline without navigating away from the home screen.

---

## Accessibility

- All interactive elements have `.accessibilityLabel` and `.accessibilityHint`
- Timer rings include `.accessibilityValue(formatDuration(elapsed))`
- Color is never the *sole* indicator of state — always pair with an icon or text label
- Support Dynamic Type — use relative font sizes, never fixed point sizes for text
- Support VoiceOver — mark decorative icons with `.accessibilityHidden(true)`

---

## File structure

```
BabyMetrics/
├── App/
│   ├── BabyMetricsApp.swift
│   └── AppContainer.swift          # ModelContainer setup
├── Models/
│   ├── Baby.swift
│   ├── SleepSession.swift
│   ├── FeedingSession.swift
│   ├── GrowthEntry.swift
│   ├── DiaperEntry.swift
│   └── ActivitySession.swift
├── ViewModels/
│   ├── TimerViewModel.swift
│   ├── SleepViewModel.swift
│   ├── FeedingViewModel.swift
│   └── ActivityViewModel.swift
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   └── CategoryCard.swift
│   ├── Sleep/
│   │   ├── SleepView.swift
│   │   └── SleepTimerRing.swift
│   ├── Feeding/
│   │   ├── FeedingView.swift
│   │   └── BreastSideSelector.swift
│   ├── Growth/
│   │   ├── GrowthView.swift
│   │   └── GrowthChart.swift
│   ├── Diapers/
│   │   └── DiaperView.swift
│   ├── Activities/
│   │   ├── ActivitiesView.swift
│   │   └── ActivityCard.swift
│   └── Shared/
│       ├── QuickStatPill.swift
│       ├── SessionLogRow.swift
│       ├── SectionHeader.swift
│       ├── ModuleHeaderView.swift
│       ├── EntrySheet.swift
│       └── EmptyStateView.swift
├── DesignSystem/
│   ├── Colors.swift
│   ├── Typography.swift
│   └── Radius.swift
└── Utilities/
    ├── DurationFormatter.swift
    └── HapticManager.swift
```

---

## Implementation order

Implement in this sequence to ensure the foundation is solid before building features:

1. `DesignSystem/` — colors, typography constants, radius enum
2. `Models/` — all SwiftData models and enums
3. `AppContainer.swift` — shared `ModelContainer`
4. `Shared/` components — `QuickStatPill`, `SessionLogRow`, `ModuleHeaderView`, `EntrySheet`, `EmptyStateView`
5. `TimerViewModel` — tested in isolation before wiring to views
6. `HomeView` + `CategoryCard` — the hub everything links from
7. Each module view in priority order: Sleep → Feeding → Diapers → Growth → Activities
8. `StatsView` — weekly/monthly aggregates using SwiftData queries
9. `HistoryView` — calendar-style day picker with a day summary
10. `SettingsView` — baby profile (name, birth date, photo), notifications, data export

---

*Design reference: see `baby_metrics_ux_design` mockup for visual reference of colors, layout proportions, and component hierarchy.*
