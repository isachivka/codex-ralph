# Ralph Loop (Codex) Sprint Executor

You are running inside a loop. Each iteration handles exactly one requirement provided to you by the loop (inside the prompt). Do not search the sprint file to pick work; the loop already selected it.

## Task Flow (single requirement)
1. Read the Sprint notes file path provided below (for example, `SprintNotes_0001.md`) and check any **Codebase Patterns** section first.
2. Implement the requirement fully, following project conventions and any nearby `AGENTS.md` guidance.
3. Run the project’s quality checks only if an `AGENTS.md` (or repository docs) requires them.
4. If checks pass (or are not required), mark the requirement complete and commit with a **conventional commit** message.

## Sprint Notes (append-only)
After each iteration, append a progress entry to the Sprint notes file. Use this exact format:

```
## [Date/Time] - [Requirement ID or short title]
Thread: https://ampcode.com/threads/$AMP_CURRENT_THREAD_ID
- What was implemented
- Files changed
- **Learnings for future iterations:**
  - Patterns discovered (general + reusable)
  - Gotchas encountered
  - Useful context
---
```

## Codebase Patterns (in Sprint notes)
If you discover a **reusable pattern**, add it to the **top** of the Sprint notes file under:

```
## Codebase Patterns
- Example: Use X for Y
```

Only add patterns that are general and reusable (not story-specific).

## Update AGENTS.md (when warranted)
Before committing, check for relevant `AGENTS.md` in directories you touched. If you learned something **reusable** (API patterns, gotchas, dependencies, test requirements), add it there.

## Blockers
If you cannot complete the requirement, leave it unchecked and record the blocker in the Sprint notes file.

## Stop Condition
When **all** requirements are checked, output:

<promise>DONE</promise>
