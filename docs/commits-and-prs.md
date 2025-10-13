# Commits and Pull Requests

## Commit Messages
- Follow the existing prefix pattern observed in history (`docs:`, `update:`, `fix:`, `refactor:`). Choose the closest category or introduce a new one only when necessary.
- Write imperative, concise summaries under 72 characters (`update: adjust overlay opacity clamp`).
- Keep logically independent changes in separate commits; avoid mixing styling tweaks with feature changes unless inseparable.

## Branching
- Use descriptive branch names (`feature/overlay-fade-tuning`, `bugfix/hotkey-permission`).
- Rebase onto `main` frequently to minimize merge conflicts in project files.

## Pull Request Checklist
1. Provide a one-paragraph overview of the change and its motivation.
2. List testing performed (`xcodebuild build`, manual hotkey verification).
3. Attach screenshots or short recordings for UI adjustments, including before/after when relevant.
4. Link to related issues or discussions and mention reviewers who should be aware of sandbox or entitlement changes.
5. Call out any follow-up tasks or TODOs that remain.

## Review Expectations
- Address review comments via follow-up commits; squash only after approval if the repository prefers a linear history.
- Note any accessibility or permissions prompts that reviewers must acknowledge when running the branch.
- Update documentation (`README.md`, `AGENTS.md`, and docs/) alongside behavior changes to keep guidance accurate.
