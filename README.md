# Codex Ralph Wiggum Loop

Minimal Ralph Wiggum Loop runner that feeds a sprint requirement into Codex, one item per iteration.

## Quick start

```bash
npx codex-ralph path/to/Sprint_0001.md --max-iterations=1
```

## Telegram progress notifications

If you set Telegram credentials, the loop will send progress messages:

```
CODEX_RALPH_TG_KEY=123456:bot-token
CODEX_RALPH_TG_CHAT=123456789
```

Provide these as environment variables (e.g., when invoking `npx`). Each session uses a randomly selected emoji to tag progress messages.

Usage:

```
npx codex-ralph path/to/Sprint_0001.md
```

Optional flags:

```
--max-iterations=10
--cursor-agent
--gemini-agent
```

Message format (session emoji is chosen randomly from a small fixed set and stays constant for the session):

```
<session emoji>
📌 <current requirement title>
🎯 <current index> of <total requirements>
```

## Sprint format (Markdown)

Each requirement is a level-2 heading with a checkbox. The loop picks the first unchecked item.

```markdown
## [ ] Requirement description

Description: Free-form task details.

Acceptance criteria: Free-form acceptance criteria.
```

## Behavior

- Reads the sprint file, finds the first unchecked item, and passes it to Codex.
- Derives a parallel notes file alongside the sprint (for example `Sprint_0001.md` -> `SprintNotes_0001.md`) and includes its path in the prompt.
- The agent prompt references sprint/notes files (not PRD/progress files).
- Uses the Sprint notes file for progress logging and reusable Codebase Patterns.
- The loop may provide a working branch; the agent should switch if specified.
- Runs quality checks only when required by `AGENTS.md` or repo docs.
- Marks items complete only when all steps are satisfied.
- Uses conventional commits for each completed requirement (no story ID requirement).
- If no local `AGENTS.md` exists up the tree, use `./.codex/AGENTS.md`. In monorepos, prefer package-level AGENTS.md for package-specific knowledge.

## Changelog

### 0.6.1
- Fix: Corrected the command for the Gemini agent.

### 0.6.0
- Add support for Gemini agent via `--gemini-agent` flag.

### 0.5.0
- Version bump.
