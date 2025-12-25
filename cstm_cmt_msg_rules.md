# Custom Commit Message Rules

## Format
- Subject line: imperative verb + what changed (50 chars max)
- Body: explain WHY, not what (the diff shows what)
- Use present tense: "Add feature" not "Added feature"

## Structure
First line: <type>: <subject>

Body (if needed):
- Context: Why was this change necessary?
- Impact: What does this enable or fix?
- Notes: Any caveats, side effects, or follow-up needed

## Type Prefixes
Use one of these tags:
- feat: New feature or capability
- fix: Bug fix or correction
- refactor: Code restructuring without behavior change
- perf: Performance improvement
- docs: Documentation only
- test: Test additions or updates
- chore: Build, tooling, dependencies
- style: Formatting, whitespace, naming

## Content Guidelines
- Be specific: "Fix null pointer in user login" not "Fix bug"
- Mention affected area: "auth:", "ui:", "api:", etc. when relevant
- Avoid obvious statements: don't say "update file X" if that's clear from diff
- Include ticket/issue reference if applicable: "Fixes #123"

## Examples
Good:
- feat(auth): Add OAuth2 token refresh logic
- fix(api): Prevent race condition in cache writes
- refactor(db): Extract query builder to separate module

Bad:
- Updated files
- Changes
- Fixed stuff
- WIP

## Output Format
Plain text only. No markdown formatting (**bold**, `code`, etc.)