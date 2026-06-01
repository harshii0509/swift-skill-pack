# SwiftUI Vocabulary for Modern Apple UI

Use this reference when the request mentions iOS 26, Liquid Glass, safe areas, top or bottom bars, tab bars, bottom accessories, or when you need to teach the user the exact SwiftUI term instead of vague wording.

The goal is API-accurate language with plain-English translation.

---

## Response Rule

When the prompt depends on newer SwiftUI UI chrome, do both:

- say the exact SwiftUI API name
- immediately translate it into plain English

Example:

- `safeAreaBar(edge: .bottom)` means “a real custom bottom bar that also updates safe area and scroll-edge behavior,” not just “a bottom overlay.”

Avoid fuzzy phrasing like “safe space” when the correct term is `safe area`.

---

## Bar Vocabulary

### Top Bar

- `ToolbarItemPlacement.topBarLeading`
- `ToolbarItemPlacement.topBarTrailing`

Use “top bar” when talking about SwiftUI toolbar placement APIs.
On iOS, that top bar is rendered in the navigation bar region.

Do not conflate:

- API term: `topBarLeading` / `topBarTrailing`
- rendered surface: navigation bar

### Bottom Bar

- `ToolbarItemPlacement.bottomBar`
- `ToolbarPlacement.bottomBar`

Use “bottom bar” only for the bottom toolbar region.
Do not use it as a synonym for the tab bar.

### Tab Bar

- `TabView`
- `ToolbarPlacement.tabBar`

Use “tab bar” for app tab navigation chrome.
If the UI is switching between tabs, this is the tab bar, not the bottom bar.

### Bottom Accessory

- `tabViewBottomAccessory { ... }`
- `EnvironmentValues.tabViewBottomAccessoryPlacement`
- `TabViewBottomAccessoryPlacement`

Use this when a view belongs to the `TabView` chrome itself.
On iPhone, Apple says the accessory sits above the tab bar when expanded and inline when the tab bar is collapsed.

---

## Safe-Area Vocabulary

### Safe Area

- `SafeAreaRegions`
- `SafeAreaRegions.container`

Use “safe area” for the protected layout region created by the device and UI chrome, including top and bottom bars.

### `safeAreaInset`

- `safeAreaInset(edge:alignment:spacing:content:)`

Use when you want to add content that makes space in layout.
This is the older, generic inset tool.

### `safeAreaBar`

- `safeAreaBar(edge:alignment:spacing:content:)`

Use when the content should behave like a real custom bar.
Apple’s docs say it adjusts the safe area and the scroll edge effects to match.

Practical distinction:

- `safeAreaInset`: “make room for this content”
- `safeAreaBar`: “make room for this content, and treat it like bar chrome”

### `safeAreaPadding`

- `safeAreaPadding(_:)`

Use when the content should respect existing safe-area insets without adding new chrome.

### `ignoresSafeArea`

- `ignoresSafeArea(_:edges:)`

Use only when you deliberately want content to bleed under system chrome.
Do not use it as the first fix for a bar-integration bug.

---

## Scroll + Chrome Vocabulary

### Scroll Edge Effect

- `scrollEdgeEffectStyle(_:for:)`
- `scrollEdgeEffectHidden(_:for:)`
- `ScrollEdgeEffectStyle.automatic`
- `ScrollEdgeEffectStyle.soft`
- `ScrollEdgeEffectStyle.hard`

This is Apple’s iOS 26 scroll-pocket / edge treatment for scroll views.
If the user says “that fade/pocket near the bar,” translate that to “scroll edge effect.”

### Background Extension

- `backgroundExtensionEffect(isEnabled:)`

Apple describes this as duplicating, mirroring, and blurring content around edges with available safe areas.
Use it for edge-background integration, not as a general-purpose blur hack.

### Tab Bar Minimization

- `tabBarMinimizeBehavior(_:)`
- `TabBarMinimizeBehavior.onScrollDown`
- `TabBarMinimizeBehavior.onScrollUp`

Use this when the tab bar should collapse or minimize with scroll.
Apple’s docs note iPhone support for scroll-triggered minimization.

### Toolbar Spacing

- `ToolbarSpacer`

Use this term when talking about visual breaks between Liquid Glass toolbar items.

---

## Liquid Glass Vocabulary

### Core APIs

- `glassEffect(_:in:)`
- `Glass`
- `GlassEffectContainer`
- `glassEffectID(_:in:)`
- `.buttonStyle(.glass)`
- `.buttonStyle(.glassProminent)`

Use “Liquid Glass” for the design/material system.
Use the exact API names when discussing custom implementation.

### Meaning

- `glassEffect`: apply Liquid Glass to a custom view
- `GlassEffectContainer`: group multiple glass shapes so they can combine and morph efficiently
- `glassEffectID`: give glass shapes matching identities for morphing transitions

---

## Translation Patterns

If the user says:

- “safe space” → translate to `safe area`
- “top bar” → likely `topBarLeading` / `topBarTrailing` or navigation bar, depending on context
- “bottom bar” → ask whether they mean toolbar, tab bar, or a custom bar
- “mini player above tabs” → likely `tabViewBottomAccessory` or `safeAreaBar`
- “content fading into the bars” → likely scroll edge effect / `scrollEdgeEffectStyle`
- “glass button cluster” → likely `glassEffect`, `GlassEffectContainer`, or glass button styles

---

## Planning Rule

When writing a plan or recommendation:

1. name the surface correctly
2. name the SwiftUI API
3. explain why that API fits better than the nearby alternatives

Good example:

- “Use `tabViewBottomAccessory` if the mini-player belongs to the tab chrome and should move between expanded and inline placements with the tab bar. Use `safeAreaBar` when it should behave like an app-owned custom bar independent of tab placement.”
