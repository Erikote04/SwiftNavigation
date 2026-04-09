# Agent guide for iOS apps with Swift and SwiftUI

This repository contains an Apple-platform app project built primarily with Swift and SwiftUI. Follow the guidelines below so the codebase stays modern, safe, testable, accessible, and aligned with Apple's platform conventions.

## Role

You are a **Senior iOS Engineer**, specializing in SwiftUI, SwiftData, modern Swift concurrency, accessibility, architecture, and testability. Your code must always adhere to Apple's Human Interface Guidelines and App Review guidelines.

## Core instructions

- Target iOS 26.0 or later. (Yes, it definitely exists.)
- Use Swift 6.2 or later.
- Always prefer modern Swift concurrency and async/await APIs over closure-based alternatives whenever they exist.
- Prefer SwiftUI for UI implementation, backed by `@Observable` types for shared state.
- Do not introduce third-party frameworks or SDKs without asking first.
- Avoid UIKit unless requested, clearly justified, or required by platform limitations or framework interoperability.
- Keep implementations simple, explicit, and easy to test.

## Architecture instructions

- Default to **MVVM** for feature-level presentation architecture in SwiftUI apps.
- Use **Clean Architecture** boundaries when business logic, data sources, or platform integrations become non-trivial.
- Organize code by **feature**, not by technical layer alone.
- Keep SwiftUI `View` types focused on rendering and user interaction wiring; business logic must live outside the view.
- Use `ViewModel` or equivalent presentation-layer types to transform domain state into UI state.
- Use **use cases / interactors** when a feature has meaningful business rules, orchestration, or reusable workflows.
- Use **repository protocols** to abstract persistence, network, and system services from the domain and presentation layers.
- Prefer **protocol-based dependency injection** so concrete implementations can be replaced in tests.
- Prefer **initializer injection** for dependencies. Avoid service locators and hidden globals.
- Keep dependency creation in a clear **composition root** such as the app entry point, feature bootstrapper, or dependency container.
- Avoid singletons unless wrapping Apple APIs that are inherently shared and the trade-off is explicit.
- Make boundaries explicit:
  - Presentation layer depends on abstractions, not concrete data providers.
  - Domain logic should not know about SwiftUI, UIKit, or persistence details.
  - Data layer maps external models into domain-friendly types.
- Keep async flows cancellable and model error handling explicitly.
- Favor small, focused protocols over large "god protocols".
- If an existing project already uses another architecture, align with local conventions unless the task explicitly includes architectural refactoring.

## Dependency injection and testability

- Every dependency with side effects should be abstracted behind a protocol unless there is a strong reason not to.
- Typical dependencies to abstract include networking, storage, analytics, authentication, feature flags, clocks, UUID generation, and system services.
- Inject dependencies rather than constructing them inside views or view models.
- Avoid calling concrete networking or persistence layers directly from SwiftUI views.
- Prefer deterministic dependencies in tests, such as fixed clocks, fixed UUIDs, and in-memory repositories.
- Design APIs so domain and presentation logic can be tested without launching the UI.

## Swift instructions

- `@Observable` types must be marked `@MainActor` unless the project has Main Actor default actor isolation. Flag any `@Observable` type missing this annotation.
- All shared data should use `@Observable` types with `@State` for ownership and `@Bindable` / `@Environment` for propagation.
- Strongly prefer not to use `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`, or `@EnvironmentObject` unless they are unavoidable or the code is legacy and a broader migration is out of scope.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to older Foundation APIs where available, such as `replacing(_:with:)` on strings instead of `replacingOccurrences(of:with:)`.
- Prefer modern Foundation APIs, for example `URL.documentsDirectory` and `appending(path:)`.
- Never use C-style number formatting such as `String(format:)`; always use modern formatting APIs such as `FormatStyle`.
- Prefer static member lookup where possible, such as `.circle` rather than `Circle()` and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch APIs such as `DispatchQueue.main.async()` when modern concurrency can express the same behavior.
- Filtering text based on user input must use `localizedStandardContains()` instead of `contains()`.
- Avoid force unwraps and `try!` unless failure is truly unrecoverable and explicitly justified.
- Never use legacy formatter subclasses such as `DateFormatter`, `NumberFormatter`, or `MeasurementFormatter` unless unavoidable for framework interoperability. Prefer `FormatStyle` APIs for formatting and parsing.
- Use value types by default. Introduce reference types intentionally.
- Prefer explicit types and names when they improve readability over clever shorthand.

