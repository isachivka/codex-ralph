# Codex Ralph Loop

Minimal Ralph Loop runner that feeds a sprint requirement into Codex, one item per iteration.

## Quick start

```bash
npx ralph-loop --sprint=path/to/Sprint_0001.md --max-iterations=1
```

## Sprint format (Markdown)

Each requirement is a level-2 heading with a checkbox. The loop picks the first unchecked item.

```markdown
## [ ] Requirement description
- Category: functional
- Steps:
  - Step one
  - Step two
- Notes: Optional blocker note
```

## Behavior

- Reads the sprint file, finds the first unchecked item, and passes it to Codex.
- Marks items complete only when all steps are satisfied.
- Uses conventional commits for each completed requirement.
