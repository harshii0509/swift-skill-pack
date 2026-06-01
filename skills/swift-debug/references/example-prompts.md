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

## iOS 26 Bar / Safe-Area Regression

**Prompt**
`After moving to iOS 26, my ScrollView and WebView content end up under the top and bottom bars in a broken way.`

**Load first**
- `swiftui-body-bugs.md`
- `../../swift/references/swiftui-vocabulary.md`

**First checks**
- accidental `ignoresSafeArea`
- wrong choice between `safeAreaInset` and `safeAreaBar`
- custom bar backgrounds fighting scroll edge behavior
- bridge-owned content not respecting container safe areas

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
