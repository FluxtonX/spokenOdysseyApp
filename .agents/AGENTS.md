# Spoken Odyssey Development Rules & Constraints

## CRITICAL RULES FOR ALL AGENTS & DEVELOPERS

### 1. BACKEND IMMUTABILITY
- **DO NOT MODIFY** any code, schemas, migrations, or files in `spokenOdessie_backend/`.
- All backend routes (`/api/auth`, `/api/albums`, `/api/memories`, `/api/users`, etc.) and data models are locked and live in production.
- Frontend Flutter app must communicate with existing API endpoints without requesting backend code edits.

### 2. WEB APPLICATION IMMUTABILITY
- **DO NOT MODIFY** any code in `spoken-odyssey-web/` or the root `web/` configuration.
- The web app is deployed separately and must remain unchanged.

### 3. NATIVE CONFIGURATION & APP STORE RELEASE PROTECTION
- **DO NOT CHANGE** the Bundle Identifier (`com.fluxtonx.spokenodyssey`).
- Do not modify iOS provisioning profile settings, `Runner.xcodeproj`, `Info.plist` bundle keys, or Android `build.gradle.kts` package/application ID configurations.
- `firebase.json` and Firebase credentials must be preserved intact.

### 4. CLEAN ARCHITECTURE STANDARD
- The Flutter codebase under `lib/` must adhere strictly to **Clean Architecture**:
  - `core/`: Constants, Theme, Network, Service Locator (DI), Utility, Error handling.
  - `features/<feature_name>/domain`: Entities, Use Cases, Repository interfaces (pure Dart).
  - `features/<feature_name>/data`: Models (JSON parsing), Data Sources (Remote/Local), Repository implementations.
  - `features/<feature_name>/presentation`: State management (BLoC / Cubits), Pages, Widgets.

### 5. STATE MANAGEMENT
- State management must use **flutter_bloc** (Bloc / Cubit).
- Dependency injection must use **get_it** service locator.
- No direct global state mutation or untyped state handlers.
