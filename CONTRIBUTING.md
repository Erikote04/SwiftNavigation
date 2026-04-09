# Contributing to SwiftNavigation

Thanks for your interest in improving SwiftNavigation. Contributions that make the library, sample app, and bundled skill clearer, safer, and easier to adopt are welcome.

## Repository Areas

This repository currently includes:

- The `SwiftNavigation` library package
- The `Sample App` that demonstrates the public API in a realistic SwiftUI app
- The `skill/` folder, which packages a reusable AI skill for integrating SwiftNavigation

## Contributing to the Library and Sample App

Use this section when your change affects the package, public API, sample app behavior, tests, or documentation for SwiftNavigation itself.

## Types of Contributions

- Fix library bugs or behavioral regressions
- Improve route, coordinator, alert, sheet, deep-link, or state-restoration APIs
- Add or improve tests
- Improve the sample app to better demonstrate recommended usage
- Clarify README or DocC documentation
- Improve migration guidance and integration examples

## Development Workflow

1. Fork the repo, or create a branch if you already have access.
2. Keep changes focused and scoped to one concern when possible.
3. Update tests and docs when public behavior changes.
4. Run the relevant verification commands before opening a PR.
5. Open a PR with a short summary, test notes, and any migration or trade-off details.

## Quality Standards

- Keep the library API type-safe and Swift-friendly.
- Prefer MVVM-C-friendly patterns consistent with the repo.
- Keep public route data `Codable` and restoration-safe.
- Prefer `@Observable`, Swift Concurrency, and modern SwiftUI APIs.
- Keep sample app changes aligned with the recommended library integration style.
- Avoid introducing third-party dependencies without discussion first.

## Testing and Verification

Run the package tests when you touch the library:

```bash
swift test
```

Run the sample app tests when you touch sample app flows, deep links, or integration behavior:

```bash
xcodebuild \
  -project 'Sample App/SwiftNavigationSampleApp/SwiftNavigationSampleApp.xcodeproj' \
  -scheme SwiftNavigationSampleApp \
  -destination 'platform=iOS Simulator,id=8DE52934-0BE7-4772-B5D7-EB91450783F8' \
  -only-testing:SwiftNavigationSampleAppTests \
  test
```

If your change affects documentation only, note that explicitly in the PR.

## Documentation Expectations

- Update `README.md` when installation, requirements, or top-level usage changes.
- Update DocC guides when public workflows change.
- Update `Sample App/README.md` when showcase behavior or deep-link commands change.

## Pull Request Notes

Helpful PR descriptions usually include:

- What changed
- Why it changed
- What you tested
- Whether the change affects migration or adoption

## Contributing to the SwiftNavigation Skill

Use this section when your change affects `skill/SKILL.md`, the reference files under `skill/references/`, or the plugin and installation metadata in `skill/`.

## About Agent Skills

Agent Skills are structured prompt assets with:

- A `SKILL.md` file that defines behavior and checklists
- Reference files that provide focused guidance for specific topics

## Recommended Workflow (Skill Creator)

If you use the `skill-creator` skill, you can:

- Propose changes in plain language
- Have the skill generate or refine `SKILL.md` and reference content
- Review for SwiftNavigation API accuracy, workflow clarity, and repo alignment

## Alternative Workflows

### Claude without skill-creator

- Make changes directly in `skill/SKILL.md` or `skill/references/`
- Keep content concise and focused on SwiftNavigation integration

### Manual edits

- Edit Markdown or metadata files directly
- Ensure `SKILL.md`, references, and installation guidance stay consistent

## Types of Skill Contributions

- Fix incorrect SwiftNavigation guidance
- Add missing coverage for routes, coordinators, alerts, sheets, deep links, universal links, or restoration
- Improve clarity in workflows and checklists
- Expand reference files with focused integration examples
- Improve installation or plugin metadata in `skill/README.md` or `.claude-plugin/`

## Skill Quality Standards

- Keep the skill focused on SwiftNavigation integration
- Prefer repo-aligned guidance over generic coordinator advice
- Avoid drifting away from the actual public API or sample app patterns
- Keep content concise and practical
- Use references to keep `SKILL.md` lean

## Skill Maintenance Notes

- If you rename reference files, keep `skill/README.md` and `skill/SKILL.md` in sync
- If you change plugin metadata, keep `.claude-plugin/` and `agents/openai.yaml` consistent
- If the public SwiftNavigation API changes, review the skill for stale guidance

## Resources

- Agent Skills documentation: https://docs.anthropic.com/en/docs/claude-code/agent-skills
- SwiftNavigation documentation site: https://erikote04.github.io/SwiftNavigation/documentation/swiftnavigation/
- SwiftNavigation sample app guide: `Sample App/README.md`

## Code of Conduct

Be respectful and constructive. Assume positive intent and focus on improving the quality of the library, sample app, and skill.
