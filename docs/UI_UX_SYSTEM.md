# Spoken Odyssey UI/UX System

**Status:** Source of truth for future Flutter UI work  
**Scope:** Flutter client under `lib/` only  
**Last audited:** 2026-09-21  
**Implementation rule:** This document describes the current product and the target consistency rules. It does not authorize broad UI changes by itself.

## 1. Product UI/UX Vision

Spoken Odyssey is a private, family-oriented place to capture, preserve, organize, and revisit life stories. The interface should feel calm enough for reflection, clear enough for repeated recording, and trustworthy enough for personal and family material. The content is the story, voice, image, relationship, or memory; the interface should frame it without competing with it.

The product personality is warm, capable, and quietly modern. It should feel more like a well-kept personal archive than a social feed optimized for noise. Use the existing Outfit typography and purple identity as a recognizable brand anchor, but balance it with generous white surfaces, restrained borders, readable neutral text, and meaningful status colors. The emotional tone should be respectful around memories, direct around security, and reassuring around permissions, uploads, recording, and device connection.

The experience is content-first: titles, speakers, dates, relationships, media, privacy, and family context receive the strongest hierarchy. Decoration, gradients, shadows, and animation are supporting devices only. The design must work for users who may be recording in an emotional moment, managing family history, or using the app while a device is connected. Every important operation needs a visible state, a recovery path, and accessible labels.

## 2. Design Principles

1. **Content first.** Story titles, audio/image/video, people, dates, and privacy are more important than ornamental surfaces.
2. **One primary action per context.** A page may offer secondary actions, but the next meaningful step must be obvious.
3. **Minimal cognitive load.** Prefer familiar controls, short labels, progressive disclosure, and one decision at a time in forms and sheets.
4. **Consistent interaction patterns.** The same action uses the same component, placement, wording, and feedback throughout the client.
5. **Clear hierarchy.** Use type, spacing, and grouping before color or shadows to establish importance.
6. **Progressive disclosure.** Keep advanced controls such as privacy, MFA methods, session management, and device diagnostics available without making the default path dense.
7. **Accessible touch targets.** Interactive targets are at least 48 x 48 logical pixels, including icon buttons, tabs, chips, OTP cells, and navigation items.
8. **Predictable navigation.** Main destinations stay in the existing five-tab shell. Detail, settings, authentication, and device tasks use explicit push navigation or a clearly labeled modal surface.
9. **Meaningful feedback.** Every asynchronous operation communicates loading, completion, failure, and recovery where applicable.
10. **Respectful privacy.** Privacy, family visibility, recording, permissions, and delete actions use plain language and deliberate confirmation.
11. **Content-aware motion.** Animate transitions that explain orientation or state. Do not animate decoration while a user is recording, reading, or completing security steps.
12. **No invented product behavior.** UI documentation and implementation must reflect capabilities present in the Flutter client and its current contracts.

## 3. Design Tokens

These tokens describe the current visual foundation and the consolidation target. Existing branding is preserved; local feature colors should migrate toward these values.

### Colors

| Token | Current value | Use |
|---|---|---|
| Primary | `#5B3EFF` | Main CTA, active navigation, selected controls, links |
| Primary dark | `#421FD2` | Pressed/strong primary state |
| Primary light | `#8672FF` | Supporting emphasis and selected backgrounds |
| Accent | `#7000FF` | Secondary brand emphasis; use sparingly |
| Background | `#FFFFFF` | Main light surface |
| Surface | `#F9FAFC` | Page sections and quiet backgrounds |
| Card | `#FFFFFF` | Framed content on a surface |
| Border | `#E5E7EB` | Dividers, enabled fields, card outlines |
| Text primary | `#111827` | Titles and essential content |
| Text secondary | `#6B7280` | Supporting copy and metadata |
| Text muted | `#9CA3AF` | Placeholder and low-priority metadata |
| Text on primary | `#FFFFFF` | Text/icons on primary fills |
| Success | `#10B981` | Connected, completed, valid, positive status |
| Warning | `#F59E0B` | Attention, connecting, time-sensitive state |
| Error | `#EF4444` | Error, destructive, recording stop state |
| Info | `#2563EB` | Informational state; use with an icon and text |
| Disabled | `#D1D5DB` | Disabled control fill/border; pair with muted text |

The current app also uses local indigo/purple values such as `#4F46E5`, `#4A3AFF`, `#5E4EE8`, and raw red/gray values. These are audit targets: use the semantic tokens above unless a platform state or existing media treatment requires otherwise. Status must never be conveyed by color alone.

### Typography

The current theme uses `GoogleFonts.outfitTextTheme()`. Keep Outfit as the product typeface and move direct `GoogleFonts.outfit` calls toward `Theme.of(context).textTheme` so the system remains centrally adjustable.

| Level | Size | Weight | Line height | Use |
|---|---:|---:|---:|---|
| Display | 32 | 700-800 | 1.15 | Onboarding or rare full-screen product moments |
| Heading 1 | 28 | 700 | 1.2 | Major page title |
| Heading 2 | 22 | 700 | 1.25 | Section/page title |
| Heading 3 | 18 | 600-700 | 1.3 | Card and modal title |
| Body large | 16 | 400 | 1.5 | Introductory or explanatory copy |
| Body | 15 | 400 | 1.45 | Primary content |
| Body small | 13 | 400 | 1.4 | Supporting copy and metadata |
| Caption | 12 | 400-500 | 1.35 | Timestamps, secondary labels |
| Button | 15 | 600 | 1.2 | Button labels |
| Label | 13 | 500-600 | 1.25 | Field labels and compact controls |

Do not use negative letter spacing. Do not use heading sizes as a substitute for spacing or hierarchy. Allow user font scaling and verify long labels at large accessibility text sizes.

### Spacing

Use a 4-point base scale: `XS 4`, `SM 8`, `MD 12`, `LG 16`, `XL 24`, `XXL 32`, `XXXL 40`, `Section 48`.

- `XS`: icon-to-label or badge internals.
- `SM`: compact control gaps and metadata rows.
- `MD`: field gaps, card internals, tab gaps.
- `LG`: standard screen padding and card padding.
- `XL`: modal padding, major content groups.
- `XXL`: page title to first content group.
- `XXXL`: hero/onboarding breathing room.
- `Section`: separation between major page regions.

### Radius

- Small: `8` for fields, compact cards, and chips.
- Medium: `12` for buttons, standard cards, and sheets' internal groups.
- Large: `16` for prominent media/cards and the main bottom sheet surface.
- Full/Pill: `999` for tags, status pills, and segmented controls.

The current app uses 10, 12, 14, 16, 20, and 24 inconsistently. New shared components should use the scale above; existing visual identity should be changed only as part of a focused component migration.

### Elevation

Prefer border plus surface separation. Use elevation 0 for most cards and sheets, a subtle shadow for floating action/navigation surfaces, and a stronger shadow only for a modal or media viewer that must clearly separate from the page. Avoid stacking shadows on cards inside cards.

### Iconography

Use Material rounded/outlined icons consistently with the existing rounded icon language. Default sizes: 20 for inline icons, 24 for icon buttons, 32 for feature icons, and 48 for empty/error illustration icons. Icon buttons remain at least 48 x 48, expose a tooltip where the meaning is not obvious, and include a semantic label. Pair status icons with text. Do not mix custom icon families without a product reason.

## 4. Layout System

- Standard horizontal page padding is `16` on compact content and `24` on forms, recording, and modal surfaces.
- Constrain dense content to approximately 600-720 logical pixels on tablets and larger screens; keep reading and form measure comfortable instead of stretching full width.
- Major sections use `24`-`48` vertical separation. Cards in a list use `12`-`16` gaps.
- App bars use the shared transparent app-bar treatment already present in the main shell, with title and actions aligned to the same 48-pixel grid.
- Bottom actions remain above the safe area and keyboard. A form must scroll when the keyboard appears; the primary action must not be hidden behind it.
- Use `SafeArea` at page boundaries, not repeatedly inside every child.
- Scrollable content owns its refresh behavior. Preserve scroll position for the main tab pages, as the current timeline, family, profile, and discover pages do.
- On small phones, collapse secondary actions into an icon menu or sheet, keep one-column lists, and allow labels to wrap. On large phones and tablets, increase breathing room and use a constrained content column or two-column media grid where the existing feature supports it.

