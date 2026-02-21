# WORKPLAN — Where To Flock

Two devs, two workstreams, one base scaffold. Branch off `main` (base commit) into your feature branch and work independently. Merge into `main` for integration checkpoints.

## Branches
| Dev | Branch |
|-----|--------|
| Abby | `feature/abby-claude-layer` |
| Mike | `feature/mike-flutter-infra` |

---

## Abby — Claude Layer + Interaction Design
**Branch:** `feature/abby-claude-layer`
**Primary files:** `lib/services/claude_service.dart`, `lib/widgets/components/component_renderer.dart`, `prompts/`

### Phase 1 — Schema & Prompts
- [ ] Define final JSON schema for Claude's structured response (`target_user`, `target_block`, `component`, `props`)
- [ ] Write system prompt: role, trip context, component catalog with prop shapes, output format rules
- [ ] Write per-block decision flow specs (what questions in what order):
  - [ ] Breakfast flow
  - [ ] Morning Activity flow
  - [ ] Lunch flow
  - [ ] Afternoon Activity flow
  - [ ] Dinner flow
- [ ] Decide: real venue data vs. Claude-generated plausible NYC options (hardcode fallback list if needed)

### Phase 2 — Claude Service
- [ ] Implement `claude_service.dart`: send labeled inputs, parse structured JSON response
- [ ] Maintain conversation history per trip session (all inputs labeled by person)
- [ ] Handle streaming vs. single-shot response (pick one for demo; single-shot is simpler)
- [ ] Add error handling + fallback component if Claude returns unexpected shape

### Phase 3 — Component Selection Logic
- [ ] Implement `component_renderer.dart` dispatch: reads `component` string, instantiates correct widget
- [ ] Wire `props` JSON to each widget's constructor (coordinate prop shapes with Mike)
- [ ] Test dispatch with hardcoded mock responses before connecting live Claude

### Phase 4 — Conflict Detection & Resolution
- [ ] Write prompt logic to detect conflicts (geographic, time, vibe)
- [ ] Define `conflict_card` props and trigger condition
- [ ] Implement shared conflict flow: Claude surfaces to both users simultaneously

### Phase 5 — Final Plan Generation
- [ ] Write final plan prompt: given all decided blocks, generate styled `final_plan_card` props for each
- [ ] Define vibe color logic (overall day vibe → hex color per card)
- [ ] Test end-to-end: claim → decide × 5 blocks → final plan

### Phase 6 — Polish
- [ ] 2–3 decision steps max per block (tune prompt)
- [ ] Ensure component variety across blocks (avoid showing same widget twice in a row)
- [ ] Write `prompts/` directory with versioned prompt files for easy iteration
- [ ] Hardcode demo fallbacks for any flaky external calls

---

## Mike — Flutter UI + Infrastructure
**Branch:** `feature/mike-flutter-infra`
**Primary files:** `lib/widgets/`, `lib/services/firebase_service.dart`, `lib/screens/`, `lib/theme/`

### Phase 1 — Layout
- [x] Implement `ThreePanelLayout`: responsive three-column layout (left sidebar, center, right sidebar)
- [x] Add header bar with trip title and person indicators
- [x] Implement `SidebarPanel` with scroll, person color theming, and placeholder for genUI stack
- [x] Implement `ItineraryPanel`: vertical list of `ItineraryBlockWidget` slots

### Phase 2 — Firebase Setup (DEFERRED)
- [ ] Create Firebase project (Firestore, web config)
- [ ] Add `google-services` / web config to `web/index.html`
- [ ] Implement `firebase_service.dart`:
  - [ ] `createTrip()` — initialize trip document with 5 default blocks
  - [ ] `watchTrip(trip_id)` — stream trip doc changes
  - [ ] `claimBlock(trip_id, block_id, person_id)` — update block owner + status
  - [ ] `updateBlockResult(trip_id, block_id, result)` — write decided result
  - [ ] `addConflict()` / `resolveConflict()`
- [ ] Test two-client real-time sync (open two browser tabs)

### Phase 3 — Output Widgets (center itinerary)
- [x] `ItineraryBlockWidget` — time, title, status color, owner avatar chip
  - [x] Unclaimed state (grey, tap/drag to claim)
  - [x] Claimed/in-progress state (person color, spinner)
  - [x] Decided state (filled with result details)
- [x] `ConflictCardWidget` — description + option buttons, shared interaction
- [x] `TransitionBlockWidget` — from/to/duration/method
- [x] `FinalPlanCard` — full styled output block with vibe color

### Phase 4 — Input Widgets (sidebars, Claude-selected) (DEFERRED - Simulating via Mock)
- [ ] `MoodBoard` — image grid, multi-select up to `max_select`
- [ ] `ThisOrThat` — swipeable card pairs, left/right images
- [ ] `VibeSlider` — labeled slider with endpoint images
- [ ] `VibeSlider2D` — 2D drag point on axes with quadrant images
- [ ] `ComparisonCards` — expandable option cards with vibe tags
- [ ] `ComparisonTable` — feature grid comparison
- [ ] `QuickConfirm` — suggestion card with Yes/No
- [ ] `DomainClaim` — drag-and-drop block assignment between columns

### Phase 5 — Image Integration (DEFERRED)
- [ ] Choose image search API (Unsplash, Pexels, or Google Custom Search)
- [ ] Implement image fetch by query string (venue name, neighborhood, vibe keyword)
- [ ] Add `cached_network_image` for all image widgets
- [ ] Prepare curated fallback image set for demo (no network = still looks good)

### Phase 6 — Polish
- [x] Animate block status transitions (color change, avatar fade-in)
- [x] Loading state for Claude response (skeleton / shimmer in sidebar)
- [ ] Keyboard/click claim interaction (drag is nice, click-to-claim is the fallback)
- [x] Ensure layout works at 1280px+ wide (demo screen width)
- [x] `AppTheme` finalized: fonts, corner radii, shadows, person palette
- [x] Autodrive demo script (Simulated local state transitions)

---

## Shared / Integration
- [ ] Agree on `ComponentResponse` prop shapes (Abby drives schema, Mike confirms widget parity)
- [ ] Integration checkpoint: mock Claude response → `ComponentRenderer` → correct widget renders
- [ ] Integration checkpoint: claim a block in one browser tab → other tab updates in real time
- [ ] Integration checkpoint: full end-to-end demo flow works without errors
- [ ] Demo script rehearsal and hardcoded fallbacks locked in
- [ ] Presentation: each dev explains their layer to judges

---

## Demo Scope (ship these, cut the rest)
**Must ship:**
- [ ] Three-panel layout functional
- [ ] Block claiming (click or drag)
- [ ] 4 input components working: `mood_board`, `vibe_slider`, `comparison_cards`, `this_or_that`
- [ ] `itinerary_block` output (all status states)
- [ ] Claude selecting and populating at least 2 different component types live
- [ ] Real-time sync (two tabs)
- [ ] One conflict + resolution
- [ ] Final plan view

**Stretch (if time):**
- [ ] `vibe_slider_2d` (wow moment — prioritize if demo permits)
- [ ] `domain_claim` drag interaction
- [ ] `timeline_drag` reordering
- [ ] `neighborhood_heatmap`
