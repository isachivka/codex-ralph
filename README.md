# Codex Ralph Wiggum Loop

Minimal Ralph Wiggum Loop runner that feeds a sprint requirement into Codex, one item per iteration.

## Quick start

```bash
npx codex-ralph --sprint=path/to/Sprint_0001.md --max-iterations=1
```

## Sprint format (Markdown)

Each requirement is a level-2 heading with a checkbox. The loop picks the first unchecked item.

```markdown
## [ ] Requirement description
Description: Free-form task details.
```

## Behavior

- Reads the sprint file, finds the first unchecked item, and passes it to Codex.
- Derives a parallel notes file alongside the sprint (for example `Sprint_0001.md` -> `SprintNotes_0001.md`) and includes its path in the prompt.
- The agent prompt references sprint/notes files (not PRD/progress files).
- Uses the Sprint notes file for progress logging and reusable Codebase Patterns.
- Runs quality checks only when required by `AGENTS.md` or repo docs.
- Marks items complete only when all steps are satisfied.
- Uses conventional commits for each completed requirement.