## 5. Navigation System

### Main navigation

`MainScreen` owns the authenticated shell and an `IndexedStack` with five destinations:

1. `TimelinePage` labeled Home.
2. `DiscoverPage` labeled Discover.
3. `RecordStudioPage` reached through the center create action; it is not a bottom-nav item.
4. `FamilyCirclePage` labeled Family.
5. `ProfilePage` labeled Profile.

The center floating add action opens `CreateOptionsModal`, which offers the existing creation paths and can select Voice Studio. Keep this as the singular creation entry point unless a feature has a documented contextual create action.

### Secondary navigation

- Use push navigation for detail pages, notifications, public profiles, settings, albums, and the standalone smart-glasses settings page.
- Use tabs for sibling views within a feature: Timeline uses All Memories, Albums, Milestones, Followers; Family Circle uses Members, Family Tree, Memories, Invitations; Notifications uses its existing filter tabs.
- Use modal bottom sheets for short creation, selection, share, comment, upload, invite, AI Historian, album, and device scan/gallery tasks.
- Use dialogs for blocking confirmation, permission explanation, MFA, and destructive actions requiring immediate attention.
- Use a full-screen page for recording, OTP/password steps, QR scanning, media detail, and complex settings where keyboard, scroll, or device state needs room.
- Back always dismisses the top-most modal/sheet first, then returns to the previous page. Destructive or unsaved work must be confirmed.
- The only named app routes are `/`, `/onboarding`, `/sign-in`, `/sign-up`, `/forgot-password`, `/verify-otp`, `/reset-password`, and `/home`. Feature pages currently use direct `MaterialPageRoute` pushes; future deep-link work should centralize route ownership without changing current contracts.

## 6. Reusable Component System

The current reusable surfaces are feature-local. They are the source material for a shared component layer; do not duplicate them screen by screen.

### Primary button
**Purpose:** The single primary action in a context. **Structure:** Full-width on forms/sheets, intrinsic width in list actions. **Content:** Verb plus object, e.g. `Create account`, `Save changes`, `Sync & Import New Media`. **Spacing:** Minimum height 48, horizontal padding 16-20, medium radius. **Behavior:** Disable while the same operation is loading; show an inline progress indicator without changing button width. **States:** Enabled, pressed, disabled, loading, success where useful. **Accessibility:** Button role, complete label, announced disabled/loading state.

### Secondary, text, and icon buttons
**Purpose:** Non-primary actions or navigation. **Structure:** Outlined secondary for important alternatives, text button for low-emphasis actions, icon button only for a familiar single action. **Behavior:** Never use a text button with a filled background when an outlined/primary component is the intended hierarchy. Tooltips and semantic labels are required for icon-only controls.

### App bar
**Purpose:** Orient and expose global contextual actions. **Structure:** Shared title, optional back affordance, up to three actions. **Behavior:** Main shell app bar can hide on downward scroll as currently implemented; detail pages remain stable. **Accessibility:** Title is the page heading; actions have labels and badges are announced.

### Section header
**Purpose:** Name a content group and expose at most one related action. **Structure:** Heading plus optional supporting text/action. **Spacing:** `XL` above, `MD` below. Avoid putting unrelated actions beside a heading.

### Card / memory card
**Purpose:** Group a discrete memory, person, album, notification, or device status. **Structure:** Surface, content hierarchy, optional media, metadata, actions. **Behavior:** Whole-card tap only when the entire card has one destination; otherwise keep action targets distinct. **States:** Loading placeholder, content, unavailable media, error/retry. **Accessibility:** Announce title, owner/date/privacy, media type, and action count.

### Family member and profile cards
Use the existing family member/profile content hierarchy: avatar, display name, relationship/role, status, then one clear action. Do not bury invite, accept, remove, follow, or open-profile actions in tiny text.

### Input field and search field
**Purpose:** Capture a single value or filter content. **Structure:** Persistent label, optional hint, field, supporting/error text. **Spacing:** `MD` between fields. **Behavior:** Preserve entered values on validation errors; show password visibility as a labeled icon button; debounce search as the timeline currently does. **Accessibility:** Correct keyboard type, autofill hints, error semantics, and visible focus state.

### Tabs, segmented controls, chips, tags, avatar
Use tabs for stable sibling views and segmented controls for a small local mode switch. Chips/tags represent filters or metadata, not primary navigation. Avatars need an image fallback with the person's initials/name. Selected state must use label, contrast, and indicator, not color alone.

### Audio player, media preview, image viewer, upload
Reuse `MemoryCard`, `VideoPlayerWidget`, `FullScreenImageViewer`, and publish/media picker patterns. Controls must expose play/pause, duration/progress, mute/full-screen where available, and failure/retry. Uploads show selected media, progress, cancel/retry, and clear completion.

### Loading, empty, error, success
Use one shared state family with a consistent icon/illustration, short explanation, and one recovery/primary action. Loading preserves layout shape where possible. Empty states explain what is absent and provide the next useful action. Errors state what failed and how to recover. Success feedback is inline or a snackbar/banner, not an unexplained toast.

### Dialog, sheet, snackbar/banner
Dialogs are blocking and short. Sheets are for contextual choices and multi-control tasks. Snackbars confirm a transient result or offer one recovery action; banners are for persistent/in-app notices such as updates. All have safe-area and keyboard handling.

## 7. Content Hierarchy Rules

For every screen, the order is: primary content, supporting context, primary action, secondary actions, then destructive/advanced actions. The primary action must be visible without requiring a user to infer it from an icon. Metadata is visually quieter but remains readable. Destructive actions are separated, use explicit verbs, and require confirmation when the result is irreversible.

For a memory, the hierarchy is title or first meaningful content, speaker/owner and date, media, privacy/family context, then reactions/comments/edit/delete. For a person, it is name/avatar, relationship and identity context, then connection or profile actions. For a device, it is connection status, device name/battery, then capture/import controls. For security, it is current status, the safest next action, and recovery/session controls.

## 8. Screen-by-Screen UI/UX Specification

### Screen: SplashPage

**Purpose:** Initialize the app and decide whether the user is authenticated, has seen onboarding, or needs sign-in.  
**User Goal:** Reach the correct first destination.  
**Entry Points:** Initial `/` route.  
**Exit Points:** `/home`, `/onboarding`, or `/sign-in`.

**Content Hierarchy:** 1. Spoken Odyssey brand mark. 2. Minimal initialization state. 3. No user action unless a failure state is added.

**Layout:** Full-screen branded surface with centered logo/identity and restrained motion. Do not expose backend or Firebase details.  
**Component Usage:** Brand mark, shared loading indicator, optional recoverable initialization state.  
**Primary CTA:** None during normal initialization.  
**Secondary Actions:** A retry action only if initialization can fail visibly.

**States:** Loading; authenticated; first-run onboarding; returning unauthenticated; initialization failure with retry.  
**Interaction:** Wait; do not make the splash a dead-end.  
**Content Rules:** No invented marketing claims or feature list.  
**Accessibility:** Announce app loading status; respect reduced motion.  
**Responsive Behavior:** Center content within safe area on all device sizes.

### Screen: OnboardingPage

**Purpose:** Explain the three verified product promises before first sign-in.  
**User Goal:** Understand capture, pacing, and privacy, then continue.  
**Entry Points:** Splash first-run decision.  
**Exit Points:** Sign in via Skip or final action.

**Content Hierarchy:** 1. Onboarding image. 2. Title: capture life, record at your pace, private by design. 3. Description. 4. Progress and next/skip controls.