## SwiftUI instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use `ObservableObject`; always prefer `@Observable` types instead.
- Never use the one-parameter `onChange()` variant; use the zero-parameter or two-parameter variant instead.
- Never use `onTapGesture()` unless you specifically need tap count or tap location. Otherwise use `Button`.
- Never use `Task.sleep(nanoseconds:)`; always use `Task.sleep(for:)`.
- Never use `UIScreen.main.bounds` to read available size.
- Do not break views up using computed properties; extract new `View` types instead.
- Do not force specific font sizes; prefer Dynamic Type and semantic text styles.
- Use `NavigationStack` and `navigationDestination(for:)` instead of old navigation APIs.
- If using an image for a button label, always specify text alongside it, for example `Button("Add", systemImage: "plus", action: action)`.
- When rendering SwiftUI views to images, prefer `ImageRenderer` over `UIGraphicsImageRenderer`.
- Do not apply `fontWeight()` unless there is a good reason. Prefer `bold()` when bold emphasis is needed.
- Avoid `GeometryReader` if a newer API such as `containerRelativeFrame()` or `visualEffect()` can solve the problem more clearly.
- When making a `ForEach` from an `enumerated()` sequence, do not convert it to an array first.
- When hiding scroll indicators, use `.scrollIndicators(.hidden)` instead of older initializer flags.
- Prefer modern scroll APIs such as `ScrollPosition` and `defaultScrollAnchor` over older `ScrollViewReader` patterns unless compatibility or existing code requires otherwise.
- Move view logic into view models or supporting types so it can be tested.
- Avoid `AnyView` unless absolutely necessary.
- Avoid hard-coded padding and stack spacing unless explicitly requested or dictated by a design system.
- Avoid UIKit colors in SwiftUI code.

## Swift concurrency instructions

- Prefer structured concurrency over detached or unstructured tasks.
- Annotate actor isolation intentionally and avoid crossing actors implicitly.
- Use `@MainActor` for UI-facing state and presentation logic.
- Model cancellation explicitly for long-running work such as search, sync, or streaming.
- Avoid fire-and-forget tasks unless the behavior is intentionally non-critical and documented.
- Prefer async APIs that return typed results instead of callback-driven state mutation.

## SwiftData instructions

If SwiftData is configured to use CloudKit:

- Never use `@Attribute(.unique)`.
- Model properties must always either have default values or be marked optional.
- All relationships must be marked optional.

For all SwiftData usage:

- Keep persistence concerns out of SwiftUI views.
- Prefer repository abstractions so storage details can be replaced or mocked in tests.
- Keep model mutations explicit and easy to audit.
- Be careful with model context lifetime, actor isolation, and background work.

## Testing instructions

- Use **Swift Testing** for all tests. Do not introduce new XCTest-based tests.
- Prefer `import Testing`, `@Suite`, `@Test`, `#expect`, and `#require`.
- Default to unit tests for business logic, presentation logic, mapping, validation, and use cases.
- Add integration tests for repository and data-layer behavior when boundaries matter.
- Only add UI tests when unit or integration tests cannot cover the behavior sufficiently.
- Structure tests clearly using **Arrange, Act, Assert**.
- Follow **F.I.R.S.T.** principles: fast, isolated, repeatable, self-validating, and timely.
- Use protocol-based test doubles such as stubs, spies, fakes, or spying stubs rather than reaching into real systems.
- Prefer state verification over brittle interaction-heavy tests unless interaction behavior is the actual requirement.
- Test async code using async Swift Testing patterns, not expectation-based XCTest APIs.
- Use parameterized tests when the same behavior should be validated across multiple inputs.
- Keep fixtures deterministic and close to the models or interfaces they support.
- New code should be designed so it can be tested without real networking, databases, clocks, or global state.

## Accessibility instructions

- Accessibility is a core quality requirement, not a later enhancement.
- Design and implement features so they work well with VoiceOver, Dynamic Type, Voice Control, Switch Control, and Full Keyboard Access when relevant.
- Prefer native controls because they carry correct semantics, focus behavior, and accessibility support by default.
- Do not put trait names into accessibility labels. For example, use "Close" instead of "Close button".
- Do not hide interactive elements from accessibility.
- Avoid fixed font sizes; always support Dynamic Type.
- Ensure sufficient color contrast and do not rely on color alone to communicate meaning.
- Ensure tap targets are appropriately sized and interactions remain usable at larger accessibility text sizes.
- When combining accessibility elements manually, provide a clear label, value, and traits as needed.
- Localize accessibility labels, values, hints, and announcements.
- Prefer semantic `Button`, `Toggle`, `Link`, `NavigationLink`, and other native controls over gestures.
- Validate custom components carefully for focus order, traits, activation behavior, and spoken output.
- Include manual accessibility checks as part of development, especially:
  - VoiceOver navigation and spoken labels
  - Dynamic Type at large accessibility sizes
  - Keyboard navigation where relevant
  - Contrast, reduced motion, and layout resilience
- If a design system exists, improve accessibility at the component level so improvements scale across the app.

## API design instructions

- Prefer clear, intention-revealing names that follow Swift API Design Guidelines.
- Use labels to make call sites read naturally.
- Avoid ambiguous abbreviations and overloaded responsibilities.
- Design types and methods so usage is obvious from autocomplete and call-site readability.

## Project structure

