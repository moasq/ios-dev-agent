# Contributing

Thanks for your interest in contributing to iOS Dev Agent.

## How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-skill`)
3. Make your changes
4. Test with `./install.sh --tool all` in a sample project
5. Push and open a Pull Request

## Adding a New Skill

1. Create a directory in `.agents/skills/your-skill/`
2. Add a `SKILL.md` with YAML frontmatter following the [Agent Skills spec](https://agentskills.io/specification)
3. Add reference files in `your-skill/reference/` if needed
4. Test that the skill loads in at least one supported tool

## Adding Support for a New Tool

1. Add the tool's config directory and rule format
2. Add symlinks to shared `rules/` and `.agents/`
3. Add the tool to `install.sh`
4. Update the README

## Code Style

- Shell scripts: `set -euo pipefail`, use functions, quote variables
- Python: stdlib only, no external dependencies, type hints where helpful
- Markdown: ATX headings, fenced code blocks, tables for structured data

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