**Layout:** Full-screen image with readability overlay, bottom content, progress indicators, and safe-area controls.  
**Component Usage:** Onboarding slide, progress indicator, text button, primary continuation button.  
**Primary CTA:** Continue/finish on the final slide, bottom fixed and full-width where space allows.  
**Secondary Actions:** Skip at top right.

**States:** Slide transition; final slide; image fallback.  
**Interaction:** Swipe horizontally; tap next/finish; skip persists `has_seen_onboarding`.  
**Content Rules:** Keep copy short and promise-based; do not add features not represented in the current three slides.  
**Accessibility:** Slides have meaningful image labels; progress is announced; controls are 48 pixels minimum.  
**Responsive Behavior:** Preserve readable text over images; avoid fixed bottom controls covering content on small phones.

### Screen: SignInPage

**Purpose:** Authenticate an existing user, including optional MFA.  
**User Goal:** Sign in or recover access.  
**Entry Points:** Splash, sign-up completion, password reset completion, logout.  
**Exit Points:** Home, MFA dialog, sign-up, forgot password.

**Content Hierarchy:** 1. Email/password fields. 2. Sign in. 3. Forgot password and create-account paths. 4. Social sign-in controls if shown by the existing lower section.

**Layout:** Branded form with scroll, shared inputs, one primary button, and authentication alternatives.  
**Component Usage:** Auth header, input field, password visibility button, primary button, inline link, MFA dialog.  
**Primary CTA:** `Sign in`, full-width below fields; loading keeps the same button geometry.  
**Secondary Actions:** `Forgot your password?`, `Create Account`, Google/Apple actions if enabled in the existing page.

**States:** Idle, focused, validation error, loading, server/auth error, MFA required, cancelled social sign-in.  
**Interaction:** Submit after validation; open recovery/sign-up; complete MFA without dismissing required verification.  
**Content Rules:** Use `Sign in` consistently; use actionable error text such as invalid credentials or connection failure.  
**Accessibility:** Email keyboard/autofill, password semantics, visible focus, error announcement, labels for visibility and social providers.  
**Responsive Behavior:** Scroll on small screens and keyboard; constrain form width on tablets.

### Screen: SignUpPage

**Purpose:** Create an account and accept terms.  
**User Goal:** Register and enter the authenticated product.  
**Entry Points:** Sign in.  
**Exit Points:** Home or sign in.

**Content Hierarchy:** 1. Email/password/confirmation. 2. Terms consent. 3. Create account. 4. Existing-account path.

**Layout:** Same auth shell as sign-in.  
**Component Usage:** Shared auth form, checkbox with linked terms/privacy, primary button.  
**Primary CTA:** `Create account`.  
**Secondary Actions:** Sign-in link.

**States:** Idle, invalid email, weak/mismatched password, terms unchecked, loading, duplicate account/server error, success.  
**Interaction:** Validate locally, then submit; preserve entered values after recoverable errors.  
**Content Rules:** Align password requirements with actual validation; current code uses six characters here and eight in reset, which is a high-priority consistency finding.  
**Accessibility:** Make the whole consent row understandable to screen readers; do not rely on a tiny checkbox target.  
**Responsive Behavior:** Single-column scrollable form.

### Screen: ForgotPasswordPage

**Purpose:** Start password recovery.  
**User Goal:** Request a verification code/link.  
**Entry Points:** Sign in.  
**Exit Points:** Sign in after request or VerifyOtpPage.

**Content Hierarchy:** 1. Explanation. 2. Email field. 3. Continue.  
**Layout:** Back app bar plus constrained form.  
**Component Usage:** Shared back app bar, input, primary button, snackbar/banner feedback.  
**Primary CTA:** `Continue`.  
**Secondary Actions:** Back.

**States:** Idle, validation, loading, request sent, error.  
**Interaction:** Submit email; show useful recovery feedback.  
**Content Rules:** Avoid promising both a link and a code unless the current backend flow supports both; the current client proceeds to OTP in some paths and needs terminology alignment.  
**Accessibility/Responsive:** Same form standards as sign-in; keyboard-safe scroll.

### Screen: VerifyOtpPage

**Purpose:** Verify a six-digit password-recovery code.  
**User Goal:** Enter and submit the code or resend it after the timer.  
**Entry Points:** Password recovery flow.  
**Exit Points:** ResetPasswordPage or back.

**Content Hierarchy:** 1. Destination email. 2. Six OTP cells. 3. Timer/resend. 4. Verify.  
**Layout:** Back app bar, explanatory copy, six stable cells, bottom action.  
**Component Usage:** OTP input group, timer, primary button.  
**Primary CTA:** `Verify code`.  
**Secondary Actions:** `Resend code` only when enabled; back.

**States:** Empty, partially filled, complete, loading, invalid code, timer active, resend enabled.  
**Interaction:** Advance focus on input, move back on delete, submit at six digits, restart timer on resend.  
**Content Rules:** Use one casing for `code`; never expose token values beyond the necessary flow.  
**Accessibility:** Each cell needs a coherent grouped label; screen readers should hear progress through six digits.  
**Responsive Behavior:** Use flexible cell widths so six fields fit at large text sizes.

### Screen: ResetPasswordPage

**Purpose:** Set a new password after OTP verification.  
**User Goal:** Create a valid password and return to sign in.  
**Entry Points:** Verify OTP.  
**Exit Points:** Sign in after success or back.

**Content Hierarchy:** 1. Requirement copy. 2. New/confirm password. 3. Continue.  
**Layout:** Back app bar and scrollable form.  
**Component Usage:** Password fields, primary button, success feedback.  
**Primary CTA:** `Set password` or `Continue`, choose one label and use it consistently.  
**Secondary Actions:** Back.

**States:** Validation, loading, success, error.  
**Interaction:** Keep the user on the form after an error; redirect only after confirmed success.  
**Content Rules:** Password policy must match sign-up and backend behavior.  
**Accessibility/Responsive:** Same as sign-up; do not use a custom overlay toast when a standard accessible snackbar/banner or success page is sufficient.

### Screen: MainScreen

**Purpose:** Authenticated product shell and primary navigation.  
**User Goal:** Move between memories, discovery, recording, family, and profile.  
**Entry Points:** Authenticated state.  
**Exit Points:** Child destinations, settings, notifications, device settings, logout.

**Content Hierarchy:** 1. Current tab content. 2. Shared app bar title/context actions. 3. Bottom navigation and create action.  
**Layout:** Transparent app shell over the configured background image, indexed five-page stack, global app-bar actions, centered add button, bottom nav.

**Component Usage:** Shared app bar, badge icon button, smart-glasses status, AI Historian action, create action, navigation item.  
**Primary CTA:** Center `+` create action.  
**Secondary Actions:** Notifications, AI Historian, Family invite on Family tab, smart-glasses status.

**States:** Child loading/empty/error; app bar shown/hidden on scroll; unread notification badge; unauthenticated redirect.  
**Interaction:** Tap tabs; scroll hides app bar; tap create to open options; tap global status/actions.  
**Accessibility:** Navigation items need selected semantics and labels; the center action needs a complete label, not only `+`; badges announce counts.  
**Responsive Behavior:** Preserve five destinations and safe-area bottom padding; ensure the center action does not obscure navigation labels.

### Screen: TimelinePage

**Purpose:** Browse the user's memories and related timeline views.  
**User Goal:** Find, view, organize, and create memories.  
**Entry Points:** Home tab; family/discover/profile links may open it with a tab.  
**Exit Points:** Memory detail, album detail, create album, publish wizard, profile/followers.

**Content Hierarchy:** 1. Selected view and memories. 2. Search/filter controls. 3. Memory metadata/media. 4. Create/organize actions.

**Layout:** Segmented local tabs: All Memories, Albums, Milestones, Followers; list/grid modes, search, refresh, memory cards, empty state.  
**Component Usage:** Segmented control, search field, `MemoryCard`, album cards, `CreateAlbumModal`, `FullScreenImageViewer`, comments/reactions where present.  
**Primary CTA:** Contextual `Record`/create memory via the shell or empty state.  
**Secondary Actions:** Search, view toggle, album creation, open detail, follow-related actions.

