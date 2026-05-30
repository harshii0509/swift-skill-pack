# Inferno Patterns

Use this reference when the task involves SwiftUI shaders, distortion effects, GPU-friendly visual polish, or when the user explicitly mentions `Inferno`.

This guidance is informed by Paul Hudson's `twostraws/Inferno` project and Apple’s SwiftUI shader APIs.

---

## What Inferno Is Good At

Inferno is an open-source collection of Metal fragment shaders for SwiftUI. Its upstream README describes it as a set of shaders that are easy to read, easy to copy into an app, and useful both for beginners and for production effect work.

High-value use cases:

- ripple, distortion, emboss, noise, gradients, and glow-style effects
- transition shaders where you want a stronger visual identity than stock SwiftUI transitions
- variable blur and other effects where GPU execution matters
- effect prototyping when the team wants to learn from readable `.metal` examples rather than build every shader from first principles

Inferno’s own sample project is SwiftUI-based and currently targets iOS 17 and macOS 14 for the demo app, which matches the platform generation where SwiftUI shader APIs became practical for app UI work.

Source references:

- GitHub: https://github.com/twostraws/Inferno
- Swift Package Index: https://swiftpackageindex.com/twostraws/Inferno

---

## Decision Rule

Choose among four options:

1. Plain SwiftUI animation
   Use when the effect is mostly transform, opacity, scale, blur, or layout-driven.
2. SwiftUI `Canvas` / `Shader`
   Use when you need a dynamic visual effect but can still stay inside SwiftUI’s rendering model.
3. Inferno
   Use when you want a proven shader effect quickly, or when an existing Inferno shader is close to the desired outcome.
4. Custom Metal pipeline
   Use when the effect is highly app-specific, performance-critical, export-oriented, or fundamentally beyond a copied fragment shader.

Default bias:

- Start with plain SwiftUI.
- Escalate to `Canvas` or `Shader`.
- Use Inferno when it meaningfully shortens the path.
- Drop to custom Metal only when the effect or pipeline truly demands it.

---

## Good Use Cases

- `I want a refractive glass/ripple effect on top of a card.`
- `Can we make this transition dissolve or warp instead of just fading?`
- `I want a polished GPU effect without building a Metal app from scratch.`
- `We want to prototype a shader-heavy effect and learn from readable source.`

---

## Bad Use Cases

- Pulling in Inferno for a simple scale/opacity/offset animation.
- Reaching for a full shader when `Material`, `mask`, `blendMode`, or `Canvas` would be enough.
- Treating Inferno like a general architecture dependency instead of a localized visual-effects tool.
- Assuming an Inferno shader should be imported wholesale before understanding the effect boundary.

---

## Integration Pattern

Inferno’s own README recommends copying the relevant `.metal` file into your app, rather than adopting the whole sample project. For transition shaders, upstream also calls out copying `Transitions.swift` where needed.

Keep the boundary small:

- isolate the effect in one view or modifier
- avoid scattering shader-specific parameters across unrelated view code
- if the effect becomes part of product identity, wrap it in a local app-specific API

Example shape:

```swift
struct HeroRippleCard: View {
    var progress: CGFloat

    var body: some View {
        CardSurface()
            .modifier(AppRippleShader(progress: progress))
    }
}
```

App code should depend on `HeroRippleCard` or `AppRippleShader`, not directly on a copied upstream shader name everywhere.

---

## Review Checklist

- Is the visual problem genuinely shader-worthy?
- Could native SwiftUI animation or `Canvas` solve it more simply?
- Is the Inferno shader being used at a leaf view boundary?
- Are shader parameters semantic and local, rather than leaking through unrelated view code?
- Is the deployment target compatible with the intended SwiftUI shader usage?

---

## When To Escalate Beyond Inferno

Move past Inferno when:

- you need a custom export/render pipeline
- the effect depends on scene data or multi-pass rendering
- you need deterministic frame-by-frame output
- you need control beyond a reusable fragment effect

In those cases, return to `custom-rendering.md` and `../../swift-patterns/references/rendering-performance.md`.
