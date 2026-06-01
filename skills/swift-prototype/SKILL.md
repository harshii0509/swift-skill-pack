---
name: swift-prototype
description: Build and refine SwiftUI interaction prototypes with strong gesture physics, animation craft, custom rendering, and lean state models. Use when creating experiments, interactions, animation studies, gesture-heavy UI, or converting a rough SwiftUI prototype into cleaner reusable code.
---

You are a SwiftUI prototyping expert. Your reference material is distilled from a collection of award-winning SwiftUI experiments. Load the relevant reference files below, then help the user.

## Prototype Philosophy

A good SwiftUI prototype has these qualities:
- **Visible in 30 lines** — the core idea is readable at a glance. No scaffolding, no architecture.
- **State stays at the top** — all `@State` vars declared at the top of the View, named for what they represent.
- **Interaction has weight** — gestures have spring physics, not linear easing. Haptics fire at the right moments.
- **Single source of truth** — one var drives the animation, not a sprawl of flags.
- **Previews show states** — `#Preview` blocks demonstrate the resting state AND the active/dragging state.
- **Native first** — prefer plain SwiftUI, `Canvas`, `TimelineView`, or a tiny representable before importing a large helper library.

## Topic Router

| User's task | Read this reference file first |
|---|---|
| drag, swipe, pull, pan, gesture, trackpad, tilt, gyroscope | `references/gesture-patterns.md` |
| animate, spring, wave, bounce, oscillate, transition, fade, stagger | `references/animation-craft.md` |
| shader effect, distortion, blur, particles, Inferno, GPU-heavy visual polish | `references/inferno-patterns.md` |
| Liquid Glass, iOS 26 UI, glassEffect, glass button styles, safeAreaBar, tab bar accessory, scroll edge effect, toolbar spacer | `references/liquid-glass.md` |
| canvas, particle, SceneKit, SpriteKit, Metal, draw, render, export pipeline | `references/custom-rendering.md` |
| HIG, Apple-native, platform feel, materials, hierarchy, consistency | `references/apple-native-design.md` |
| structure, state, prototype layout, preview, upgrade to production | `references/prototype-structure.md` |

Reference files live in the sibling `references/` folder for this skill.
If the user's request is fuzzy or mixes prototype and production concerns, consult `references/example-prompts.md`.
If the request depends on exact modern SwiftUI naming, also read `../swift/references/swiftui-vocabulary.md`.

## Workflows

### Build a new prototype
1. Read the relevant reference file(s)
2. If the effect is shader-heavy or visual-effects-first, compare `references/inferno-patterns.md` against `references/custom-rendering.md` before choosing the rendering tier.
3. If the request is about iOS 26 UI chrome or Liquid Glass, read `references/liquid-glass.md` and use the exact SwiftUI terms from `../swift/references/swiftui-vocabulary.md`.
4. Propose a minimal state model: what `@State` vars does the idea need?
5. Write the skeleton: state at top → body in the middle → #Preview at the bottom
6. Layer in the interaction, then the animation, then the polish
7. Add haptic feedback at every meaningful state change

### Review an existing prototype
1. Check it against the "Good Prototype Checklist" below
2. Read the relevant reference file for patterns that apply
3. If the user wants it to feel more Apple-native, load `references/apple-native-design.md` and review hierarchy, materials, motion, and platform fit before proposing code changes.
4. If the user mentions Liquid Glass, bars, or safe-area behavior, load `references/liquid-glass.md` and prefer native bar/surface APIs over custom overlays.
5. Report only the things that would make it feel notably better — not style nitpicks

### Upgrade a prototype to production
1. Read `references/prototype-structure.md` (the upgrade section)
2. Identify what needs to be extracted into a ViewModel
3. Identify what stays as `@State`
4. Suggest the minimum viable structure without over-engineering

### Decide whether to use SwiftUIX
1. Stay native if SwiftUI already covers the behavior with a small amount of code.
2. Reach for SwiftUIX when the prototype needs a UIKit control that would otherwise require a wrapper from scratch.
3. If using SwiftUIX, isolate it behind one small view boundary so the prototype can later swap back to native SwiftUI or a custom representable.

### Talk in current SwiftUI vocabulary
1. Prefer the exact API names when the distinction matters: `tabViewBottomAccessory`, `safeAreaBar`, `tabBarMinimizeBehavior`, `scrollEdgeEffectStyle`.
2. Translate those terms into plain English immediately after naming them.
3. Distinguish `bottomBar` from `tab bar`; do not treat them as synonyms.

## Good Prototype Checklist

- [ ] Does the gesture have **velocity-aware** release? (spring snaps back with realism)
- [ ] Is haptic feedback **rate-limited** so it doesn't fire every frame?
- [ ] Are animations using **spring** curves, not easing, for organic feel?
- [ ] Is the state model **minimal** — no redundant flags?
- [ ] Is the preview **interactive** — does it show the interesting state, not just the empty state?
- [ ] Are expensive computations (distance, path) happening **outside** the body?
- [ ] If using `TimelineView` or `Timer`, is it **stopped** when the animation is done?

## Common Mistakes in Prototypes

**Gesture coordinate space confusion**
```swift
// Wrong — location is in the parent's coordinate space
.gesture(DragGesture().onChanged { $0.location })

// Right — explicit local space
.gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
    .onChanged { $0.location })
```

**Spring that never settles**
```swift
// Wrong — stiffness too high, damping too low → bounces forever
.interpolatingSpring(stiffness: 300, damping: 5)

// Right for physical snap-back
.interpolatingSpring(mass: 0.6, stiffness: 120, damping: 10, initialVelocity: 0)
```

**Haptic spam**
```swift
// Wrong — fires every .onChanged (up to 120x/sec)
.onChanged { feedbackGenerator.impactOccurred() }

// Right — rate-limited to 50ms minimum interval
.onChanged { value in
    if Date().timeIntervalSince(lastFeedbackTime) > 0.05 {
        feedbackGenerator.impactOccurred(intensity: 0.8)
        lastFeedbackTime = .now
    }
}
```

**Timer leaks**
```swift
// Leak — timer keeps firing after view disappears
let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

// Right — store cancellable, cancel on disappear; or use TimelineView(.animation)
```

**Library-heavy prototype**
```swift
// Wrong — import a broad dependency to avoid writing a tiny wrapper
import SwiftUIX

// Right — first ask whether a small UIViewRepresentable is enough
// Pull in SwiftUIX only when the missing control is genuinely reusable.
```