**States:** Loading, loaded list/grid, empty, search no-results, refresh, network error with retry, media unavailable.  
**Interaction:** Debounced search, pull to refresh, switch tabs/view modes, tap card, react/comment, open media.  
**Content Rules:** Do not mix milestones fallback content with a misleading milestone label; distinguish no milestones from all memories.  
**Accessibility/Responsive:** Cards expose title/date/media type; grid becomes one column on narrow phones; no horizontal overflow in tabs.

### Screen: FeedPage

**Purpose:** Present a profile-oriented memory feed with bio and social context.  
**User Goal:** Browse a person's story content and related stats.  
**Entry Points:** Profile/public profile navigation.  
**Exit Points:** Memory detail, public profile, follow/profile actions.

**Content Hierarchy:** 1. Person identity/bio. 2. Story feed. 3. Stats and social actions.  
**Layout:** Scrollable profile header, bio/stats cards, story cards, empty/loading/error states.  
**Component Usage:** Profile summary, stat card, `MemoryCard`, primary/secondary social buttons.  
**Primary CTA:** Follow/open profile according to current relationship state.  
**Secondary Actions:** Browse stories and memory actions.

**States:** Loading, loaded, empty feed, error, follow loading.  
**Interaction:** Tap story/profile/stat links; follow/unfollow where supported.  
**Content Rules:** Avoid placeholder identity data in a user-facing state; fallback copy must be clearly generic only when data is absent.  
**Accessibility/Responsive:** Identity and follow state announced; cards stack on small screens.

### Screen: MemoryDetailPage

**Purpose:** Read or play one memory with its full context.  
**User Goal:** Consume, react to, comment on, edit, organize, or delete a memory according to permissions.  
**Entry Points:** Timeline, feed, family, album, notifications.  
**Exit Points:** Back, media viewer, comments sheet, album/profile destinations.

**Content Hierarchy:** 1. Title/story content and primary media. 2. Owner/date/privacy. 3. Audio/video/photo controls. 4. Reactions/comments and management actions.  
**Layout:** Stable detail app bar, media/content region, metadata, action bar, comments.  
**Component Usage:** `MemoryCard` patterns, `VideoPlayerWidget`, audio player, `StoryLayersSection`, comments sheet, reaction bar.  
**Primary CTA:** Play/read content; management CTA depends on ownership.  
**Secondary/Destructive:** React, comment, add layer, edit/delete with confirmation.

**States:** Loading, loaded, missing/not authorized, media loading/failure, comment loading/error, delete confirmation/success.  
**Interaction:** Play/pause, full-screen media, comment, reaction, add story layer, edit/delete.  
**Accessibility/Responsive:** Media controls labeled; captions/metadata used when available; content remains readable at large text sizes.

### Screen: DiscoverPage

**Purpose:** Explore public stories and people available through discovery.  
**User Goal:** Find relevant public content and open a person or memory.  
**Entry Points:** Discover tab.  
**Exit Points:** Public profile, memory detail, follow action.

**Content Hierarchy:** 1. Search/filter/discovery context. 2. Results. 3. Public profile/story actions.  
**Layout:** Search/discovery controls, result cards, optional filters and loading pagination/refresh.  
**Component Usage:** Search field, profile/story cards, chips/tabs if already present, empty/error state.  
**Primary CTA:** Open the selected public story/profile.  
**Secondary Actions:** Follow, filter, clear search, retry.

**States:** Initial, loading, loaded, empty/no results, error, follow in progress.  
**Interaction:** Search, filter, tap result, follow/unfollow.  
**Content Rules:** Show only content the current API exposes as discoverable; privacy language must be clear.  
**Accessibility/Responsive:** Search semantics, result count, card labels, one-column narrow layout.

### Screen: RecordStudioPage

**Purpose:** Record a voice story and hand it to the publishing flow.  
**User Goal:** Start, pause/resume, stop, discard, and publish a recording.  
**Entry Points:** Center create action or direct Voice Studio tab state.  
**Exit Points:** Publish wizard, reset/idle, back through shell.

**Content Hierarchy:** 1. Recording status and elapsed time. 2. Waveform. 3. Mic/pause/stop controls. 4. Reset.  
**Layout:** Full-height focused studio with title, timer, waveform, large mic state, and stable controls.  
**Component Usage:** `WaveformVisualizer`, record state, primary recording control, publish sheet.  
**Primary CTA:** `Start recording` when idle; stop/finish when active.  
**Secondary/Destructive:** Pause/resume; `Reset recording` requires confirmation if audio would be lost.

**States:** Idle, recording, paused, stopping, stopped, permission denied, error, publishing.  
**Interaction:** Tap to start; pause/resume; stop opens `PublishWizardModal`; reset clears the current recording.  
**Content Rules:** Use one term consistently: `recording`, not alternating `voice story`/`audio` for the same state.  
**Accessibility:** Announce recording/paused and elapsed time without excessive live updates; controls have labels and haptic/audio alternatives where supported.  
**Responsive Behavior:** Keep mic/control geometry stable; avoid overflow in landscape and with large text.

### Screen: FamilyCirclePage

**Purpose:** Manage family members, family tree, shared memories, and invitations.  
**User Goal:** Understand family relationships, connect members, collaborate on memories, and process invites.  
**Entry Points:** Family tab; notification/profile links.  
**Exit Points:** Member profile, memory detail, QR scanner, invite sheet, publish wizard.

**Content Hierarchy:** 1. Current family tab content. 2. Member/tree/memory/invitation status. 3. Add/invite/approve actions.  
**Layout:** Four tabs: Members, Family Tree, Memories, Invitations; tab content may include filters, cards, tree, approvals, and shared memory creation.  
**Component Usage:** `FamilyTreeWidget`, family member card, invitation card, `InviteMemberModal`, `QRScannerPage`, `MemoryCard`, publish wizard.  
**Primary CTA:** Invite/add member in Members context; create family memory in Memories context.  
**Secondary/Destructive:** Approve/decline/remove with clear confirmation.

**States:** Loading, loaded, no members, no shared memories, pending approvals/invitations, error with retry, permission/role limitation.  
**Interaction:** Switch tabs, search/filter memories, approve/decline, invite, scan QR, open member/memory.  
**Content Rules:** Use `family member`, `invitation`, `approval`, and `shared memory` consistently.  
**Accessibility/Responsive:** Tabs scroll without clipping; tree has an alternate accessible list/summary; badges include counts and meaning.

### Screen: QRScannerPage

**Purpose:** Scan a family invitation QR code.  
**User Goal:** Capture and process an invitation code.  
**Entry Points:** Family invite flow.  
**Exit Points:** Family Circle or prior screen after success/cancel.

**Content Hierarchy:** 1. Camera scanning area. 2. Short instruction. 3. Cancel/back.  
**Layout:** Full-screen scanner with clear framing and permission/error overlay.  
**Component Usage:** `mobile_scanner`, permission state, result dialog/banner.  
**Primary CTA:** Scan is continuous; a confirmation action appears only after a valid result.  
**States:** Camera permission, scanning, valid result, invalid/expired QR, processing, success, retry.  
**Interaction:** Point camera, accept result, cancel.  
**Accessibility/Responsive:** Provide a non-camera invitation-code alternative if supported by the existing flow; announce result and permission state.

### Screen: ProfilePage

**Purpose:** Present the authenticated user's identity, biography, expertise, life motto, stats, memories/albums, and account actions.  
**User Goal:** Understand and manage their public/private identity and navigate to settings.  
**Entry Points:** Profile tab.  
**Exit Points:** Settings, share profile, edit profile, memory/album/follower views, logout.

**Content Hierarchy:** 1. Cover/avatar/name. 2. Bio, profession, location, motto, expertise. 3. Stats and content. 4. Share/settings/logout.  
**Layout:** Cover image with overlapping avatar, profile content, stat cards, content sections, top actions.  
**Component Usage:** Avatar fallback, profile header, stat card, share sheet, edit dialog, settings page.  
**Primary CTA:** Contextual edit/share action; do not let logout compete visually.  
**Secondary/Destructive:** Settings, share, logout confirmation.

