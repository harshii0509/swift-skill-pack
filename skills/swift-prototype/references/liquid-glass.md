# Liquid Glass and iOS 26 SwiftUI Surfaces

Use this reference when the task involves Liquid Glass, iOS 26 SwiftUI APIs, custom bars, tab chrome, safe-area behavior, or “why does this new Apple UI surface behave this way?”

This guidance is grounded in Apple’s current SwiftUI and design documentation, especially:

- What’s new in iOS 26: https://developer.apple.com/ios/whats-new/
- Adopting Liquid Glass: https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass
- Applying Liquid Glass to custom views: https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views
- SwiftUI updates: https://developer.apple.com/documentation/updates/swiftui

---

## First Principle

Start with standard Apple UI first.

Apple’s guidance is that standard components from SwiftUI, UIKit, and AppKit automatically pick up the new Liquid Glass look on current releases. That means the first move is usually:

1. build with the latest SDK
2. run the app on the latest OS
3. remove custom chrome that fights the system
4. only add custom Liquid Glass where the system components do not already solve it

Do not begin by recreating Apple’s new chrome with custom blur stacks.

---

## What To Review First in Existing Apps

If the app feels “wrong” after rebuilding on iOS 26, check these first:

- custom backgrounds on navigation bars, tab bars, split views, and toolbars
- opaque overlays sitting on top of standard bars
- hand-rolled blur cards replacing standard controls
- `ignoresSafeArea` being used to fake bar integration
- custom buttons that should now just use glass button styles

Apple explicitly warns that custom backgrounds and appearances in bars can interfere with Liquid Glass and the scroll edge effect.

---

## Core Liquid Glass APIs

### Use `glassEffect(_:in:)` for custom glass

Reach for this when the element is custom and the system does not already provide the surface.

```swift
if #available(iOS 26, *) {
    Text("Filter")
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular.interactive(), in: Capsule())
}
```

Guidance:

- apply `glassEffect` after layout modifiers that define the bounds
- keep shapes consistent across related controls
- use `.interactive()` only for controls that actually respond to touch or pointer input

### Use `GlassEffectContainer` when multiple glass elements coexist

This is the default for grouped floating controls, chips, or tool palettes.

Why:

- better rendering behavior
- better morphing behavior
- clearer grouping semantics

### Use `glassEffectID(_:in:)` only for hierarchy-changing morphs

Use it when glass shapes should animate into or out of one another across transitions.
Do not sprinkle it everywhere “just in case.”

### Use glass button styles before custom glass buttons

- `.buttonStyle(.glass)`
- `.buttonStyle(.glassProminent)`

If the UI is a normal action surface, start here before building a custom glass button shell.

### Use `ToolbarSpacer` in Liquid Glass toolbars

If toolbar items feel crowded or visually merged, use `ToolbarSpacer` before inventing custom separator chrome.

---

## New iOS 26 Surface APIs You Should Know

### `safeAreaBar`

Use `safeAreaBar(edge:alignment:spacing:content:)` when the content should behave as a real custom bar.

Why it matters:

- it adjusts safe area
- it adjusts scroll edge effects
- it behaves more like bar chrome than a generic inset

Prefer this over:

- a raw overlay
- `ignoresSafeArea` hacks
- `safeAreaInset` when the thing is conceptually a bar

### `safeAreaInset`

Still valid, but it is the generic “make room for content” tool.
Use it when you are adding content near an edge, not when you are intentionally building custom bar chrome.

### `tabViewBottomAccessory`

Use `tabViewBottomAccessory` when the content belongs to the `TabView` chrome itself.

Apple’s docs say:

- when the tab bar is normal size on iPhone, the accessory appears above it
- when the tab bar is collapsed, the accessory displays inline

That makes it the right first choice for:

- mini players attached to tab navigation
- tab-scoped status surfaces
- accessory UI that should move with tab-bar state

### `tabViewBottomAccessoryPlacement`

Use the environment value when the accessory content should adapt between expanded and inline placements.

### `tabBarMinimizeBehavior(_:)`

Use this when the tab bar should minimize with scroll on iPhone.
Do not fake tab-bar collapse with a custom offset animation before trying the system behavior.

### `scrollEdgeEffectStyle(_:for:)`

This controls the new scroll edge effect style.
Use it when the default pocket/fade treatment needs tuning, not as the first answer to every bar problem.

### `backgroundExtensionEffect(isEnabled:)`

Use it when content or backgrounds need to extend naturally into safe-area edges.
Apple describes it as duplicating, mirroring, and blurring views around those edges.
It is not a generic replacement for Liquid Glass.

---

## Decision Shortcuts

### “I need a custom floating control cluster”

Start with:

- `glassEffect`
- `GlassEffectContainer`

### “I need a standard action button to feel current”

Start with:

- `.buttonStyle(.glass)`
- `.buttonStyle(.glassProminent)`

### “I need a mini-player above the tab bar”

Start with:

- `tabViewBottomAccessory`

Use `safeAreaBar` instead when the surface is app-owned bar chrome and not tied to `TabView` behavior.

### “I need a persistent bottom bar that scroll content respects”

Start with:

- `safeAreaBar(edge: .bottom)`

### “My content should visually extend into the safe-area edge”

Start with:

- `backgroundExtensionEffect(isEnabled:)`
- or adjust `scrollEdgeEffectStyle` if the issue is really the scroll pocket treatment

### “The bars feel wrong after adopting iOS 26”

Start with:

- removing custom bar backgrounds
- checking standard toolbars and tab bars
- verifying you are not fighting automatic Liquid Glass adoption

---

## Common Mistakes

### Mistake: Custom blur before native Glass

Do not stack `Material`, blur, overlays, and strokes to imitate Liquid Glass before trying the native APIs.

### Mistake: `safeAreaInset` when you mean “bar”

If the surface should behave like real app chrome, `safeAreaBar` is usually the better vocabulary and API.

### Mistake: Overlay mini-player on top of tab chrome

If it belongs to tab navigation and should react to tab bar placement, start with `tabViewBottomAccessory`.

### Mistake: `ignoresSafeArea` as the first fix

That often hides the actual integration bug and makes bars, web content, or scroll edge behavior worse.

### Mistake: Too much custom glass

Apple’s guidance is to use custom Liquid Glass sparingly.
If everything is glass, the hierarchy gets muddier instead of clearer.

---

## Review Checklist

- Are standard bars and controls being allowed to adopt Liquid Glass automatically?
- Are custom bar backgrounds removed unless they are truly necessary?
- Is `glassEffect` only used on elements that actually benefit from custom glass?
- Are grouped glass elements wrapped in `GlassEffectContainer`?
- Is `glassEffectID` only used for real morphing transitions?
- Is `tabViewBottomAccessory` used for tab-chrome accessories?
- Is `safeAreaBar` used for custom bars instead of overlays?
- Are scroll edge effects being tuned intentionally rather than fought accidentally?
- Are iOS 26 APIs gated with availability when needed?

---

## Escalation Rule

If the request becomes primarily about exact terminology, also load `../../swift/references/swiftui-vocabulary.md`.

If the request becomes primarily about a broken implementation rather than adoption strategy, hand the first pass to `../../swift-debug/SKILL.md`.
