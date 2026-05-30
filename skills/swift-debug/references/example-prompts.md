# Swift Debug Example Prompts

Use these prompts to calibrate the first debugging lane and avoid jumping to architecture changes before the bug is understood.

---

## Stale SwiftUI State

**Prompt**
`The model changes, but the screen only refreshes after navigation.`

**Load first**
- `swiftui-body-bugs.md`

**First checks**
- wrong ownership wrapper
- identity instability
- body work hiding the actual change
- off-main mutation

---

## Async / Actor Bug

**Prompt**
`I’m getting random duplicates when two tasks update the same list.`

**Load first**
- `concurrency-pitfalls.md`

**First checks**
- missing actor isolation
- read-modify-write race
- deduped task needed

---

## Representable Lifecycle Bug

**Prompt**
`My wrapped UIScrollView behaves correctly on first render, then resets after state changes.`

**Load first**
- `xcode-debug-tools.md`

**Supporting read**
- `../../swift-patterns/references/uikit-swiftui-bridge.md`

**First checks**
- `makeUIView` versus `updateUIView`
- coordinator stale state
- teardown not happening

---

## Performance Regression

**Prompt**
`Scrolling got janky after I added a lot of visual polish.`

**Load first**
- `xcode-debug-tools.md`
- `swiftui-body-bugs.md`

**First checks**
- expensive work in `body`
- too many blended layers
- wrong animation strategy
- image decode/downsample issues

---

## Sensor / Delegate State Bug

**Prompt**
`ARKit callbacks are arriving, but my SwiftUI state only updates sometimes.`

**Load first**
- `concurrency-pitfalls.md`

**First checks**
- delegate callback isolation
- `Task { @MainActor in ... }` handoff
- object lifetime and cancellation

---

## Good Response Shape

- Name the symptom precisely.
- Pick the first diagnostic surface, not five at once.
- Suggest the smallest instrumentation that can prove the hypothesis.
- Avoid refactors until the root cause is visible.
