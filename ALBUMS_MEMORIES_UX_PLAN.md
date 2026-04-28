# Albums & Memories UX Plan

## Goal
- Make albums fully cloud-first.
- Remove local-only album creation from the active product flow.
- Use `memory` / `memories` as the user-facing language instead of `story` / `stories`.
- Let people add photo, video, voice, and text memories directly inside an album.
- Present album content like a clean gallery with strong date context.

## Product Direction
- Albums are curated containers for memories.
- Every new album is created in the cloud.
- Every memory added from an album is saved to the cloud archive and linked back to that album.
- The archive should feel visual first, then descriptive.

## Albums List Experience
- Hero header introduces albums as cloud-synced collections.
- Main list uses an editorial timeline layout:
  - Month heading
  - Large cover image
  - Dark caption block
  - Memory count
  - Clear “cloud synced” state
- Empty state should guide the user to create the first album.
- Pull to refresh stays available.

## Album Creation Experience
- Keep one creation path only:
  - Cover image
  - Album title
  - Description
- No local/private-on-device toggle in the main flow.
- Success messaging should reinforce cloud sync.

## Album Detail Experience
- App bar should contain:
  - Back
  - Add memory
- Add memory opens a bottom sheet with:
  - Photo memory
  - Video memory
  - Voice memory
  - Text memory
- Selecting an option opens the composer with the album preselected.

## Memory Gallery Experience
- Album memories are grouped by month.
- Each tile should show:
  - Media preview
  - Date or date-time
  - Title
  - Short description when available
- Gallery should feel like a visual archive wall rather than a feed.

## Memory Actions
- Tap memory:
  - Open detail view
- Long press or overflow menu:
  - Delete memory
- Delete should:
  - Remove the memory from the album
  - Remove it from the cloud archive for the owner

## Vocabulary Rules
- Replace visible “story” wording with:
  - Memory
  - Memories
  - Memory archive
  - Memory draft
- Keep internal class names if needed for now, but move visible product copy to memory-first language.

## Home Screen Alignment
- Remove local album showcase from the active home flow.
- Replace it with a cloud album spotlight card or carousel.
- Quick actions should be:
  - Voice Memory
  - Write Memory
  - Photo Memory
  - Video Memory

## Backend & Data Rules
- Album creation:
  - MongoDB document
  - Cover stored in S3
- Memory creation:
  - MongoDB document
  - Media stored in S3 when present
  - `albumId` links memory to album
- Memory deletion:
  - Delete memory document
  - Remove embedded album snapshot reference

## Near-Term Follow-Ups
- Add album editing flow.
- Add album deletion flow.
- Add memory reordering or pinned memory cover selection.
- Add optimistic updates for add/delete memory actions.
- Add better upload progress feedback for large videos and voice notes.

## Quality Bar
- Responsive on phone widths first.
- No overflow warnings.
- No mixed local/cloud language in the active albums journey.
- Theme support should remain correct for light and dark mode.
