# Directory Structure Convention

```
ProjectRoot/
├── .claude/                  → Claude Code configuration
│   ├── rules/                → Always-loaded governance
│   ├── skills/               → On-demand knowledge
│   ├── agents/               → Autonomous specialists
│   ├── scripts/              → Shell automation
│   ├── hooks/                → Lifecycle hooks
│   └── errors/               → Error learning ledger
├── AppName/                  → Main app source
│   ├── App/                  → @main entry, RootView, MainView
│   ├── Models/               → Data models (with static sampleData)
│   ├── Features/             → Feature modules
│   │   ├── FeatureName/      → View + ViewModel co-located
│   │   └── Common/           → Shared reusable views
│   ├── Theme/                → AppTheme.swift only
│   ├── Services/             → Domain services (not in Features/)
│   │   └── DomainName/       → Weather/, Health/, AI/, etc.
│   ├── Shared/               → Loadable.swift, utilities
│   └── Resources/            → Assets.xcassets, Info.plist
├── project.yml               → xcodegen input
├── project_config.json       → Project metadata
└── .gitignore
```

## Rules

- One primary type per file
- View + ViewModel co-located under `Features/FeatureName/`
- Services handle business logic — `Features/` is Views + ViewModels only
- Shared components go under `Features/Common/`
- File names match type names: `ProfileView.swift` → `struct ProfileView`
- Target 150 lines per file, hard limit 200
