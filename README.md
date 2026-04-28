# Spoken Odyssey App Flow

Ye app professionally tab lagegi jab iska main journey `story capture -> organize -> share -> preserve` ho.

## Status Legend
- `[Done]` complete and already reflected in current code
- `[Partial]` kuch hissa implemented hai, lekin flow abhi complete nahi
- `[Pending]` abhi banana baqi hai

## Audit Snapshot
**What is solid right now**
- `[Done]` Firebase auth, biometric login foundation, splash/onboarding/auth entry
- `[Done]` Home, Discover, Albums, Family, and Settings major UI flows rebuilt
- `[Done]` app-side `Record Story` composer with voice/text/photo/video entry points
- `[Done]` albums backend create/list flow with MongoDB + optional S3 cover upload
- `[Done]` MongoDB-backed profile completion gate and one-time onboarding handoff
- `[Done]` persistent light/dark theme and responsive cleanup across major screens

**What works but is not fully product-complete**
- `[Done]` memory creation flow is now backed by MongoDB APIs and refreshes Home from backend state after save
- `[Partial]` family flow is dynamic in-app, but not yet backed by real APIs
- `[Partial]` profile/onboarding persistence is now backed by MongoDB, but full account-management surface is not complete yet
- `[Partial]` album detail exists, and published memories can now attach to selected albums, but full CRUD and in-album management actions are still missing
- `[Partial]` backend auth/user foundation exists, but most domain modules are not built yet

**What remains next**
- `[Pending]` family/settings persistence APIs
- `[Pending]` albums edit/delete/add-memory actions
- `[Pending]` production-grade media strategy, retries, and deeper backend hardening

## 1. App Entry
**Goal**
- Splash
- Session check
- If first time: Onboarding
- If signed out: Login / Signup
- If signed in but profile incomplete: Complete Profile
- Else: Main App

**Status**
- `[Done]` Splash, session check, auth routing, and main app entry implemented hain.
- `[Done]` authenticated users now enter `MainTabScreen` on `Home` by default.
- `[Done]` signed-in users are now routed through a MongoDB-backed profile-completion gate before entering the main app.

## 2. Onboarding
**Goal**
- 3 slides se zyada nahi
- Record your story
- Organize into albums
- Share with family privately
- Last CTA:
- Create Account
- secondary: Sign In

**Status**
- `[Done]` onboarding/auth entry exists with 3 focused slides aligned to story capture, albums, and private family sharing.
- `[Done]` one-time onboarding completion is now persisted locally before login/signup flow.
- `[Partial]` onboarding visuals can still be polished further, but the product flow is now complete.

## 3. Auth Flow
**Goal**
- Signup / Login with Firebase Auth
- Firebase token backend ko bhejo
- Backend MongoDB me user sync kare
- First manual login ke baad biometric enable prompt
- Then app me enter

**Architecture**
- Firebase ka role: `auth only`
- Backend/MongoDB ka role:
- user profile
- albums
- memories
- family access
- settings

**Status**
- `[Done]` Firebase Auth integrated hai.
- `[Done]` biometric flow/controller layer present hai, including a post-manual-login prompt to enable biometrics on supported devices.
- `[Done]` Firebase token backend ko jata hai, MongoDB user sync/profile fetch hoti hai, and users are routed onward through the correct post-auth path.

## 4. First-Time Setup
**Goal**
- Login ke baad direct tabs par mat bhejo
- Show:
- Profile photo
- Display name
- Short bio
- Default privacy
- Invite family later / skip
- CTA:
- Start Recording

**Status**
- `[Done]` dedicated first-time setup gate after signup/login now exists.
- `[Done]` users can complete display name, short bio, location, and default privacy before entering the app.
- `[Partial]` profile photo during first-time setup is still deferred to later profile editing/settings flow.

## 5. Main Navigation
**Goal**
- Home
- Record
- Albums
- Family
- More
- Discover ko main tab se hata kar Home ke andar section ya secondary page banao

**Reason**
- app ka core creation hai, discovery nahi

**Status**
- `[Partial]` current tabs: Home, Discover, Albums, Family, More.
- `[Partial]` Discover ko secondary experience ki tarah improve kiya gaya hai, lekin abhi bhi dedicated tab ke roop me present hai.
- `[Pending]` `Record` tab / creation-first nav structure abhi introduce karni baqi hai.

