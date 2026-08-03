# Consistency Tracker 🎯

> **Daily consistency made effortless to track with a clean, intuitive, and state-of-the-art interface.**

Consistency Tracker is an offline-first cross-platform application (macOS & Android) built with Flutter. It helps you set daily target goals, focus in uninterrupted sessions, and build long-term streaks with zero friction.

---

## Key Features

### 🎯 Target Goals Management
- **Intuitive Goal Setup**: Easily create daily target goals with target focus minutes, custom colors, reminder times, and motivational quotes.
- **Per-Goal Isolation**: Track multiple goals simultaneously with independent daily progress bars.
- **GitHub-Style Goal Deletion**: Secure confirmation dialog requiring you to type the exact goal name to confirm deletion.

### ⏱️ Segmented Focus Timer
- **Minimal Circular Clock**: Modern 60-segment circular progress ring with a deep pulsing shadow background and clean countdown display.
- **Exact Elapsed Time Tracking**: Stopping early logs the exact elapsed focus time (e.g. 2 minutes logged towards today's target, with no target inflation).
- **Daily Target Trophies**: Earn a celebration trophy dialog when your cumulative daily focus time reaches your target goal.

### 📅 Visual Consistency Calendar Heatmap
- **Start-Date Heatmap Filtering**: The calendar view starts strictly from the day you created your goal—omitting pre-start days for a clean grid.
- **Missed Day Rules**: Unmet past days after your goal start date display a clear red `X` icon (`#F43F5E`).
- **Strict Target Verification**: Days mark green with a checkmark (`✓`) **only** when your cumulative daily focus time meets or exceeds your target minutes.

### ⚙️ Focus Session Settings
- **Custom Durations**: Configure custom focus duration (5–120 mins) and break duration (0–60 mins) steppers.
- **Sound & Notifications**: Toggle phase transition chime sounds and desktop/mobile notifications.
- **Continuous Focus Mode**: Option to run continuous focus sessions without mandatory breaks.

---

## Platform Support & Tech Stack

- **Framework**: Flutter / Dart
- **State Management**: BLoC Pattern (`flutter_bloc`)
- **Offline Storage**: Hive Key-Value Database (`hive_flutter`)
- **Platforms**: macOS Desktop & Android Mobile
- **Testing**: 67 automated unit, integration, and QA edge-case test cases.

---

## Quick Start

```bash
# Clone the repository
git clone https://github.com/your-username/consistency_tracker.git

# Navigate to project directory
cd consistency_tracker

# Install dependencies
flutter pub get

# Run on macOS Desktop
flutter run -d macos

# Build for macOS Debug Bundle
flutter build macos --debug
```
