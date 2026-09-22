# Spoken Odyssey Web / Backend / Flutter Parity Audit

**Date:** 2026-09-21  
**Scope:** Read-only comparison of `spoken-odyssey-web/`, `spokenOdessie_backend/`, and the Flutter client under `lib/`.  
**Rules applied:** `AGENTS.md` was read first. Backend and web files were not modified. Native configuration, APIs, models, repositories, and services were not changed.

## Executive Summary

The Flutter app has broad coverage for the primary product journey: authentication, memories, recording, albums, family members, notifications, profile, settings, legacy access, AI Historian, store catalog, and Smart Glasses. It is **not yet feature-parity complete** with the web application and backend.

The most serious findings are contract mismatches that can make existing Flutter flows fail:

1. Flutter password recovery calls `POST /api/auth/verify-otp`, but the current backend auth routes do not register that route. The web flow uses `/api/auth/verify-mock` through its compatibility path.
2. Flutter session revocation posts to `/api/auth/revoke-session`; the backend exposes `DELETE /api/auth/sessions/:id` and `DELETE /api/auth/sessions`. The current Flutter request does not match the server route.
3. Flutter store checkout posts to `/api/v1/store/orders`; the backend order routes do not expose a customer `POST /` checkout route. Payment routes expose checkout-session/intent APIs instead.
4. Flutter declares several endpoint constants that are not implemented or consumed, including refresh-token, OTP, revoke-session, family vaults, AI status, order detail, coupon, family badge, and family mark-seen paths.

The largest verified missing product areas in Flutter are:

- Insights page and live archive insights.
- Passkey registration, deletion, and working passkey login verification.
- Family prompts/answers, guardian controls, relationship graph editing, and family-space albums/timeline behavior.
- Legacy pending requests, approve/reject release, and family vault views.
- Push-device token registration/unregistration and login heartbeat.
- Subscription/pricing UI parity. The web has subscription/pricing screens, but the current backend route inventory does not expose a complete subscription contract; this needs product/API clarification before Flutter implementation.

### Completed in the current integration pass

- The existing Settings > Insights tab now loads `/api/insights/summary` through the Flutter Clean Architecture path instead of displaying hard-coded sample values. It includes loading, unavailable/error, retry, and response fallback handling.
- Flutter session revocation now calls the backend-compatible `DELETE /api/auth/sessions/:id` route.

## Classification

- **Integrated:** Flutter has a presentation flow and a verified data-source/repository path for the relevant backend capability.
- **Partial:** A Flutter surface exists, but important web/backend behavior or states are missing.
- **Missing:** Web/backend behavior is present and there is no equivalent Flutter screen or client integration.
- **Contract mismatch:** Flutter calls a path/method that does not match the current backend route inventory.
- **Web-only / contract unclear:** Web presents the feature, but the inspected backend does not expose a complete production contract; do not invent a Flutter implementation.

## 1. Route and Screen Inventory

### Web application routes found

`/`, `/onboarding`, `/auth`, `/auth/action`, `/auth/reset-password`, `/signup`, `/profile-setup`, `/home`, `/timeline`, `/memories`, `/memories/[id]`, `/discover`, `/explore`, `/search`, `/people/[id]`, `/followers`, `/profile`, `/record`, `/albums`, `/albums/[id]`, `/family`, `/family/tree`, `/family/memories`, `/family/albums/[id]`, `/family/join`, `/invite/[token]`, `/family-historian`, `/insights`, `/notifications`, `/settings`, `/settings/profile`, `/settings/privacy`, `/settings/security`, `/settings/notifications`, `/legacy`, `/store`, `/pricing`, and `/subscription`-related flows.

### Flutter page classes found

Flutter has pages for auth/onboarding, main shell, timeline, discover, record studio, family circle, QR scanner, profile/public profile, memories/feed/detail, albums/detail, notifications, settings/legacy vault, store catalog, and Smart Glasses settings. There is no dedicated Flutter page for Search, Insights, Subscription, Pricing, Family Historian full page, Family Join/Invite token page, Family Albums, or Family Memories as independent web-equivalent routes.

The Flutter app sometimes embeds equivalent behavior in tabs or sheets. That is marked **Partial**, not automatically missing.

## 2. Authentication and Account