## 6. Home Screen
**Goal**
- Welcome header
- Continue last draft
- Quick actions:
- Voice Story
- Write Story
- Photo Story
- Video Story
- Recent memories
- Recent albums
- Legacy / activity insights
- Primary CTA always visible:
- Record Story

**Status**
- `[Done]` Home screen dashboard-style rebuild ho chuki hai.
- `[Done]` quick actions, recent albums, insights, hero CTA, and animated archive header implemented hain.
- `[Done]` quick actions are now creation-first shortcuts aligned with the current memory flow.
- `[Done]` recent memories and latest draft are now loaded from backend-backed memory data instead of static local story cards.

## 7. Discover Screen
**Goal**
- Search across public archives
- Featured people and latest stories
- Theme + era + sort filters
- Follow/unfollow logic
- Person detail drill-down

**Status**
- `[Done]` Discover screen ko dynamic logic ke sath rebuild kiya gaya hai.
- `[Done]` search, filters, sorting, follow state, and person detail navigation implemented hain.
- `[Done]` person detail ab same discover dataset se driven hai.
- `[Pending]` real backend-powered public discovery feed future phase me aa sakti hai.

## 8. Core Memory Flow
**Goal**
- Tap Record
- Choose:
- Voice
- Text
- Photo + text
- Video
- Create memory
- Add title
- Add tags / mood / date
- Choose privacy
- Add to existing album or create new album
- Save draft or publish
- Confirmation screen

**Status**
- `[Done]` multi-step `Record Story` composer implement kiya gaya hai with format selection, title/body capture, mood/tags/date, privacy, album selection, draft/publish actions, and confirmation state.
- `[Done]` Home screen quick actions ko creation-first shortcuts me convert kiya gaya hai for voice, text, photo story, and video story entry points.
- `[Done]` voice recording, photo picking, and video selection app-side flow me wired hain.
- `[Done]` memory flow now saves through backend APIs into MongoDB instead of only updating local app state.
- `[Done]` Home recent memories and draft resume state now refresh from backend-truth after each save.
- `[Done]` published memories can now be linked to a selected album in backend data.

## 9. Albums Flow
**Goal**
- Albums list
- Empty state with Create Album
- Create album dialog
- Optional cover upload
- Save title + subtitle
- Open album detail
- Add memories inside album
- Edit album
- Delete album

**Professional Rule**
- album sirf cover card nahi, memory container hona chahiye

**Status**
- `[Done]` albums list ko static cards se nikaal kar dynamic bana diya gaya.
- `[Done]` create album dialog with animation implemented hai.
- `[Done]` title, subtitle, and cover image flow added hai.
- `[Done]` MongoDB + S3 based save architecture wire ki gayi hai.
- `[Done]` albums active product flow ab cloud-only hai; local-only album creation active UX se hata di gayi hai.
- `[Done]` albums list ko editorial timeline style me reshape kiya gaya hai.
- `[Done]` album cards ab month-grouped visual archive presentation dikhati hain.
- `[Done]` published memories selected with a cloud album now attach to that album in backend data.
- `[Done]` cloud-first albums UX ke liye separate plan file add ki gayi hai:
- `ALBUMS_MEMORIES_UX_PLAN.md`

## 10. Album Detail Flow
**Goal**
- Cover
- Title / subtitle
- Stats:
- memories count
- created date
- privacy
- Memory list
- FAB:
- Add Memory
- Actions:
- edit cover
- edit info
- share
- delete

**Status**
- `[Done]` album detail now shows cover, title, subtitle, and memory count.
- `[Done]` album detail app bar now includes a direct add-memory action.
- `[Done]` add-memory action opens a bottom sheet with photo, video, voice, and text options.
- `[Done]` selected format opens the composer with the album preselected.
- `[Done]` published memories are merged back into album detail immediately after creation.
- `[Done]` album memories now render in a month-grouped gallery style.
- `[Done]` memory tiles include media preview, title, description, and date-time context.
- `[Done]` delete-memory action is now available from each memory tile and removes the memory from both archive and album snapshot.
- `[Partial]` album-level edit/share/delete actions are still not complete.

