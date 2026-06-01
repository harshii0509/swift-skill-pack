# Swift Patterns Example Prompts

Use these prompts to calibrate when `swift-patterns` should lead and what a strong answer should focus on.

---

## Session Ownership

**Prompt**
`Should selected conversation, auth, and profile each have their own session, or is that overkill?`

**Load first**
- `session-architecture.md`

**Optimize for**
- long-lived shared state boundaries
- dependency direction
- testability
- avoiding singleton creep

---

## Mixed UIKit / SwiftUI App

**Prompt**
`My app is still mostly UIKit, but new screens are SwiftUI. What is the cleanest bridge strategy?`

**Load first**
- `uikit-swiftui-bridge.md`

**Optimize for**
- choosing where UIKit remains the owner
- using `UIHostingController` or representables intentionally
- limiting bridge surface area

---

## SwiftUIX Adoption

**Prompt**
`We need search, paging, and blur surfaces quickly. Is SwiftUIX a good dependency here?`

**Load first**
- `swiftuix-patterns.md`
- `uikit-swiftui-bridge.md`

**Optimize for**
- native-vs-package-vs-custom decision
- local adapter boundaries
- long-term dependency cost

---

## Multiplatform Product Structure

**Prompt**
`We have one SwiftUI app that needs iPhone, iPad, Mac, widgets, and Live Activities. What structure keeps that maintainable?`

**Load first**
- `food-truck-patterns.md`

**Optimize for**
- one codebase with multiple app surfaces
- shared domain state with surface-specific entry points
- feature structure that does not collapse into giant root views

---

## Navigation Decision

**Prompt**
`Our navigation now includes deep links, sheets, tabs, and state restoration. Should we adopt Swift Navigation or keep plain SwiftUI navigation?`

**Load first**
- `swift-navigation-patterns.md`

**Optimize for**
- explicit navigation ownership
- deep-linkability and testability
- avoiding extra dependency surface when native navigation is already enough

---

## Observation Compatibility

**Prompt**
`We want to move toward Observation APIs, but our minimum iOS version is older. Where does Swift Perception fit?`

**Load first**
- `swift-perception-patterns.md`
- `session-architecture.md`

**Optimize for**
- backporting the mental model without rewriting state ownership twice
- deciding where native Observation can wait
- keeping debug and migration costs visible

---

## Modularization

**Prompt**
`The app is growing and incremental builds are getting slow. How should I split it into packages?`

**Load first**
- `spm-modularization.md`

**Optimize for**
- feature or domain boundaries
- dependency direction
- avoiding premature package explosion

---

## Rendering Tier Decision

**Prompt**
`Should this effect stay in SwiftUI, move to Canvas, or become a dedicated Metal/export pipeline?`

**Load first**
- `rendering-performance.md`

**Optimize for**
- lightest viable rendering tier
- live rendering versus export rendering
- explicit performance tradeoffs

---

## Modern SwiftUI Surface Terminology

**Prompt**
`Before we refactor this tabbed app, I need us to use the right terms for the mini-player, tab chrome, and bottom toolbar.`

**Load first**
- `../../swift/references/swiftui-vocabulary.md`

**Optimize for**
- naming `tabViewBottomAccessory`, `tab bar`, and `bottomBar` correctly
- keeping terminology aligned before making structure changes
- avoiding architecture advice that is based on the wrong surface model

---

## Good Response Shape

- Recommend one default pattern first.
- Explain why that ownership boundary is the cleanest.
- Mention the main risk if the wrong pattern is chosen.
- Pull in a second reference only when the problem truly crosses concerns.