**States:** Loading, loaded, missing media fallback, error, save profile, logout confirmation.  
**Interaction:** Edit fields/media, share, open stats/content, logout.  
**Content Rules:** Avoid hard-coded sample names, locations, bios, and mottos as if they were real user data; use neutral empty copy when absent.  
**Accessibility/Responsive:** Cover/avatar relationship remains understandable without visual overlap; settings/logout have semantic labels; content stacks on narrow screens.

### Screen: PublicProfilePage

**Purpose:** View another discoverable person's profile and stories.  
**User Goal:** Learn who the person is, follow if supported, and browse public stories.  
**Entry Points:** Discover, followers, notifications, family links.  
**Exit Points:** Memory detail, follow/unfollow, back.

**Content Hierarchy:** 1. Person identity. 2. Public bio/stats. 3. Public story cards. 4. Follow/share actions.  
**Layout:** Profile header and story sections using public visibility rules.  
**Component Usage:** Profile header/card, follow button, `MemoryCard`, loading/error states.  
**Primary CTA:** Follow/unfollow or open story based on current state.  
**States:** Loading, loaded, not found/private, follow loading/error.  
**Accessibility/Responsive:** Same identity and card requirements as ProfilePage; never expose private content in the UI.

### Screen: AlbumsPage

**Purpose:** Browse and create memory albums.  
**User Goal:** Organize memories into named visual collections.  
**Entry Points:** Timeline Albums tab or other album links.  
**Exit Points:** Album detail, Create Album modal, back.

**Content Hierarchy:** 1. Album grid. 2. Cover/title/count. 3. Create action.  
**Layout:** App bar with add action, two-column grid where space permits, empty state.  
**Component Usage:** Album card, `CreateAlbumModal`, shared empty/error/loading state.  
**Primary CTA:** `Create album` in empty state or app-bar add action.  
**States:** Loading, albums loaded, empty, cover unavailable, error with retry.  
**Interaction:** Tap album; create album; select cover through existing picker.  
**Accessibility/Responsive:** Grid becomes one column where cards would be too narrow; titles/counts are announced.

### Screen: AlbumDetailPage

**Purpose:** View and manage the memories inside one album.  
**User Goal:** Review, add, or remove memories and open their detail.  
**Entry Points:** AlbumsPage, timeline album view.  
**Exit Points:** Memory detail, back, album actions.

**Content Hierarchy:** 1. Album title/cover/context. 2. Memory list/grid. 3. Add/remove actions.  
**Layout:** Detail app bar and memory collection.  
**Component Usage:** `MemoryCard`, album action menu, empty/error/loading state.  
**Primary CTA:** Add memory when empty or when contextual action is available.  
**States:** Loading, populated, empty, error, remove confirmation.  
**Accessibility/Responsive:** Preserve card hierarchy and media labels; avoid action overflow in compact widths.

### Screen: NotificationsPage

**Purpose:** Read and act on application, family, social, and approval notifications.  
**User Goal:** Understand what changed and take the relevant next action.  
**Entry Points:** Main shell notification icon or in-app banner.  
**Exit Points:** Family, profile, memory, approval detail, back.

**Content Hierarchy:** 1. Unread/high-priority items. 2. Filter tabs. 3. Notification context and action.  
**Layout:** App bar, existing filter tabs, notification cards/admin approval cards, read/clear controls.  
**Component Usage:** Notification card, badge, `InAppNotificationBanner`, approval action group, loading/empty/error.  
**Primary CTA:** Action defined by notification type, e.g. review invitation/approval.  
**States:** Loading, empty, unread/read, realtime banner, action loading, action error, retry.  
**Interaction:** Open related destination, mark read, approve/decline where present, filter.  
**Accessibility:** Announce unread count and notification type; actions must state their target.  
**Responsive:** Cards stack actions and wrap text rather than clipping.

### Screen: SettingsPage

**Purpose:** Manage profile details, privacy, notifications, security, active sessions, MFA, smart glasses, and account controls surfaced by the current page.  
**User Goal:** Change preferences or protect/manage the account.  
**Entry Points:** Profile settings action.  
**Exit Points:** Profile, legacy vault, MFA setup, smart-glasses settings, logout/delete flows.

**Content Hierarchy:** 1. Selected settings category. 2. Current values/status. 3. Save/apply action. 4. Advanced/destructive actions separated.  
**Layout:** Current tabbed/sectioned settings experience with profile editing, privacy dropdowns, notification switches, password form, active sessions, MFA, and device entry points.  
**Component Usage:** Shared form fields, switch rows, dropdowns, session cards, `MfaSetupModal`, confirmation dialog, image-source sheet.  
**Primary CTA:** `Save changes` for the active editable section; immediate toggles may save inline and show feedback.  
**States:** Loading profile/settings, dirty form, validation, save success/error, MFA enabled/disabled, sessions loading/empty, logout/delete confirmation.  
**Interaction:** Edit text/media, change privacy, toggle notification preferences, change password, manage sessions, set MFA, open device settings.  
**Content Rules:** Keep privacy, notifications, and security terminology distinct. Never use sample defaults as saved values without explicit data.  
**Accessibility/Responsive:** Labels persist; switches have current state and consequence; long settings sections scroll; keyboard never hides Save.

### Screen: LegacyVaultPage

**Purpose:** Manage the legacy-related feature exposed from settings.  
**User Goal:** View or configure the existing legacy vault capability.  
**Entry Points:** Settings.  
**Exit Points:** Settings/back and any existing vault actions.

**Content Hierarchy:** 1. Vault status/content. 2. Available legacy action. 3. Privacy/confirmation context.  
**Layout:** Dedicated detail page using the shared settings/detail shell.  
**Component Usage:** Shared app bar, card/list, empty/error/loading state, confirmation where destructive.  
**States:** Loading, empty, loaded, error, permission/privacy limitation.  
**Interaction:** Follow the concrete controls already present; do not expose unsupported promises.  
**Accessibility/Responsive:** Explicitly label sensitive content and actions.

### Screen: StoreCatalogPage

**Purpose:** Display the existing store catalog for recording/memory hardware.  
**User Goal:** Browse available products and open the current purchase/action flow.  
**Entry Points:** Existing store navigation only.  
**Exit Points:** Product/action sheet or back.

**Content Hierarchy:** 1. Product name/image. 2. Description and price/details. 3. Product action.  
**Layout:** Catalog list/cards with loading, empty, and error states.  
**Component Usage:** Product card, media fallback, bottom sheet for product action.  
**Primary CTA:** Use the exact existing product action label; do not imply checkout if the current client only presents catalog information.  
**States:** Loading, loaded, empty, error, action loading/success/failure.  
**Accessibility/Responsive:** Product cards expose name, detail, and action; cards stack on narrow screens.

### Screen: SmartGlassesSettingsPage

**Purpose:** Connect, monitor, control, and import media from smart glasses.  
**User Goal:** Pair a device, see connection/battery, capture media, record, and sync imports.  
**Entry Points:** Main-shell status icon, settings, device controls.  
**Exit Points:** Back, scan sheet, gallery sheet, permission dialog, app settings.

**Content Hierarchy:** 1. Connection/device/battery state. 2. Pair/disconnect. 3. Capture controls. 4. Import/gallery.  
**Layout:** Status panel, device controls, recording/capture actions, imported media access. Keep the default state simple for non-technical users.  
**Component Usage:** `SmartGlassesStatusBar`, permission dialog, `SmartGlassesScanSheet`, `SmartGlassesGallerySheet`, media preview/player.  
**Primary CTA:** `Scan & Pair Smart Glasses` when disconnected; `Disconnect Glasses` when connected.  
**States:** Disconnected, scanning, connecting, connected, battery/charging, Bluetooth off, permission required, unavailable, importing/progress/complete/failure, recording.  
**Interaction:** Request permission, scan, connect, disconnect, take photo, toggle video/voice recording, sync/import, open media.  
**Content Rules:** Say `Smart Glasses` consistently; explain Bluetooth, location, and Wi-Fi requirements before system prompts.  
**Accessibility/Responsive:** Status includes text and icon; controls remain reachable while importing; media lists use content labels.

