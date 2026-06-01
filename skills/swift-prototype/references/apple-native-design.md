# Apple-Native Design

Use this reference when the task is about making SwiftUI UI feel native to Apple platforms, or when the user explicitly mentions HIG, Human Interface Guidelines, platform conventions, materials, layout, toolbars, or “feels at home on iPhone/iPad/Mac”.

This guidance is informed by Apple’s Human Interface Guidelines and SwiftUI design fundamentals.

---

## What “Apple-Native” Usually Means

Apple’s current Human Interface Guidelines foreground three principles in particular:

- hierarchy
- harmony
- consistency

For SwiftUI work, that usually means:

- clear content emphasis before decorative chrome
- using system materials, spacing, and controls where they already solve the problem
- respecting platform conventions instead of inventing a design language that fights the device
- letting current platform chrome adopt the latest system appearance before customizing it

Primary sources:

- HIG: https://developer.apple.com/design/human-interface-guidelines/
- SwiftUI overview: https://developer.apple.com/documentation/swiftui
- Interface fundamentals: https://developer.apple.com/documentation/technologyoverviews/interface-fundamentals
- Liquid Glass overview: https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass

---

## Decision Rule

Choose among three modes:

1. Native-first polish
   Use when the app should feel obviously at home on Apple platforms.
2. Expressive but compliant
   Use when the user wants a stronger visual identity without violating platform expectations.
3. Deliberately experimental
   Use when the request is explicitly prototype/art-direction-first, not production-native.

Default bias:

- For product UI, stay in native-first polish unless the user clearly asks for a bolder visual language.

---

## High-Value HIG Checks

### Hierarchy

- Is the primary task visually dominant?
- Are controls visually secondary to content when appropriate?
- Is there one obvious focal action per region?

### Harmony

- Do shapes, materials, and motion feel coherent with the platform?
- Are glass/material effects supporting the interface rather than competing with it?
- Does the composition feel comfortable at Apple default text sizes and spacing?

### Consistency

- Are standard controls used where possible?
- Do toolbars, search fields, sheets, lists, and split views behave like their platform peers?
- Does the same interaction pattern mean the same thing across the app?
- If the app targets the latest SDKs, are standard bars and controls being allowed to pick up the current system look before custom styling is added?

---

## Good Use Cases

- `Make this SwiftUI settings screen feel like a real iOS settings surface.`
- `Review whether this toolbar/search layout feels Apple-native.`
- `We want stronger visual polish, but still want App Store-friendly platform fit.`

---

## Bad Use Cases

- Treating HIG as a rulebook that forbids all visual personality.
- Replacing standard navigation and input patterns without a strong reason.
- Using materials, blur, and motion as decoration with no hierarchy payoff.
- Fighting current system chrome with custom opaque bar backgrounds or hand-rolled blur overlays.
- Asking HIG questions when the real problem is state ownership or a broken implementation.

---

## Practical SwiftUI Guidance

- Prefer system controls and built-in behaviors before custom replicas.
- Use `Material` and system backgrounds before inventing custom glass stacks.
- If the UI specifically targets iOS 26+, prefer native Liquid Glass and standard bars before layering custom blur.
- Let platform navigation patterns stay recognizable: split views, stacks, sheets, toolbars, search.
- Keep motion purposeful and restrained in product surfaces; save the loudest effects for prototypes or hero moments.
- Treat accessibility, Dynamic Type, and layout adaptability as part of “native feel,” not as separate cleanup work.

---

## Review Checklist

- Does the screen have a clear visual hierarchy?
- Are materials, tint, and spacing helping readability rather than muddying it?
- Would this feel at home next to first-party Apple apps?
- Are standard controls doing the job already?
- Is the design expressive in a way that still preserves predictability?

---

## Escalation Rule

If the request becomes more about gesture craft, animation personality, or experimental visual effects, pivot to `animation-craft.md` or `inferno-patterns.md`.

If the request becomes specifically about Liquid Glass, custom bar APIs, or iOS 26 safe-area surfaces, load `liquid-glass.md`.

If the request becomes about app-wide structure or multiplatform composition, load `../../swift-patterns/references/food-truck-patterns.md`.