| Capability | Web/backend evidence | Flutter status | Severity |
|---|---|---|---|
| Email sign-in/register | `spoken-odyssey-web/src/services/backend.js`; backend `auth.routes.js` register/login | Integrated in `features/auth` | Integrated |
| Google sign-in | Web backend helper and backend `/api/auth/google` | Integrated through Firebase plus backend sync | Integrated |
| Password forgot/reset | Backend `/forgot-password`, `/reset-password`; web auth pages | Flutter has forgot/OTP/reset pages | **Contract mismatch** for OTP step |
| OTP verification | Flutter `lib/features/auth/data/datasources/auth_remote_datasource.dart` calls `ApiEndpoints.verifyOtp` = `/api/auth/verify-otp` | Backend `auth.routes.js` exposes `/send-verification` but no `/verify-otp`; web uses compatibility `/verify-mock` | **Critical** |
| Mock email verification compatibility | Web `verifyMockEmailOnBackend()` calls `/api/auth/verify-mock` | No Flutter equivalent | High |
| MFA TOTP login | Backend `/mfa/totp/verify`; Flutter `AuthRemoteDataSource` and MFA dialog | Integrated | Integrated |
| MFA recovery login | Backend `/mfa/recovery/verify`; Flutter datasource/dialog | Integrated | Integrated |
| Passkey login | Backend `/passkeys/login/options`, `/passkeys/login/verify`; web `MfaVerificationModal` invokes browser passkey flow | Flutter MFA UI contains a passkey presentation path, but Flutter datasource has no passkey API/WebAuthn integration | **High / partial** |
| Passkey registration/delete | Backend `/passkeys/register/options`, `/passkeys/register/verify`, `DELETE /passkeys/:id`; web settings/security manages passkeys | No Flutter datasource, entity, state, or settings control | **High / missing** |
| Recovery-code regeneration | Backend `/mfa/recovery/regenerate`; web security page exposes it | Flutter settings exposes MFA setup/disable but no recovery-code regeneration flow | High |
| Active session listing | Backend `GET /auth/sessions`; Flutter settings datasource | Integrated | Integrated |
| Revoke one session | Backend `DELETE /auth/sessions/:id` | Flutter `SettingsRemoteDataSource.revokeSession()` now calls `DELETE /auth/sessions/:id` | Resolved |
| Revoke all other sessions | Backend `DELETE /auth/sessions`; web security flow | No explicit Flutter equivalent found | High |
| Login-notification toggle | Backend `PUT /auth/notifications/toggle`; web settings/security uses it | Flutter endpoint constant is absent from settings datasource behavior | Medium |
| Profile setup after registration | Web `/profile-setup` collects profile/media data | Flutter sign-up goes directly to Home; profile fields are only later available in Settings | Medium / partial |

## 3. Memories, Media, and Publishing

| Capability | Web/backend evidence | Flutter status | Severity |
|---|---|---|---|
| Memory list/feed/discovery/detail | Backend memory routes; Flutter Timeline, Feed, MemoryDetail, Discover | Integrated | Integrated |
| Create memory with media | Web `PublishWizard`, backend `POST /api/memories` multipart; Flutter publish wizard and repository | Integrated but less complete than web | Medium / partial |
| Update memory/media | Web `updateMemoryOnBackend()` and backend `PATCH /memories/:id` | Flutter endpoint exists in datasource/repository path, but UI audit found no equivalent complete edit-media experience | High / partial |
| Delete memory | Backend and Flutter MemoryCard/detail action | Integrated | Integrated |
| Memory interactions/reactions/share | Backend routes and web FeedCard/MemoryViewModal | Flutter has reactions/interactions/share datasource paths; verify all detail UI actions are exposed | Medium / partial |
| Comments/replies/comment reactions | Backend comments routes; web CommentsSection; Flutter comments sheet and datasource | Integrated at basic level; parity risk remains around reply/media behavior | Medium / partial |
| Story layers | Backend memory and family story-layer routes; web MemoryViewModal uses layers | Flutter has `StoryLayersSection` and datasource support | Integrated / verify UI states |
| Multi-file previews and replace/remove | Web memory detail/publish has previews and replace behavior | Flutter publish wizard only has limited picker/attached-path behavior; no equivalent rich edit-preview workflow | High / partial |
| Upload presigned URL flow | Backend `/api/upload/presigned-url` exists | Flutter uses direct media/repository flows; no presigned upload client path found | Medium / contract-dependent |
| Glasses ingest endpoint | Backend `POST /api/memories/glasses-ingest` | Flutter Smart Glasses imports local media/gallery but no verified API ingest integration found | High / partial |