## 9. Feature-Specific UX Rules

### Authentication and MFA
Keep sign-in, sign-up, recovery, OTP, password reset, Google/Apple, and MFA under one auth visual system. The current MFA dialog supports TOTP, passkey tab presentation, and recovery methods; passkey behavior must not be presented as available unless its action is implemented. MFA errors keep the dialog open for retry.

### Profile, family, memories, publishing, albums
Profiles establish identity; memories are the primary content object; albums organize memories; family provides relationship context and shared access. Publishing is a staged flow through `PublishWizardModal`, including audio/image/media selection and fields such as title, mood, privacy, and tags. Keep privacy visible before submission and show upload progress/failure/retry.

### Record Studio and media
The record studio is a focused capture state. Stopping a recording opens publishing; do not silently discard audio. Memory cards support audio through `just_audio`, video through `video_player`, and image preview/full screen. Every media type needs a type label and failure fallback.

### AI Family Historian
`AiHistorianSheet` is a contextual assistant opened from the main shell. Keep it subordinate to the user's memories, show conversational loading/error states, and avoid implying that generated answers are authoritative historical truth. The sheet must remain dismissible and preserve the current context.

### Notifications and realtime feedback
Notifications are actionable records, not decoration. Unread count, in-app banner, filter, read state, and approval actions use shared notification components. Do not stack banners or interrupt recording/forms with low-priority notices.

### Settings, privacy, security, MFA, active sessions
Group profile, privacy, notifications, security, device, and account actions. Explain consequences for visibility and session revocation. Password change, MFA setup, logout, delete, and session removal use explicit confirmation and useful recovery messages.

### Smart Glasses
The current client supports SDK initialization, device discovery, Bluetooth/location/nearby Wi-Fi permissions, connection persistence, battery events, photo/video/voice controls, and Wi-Fi import events. Treat device state as a state machine and always provide the next recovery action for permission required, Bluetooth off, no device found, failed connection, or failed transfer.

## 10. Forms & Input UX

- Standard field height is at least 48, with persistent labels and `MD` field gaps.
- Labels describe the value; placeholders show an example only, never the only label.
- On focus, use the primary border and preserve contrast. On error, pair border/icon with an inline human-readable message.
- Validation happens at the smallest useful scope and again before submit. Preserve values after errors.
- Password fields have visibility toggles with semantic labels. Password policy is centralized and identical across sign-up, reset, and change-password flows.
- OTP uses one grouped accessible control with six stable visual cells, numeric keyboard, auto-advance, delete-back behavior, timer, and resend state.
- Search fields show clear/filter affordances and debounce network searches. Empty query restores the unfiltered state.
- Date/time selection uses platform-appropriate pickers and displays the chosen value in a readable format.
- Media selection states are: before selection, selected preview, uploading, uploaded, failed with retry, and remove/replace confirmation.
- Form lifecycle: **Before input → Focused → Filled → Error → Disabled → Success**. Each state has visible styling and a semantic announcement where appropriate.

## 11. Loading / Empty / Error / Success System

### Loading
Preserve the final layout shape when possible. Use a centered progress indicator only for a whole-page load; use inline indicators for cards, buttons, imports, and saves. Disable only the action currently in progress.

### Empty
State what is absent, why it may be absent, and the next useful action. Examples already present include no albums and no imported glasses media. Keep empty copy specific: `No albums yet. Create an album to organize your memories.`

### Error
Say what failed in plain language, preserve user input, and expose `Retry`, `Try again`, `Open Settings`, or another concrete recovery. Avoid `Something went wrong` as the only message. Server and network errors should use the existing parsed messages where they are actionable.

### Success
Use inline confirmation for saves/uploads, a snackbar/banner for transient completion, or a destination transition for completed auth. Do not use custom overlay toasts that are hard for screen readers to discover.

### Offline and permissions
The current client has network failure handling and device permission/Bluetooth states. Offline or permission messaging must say what can still be done and how to restore access. Do not force sign-out for ordinary forbidden business responses; the API client correctly distinguishes 401 from 403 and the UI should preserve that behavior.

## 12. Dialog & Bottom Sheet Rules

- **Dialog:** MFA, permission explanation, destructive confirmation, or a short blocking decision.
- **Bottom sheet:** Create options, publish wizard, invite, comments, album creation, image source choice, AI Historian, device scan/gallery, and other contextual multi-control tasks.
- **Full-screen:** Recording, OTP/password recovery, QR scanner, complex detail, or settings requiring sustained reading/input.
- **Inline:** Read state, small validation, non-destructive status, and lightweight permission guidance.

Sheets use a shared top handle, title, close affordance, safe-area padding, keyboard-aware scrolling, and a predictable maximum height. Dialogs have one clear primary action and a visible cancel path. Destructive actions name the object and consequence, e.g. `Remove this session?` rather than `Are you sure?`.

## 13. Media UX

- Image previews show a stable aspect ratio, loading placeholder, unavailable fallback, and full-screen viewer where supported.
- Audio recording uses the Record Studio state machine. Playback exposes play/pause, progress, duration, and failure/retry.
- Video uses the shared video player with loading, playback, error, and full-screen behavior.
- Uploads show selected item(s), progress/status, retry, cancel where safe, and completion. Do not close the publishing surface while an upload is unresolved without confirmation.
- Delete/remove/replace actions are explicit and confirmed when data loss is possible.
- Captions, title, date, owner, privacy, and media type remain visible or available as accessible metadata.

## 14. Smart Glasses UX

The device flow is: explain permissions → request permission → scan → show discovered device → connect → show connected/battery state → capture or record → import with progress → show gallery/media result. For each failure, expose one next action:

- Device discovery: `Scan & Pair Smart Glasses` and a no-device explanation.
- Permission required: explain Bluetooth/location/nearby Wi-Fi and offer app settings.
- Bluetooth off: explain and offer the platform enable/settings action.
- Connecting: show progress and allow cancellation/back where supported.
- Connected: show name, connection text, battery, charging, and disconnect.
- Recording: show active type and stop action; do not hide active state in a badge.
- Import: show current file/progress/status, completion, failure reason, and retry.
- Device unavailable: preserve the page and offer scan/retry rather than silently failing.

## 15. Accessibility

- Meet WCAG-oriented contrast targets for text and controls; validate primary purple on white and white text on purple in actual rendered states.
- Minimum touch target is 48 x 48 logical pixels.
- Support text scaling without clipping, overlap, or loss of action labels.
- Every icon-only action has a semantic label and tooltip where appropriate.
- Maintain logical focus order: title → primary content → primary action → secondary actions.
- Use `Semantics` for memory/media type, recording state, device connection, notification unread count, and tab selection.
- Announce validation, loading completion, errors, and permission changes. Do not communicate status through color alone.
- Respect reduced-motion preferences for onboarding, app-bar, waveform, and transitions. Recording feedback may use stable visual/audio cues without decorative motion.
- Keyboard-safe layouts scroll focused fields into view. External keyboard navigation must not trap focus in dialogs/sheets.

## 16. Responsive Design

Use these practical breakpoints: compact phone below 360 logical pixels wide, phone 360-599, large phone/small tablet 600-839, tablet 840+. These are layout guidance, not a reason to alter feature behavior.

- Compact: one column, wrapped labels, scrollable tabs, no fixed-width six-cell/CTA assumptions.
- Phone: current layouts with 16-24 padding and stable 48-pixel controls.
- Large phone: increase section spacing modestly and allow media grids where content remains legible.
- Tablet: constrain forms and reading content, use two-column album/media grids where supported, and keep navigation semantics clear rather than stretching cards.
- Orientation: recording and media viewing may benefit from landscape but must remain usable in portrait; no critical action may be available only in one orientation.
- Safe area, keyboard, and bottom navigation must be tested with notches, home indicators, and large text.

