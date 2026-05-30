# SwiftUIX Patterns

Use this reference when the task involves `SwiftUIX`, missing SwiftUI controls, or deciding whether a third-party bridge is better than a custom wrapper.

This guidance is informed by SwiftUIX itself, plus the UIKit and SwiftUI hybrid patterns seen in `any-distance-ios`.

---

## What SwiftUIX Is Good At

SwiftUIX describes itself as an expansion of SwiftUI that fills gaps with components, extensions, and utilities. It is especially useful when you need Apple-platform controls that SwiftUI still does not expose ergonomically.

High-value categories from the project include:

- UIKit-to-SwiftUI ports such as `CollectionView`, `CocoaList`, `CocoaTextField`, `CocoaScrollView`, `PaginationView`, and `VisualEffectView`
- System helpers such as keyboard-aware padding, navigation-bar helpers, and window overlays
- Bridged utility views such as `ActivityIndicator`, `ImagePicker`, `SearchBar`, and `LinkPresentationView`

Prefer it when the missing control is mature, reusable, and likely to appear in multiple screens.

The current upstream repository also frames SwiftUIX as a broad SwiftUI gap-filler with Swift Package Manager installation, documentation on `swiftuix.github.io`, and compatibility across Apple platforms including iOS, macOS, tvOS, watchOS, and visionOS.

---

## Decision Rule

Choose among three options:

1. Native SwiftUI
   Use when modern SwiftUI already solves the need cleanly on the app's deployment target.
2. SwiftUIX
   Use when the app needs a common UIKit/AppKit-backed control quickly and you want a maintained bridge instead of writing it from scratch.
3. Custom representable
   Use when behavior is highly app-specific, lifecycle-sensitive, or only needed in one place.

Default bias:

- Start native.
- Use SwiftUIX for common controls.
- Drop to a custom wrapper for special behavior.

---

## Architectural Guardrails

- Keep `import SwiftUIX` close to feature edges rather than scattered across the whole app.
- Wrap SwiftUIX types in local views when they are likely to become app conventions.
- Avoid exposing SwiftUIX-specific types deep in domain or state-management layers.
- If a control becomes central to the design system, create a local facade so the package can be swapped later.

Example:

```swift
import SwiftUI
import SwiftUIX

struct AppSearchField: View {
    @Binding var text: String

    var body: some View {
        SearchBar("Search", text: $text)
    }
}
```

The rest of the codebase should usually use `AppSearchField`, not `SearchBar` directly.

This mirrors the shape used in `any-distance-ios`, where thin local wrappers like `SearchField`, `ZoomableScrollView`, and `TappableScrollView` prevent raw UIKit details from leaking through the whole app.

---

## Good Use Cases

- You need a UIKit-backed `SearchBar` now and native `.searchable` is not enough for the design or deployment target.
- You need paging behavior closer to `UIPageViewController` through `PaginationView`.
- You need a blur or visual-effect surface through `VisualEffectView`.
- You need collection-style behavior closer to `UICollectionView`.
- You need a bridged text input surface such as `CocoaTextField` or `TextView`.
- You need a keyboard-aware layout helper without rebuilding the same observer logic.
- You need a quick bridge for image picking, link previews, or activity sheets.

---

## Bad Use Cases

- Importing SwiftUIX for a one-off behavior that a 20-line `UIViewRepresentable` would solve.
- Reaching for SwiftUIX before checking whether current SwiftUI already supports the feature.
- Threading SwiftUIX dependencies into non-UI layers.
- Depending on package internals instead of the documented public API.

---

## Review Checklist

- Is the feature actually missing from the app's target SwiftUI API surface?
- Would a local wrapper reduce coupling?
- Is the team comfortable carrying the dependency for this use case?
- Is the SwiftUIX control isolated enough to replace later?
- Do previews and tests still work if the wrapped control is unavailable on a platform?

---

## Integration Notes

- SwiftUIX's repository documents Swift Package Manager installation and positions the package as a bridge for UIKit/AppKit gaps.
- The project lists controls such as `CollectionView`, `SearchBar`, `CocoaTextField`, `PaginationView`, `VisualEffectView`, `ImagePicker`, and keyboard helpers.
- The upstream repo currently calls out Swift 5.10+, Xcode 15.4+, and multi-platform support, so treat adoption as an app-level dependency decision rather than a throwaway experiment import.
- Treat it as UI infrastructure, not as application architecture.

If a user explicitly asks for `SwiftUIX`, load this file together with `uikit-swiftui-bridge.md`.
