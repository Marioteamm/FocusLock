
# FocusLock — iOS Screen Time App

## Requirements
- Xcode 16+
- iOS 18.0+
- **Release / real Screen Time:** physical iPhone + paid Apple Developer account (Family Controls entitlement)
- **Debug / UI Preview:** free Personal Team + Simulator (mock Screen Time, no Family Controls signing)

## UI Preview mode (Debug, Personal Team, Simulator)

**Debug** builds use `FOCUSLOCK_MOCK_SCREEN_TIME` and empty `*-Debug.entitlements` (no Family Controls / App Groups in the profile).

| What | Debug (Preview) | Release |
|------|-----------------|---------|
| Screen Time APIs | Mock services | Live services |
| App picker | `MockAppPickerView` (demo apps) | `FamilyActivityPicker` |
| Entitlements | `FocusLock-Debug.entitlements` | `FocusLock.entitlements` |
| Shields / real blocking | No | Yes |
| ShieldExtension / DeviceActivityMonitor | Not built (scheme + `EXCLUDED_SOURCE_FILE_NAMES`) | Built + embedded |

**Debug build** compiles only the **FocusLock** app target. Extensions are skipped (`buildForRunning = NO` in scheme) and not embedded (Run Script phase). **Release / Archive** builds extensions first, then embeds them into the app.

1. Open `FocusLock.xcodeproj`, select scheme **FocusLock**, configuration **Debug**.
2. Set your **Personal Team** under Signing for all targets.
3. Run on **iPhone Simulator** (⌘R).
4. Complete onboarding — pick demo apps (Instagram, TikTok, …), set limits, explore all tabs.
5. Yellow banner: **UI Preview — Screen Time вимкнено**.

To test real blocking on device:

1. Scheme **FocusLock Release** (or **Product → Archive** with Release).
2. Paid Apple Developer team + Family Controls capability on app and both extensions.
3. `FocusLock/FocusLock.entitlements` (not `FocusLock-Debug.entitlements`).
4. Physical iPhone — `FamilyActivityPicker`, shields, and monitoring require real Screen Time.

See [SCREEN_TIME_BUILD_MODES.md](SCREEN_TIME_BUILD_MODES.md) for the full Debug vs Release matrix.

## Setup

### 1. Replace Bundle ID
Replace `com.yourcompany.focuslock` everywhere with your team’s bundle ID:
- `FocusLock/FocusLock.entitlements`
- `ShieldExtension/ShieldExtension.entitlements`
- `DeviceActivityMonitor/DeviceActivityMonitor.entitlements`
- `Shared/AppGroupConstants.swift` (`suiteName`)
- Xcode target bundle identifiers (Build Settings)

App Group must be: `group.<your-bundle-id-suffix>` (e.g. `group.com.yourteam.focuslock`).

### 2. Open project
Open `FocusLock.xcodeproj` in Xcode.

### 3. Capabilities (each target)

| Target | App Groups | Family Controls |
|--------|------------|-----------------|
| FocusLock | ✅ | ✅ |
| ShieldExtension | ✅ | ✅ |
| DeviceActivityMonitor | ✅ | ✅ |

### 4. Development Team
Set **DEVELOPMENT_TEAM** for all three targets in Signing & Capabilities.

### 5. Before App Store submission
- Replace **all** `com.yourcompany.focuslock` / `group.com.yourcompany.focuslock` IDs with your production bundle + App Group.
- Test on a **physical device**: onboarding → pick apps → limits → shield → bonus → focus session → midnight reset.
- Request **Family Controls** entitlement approval in App Store Connect if required.
- Privacy Nutrition Labels: disclose Screen Time / device usage data per Apple guidelines.

### 6. Run on device
1. Enable Developer Mode on iPhone.
2. Select your device in Xcode.
3. Product → Run (⌘R).
4. Approve Screen Time authorization when prompted.

## Architecture

```
FocusLock (app)
├── SwiftUI + SwiftData
├── FamilyActivityPicker → per-app AppLimit rows
├── DeviceActivityService → one monitor activity per limit
├── ManagedSettings (named store) → shields
└── App Group UserDefaults → extension sync

ShieldExtension.appex
├── ShieldConfigurationExtension (custom shield UI)
└── ShieldActionExtension (+15 min once/day via .defer)

DeviceActivityMonitor.appex
└── Applies shields when usage thresholds fire

Shared/ (compiled into app + extensions)
├── AppGroupConstants
├── FamilyActivitySelectionStorage (PropertyList Codable)
└── FocusLockManagedSettings (named ManagedSettingsStore)
```

## Testing limits
1. Pick apps (e.g. Safari) via **+**.
2. Set limit to **1 minute** on the card.
3. Use Safari for 1+ minutes.
4. Shield screen should appear with **Add 15 Minutes** (once per day).

## Notes
- Usage time in UI comes from App Group keys updated by Device Activity; exact per-app reporting may require a DeviceActivityReport extension for production analytics.
- Replace placeholder app names (`Додаток 1`) with `Label(token)` in UI if you add token-based labels later.

## Contact

Developer: Marioteamm

For project inquiries or custom app development:

📧 Email: milanaliveyou@gmail.com

<img width="586" height="1212" alt="Знімок екрана 2026-06-01 213125" src="https://github.com/user-attachments/assets/a41f93a3-93ae-4852-a44f-aa0fdc9bf361" />