## 17. Animation & Motion

Use 150-250ms for local control/state changes, 250-350ms for page/sheet transitions, and up to 500ms only for onboarding or a meaningful first-load transition already present. Motion should communicate selection, navigation, loading progress, recording state, or media transition. Avoid animated gradients, repeated pulses, or motion behind text/content. Respect reduced motion and never make a user wait for a decorative animation before an action is available.

## 18. UX Anti-Patterns

- Random spacing or one-off paddings for equivalent controls.
- Multiple visual primary buttons in one context.
- Different purple, red, gray, radius, or button treatments for the same semantic action.
- Important actions hidden behind unlabeled icons or scroll positions.
- Dialogs used for content that can be inline.
- Tiny GestureDetector targets instead of semantic buttons.
- Cards nested inside cards without a clear boundary.
- Placeholder/sample profile data presented as real user content.
- A generic error with no recovery.
- Loading indicators that shift the layout or leave buttons active.
- Status communicated by color only.
- Password requirements that differ between registration, reset, and change-password.
- Different labels for the same concept: `Sign in`/`Log in`, `Smart Glasses`/`Glasses`, `Resend Code`/`Resend code`.
- Feature pages that introduce a new navigation pattern when an existing shell, tab, sheet, or detail page can be reused.

## 19. Terminology / Content Guidelines

| Preferred term | Avoid |
|---|---|
| Sign in | Log in, Login |
| Create account | Register, Sign up as a button label |
| Memory | Story, post, entry when referring to the same object |
| Voice Studio | Record screen, Audio page |
| Record a memory | Make a recording, Capture audio |
| Smart Glasses | Glasses, smart device in user-facing copy |
| Family member | Contact, connection when a family relationship is meant |
| Invitation | Invite request, join notice |
| Album | Collection when the product means Album |
| Verification code | OTP, code in user-facing explanatory copy |
| Password reset | Password recovery when naming the completed action |
| Sync and import | Download media, transfer files when addressing users |

Button labels use a verb and object: `Save changes`, `Create album`, `Invite member`, `Retry import`, `Allow access`, `Disconnect Smart Glasses`. Empty states describe the absence without blame. Errors name the failed operation and recovery. Delete confirmations name the object and consequence. Permission copy explains why access is needed before the system prompt.

## 20. UI/UX Technical Architecture

Keep the existing Clean Architecture and `flutter_bloc`/GetIt boundaries. The recommended UI ownership is:

- `lib/core/theme/app_theme.dart`: ThemeData, text styles, component themes, focus/disabled states.
- `lib/core/constants/app_colors.dart`: semantic colors and gradients that remain justified.
- New or consolidated `lib/core/theme/design_tokens.dart` only if token values need typed spacing/radius/elevation constants; avoid duplicating `AppColors`.
- `lib/core/widgets/`: shared app bar, buttons, fields, cards, state views, dialogs, sheets, media controls, and accessibility helpers.
- `lib/features/<feature>/presentation/widgets/`: feature-specific composition using shared primitives.
- `lib/features/<feature>/presentation/pages/`: screen layout and navigation orchestration.
- Existing Cubits remain owners of async state; pages render explicit loading/empty/error/success states and do not move business logic into widgets.
- `main.dart` remains the app composition/root routing owner until a focused navigation change is approved.

Existing reuse candidates: `MemoryCard`, `VideoPlayerWidget`, `WaveformVisualizer`, `FamilyTreeWidget`, `SmartGlassesStatusBar`, `SmartGlassesScanSheet`, `SmartGlassesGallerySheet`, `PublishWizardModal`, `CreateOptionsModal`, `MfaVerificationDialog`, `MfaSetupModal`, `InAppNotificationBanner`, `FullScreenImageViewer`, `CommentsBottomSheet`, and `ShareProfileModal`.

The first shared primitives to add or consolidate are `AppButton` variants, `AppTextField`, `AppIconButton`, `AppAppBar`, `SectionHeader`, `AsyncStateView`, `EmptyState`, `ErrorState`, `ConfirmationDialog`, `AppBottomSheetScaffold`, `StatusBadge`, `Avatar`, and media control primitives. Improve existing feature widgets into these primitives before creating parallel replacements.

### Implemented Phase 1 foundation

The first implementation slice now exists in the Flutter client:

- `lib/core/theme/design_tokens.dart` owns spacing, radius, control dimensions, and the shared floating shadow.
- `lib/core/widgets/app_ui.dart` provides `AppButton`, `AppTextField`, `AppIconButton`, and `AppFeedback`.
- `AppTheme` now supplies shared text, input, button, checkbox, switch, snackbar, dialog, and bottom-sheet states.
- Authentication screens use shared fields/buttons, accessible password visibility controls, consistent recovery wording, OTP semantics, and standard success feedback.
- MFA exposes only the currently implemented TOTP/recovery actions; the non-functional passkey action is not presented as usable.
- Profile empty values no longer render sample identity content and profile load errors expose retry.
- Record Studio controls expose semantics and confirm destructive recording reset.
- Publish flow reports recoverable failure, prevents unsupported empty voice/visual capture submission, and no longer presents placeholder voice-capture copy.
- Smart Glasses settings exposes disconnected, scanning, connecting, permission-required, Bluetooth-off, connected, and unavailable states with next-step guidance.
- Timeline and Discover inner tabs use the shared accessible segmented control; milestone and discovery empty/error states are explicit and recoverable.
- Main shell actions, Profile cover actions, Album actions, Notifications/Family retry actions, and Smart Glasses sheet actions use stable labeled touch targets.
- Public Profile and Profile surfaces no longer present hard-coded sample identities or showcase counts when API data is absent.

These changes preserve Cubit, repository, API, media SDK, and navigation contracts. The remaining shared primitives and screen migrations in the roadmap are still planned work, not completed standards.

## 21. Current UI/UX Audit

| Screen/area | Current issue | Severity | Recommended direction | Reusable component |
|---|---|---|---|---|
| Global theme | Theme exists, but many pages bypass it with direct Outfit styles and raw colors | High | Route text/color/button styling through theme and semantic tokens | ThemeData, AppButton, AppTextField |
| Main shell | Custom GestureDetector nav items and center FAB need stronger semantics and shared sizing | High | Use semantic navigation/button primitives while preserving five-tab behavior | AppNavigationBar, AppIconButton |
| Auth forms | Sign-up, reset, and change-password rules/labels are inconsistent | Critical | Centralize password policy and auth form components | AuthField, OTPInput, AppButton |
| Auth feedback | Snackbars and a custom password overlay toast vary in accessibility and wording | High | Use shared feedback with recovery and screen-reader support | AppFeedback, SuccessBanner |
| Auth MFA | MFA dialog uses local colors, raw TextStyle, and a passkey tab whose behavior is not evident in the inspected client | High | Standardize dialog and make only implemented methods actionable | ConfirmationDialog, SegmentedControl |
| Timeline | Local segmented control/colors and several state/view modes are embedded in a large page | High | Extract shared tabs/search/state/card composition | SegmentedControl, SearchField, AsyncStateView |
| Memory media | Audio/video/image controls are split across memory widgets and pages | High | Consolidate media controls and failure/retry semantics | AudioPlayer, VideoPlayer, MediaViewer |
| Publish wizard | The wizard contains a visible placeholder for voice recording flow and form fields with local styling | Critical | Complete or clearly omit unsupported step; standardize staged form/upload state | BottomSheetScaffold, FormSection, UploadField |
| Record Studio | Strong focused flow, but uses raw gestures, raw colors, and no visible permission state in the page | High | Keep state machine, add semantic controls, permission/error/recovery states | RecordControl, AsyncFeedback |
| Family Circle | Four-tab family surface is feature-rich but dense; error/retry and invite patterns are local | High | Preserve tabs, simplify hierarchy, standardize member/invitation cards | TabBar, FamilyMemberCard, InvitationCard |
| Profile | Uses hard-coded example fallback identity/content and local decorative styling | Critical | Use explicit empty values and shared profile/header/stat components | ProfileHeader, StatCard, Avatar |
| Settings | Broad settings page combines profile, privacy, notifications, security, sessions, MFA, and devices with local controls | High | Group sections, persist shared field/switch/dialog patterns, keep security actions explicit | SettingsSection, SwitchRow, FormField |
| Albums | Album cards and empty/error states are locally styled and error lacks a retry action | Medium | Reuse album card and standard async state | AlbumCard, AsyncStateView |
| Notifications | Many local snackbars/cards and multiple action types increase consistency risk | High | Standardize notification card, action group, badge, and feedback | NotificationCard, Badge, AppFeedback |
| Smart glasses | Device UI uses a second indigo palette and several custom sheets/dialogs | High | Map all states to semantic device status components and shared sheet/dialog primitives | DeviceStatusCard, DeviceSheet |
| Accessibility | Numerous GestureDetector/text actions, custom badges, and icon-only controls need semantic audit | Critical | Add semantics and 48-pixel targets systematically | AccessibleAction, AppIconButton |
| Responsive behavior | Fixed OTP cells, grids, sheets, and dense tabs need small-width/large-text testing | High | Add responsive constraints and overflow tests | ResponsiveLayout, AdaptiveGrid |
| Documentation | No centralized UI/UX source of truth existed before this file | High | Keep this document current with approved component and terminology decisions | This document |

