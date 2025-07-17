# ECG Player State Management Refactoring Plan

## Current State Analysis

### Problems Identified

- **Complex state management**: ~30+ scattered state properties in `assets/js/hooks/ecg/ecg_player.js` (~3000 LOC)
- **Manual synchronization**: Multiple `this.updateCursorStyle()` calls scattered throughout codebase
- **State consistency issues**: Manual property updates prone to forgotten updates and race conditions
- **Complex side effects**: Animation loops, DOM manipulation, event handling all mixed together
- **Hard to debug**: State changes and side effects are implicit and scattered

### Current State Properties

```javascript
// From initializeState() - 30+ properties including:
this.isPlaying = false;
this.cursorPosition = 0;
this.displayMode = "single";
this.calipersMode = false;
this.activeCaliper = null;
this.animationId = null;
this.startTime = null;
this.pausedTime = 0;
// ... many more
```

## Recommended Solution: MobX + XState

### Architecture Overview

1. **MobX Store** - Manages data state and automatic UI reactivity
2. **XState Machine** - Manages business logic, state transitions, and side effects
3. **Phoenix Hook** - Coordinates between LiveView, XState, and MobX

### Benefits

- **Automatic reactivity**: UI updates automatically when data changes
- **Bulletproof state transitions**: Prevents invalid states like "measuring calipers while changing display mode"
- **Reduced LOC**: Estimated 500-900 lines reduction (20-30%)
- **Better debugging**: XState DevTools + MobX DevTools
- **Cleaner code**: Separation of concerns between data, business logic, and UI

## Implementation Plan

### Phase 1: Setup Dependencies

```bash
cd assets
npm install xstate mobx
```

### Phase 2: Create Parallel Implementation Structure

**IMPORTANT**: We will create a completely new implementation alongside the existing `ecg_player.js` file. This allows for gradual migration and easy rollback if needed.

**New File Structure**:
```
assets/js/hooks/ecg/
├── ecg_player.js              # Original implementation (keep untouched)
├── ecg_player_v2.js           # New MobX/XState implementation
├── stores/
│   └── ecg_player_store.js    # MobX store
└── machines/
    └── ecg_player_machine.js  # XState machine
```

### Phase 3: Create MobX Store

**File**: `assets/js/hooks/ecg/stores/ecg_player_store.js`

```javascript
import { makeObservable, observable, action, computed, reaction } from "mobx";

class ECGPlayerStore {
  constructor() {
    makeObservable(this, {
      // Observable state
      isPlaying: observable,
      cursorPosition: observable,
      displayMode: observable,
      selectedLead: observable,
      calipersMode: observable,
      calipers: observable,

      // Actions
      play: action,
      pause: action,
      updateCursor: action,
      changeDisplayMode: action,

      // Computed values
      cursorPixelPosition: computed,
      canChangeLead: computed,
    });
  }

  // State properties with defaults
  isPlaying = false;
  cursorPosition = 0;
  displayMode = "single";
  selectedLead = "II";
  calipersMode = false;
  calipers = [];

  // Actions
  play() {
    this.isPlaying = true;
  }
  pause() {
    this.isPlaying = false;
  }
  updateCursor(position) {
    this.cursorPosition = position;
  }
  changeDisplayMode(mode) {
    this.displayMode = mode;
  }

  // Computed values
  get cursorPixelPosition() {
    return (this.cursorPosition * this.chartWidth) / this.widthSeconds;
  }

  get canChangeLead() {
    return this.displayMode === "single";
  }
}
```

### Phase 4: Create XState Machine

**File**: `assets/js/hooks/ecg/machines/ecg_player_machine.js`