## 11. Family Flow
**Goal**
- Invite family member
- Assign role:
- viewer
- contributor
- legacy custodian
- Choose access:
- private
- selected albums
- full family circle
- Shared memories
- Legacy access settings

**Status**
- `[Done]` family screen ko dynamic local-state flow me convert kiya gaya hai.
- `[Done]` invite family member flow with relationship, role, and access selection implemented hai.
- `[Done]` manage access flow with viewer / contributor / legacy custodian roles implemented hai.
- `[Done]` private / selected albums / full family circle access modes implemented hain.
- `[Done]` shared memories section and member-specific shared preview implemented hai.
- `[Done]` legacy access settings flow with trusted custodian and activation rule implemented hai.
- `[Partial]` current family flow rich and interactive hai, lekin local-state based hai.
- `[Pending]` backend persistence / real family APIs abhi banana baqi hain.

## 12. More / Settings Flow
**Goal**
- Profile
- Privacy
- Security
- Biometrics
- Notifications
- Data export
- Help
- Logout
- Delete account

**Status**
- `[Done]` profile screen ko dynamic live-preview flow ke sath polish kiya gaya hai.
- `[Done]` profile photo / cover selection, expertise editing, and save flow implemented hain.
- `[Done]` privacy selectors now interactive hain.
- `[Done]` light / dark theme toggle settings menu me add kiya gaya hai with persistent app-level preference.
- `[Done]` app shell, bottom navigation, shared text fields, and key detail screens ko theme-aware bana diya gaya hai.
- `[Done]` `DevicePreview` app bootstrap se remove kar diya gaya hai; app now runs directly with production-style startup flow.
- `[Done]` visual insights screen ke responsive overflow fixes land kiye gaye hain for smaller devices.
- `[Done]` settings/profile save flow is now connected to MongoDB-backed profile updates.
- `[Pending]` notifications
- `[Pending]` data export
- `[Pending]` help / support
- `[Pending]` delete account
- `[Pending]` full backend persistence and account-management workflow baqi hai.

## 13. Backend Flow
**Goal**
- Firebase token verify
- MongoDB user fetch/sync
- Albums/memories save in MongoDB
- Media upload to S3
- S3 key save in MongoDB
- Signed URL return to app

**Status**
- `[Done]` Node/Express modular backend bootstrapped hai with MongoDB connect, auth routes, and albums routes.
- `[Done]` albums module create/list APIs MongoDB ke sath connected hain.
- `[Done]` S3 upload service configured hai for album covers.
- `[Done]` Firebase Admin/backend auth verification structure present hai.
- `[Partial]` `socket.io` server initialize hota hai, but app-specific real-time events abhi wire nahi hue.
- `[Done]` user model/auth sync path present hai with profile update route for onboarding/settings persistence.
- `[Pending]` memories module
- `[Pending]` family module
- `[Pending]` settings/profile persistence module
- `[Pending]` notifications / real-time domain events
- `[Pending]` full signed URL media strategy
- `[Pending]` production-grade end-to-end hardening

## 14. Recommended Data Ownership
**Decision**
- Firebase: `authentication only`
- MongoDB:
- users
- memories
- albums
- family access
- preferences
- S3:
- cover images
- photos
- audio
- video

**Status**
- `[Done]` current architecture isi direction me align hai.

## 15. Best Product Sequence To Build
**Recommended Order**
1. Auth + profile completion
2. Memories module
3. Albums full CRUD
4. S3 upload stable
5. Family invites + permissions
6. Settings persistence
7. Insights / discovery later

**Current Progress Comment**
- `[Done]` Discovery dynamic
- `[Done]` Home dashboard rebuild
- `[Done]` App-side Record Story flow
- `[Partial]` Albums dynamic foundation with backend create/list
- `[Partial]` Auth/backend foundation
- `[Done]` Profile completion gate
- `[Pending]` Memories backend persistence
- `[Pending]` Family backend persistence

## Best Final Flow
- User signs up
- Completes profile
- Records first memory
- Saves it into an album
- Uploads cover/media
- Invites family
- Sets privacy / legacy
- Returns later through biometrics

## Current Build Note
Ab se jo task complete hoga usko isi README me status comment ke sath mark kiya jayega taa ke progress clearly tracked rahe.











## All remaining task 
