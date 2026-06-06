# Screen Time: Debug (mock) vs Release (live)

## Separation model (three layers)

| Layer | Debug | Release |
|-------|-------|---------|
| **1. Compiler flag** | `FOCUSLOCK_MOCK_SCREEN_TIME` in `SWIFT_ACTIVE_COMPILATION_CONDITIONS` | Flag **absent** |
| **2. Source exclusion** | `Live*.swift`, `FocusLockManagedSettings.swift` not compiled | All Live + Mock sources compiled |
| **3. Entitlements** | `*-Debug.entitlements` (empty) | `FocusLock.entitlements` + extension entitlements (Family Controls + App Groups) |
| **4. Runtime** | `FocusLockConfig.useMockScreenTime == true` | `useMockScreenTime == false` |
| **5. Service wiring** | Facades → `Mock*Service` | Facades → `Live*Service` |

Both **Mock** and **Live** source files remain in the repository. Nothing is deleted.

## Service facades (`#if FOCUSLOCK_MOCK_SCREEN_TIME`)

| Facade | Mock (Debug) | Live (Release) |
|--------|----------------|----------------|
| `ScreenTimeService` | `MockFamilyControlsService` | `LiveFamilyControlsService` → `AuthorizationCenter` |
| `DeviceActivityService` | `MockDeviceActivityService` | `LiveDeviceActivityService` → `DeviceActivityCenter` |
| `ManagedSettingsService` | `MockManagedSettingsService` | `LiveManagedSettingsService` → `FocusLockManagedSettings` |

Frameworks used in Release: **FamilyControls**, **ManagedSettings**, **DeviceActivity**.

## Extensions

| Target | Debug (Run / ⌘B) | Release (Archive) |
|--------|------------------|-------------------|
| ShieldExtension | Not built (`buildForRunning = NO`) | Built + embedded |
| DeviceActivityMonitor | Not built | Built + embedded |

Embed run script copies `.appex` only when `CONFIGURATION != Debug`.

## How to build

### UI Preview (Personal Team, Simulator)

- Scheme: **FocusLock**
- Configuration: **Debug** (default for Run)
- Destination: iPhone Simulator
- No Family Controls entitlement in provisioning profile

### Real Screen Time (paid team, physical iPhone)

- Scheme: **FocusLock Release** (or Archive with **Release**)
- Configuration: **Release**
- Signing: `FocusLock/FocusLock.entitlements` on app + extensions
- Enable **Family Controls** capability for all three targets in Apple Developer
- Replace `com.yourcompany.focuslock` / App Group IDs before shipping

## Key files

- `FocusLock/Core/FocusLockConfig.swift` — `useMockScreenTime` tied to compile flag
- `FocusLock/Services/Live/` — real APIs (Release only compiled into active paths)
- `FocusLock/Services/Mock/` — simulator / Personal Team
- `FocusLock.xcodeproj/project.pbxproj` — `EXCLUDED_SOURCE_FILE_NAMES`, entitlements per configuration