## 4. Family and Relationship Features

| Capability | Web/backend evidence | Flutter status | Severity |
|---|---|---|---|
| Family members/invitations/approvals | Backend family/user routes; Flutter FamilyCircle, invite modal, QR scanner | Integrated for core flow | Integrated |
| Family tree visual | Web `FamilyTreeCanvas`, backend relationship graph/edge routes | Flutter `FamilyTreeWidget` exists, but no verified relationship graph/edge datasource integration | **High / partial** |
| Set relationship edge | Web `SetRelationshipModal` calls `upsertRelationshipEdge()`; backend family-circle route | No Flutter endpoint/data source/UI found | High / missing |
| Relationship graph loading | Web calls `getRelationshipGraph()` with fallback; backend route | Flutter family tree appears to derive from members rather than the backend graph | High / partial |
| Family shared memories | Backend `/family-circle/shared-memories`; Flutter family datasource/page | Integrated basic flow | Integrated |
| Family albums | Web family page and `getFamilyCircleAlbumsFromBackend()`; backend albums `/space/:familyCircleId` | Flutter has generic AlbumsPage, no family-space album client/page found | High / missing |
| Family timeline/memory filtering | Web `getFamilySpaceTimeline()` and family memories filters | Flutter has family memory tab/filtering but no verified family-space timeline endpoint | Medium / partial |
| Family prompts/questions | Web family page actively creates, lists, and responds to prompts; backend prompt routes | No Flutter prompt entity/datasource/page/widget found | **High / missing** |
| Prompt voice questions/answers | Web supports audio prompt/response; backend supports audio fields | Missing in Flutter | High |
| Guardian controls | Web family page calls `getGuardianControls()` and `updateGuardianConsent()`; backend routes | No Flutter equivalent | **High / missing** |
| Family join by web token | Web `/family/join`, `/invite/[token]`, backend validate/accept token | Flutter has QR scanner and token endpoint constant, but no verified token-entry/deep-link acceptance page | High / partial |
| Family badge/mark-seen | Web navigation uses `getFamilyBadgeCount()` and `markFamilySeen()`; backend routes | Flutter has local invite badge but no verified badge-count/mark-seen API usage | Medium |
| Family legacy vault views | Web family page displays release requests/vaults; backend legacy pending/family-vault routes | Flutter LegacyVaultPage only covers basic legacy settings/vault memories/request flow | High / partial |

## 5. Insights and AI

| Capability | Web/backend evidence | Flutter status | Severity |
|---|---|---|---|
| AI Family Historian chat | Web full page `/family-historian`; backend `/api/ai/family-historian/chat`; Flutter `AiHistorianSheet` and Cubit | Integrated as a sheet, not full web-equivalent page | Medium / partial |
| AI status | Flutter declares `aiHistorianStatus`, but no usage found; backend route exists | Unused/partial | Low |
| Archive insights summary | Web `/insights` actively calls `getUserInsightsFromBackend()` and fallback insights engine; backend `/api/insights/summary` | Integrated into the existing Flutter Settings > Insights tab through `SettingsRemoteDataSource`, `SettingsRepository`, and `SettingsCubit`; no standalone web-equivalent page yet | Medium / partial |
| Home insights entry point | Web Home links to Insights | Flutter Home/Timeline has no equivalent destination | High |

## 6. Notifications and Presence

| Capability | Web/backend evidence | Flutter status | Severity |
|---|---|---|---|
| Notification list/read/delete | Backend notification routes; Flutter NotificationsPage/Cubit | Integrated | Integrated |
| Push device registration | Web FCM registers `/api/notifications/device-token`; backend supports register/unregister | Flutter initializes local notifications but no backend device-token registration path found | High / missing |
| Presence heartbeat | Web AuthProvider calls `/api/users/heartbeat`; backend route exists | No Flutter heartbeat integration found | Medium |
| Realtime notification parity | Web has FCM/browser registration and app banner behavior; Flutter has local notification service and in-app banner | Partial; native push token lifecycle is not verified | High / partial |

## 7. Legacy Access

