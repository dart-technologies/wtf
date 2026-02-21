# Where To Flock — Claude Code Context

## Project Summary
**Where To Flock (WTF)** is a collaborative one-day trip planner where two people plan a day in NYC together. A shared itinerary sits in the center; each person claims blocks and works through AI-driven generative UI decisions in their own sidebar. Claude selects which component to render based on the decision domain and user preferences — the interface is generative, not hardcoded.

## Repo Structure
```
wtf/
├── lib/
│   ├── main.dart                     # Entry point
│   ├── app.dart                      # MaterialApp + routing
│   ├── models/                       # Data models (Trip, Block, Person, ComponentResponse)
│   ├── services/                     # Firebase + Claude API clients
│   ├── theme/                        # AppTheme, person colors
│   ├── screens/                      # TripScreen (main screen)
│   └── widgets/
│       ├── layout/                   # ThreePanelLayout, ItineraryPanel, SidebarPanel
│       └── components/
│           ├── component_renderer.dart   # Dispatches to the right widget by component name
│           ├── input/                    # mood_board, this_or_that, vibe_slider, vibe_slider_2d,
│           │                             # comparison_cards, comparison_table, quick_confirm, domain_claim
│           └── output/                   # itinerary_block, conflict_card, final_plan_card, transition_block
├── pubspec.yaml
└── web/index.html
```

## Key Concepts

### Itinerary Blocks
Five fixed time blocks per day (adjustable by Claude):
- `breakfast`: 9:00–10:00am
- `morning_activity`: 10:00am–12:00pm
- `lunch`: 12:00–1:30pm
- `afternoon_activity`: 1:30–4:30pm
- `dinner`: 6:00–8:00pm

### Block Status Flow
`unclaimed` → `claimed` → `in_progress` → `decided`

### Person Colors
- **Person A (Abby)**: `#4A9EFF` (blue)
- **Person B (Mike)**: `#FF6B6B` (coral)
- **Unclaimed / AI**: `#9E9E9E` (grey)

### Firebase Data Shape
Single Firestore document per trip at `trips/{trip_id}`. See `lib/models/trip.dart` for full schema. Both clients listen to this document in real time.

### Claude Integration
- One Claude conversation per trip session
- All inputs sent to Claude are labeled by person
- Claude responds with structured JSON: `{target_user, target_block, component, props}`
- `ComponentRenderer` in `lib/widgets/components/component_renderer.dart` reads the `component` field and instantiates the correct widget

### Component Catalog
**Input** (Claude-selected, rendered in sidebars):
`mood_board`, `this_or_that`, `vibe_slider`, `vibe_slider_2d`, `comparison_cards`, `comparison_table`, `quick_confirm`, `domain_claim`

**Output** (rendered in center itinerary or final view):
`itinerary_block`, `conflict_card`, `final_plan_card`, `transition_block`

## Work Split
| Owner | Domain | Key Files |
|-------|--------|-----------|
| **Abby** | Claude layer + interaction design | `lib/services/claude_service.dart`, system prompt, `ComponentRenderer` dispatch logic, decision flow |
| **Mike** | Flutter UI + infrastructure | `lib/widgets/`, `lib/services/firebase_service.dart`, layout, image search |

## Dev Branches
- `feature/abby-claude-layer` — Abby's workstream
- `feature/mike-flutter-infra` — Mike's workstream

Both branch off the same base scaffold commit.

## Run Locally
```bash
flutter pub get
flutter run -d chrome
```

## Key Dependencies
- `cloud_firestore` — real-time shared state
- `firebase_core` — Firebase initialization
- `http` — Claude API calls
- `provider` or `riverpod` — local state management
- `cached_network_image` — images in components
