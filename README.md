# Playdeck

Dual-mode iPhone companion: **Deck** (Stream Deck–style macros on a Mac) and **Ride** (CarPlay-*inspired* dashboard linked to a primary phone). Not real Apple CarPlay.

**Mode rule:** Deck and Ride are mutually exclusive — never simultaneous. You are always in Deck, in Ride, or neither.

| Piece | What it is |
| --- | --- |
| **PlaydeckProtocol** | Shared Swift package — message types, pairing stubs, framed JSON |
| **PlaydeckMac** | Menu-bar helper — Bonjour `_playdeck._tcp`, Accessibility hello-world, USB → `ModeSuggest.deck` |
| **PlaydeckiOS** | SwiftUI app — dense Deck grid + Ride shell, local pairing + Sign in with Apple / CloudKit stubs |

Mac helper ships as a **notarized direct-download DMG** (not Mac App Store) so Accessibility + Automation stay available. iOS is App Store–bound.

---

## Repository layout

```
playdeck/
├── Package.swift                 # Root SPM — builds/tests PlaydeckProtocol
├── Packages/PlaydeckProtocol/    # Shared Codable protocol + ModeController
├── Apps/
│   ├── PlaydeckMac/              # macOS menu-bar helper
│   └── PlaydeckiOS/              # iOS companion
├── Playdeck.xcodeproj/           # App targets + local package ref
├── Playdeck.xcworkspace/         # Opens project + protocol package
├── project.yml                   # XcodeGen source (optional regenerate)
└── Scripts/generate-xcodeproj.sh
```

---

## Setup (macOS + Xcode)

**Requirements:** macOS 14+, Xcode 15+, iOS 17 SDK. Signing team set in Xcode for device runs.

1. Clone and open the workspace:

   ```bash
   git clone https://github.com/AnantKIyer/playdeck.git
   cd playdeck
   open Playdeck.xcworkspace
   ```

2. Select scheme **PlaydeckMac** or **PlaydeckiOS**, pick a run destination, build.

3. Optional — regenerate the Xcode project from `project.yml`:

   ```bash
   brew install xcodegen
   ./Scripts/generate-xcodeproj.sh
   ```

4. Shared package only (no UI):

   ```bash
   swift test
   ```

### Linux / CI note

This Cloud Agent / Linux environment has **no Swift toolchain and no Xcode**. CI checks scaffold layout on Ubuntu; `swift test` runs only when Swift is present.

| Target | Linux CI | macOS + Xcode |
| --- | --- | --- |
| `PlaydeckProtocol` (`swift test`) | Yes, if Swift installed | Yes |
| `PlaydeckMac` / `PlaydeckiOS` | **No** — needs Xcode | Yes |

Full app builds, Accessibility, IOKit USB, Sign in with Apple, and CloudKit require macOS.

---

## Permissions

### Mac helper (`PlaydeckMac`)

| Permission | Why |
| --- | --- |
| **Accessibility** | `CGEvent` key chords + UI presses (hello-world: ⌘⇧P, Mission Control stub) |
| **Automation** | Per-app AppleScript / Shortcuts later (TCC prompts) |
| **Local Network** | Bonjour `_playdeck._tcp` pairing with phones |
| **USB (IOKit)** | Detect cable attach → `ModeSuggest.deck` (opt-out in Settings) |

Without Accessibility, Deck is limited to URL opens and curated Shortcuts. First-run Settings rechecks trust via `AXIsProcessTrustedWithOptions`.

**Distribution:** notarized direct download — App Sandbox is off in entitlements for MVP helper power.

### iOS (`PlaydeckiOS`)

| Permission / capability | Why |
| --- | --- |
| **Local Network** + Bonjour `_playdeck._tcp` | Mesh with Mac / primary phone |
| **Sign in with Apple** (stub) | Optional account path |
| **CloudKit** (stub) | Optional layout backup — not the live control path |

Ride does **not** request Notification Center access; alerts are app-mediated only.

---

## Architecture overview

```
[Companion iPhone]  ←local mesh→  [Primary iPhone]   ← Ride host
         ↕
         └──────────→ [Mac helper]                    ← Deck executor
```

- **Deck:** Mac + companion (primary optional). Mac executes; phone is the remote. Dense Stream Deck–style pages; no shell actions in MVP.
- **Ride:** Dual-iPhone. Music priority: YouTube Music / YouTube, then Apple Music. Maps: Apple or Google per primary. Not CarPlay.
- **Transport:** Network.framework Bonjour (`_playdeck._tcp`) + length-prefixed framed JSON (`FramedJSON`). Multipeer fallback later.
- **Accounts:** User chooses **local pairing** *or* **Sign in with Apple + CloudKit**. Live control always stays on the local mesh.
- **USB → Deck:** Mac watches USB; on paired attach sends `ModeSuggest.deck`. Skipped if Ride is active. Settings: “Open Deck when connected by cable.”
- **Exclusivity:** `ModeController` enforces Deck XOR Ride; leave either mode anytime.

### Protocol package highlights

- `PlaydeckEnvelope` — hello, pairing, mode suggest/changed, deck invoke, ride state/transport, heartbeat
- `FramedJSON` / `FramedJSONReader` — 4-byte BE length + UTF-8 JSON
- `PairingSessionStub` / `AppleIDCloudKitAccountStub` — crypto & CloudKit placeholders
- `ModeController` — mutual exclusion + USB suggest respecting Ride

---

## Scaffold status (this PR)

Implemented as a buildable scaffold (stubs where noted):

1. Shared **PlaydeckProtocol** package + unit tests  
2. Mac menu bar: Bonjour advertiser, Accessibility key chord + Mission Control stub, USB `ModeSuggest.deck` stub  
3. iOS: Deck dense grid UI, Ride shell UI, mode exclusivity, local pairing + SIWA/CloudKit stubs  
4. README, `project.yml`, `Playdeck.xcodeproj` / `.xcworkspace`, Linux-friendly CI layout check  

Next engineering steps (from the locked plan): real Noise/TLS pairing, Deck executor wiring, Ride remotes against primary, trip-card publishers, notarized DMG + TestFlight.