## 22. Screen Relationship Map

| Screen | User goal | Next action | Destination |
|---|---|---|---|
| Splash | Determine app entry state | Wait for auth/onboarding decision | Home, Onboarding, or Sign in |
| Onboarding | Understand product promise | Finish or skip | Sign in |
| Sign in | Authenticate | Submit credentials or choose recovery/MFA | Home, MFA dialog, Forgot password, Sign up |
| Sign up | Create account | Accept terms and submit | Home |
| Forgot password | Start recovery | Submit email | Verify OTP or Sign in feedback |
| Verify OTP | Confirm recovery code | Verify or resend | Reset password |
| Reset password | Set new password | Submit valid password | Sign in |
| Home/Timeline | Browse memories | Open, search, organize, create | Memory detail, Album detail, Record Studio, Family/Profile links |
| Discover | Find public content/people | Open result or follow | Public profile or Memory detail |
| Record Studio | Capture a voice story | Stop and publish | Publish wizard |
| Publish wizard | Add title/media/privacy and publish | Submit | Timeline, family memory context, or current modal result |
| Family Circle | Manage family and shared memories | Invite, scan, approve, open content | Invite sheet, QR scanner, member/profile, Memory detail |
| Profile | Review identity/content | Edit/share/settings/logout | Edit dialog, share sheet, Settings, Sign in |
| Public profile | View another person | Follow or open story | Discover, Memory detail |
| Albums | Organize memories | Create/open album | Create album sheet or Album detail |
| Album detail | Review album memories | Open/add/remove | Memory detail or Albums |
| Notifications | Respond to updates | Open related item or act | Family, Profile, Memory detail, approval flow |
| Settings | Manage account/preferences/security | Save, configure, review sessions | Profile, MFA sheet, Legacy Vault, Smart Glasses |
| Legacy Vault | Manage legacy feature | Use current vault action | Legacy Vault result or Settings |
| Smart Glasses | Connect and import/capture | Permission, scan, connect, import | Scan sheet, Gallery sheet, media result |
| Store catalog | Browse existing products | Open product action | Product sheet or back |
| AI Historian sheet | Ask about recorded memories/family history | Submit question | Answer in sheet or retry |

### Important verified flows

- **New user:** Splash → Onboarding → Sign in → Sign up → Home.
- **Returning user:** Splash → Home when saved user exists, otherwise Sign in.
- **Password recovery:** Sign in → Forgot password → Verify OTP → Reset password → Sign in.
- **MFA sign-in:** Sign in → MFA dialog → authenticated Home, or retry in dialog.
- **Create voice memory:** Home create action → Record Studio → Publish wizard → Timeline/family context.
- **Organize memory:** Timeline → Albums → Album detail → Memory detail.
- **Family interaction:** Family → Members/Tree/Memories/Invitations → invite, QR scan, approval, profile, or memory.
- **Media:** Publish wizard or Smart Glasses gallery → preview/playback → memory/publish context.
- **Security:** Profile → Settings → password/MFA/active sessions/privacy/notifications → confirmation and feedback.
- **Smart glasses:** Status/settings → permission → scan → connect → capture/import → gallery/media.

## 23. UI/UX Consistency Checklist

- [ ] Screen has one visible primary action.
- [ ] Correct semantic color and typography token is used.
- [ ] Spacing follows the 4-point scale.
- [ ] Equivalent actions use the same button/control component.
- [ ] Header and back behavior match the navigation level.
- [ ] Loading state preserves layout and disables only relevant actions.
- [ ] Empty state explains absence and offers a useful next action.
- [ ] Error state names the failure and offers recovery.
- [ ] Success state is visible and accessible.
- [ ] Destructive actions are explicit and confirmed when needed.
- [ ] All icon-only actions have labels/tooltips.
- [ ] Touch targets are at least 48 x 48.
- [ ] Text scales without clipping or overlap.
- [ ] Keyboard does not hide the focused field or primary action.
- [ ] Media has loading, failure, retry, and metadata states.
- [ ] Permissions explain why access is needed before prompting.
- [ ] No status depends on color alone.
- [ ] No duplicate component was introduced where an existing one could be improved.
- [ ] Navigation destination and back stack are predictable.
- [ ] Small phone, large text, tablet, and orientation behavior was checked.
- [ ] Feature terminology matches Section 19.
- [ ] No unsupported feature, API, or business behavior was invented.

## 24. Implementation Roadmap

### Phase 1 — Critical UX Problems

1. Centralize and reconcile password policy, auth labels, OTP semantics, and recovery feedback.
2. Remove or clearly mark sample profile defaults and placeholder publish behavior.
3. Add explicit loading, empty, error, retry, permission, and success states to high-risk flows: recording, publishing, media upload, notifications, settings, and smart glasses.
4. Audit semantic labels and 48-pixel targets for navigation, GestureDetector actions, icon controls, OTP, media, and device flows.

### Phase 2 — Design System Consistency

1. Move direct text/color/button styling toward `AppTheme` and semantic tokens.
2. Consolidate `AppButton`, `AppTextField`, `AppIconButton`, `AppAppBar`, segmented controls, state views, dialogs, and sheet scaffolding.
3. Standardize radius, border, elevation, feedback, status badges, avatars, cards, and form spacing.
4. Replace local smart-glasses/auth/device colors with semantic states while preserving brand identity.

### Phase 3 — Screen Refinement

1. Refine Timeline, Family, Profile, Settings, Notifications, Albums, and Discover using the shared primitives.
2. Improve memory publishing and media playback around progress, privacy, metadata, and recovery.
3. Keep the five-destination shell and existing business flows stable while improving hierarchy and discoverability.

### Phase 4 — Accessibility & Responsive Improvements

1. Test compact phones, large text, keyboard, safe areas, landscape, and tablets.
2. Add semantics and screen-reader announcements for state changes, badges, media, recording, family tree, and device connection.
3. Add reduced-motion behavior and verify contrast in all semantic states.

### Phase 5 — Final Polish

1. Tune motion durations and transitions after behavior is stable.
2. Remove remaining one-off styles and duplicated wording.
3. Add focused widget/golden/accessibility tests for shared components and the highest-risk flows.
4. Re-audit this document against the codebase whenever screens, routes, or feature contracts change.

## Scope and constraints

- Do not modify backend code under `spokenOdessie_backend/`.
- Do not modify `spoken-odyssey-web/` or root web configuration.
- Do not change native bundle identifiers, provisioning, Firebase credentials, or protected native release configuration.
- Do not change APIs, database structure, or business behavior as part of a visual consistency pass.
- This specification documents the Flutter client observed in `lib/`; it does not claim capabilities that were not found in the inspected client.
