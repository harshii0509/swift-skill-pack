# Food Truck Patterns

Use this reference when the task involves multiplatform SwiftUI architecture, app organization across iPhone/iPad/Mac, `NavigationSplitView`, `Layout`, widgets, ActivityKit, or “single codebase, multiple Apple surfaces”.

This guidance is informed by Apple’s official `Food Truck` sample.

Primary source:

- https://developer.apple.com/documentation/swiftui/food-truck-building-a-swiftui-multiplatform-app

---

## What Food Truck Is Good At

Food Truck is one of Apple’s clearest public examples of a modern SwiftUI app that spans iPhone, iPad, and Mac from one app target. The sample explicitly demonstrates:

- `NavigationSplitView` plus `NavigationStack`
- custom `Layout`
- Swift Charts
- widgets
- ActivityKit / Live Activities / Dynamic Island
- WeatherKit integration
- a shared codebase with multiple surfaces

Use it as a structure and surface-integration reference, not as a mandate to copy its exact app organization or product domain.

---

## Decision Rule

Reach for Food Truck patterns when:

- the user wants one SwiftUI codebase across multiple Apple platforms
- the app needs multiple presentation surfaces, not just one screen
- the question is about how SwiftUI app structure scales beyond toy examples

Do not use it as the primary reference for:

- prototype interaction craft
- UIKit bridge debugging
- specialized third-party architecture debates

---

## High-Value Patterns

### One app target, multiple platforms

Food Truck demonstrates that a single SwiftUI app target can serve Mac, iPad, and iPhone without inventing separate architecture per platform.

Use this when:

- domain logic is mostly shared
- platform differences are primarily in presentation and surface adaptation

### Split view + stack composition

The sample’s `NavigationSplitView` with a `NavigationStack` inside the detail region is a strong reference for apps with:

- sidebar-driven selection
- deep detail navigation
- adaptive iPad/Mac layouts

### Surface expansion

Food Truck is a good reminder that modern Apple apps may need more than “just the main app”:

- widgets
- Live Activities
- Dynamic Island
- platform-adaptive toolbars and sidebars

When the request spans these surfaces, think in terms of shared domain state with distinct presentation layers.

### Modern framework composition

The sample shows SwiftUI playing well with:

- Charts
- WeatherKit
- ActivityKit
- widgets

Use it to justify that SwiftUI production architecture can remain SwiftUI-first even when the app touches multiple Apple frameworks.

---

## Good Use Cases

- `How should we structure a SwiftUI app that runs well on iPhone, iPad, and Mac?`
- `Should we use NavigationSplitView or force everything through a single NavigationStack?`
- `What is a good official Apple sample for production SwiftUI app organization?`

---

## Bad Use Cases

- Treating Food Truck as an architecture framework.
- Copying sample code patterns without checking whether the product actually needs split view, widgets, or Live Activities.
- Using it as the main answer to a debugging question.

---

## Review Checklist

- Is the app really multiplatform, or only nominally so?
- Does the navigation structure reflect the product’s information architecture?
- Do extra surfaces like widgets or Live Activities deserve first-class planning?
- Is the shared codebase genuinely shared, or are platform differences forcing awkward abstractions?

---

## Escalation Rule

If the problem becomes more about state-driven navigation design, load `swift-navigation-patterns.md`.

If it becomes more about backported observation or deployment-target support, load `swift-perception-patterns.md`.
