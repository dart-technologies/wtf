# Where To Flock

> Two friends. One day. Claude decides the interface.

**Where To Flock** is a collaborative day-trip planner where generative UI replaces fixed forms. Two people plan a shared day in NYC — each person claims sections of the itinerary and works through AI-selected decision components in their own sidebar. Claude chooses the right widget for each decision in real time based on the domain, the person's preferences, and their prior answers.

## The Interface

```
┌─────────────────────────────────────────────────────┐
│                 WHERE TO FLOCK · NYC Day             │
├──────────────┬─────────────────────────┬────────────┤
│              │                         │            │
│   ABBY       │    SHARED ITINERARY     │   MIKE     │
│   SIDEBAR    │                         │   SIDEBAR  │
│              │  ┌─────────────────┐    │            │
│  (genUI      │  │ 9am  Breakfast  │    │  (genUI    │
│   lives      │  ├─────────────────┤    │   lives    │
│   here)      │  │ 10am Morning    │    │   here)    │
│              │  ├─────────────────┤    │            │
│              │  │ 12pm Lunch      │    │            │
│              │  ├─────────────────┤    │            │
│              │  │ 1:30 Afternoon  │    │            │
│              │  ├─────────────────┤    │            │
│              │  │ 6pm  Dinner     │    │            │
│              │  └─────────────────┘    │            │
│              │                         │            │
└──────────────┴─────────────────────────┴────────────┘
```

## How It Works

### 1. Claim
The itinerary starts with all blocks unclaimed (grey). Each person drags blocks to claim them, or assigns them to AI.

### 2. Decide (parallel)
Claude generates 2–3 decision steps per claimed block, selecting from a pre-built component catalog:

| Component | What it does |
|-----------|-------------|
| `mood_board` | Image grid for vibe decisions ("What does lunch feel like?") |
| `this_or_that` | Rapid binary preference pairs |
| `vibe_slider` | Spectrum decisions (casual ↔ fancy) |
| `vibe_slider_2d` | Two-axis decisions (chill/active × local/tourist) |
| `comparison_cards` | 2–4 specific options with expandable detail |
| `comparison_table` | Feature-based option comparison |
| `quick_confirm` | Simple yes/no on a suggestion |
| `domain_claim` | Drag blocks between people and AI |

### 3. Resolve Conflicts
When two decisions interact (e.g., dinner location vs. afternoon activity location), Claude surfaces the conflict on the shared itinerary with a `conflict_card` that both people can interact with.

### 4. Final Plan
The itinerary fills in with full venue details, transition times, and a styled `final_plan_card` for each block — colors and layout reflecting the overall vibe of the day.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter Web |
| Real-time state | Firebase Firestore |
| AI | Claude (structured JSON output) |
| Images | Image search API (runtime) |

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Build for web
flutter build web
```

## Team

| Person | Role |
|--------|------|
| **Abby** | Claude layer — system prompts, decision flow, component selection logic, final plan generation |
| **Mike** | Flutter infra — widget catalog, Firebase sync, layout, image search |

## Demo Flow (5 min)

1. **Setup (30s)** — Two friends planning a day in NYC
2. **Claim (20s)** — Blocks get assigned; one takes food, one takes activities
3. **Parallel decisions (2 min)** — Side-by-side genUI; mood boards, sliders, comparison cards
4. **Conflict (30s)** — Logistical conflict surfaces; both people resolve it together
5. **Final plan (30s)** — Itinerary fills in with full details and vibe styling
6. **Takeaway (20s)** — "We didn't code which component appears when. Claude decides the interface in real time."