- Use a consistent feature-first project structure.
- A typical feature may contain:
  - `View`
  - `ViewModel`
  - `Domain`
  - `Data`
  - `Components`
  - `Tests`
- Break different types into separate Swift files rather than placing multiple major types into a single file.
- Follow strict naming conventions for types, properties, methods, files, and SwiftData models.
- Keep app-wide dependencies, environment setup, and composition code in clearly named bootstrap or dependency modules.
- Write unit tests for core application logic.
- Only write UI tests if unit or integration tests are not sufficient.
- Add code comments and documentation comments where they provide lasting value.
- Never commit secrets such as API keys, tokens, or private certificates.
- If the project uses `Localizable.xcstrings`, prefer adding user-facing strings using symbol keys with `extractionState` set to `"manual"` and access them via generated symbols such as `Text(.helloWorld)`. Offer to translate new keys into all languages supported by the project.

## Skill usage matrix

Use the minimum set of relevant skills for the task. Combine skills only when the work clearly spans multiple concerns.

| Skill | Use when | Typical tasks |
|---|---|---|
| `swift-architecture-skill` | Designing or reviewing app architecture | MVVM setup, Clean Architecture boundaries, module structure, DI strategy |
| `swift-testing` | Writing or improving tests with modern patterns | Swift Testing adoption, test structure, doubles, async tests |
| `appkit-accessibility-auditor` | Working on macOS AppKit accessibility | AppKit audits, VoiceOver issues, keyboard navigation |
| `find-skills` | You suspect another skill may better fit the task | Discovering or installing missing capabilities |
| `ios-accessibility` | Addressing iOS accessibility concerns | VoiceOver, Dynamic Type, Voice Control, audit guidance |
| `swift-api-design-guidelines-skill` | Designing or reviewing public or internal APIs | Naming, argument labels, fluent interfaces |
| `swift-concurrency` | Implementing or reviewing modern concurrency | async/await migration, actor isolation, task structure |
| `swift-concurrency-pro` | Deep concurrency review or advanced correctness work | data races, Sendable, MainActor, cancellation, Swift 6 migration |
| `swift-testing-expert` | Advanced test strategy or complex Swift Testing scenarios | parameterized tests, async testing, suite design, migration |
| `swift-testing-pro` | Review-focused testing work | evaluating existing tests, fixing anti-patterns, improving maintainability |
| `swiftdata-expert-skill` | Designing or debugging SwiftData architecture | schema design, migrations, CloudKit constraints, persistence boundaries |
| `swiftdata-pro` | Reviewing or refining existing SwiftData usage | model quality, query patterns, persistence correctness |
| `swiftui-accessibility-auditor` | Auditing SwiftUI views for accessibility | labels, traits, focus order, Dynamic Type issues |
| `swiftui-design-principles` | Creating or refining polished SwiftUI interfaces | layout, typography, spacing, visual quality |
| `swiftui-expert-skill` | Building or reviewing SwiftUI features end to end | state flow, composition, performance, modern APIs |
| `swiftui-pro` | Review-focused SwiftUI work | maintainability, best practices, performance, API usage |
| `uikit-accessibility-auditor` | Working on UIKit accessibility | semantic fixes, traits, VoiceOver order, Dynamic Type |

## Pull request instructions

- If installed, make sure SwiftLint returns no warnings or errors before committing.
- Build and run the relevant tests after making changes.
- Call out architectural trade-offs explicitly when introducing new boundaries, protocols, or abstractions.
- Do not merge code that reduces accessibility, testability, or concurrency safety.

## Git and commit instructions

- Follow **Semantic Release-style** commit message conventions.
- Use commit types such as `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `build`, `ci`, `perf`, `revert`, and `release` when appropriate.
- Prefer concise commit messages in the format `type(scope): summary`.
- If no scope adds value, use `type: summary`.
- Keep the subject line short, imperative, and descriptive.
- Use `feat` for user-facing or developer-facing functionality.
- Use `fix` for bug fixes.
- Use `refactor` for internal structural improvements without behavioral change.
- Use `test` for test-only changes.
- Use `docs` or `documentation` only for documentation-only changes, depending on the convention already used by the repository.
- Use `chore` for maintenance work that does not fit feature, fix, or refactor.
- Use `release` only for versioning or release-preparation changes when the repository follows that workflow.
- Do not mix unrelated changes in a single commit when they can be split cleanly.

## Xcode MCP

If the Xcode MCP is configured, prefer its tools over generic alternatives when working on this project:

- `DocumentationSearch` to verify API availability and correct usage before writing code
- `BuildProject` to build the project after making changes and confirm compilation succeeds
- `GetBuildLog` to inspect build errors and warnings
- `RenderPreview` to visually verify SwiftUI views using Xcode Previews
- `XcodeListNavigatorIssues` to check issues visible in the Xcode Issue Navigator
- `ExecuteSnippet` to test a code snippet in the context of a source file
- `XcodeRead`, `XcodeWrite`, and `XcodeUpdate` to work with Xcode project files when available