| Capability | Backend/web evidence | Flutter status | Severity |
|---|---|---|---|
| Legacy settings read/update | Backend GET/PUT `/legacy-access`; Flutter LegacyCubit/datasource | Integrated basic settings | Integrated |
| Request vault release | Backend POST `/request-release`; Flutter datasource | Integrated basic request | Integrated |
| Approve release | Backend POST `/verify-release/:requestId`; web family/admin flow | No Flutter endpoint/UI found | High / missing |
| Reject release | Backend POST `/reject-release/:requestId`; web family/admin flow | No Flutter endpoint/UI found | High / missing |
| Pending release requests | Backend GET `/pending-requests`; web family page | No Flutter endpoint/UI found | High / missing |
| Family vaults | Backend GET `/family-vaults`; web family page | Flutter declares `legacyFamilyVaults` but no usage found | High / missing |

## 8. Store and Commerce

| Capability | Backend/web evidence | Flutter status | Severity |
|---|---|---|---|
| Product catalog/details | Backend product routes; web Store page; Flutter StoreCatalogPage/Cubit | Integrated catalog-level flow | Integrated |
| Cart list/add/remove | Backend cart routes; Flutter datasource/repository | Integrated basic cart data path, UI coverage limited | Medium / partial |
| Customer order checkout | Flutter `StoreRemoteDataSource.checkout()` posts to `/v1/store/orders` | Backend order routes expose GET/patch/dispatch/admin, not customer POST checkout | **Critical contract mismatch** |
| Payment checkout session/intent | Backend payment routes `/payments/create-checkout-session`, `/payments/create-intent`, `/payments/verify-session`; web subscription/store flow | No Flutter payment datasource/UI found | High / missing |
| Orders/details/tracking | Backend order routes; no verified Flutter UI | High / missing |
| Coupons | Backend coupon validate route; Flutter only declares `storeApplyCoupon`, no datasource/UI usage found | Medium / missing |
| Shipping calculation | Backend shipping route; no Flutter integration found | Medium / missing |
| Reviews | Backend product review routes; no verified Flutter UI | Medium / missing |
| Pricing/subscription | Web `/pricing` and `/subscription` UI exists; backend route inventory does not show a complete subscription module | Web-only/contract unclear; do not implement Flutter until API/product contract is defined | High / blocked |

## 9. Search and Social

| Capability | Web/backend evidence | Flutter status | Severity |
|---|---|---|---|
| Discovery people/stories | Backend discovery/featured; Flutter Discover | Integrated | Integrated |
| Global search page | Web `/search`; backend `/api/search`; Flutter uses search from Discover/Timeline but has no dedicated SearchPage | Partial |
| Followers/following | Web Followers page and backend routes; Flutter follower tab/cubit and follow actions | Partial; following destination/list parity should be verified | Medium |
| Taggable users | Web family/memory tagging uses `/users/taggable`; Flutter family datasource has taggable lookup, but publish wizard has no equivalent user-tag picker | Medium / partial |
| Profile editing media | Web profile/profile-setup supports avatar/cover previews/uploads; Flutter Settings supports picker/profile update | Partial; parity and preview states need verification |

## 10. Flutter Endpoint Contract Findings

### Declared but unused or suspicious constants

- `ApiEndpoints.verifyOtp`: used by Flutter, but no current backend route exists.
- `ApiEndpoints.refreshToken`: declared but no backend auth route or Flutter refresh interceptor usage found.
- `ApiEndpoints.revokeSession`: used by Flutter as `POST /auth/revoke-session`, while backend uses `DELETE /auth/sessions/:id`.
- `ApiEndpoints.legacyFamilyVaults`: declared but not consumed.
- `ApiEndpoints.aiHistorianStatus`: declared but not consumed.
- `ApiEndpoints.storeOrderById`: declared but not consumed.
- `ApiEndpoints.storeApplyCoupon`: declared but not consumed.
- `ApiEndpoints.familyBadgeCount`: declared but not consumed.
- `ApiEndpoints.familyMarkSeen`: declared but not consumed.

### Backend routes with no Flutter endpoint/client path found

- `/api/auth/send-verification`
- `/api/auth/passkeys/login/options`
- `/api/auth/passkeys/login/verify`
- `/api/auth/passkeys/register/options`
- `/api/auth/passkeys/register/verify`
- `DELETE /api/auth/passkeys/:id`
- `POST /api/auth/mfa/recovery/regenerate`
- `DELETE /api/auth/sessions/:id`
- `DELETE /api/auth/sessions`
- `PUT /api/auth/notifications/toggle`
- `/api/insights/summary`
- `/api/notifications/device-token`
- `/api/users/heartbeat`
- `/api/family-circle/:familyCircleId/prompts`
- `/api/family-circle/prompts/:promptId/respond`
- `/api/family-circle/:familyCircleId/guardian-controls`
- `/api/family-circle/guardian-consent/:childUserId`
- `/api/family-circle/:circleId/relationship-edge`
- `/api/family-circle/:circleId/relationship-graph`
- `/api/albums/space/:familyCircleId`
- `/api/legacy-access/verify-release/:requestId`
- `/api/legacy-access/reject-release/:requestId`
- `/api/legacy-access/pending-requests`
- `/api/legacy-access/family-vaults`
- `/api/memories/glasses-ingest`
- Store payments, order detail/tracking, coupon, shipping, and review routes listed in the backend route inventory.

