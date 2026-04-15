# SwiftNavigation Skill

Practical guidance for any AI coding tool that supports the [Agent Skills open format](https://agentskills.io/home) and needs to integrate the `SwiftNavigation` library into a SwiftUI app the right way.

This skill distills the library README, DocC guides, and maintained integration patterns into an implementation-focused workflow for routes, coordinators, view models, sheets, full screen covers, alerts, deep links, universal links, and state restoration.

## Who this is for

- Teams integrating `SwiftNavigation` into a production SwiftUI app
- Developers migrating an app to typed coordinator-driven navigation
- Anyone who wants a repo-aligned SwiftNavigation setup without digging through all docs and sample code first

## How to Use This Skill

### Option A: Using `skills.sh` (recommended)

Install this skill from the SwiftNavigation repository:

```bash
npx skills add https://github.com/erikote04/SwiftNavigation --skill swift-navigation-skill
```

Then use the skill in your AI agent, for example:

> Use the swift-navigation-skill and integrate SwiftNavigation into this app with app and child coordinators, deep links, alerts, sheets, and state restoration.

### Option B: Claude Code Plugin

The `.claude-plugin` metadata is included in this folder so it can be published or copied as a standalone plugin package.

#### Personal Usage

If you publish `skill/` as its own repository, add the marketplace:

```bash
/plugin marketplace add Erikote04/SwiftNavigation
```

Then install the plugin:

```bash
/plugin install swift-navigation-skill@swift-navigation-skill
```

#### Project Configuration

To automatically provide this skill to everyone working in a repository, configure `.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "swift-navigation-skill@swift-navigation-skill": true
  },
  "extraKnownMarketplaces": {
    "swift-navigation-skill": {
      "source": {
        "source": "github",
        "repo": "Erikote04/SwiftNavigation"
      }
    }
  }
}
```

### Option C: Manual Install

1. Clone this repository.
2. Copy or symlink the [`skill/`](./) folder into your AI tool's skills directory.
3. Ask your AI tool to use the `swift-navigation-skill` skill for SwiftNavigation integration work.

#### Where to Save Skills

Follow your tool's official documentation:

- Codex: [Where to save skills](https://developers.openai.com/codex/skills/#where-to-save-skills)
- Claude: [Using Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#using-skills)
- Cursor: [Enabling Skills](https://cursor.com/docs/context/skills#enabling-skills)

How to verify:

- Your agent should reference the implementation workflow in [`SKILL.md`](./SKILL.md)
- It should then load the relevant files from [`references/`](./references/) for the current task

## What This Skill Offers

This skill helps an AI coding tool implement SwiftNavigation in a library-aligned, project-adaptable way.

### Build the Core Navigation Surface

- Define `AppRoute`, `AppModalRoute`, and `AppAlertRoute`
- Model route payloads for persistence, deep links, and reviewability
- Use `NavigationEntryID` for exact back-navigation in repeated flows

### Implement Coordinators and MVVM-C Wiring

- Create a single root `NavigationCoordinator`
- Add app and child coordinators with `NavigationRouterProxy`
- Inject routing protocols into `@Observable` view models
- Keep dependency creation in the composition root

### Implement Presentation Correctly

- Build a single `RoutingView`
- Map stack destinations, sheets, full screen covers, and alerts
- Configure `SheetPresentationOptions`
- Keep SwiftUI views free from duplicated navigation state

### Add External Navigation and Restoration

- Build URL and notification deep-link resolvers
- Add login interception and pending navigation resume
- Wire universal links through the same URL pipeline
- Save, persist, and restore `NavigationState`

## What Makes This Skill Different

Repo-aligned: It follows the actual SwiftNavigation v2 API surface and documented integration model.

Flow-oriented: It emphasizes entry-backed navigation and exact backtracking for real multi-step flows.

Integration-first: It covers the whole setup, not just route enums or a single coordinator snippet.

## Skill Structure

```text
skill/
  SKILL.md
  README.md
  agents/
    openai.yaml
  references/
    workflow.md - End-to-end setup sequence for integrating SwiftNavigation
    routes-and-state.md - Route design, NavigationState, and NavigationEntryID guidance
    coordinators-and-di.md - App coordinator, child coordinators, routing protocols, and DI patterns
    presentation.md - RoutingView, sheets, full screen covers, and alerts
    deep-links-and-universal-links.md - URL, notification, universal-link, and interception patterns
    state-restoration.md - Snapshot persistence and restoration guidance
  .claude-plugin/
    plugin.json
    marketplace.json
```

## Publishing Note

This skill currently lives inside the main SwiftNavigation repository under `skill/`. If you want to distribute it as a standalone plugin repository, keep the contents of this folder together and update repository or license metadata as needed for that package.

## License

This repository now uses the MIT License. See [../LICENSE](../LICENSE) for details.