```javascript
import { createMachine, assign } from "xstate";

export const ecgPlayerMachine = createMachine(
  {
    id: "ecgPlayer",
    initial: "loading",
    context: {
      store: null,
      animationId: null,
      startTime: null,
    },
    states: {
      loading: {
        on: {
          DATA_LOADED: "idle",
        },
      },
      idle: {
        on: {
          PLAY: "playing",
          START_CALIPER: "measuring",
          TOGGLE_DISPLAY: {
            actions: "changeDisplayMode",
          },
        },
      },
      playing: {
        entry: ["startPlaying", "beginAnimation"],
        exit: ["stopPlaying", "endAnimation"],
        on: {
          PAUSE: "paused",
          SPACEBAR: "paused",
          STOP: "idle",
          CHANGE_LEAD: {
            guard: "canChangeLead",
            actions: "setLead",
          },
          TOGGLE_DISPLAY: {
            actions: "changeDisplayMode",
            target: "paused",
          },
        },
      },
      paused: {
        on: {
          PLAY: "playing",
          SPACEBAR: "playing",
          STOP: "idle",
          START_CALIPER: "measuring",
        },
      },
      measuring: {
        on: {
          FINISH_CALIPER: "paused",
          CANCEL_CALIPER: "paused",
        },
      },
    },
  },
  {
    guards: {
      canChangeLead: (context) => context.store.canChangeLead,
    },
    actions: {
      startPlaying: (context) => {
        context.store.play();
        context.startTime = Date.now();
      },
      stopPlaying: (context) => {
        context.store.pause();
      },
      beginAnimation: (context) => {
        // Animation loop implementation
      },
      endAnimation: (context) => {
        if (context.animationId) {
          cancelAnimationFrame(context.animationId);
          context.animationId = null;
        }
      },
      changeDisplayMode: (context, event) => {
        context.store.changeDisplayMode(event.mode);
      },
      setLead: (context, event) => {
        context.store.selectedLead = event.lead;
      },
    },
  }
);
```

### Phase 5: Create New Phoenix Hook Implementation

**File**: `assets/js/hooks/ecg/ecg_player_v2.js`

```javascript
import { interpret } from "xstate";
import { reaction } from "mobx";
import { ECGPlayerStore } from "./stores/ecg_player_store";
import { ecgPlayerMachine } from "./machines/ecg_player_machine";

const ECGPlayer = {
  mounted() {
    // Initialize MobX store
    this.store = new ECGPlayerStore();

    // Initialize XState machine with store
    this.service = interpret(
      ecgPlayerMachine.withContext({
        store: this.store,
      })
    );
    this.service.start();

    // Set up MobX reactions for DOM updates
    this.setupMobXReactions();

    // Traditional Phoenix Hook setup
    this.setupEventListeners();
    this.initializeCanvas();
  },

  setupMobXReactions() {
    // Automatic cursor updates
    this.cursorReaction = reaction(
      () => this.store.cursorPixelPosition,
      (position) => this.updateCursorDOM(position)
    );

    // Automatic display mode updates
    this.displayModeReaction = reaction(
      () => this.store.displayMode,
      (mode) => this.updateDisplayModeDOM(mode)
    );
  },

  setupEventListeners() {
    this.playButton.onclick = () => this.service.send("PLAY");

    document.onkeydown = (e) => {
      if (e.code === "Space") {
        this.service.send("SPACEBAR");
      }
    };

    this.displayModeSelect.onchange = (e) => {
      this.service.send("TOGGLE_DISPLAY", { mode: e.target.value });
    };
  },

  // Phoenix LiveView integration
  handleEvent(event, payload) {
    switch (event) {
      case "ecg_data_loaded":
        this.loadECGData(payload);
        this.service.send("DATA_LOADED");
        break;
      case "play_command":
        this.service.send("PLAY");
        break;
    }
  },

  destroyed() {
    // Clean up MobX reactions
    this.cursorReaction?.();
    this.displayModeReaction?.();

    // Clean up XState
    this.service.stop();
  },
};
```

## Migration Strategy

### Step 1: Parallel Implementation Foundation