## 11. What Is Already Integrated Well

- Core auth login/register/Google flow and backend JWT storage.
- Basic password reset UI exists, but OTP route contract must be resolved.
- TOTP/recovery MFA verification and MFA setup/disable basics.
- Main memory feed, discovery feed, memory detail, reactions, comments, story layers.
- Basic album list/detail/create/delete paths.
- Core family members, invitations, approvals, roles, QR generation/scanning basics.
- Notifications list/read/delete and local/in-app feedback.
- Profile read/update and public profile.
- Basic privacy/settings, active sessions listing, change password, legacy settings/request, AI Historian chat sheet.
- Smart Glasses native SDK flow is present and must remain untouched functionally.

## 12. Priority Implementation Order

### P0 — Resolve existing broken contracts before adding features

1. Align password recovery verification with the actual backend route (`send-verification`/compatibility verification) or obtain an approved backend contract. Do not silently invent `/verify-otp`.
2. Align session revocation with backend `DELETE /auth/sessions/:id` or an approved compatibility contract.
3. Align store checkout with the payment/order API. Do not post orders if the backend does not expose customer order creation.
4. Verify all media upload paths, especially Smart Glasses ingest and multipart field names.

### P1 — Bring web-critical product surfaces to Flutter

1. Insights page and Home entry point.
2. Passkey registration, login, deletion, and recovery-code management.
3. Family relationship graph and relationship editing.
4. Family prompts with text/audio questions and answers.
5. Guardian controls and consent.
6. Family albums and family-space timeline/filtering.
7. Legacy pending/approve/reject/family vault surfaces.
8. Native push token registration and heartbeat/presence lifecycle.

### P2 — Complete parity on existing Flutter features

1. Dedicated Search page or documented decision to keep search embedded.
2. Profile setup after registration.
3. Memory edit/media replacement and richer publish preview states.
4. Taggable member picker in publishing.
5. Store cart UI, payment checkout, orders, tracking, coupons, shipping, and reviews once contracts are confirmed.
6. Full-page AI Historian parity if the product requires the web page rather than the existing sheet.

## 13. Safe Flutter-Only Integration Rules

- Do not modify `spokenOdessie_backend/` or `spoken-odyssey-web/` under the current `AGENTS.md` constraints.
- For contract mismatches, first get the backend route/response contract approved; a Flutter-only workaround is safe only when an existing documented compatibility endpoint already exists.
- Keep all new integration in Clean Architecture: domain contract, data source/model/repository, Cubit/state, page/widgets.
- Reuse the existing shared UI primitives and the design system in `docs/UI_UX_SYSTEM.md`.
- Do not mark a feature integrated merely because an endpoint constant exists. Require a reachable page/widget, state handling, loading/empty/error/success behavior, and a verified client call.
- Preserve Smart Glasses native SDK behavior and protected native configuration.

## 14. Recommended Verification Checklist

For each parity item:

- [ ] Backend route and HTTP method verified.
- [ ] Web client request body/query/response shape verified.
- [ ] Flutter endpoint path/method/body verified.
- [ ] Flutter model/entity maps the response.
- [ ] Repository/data source exposes the operation.
- [ ] Cubit/state covers loading, empty, error, success, permission/offline where relevant.
- [ ] A reachable Flutter page/sheet/widget exposes the user action.
- [ ] Navigation entry and back behavior are defined.
- [ ] Accessibility and responsive behavior are covered.
- [ ] `flutter analyze` passes.
- [ ] Device/emulator flow verified.

## Conclusion

The Flutter app is not missing the entire product; it has a strong core. The remaining work is concentrated in advanced family collaboration, insights, passkeys/security, push/presence, legacy administration, full commerce, and a few existing contract mismatches. The P0 contract findings should be resolved before attempting to claim web/backend parity.