1. **Keep original `ecg_player.js` completely untouched**
2. Create new `ecg_player_v2.js` with MobX + XState architecture
3. Start with minimal functionality (just play/pause state)
4. Test integration with Phoenix LiveView using the new hook

### Step 2: Feature-by-Feature Migration

**Phase 2A: Basic Playback Control**
- Implement play/pause/stop functionality
- Basic cursor position tracking
- Simple animation loop
- Test with existing ECG data

**Phase 2B: Display Management**
- Display mode switching (single/multi-lead)
- Lead selection with business logic
- Canvas rendering setup
- Theme support

**Phase 2C: Advanced Features**
- Calipers functionality
- QRS flash indicators
- Fullscreen mode
- Keyboard shortcuts

**Phase 2D: Additional Features**
- Error handling and edge cases
- Keyboard shortcuts
- Fullscreen mode enhancements
- Additional user interactions

### Step 3: LiveView Integration Points

1. **Maintain identical Phoenix events**: Ensure `ecg_player_v2.js` handles the same LiveView events as original
2. **Feature flags**: Use LiveView assigns to switch between implementations
3. **Gradual rollout**: Test with subset of users before full migration
4. **Functional testing**: Compare behavior between implementations

### Step 4: Production Transition

1. **A/B testing**: Run both implementations in parallel
2. **Gradual migration**: Move features from v1 to v2 incrementally
3. **Rollback capability**: Keep original implementation as fallback
4. **Final cleanup**: Remove original implementation only after v2 is stable

### Step 5: Development Process

**For each feature migration:**
1. **Write failing tests** for the feature in v2
2. **Copy core logic** from original implementation
3. **Refactor to use MobX/XState** patterns
4. **Ensure tests pass**
5. **Test integration** with Phoenix LiveView
6. **Functional testing** against original
7. **Code review** and documentation

## Testing Strategy

### Unit Tests

- Test MobX store actions and computed values
- Test XState machine transitions and guards
- Test Phoenix Hook integration points

### Integration Tests

- Test complete user workflows (play → pause → change display mode)
- Test edge cases prevented by state machine
- Test Phoenix LiveView event handling

### Functional Tests

- Test feature parity between implementations
- Verify identical behavior for user interactions
- Test edge cases and error conditions

## Expected Outcomes

### Code Quality

- **20-30% reduction in LOC** (500-900 lines)
- **Elimination of manual synchronization** code
- **Better separation of concerns**
- **Improved debugging capabilities**

### User Experience

- **Consistent behavior** with automatic reactivity
- **Fewer UI bugs** from state consistency
- **More reliable interactions** with proper state management

### Developer Experience

- **Easier to add new features**
- **Better debugging tools**
- **More predictable state management**
- **Cleaner code architecture**

## Next Steps

### Immediate Actions (Phase 1)

1. **Review this plan** and adjust based on project priorities
2. **Set up development environment** with MobX and XState dependencies
3. **Create directory structure** for parallel implementation
4. **Set up Phoenix LiveView feature flag** to switch between implementations

### Short-term Goals (Phase 2-3)

1. **Build minimal viable v2 implementation** with just play/pause functionality
2. **Test Phoenix LiveView integration** with the new hook
3. **Validate architecture** with a simple feature before expanding
4. **Create testing framework** for comparing implementations

### Long-term Goals (Phase 4-5)

1. **Incrementally migrate features** from original to v2 implementation
2. **Maintain production stability** with rollback capabilities
3. **Full transition** to v2 implementation

### Success Criteria

- **No disruption** to existing functionality during migration
- **Measurable improvements** in code maintainability
- **Smooth developer experience** with better debugging tools
- **Reduced bugs** from improved state management
- **Successful feature flag rollout** with easy rollback capability

### Risk Mitigation

- **Parallel implementation** allows safe experimentation
- **Feature flags** enable gradual rollout and easy rollback
- **Comprehensive testing** ensures compatibility
- **Functional testing** validates behavior matches original
- **Original implementation** remains as fallback option
