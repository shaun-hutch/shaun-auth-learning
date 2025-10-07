# Copilot Instructions for AI Agents

## Project Overview
This repository is a sandbox for learning and experimenting with basic authentication setups, including both backend and frontend components. The goal is to understand how authentication flows work end-to-end.

## Key Patterns & Architecture
- Expect both backend and frontend code, even if not present yet.
- The repo is structured for rapid prototyping and learning, not production.
- Code may be minimal, experimental, or incomplete—focus on clarity and simplicity.

## Developer Workflows
- No build, test, or deployment scripts are present. Assume manual execution and testing.
- If adding backend code, prefer simple frameworks (e.g., Express for Node.js, Flask for Python).
- For frontend, use basic setups (e.g., plain HTML/JS, minimal React, etc.).
- Document any new commands or workflows in the README for future discoverability.

## Conventions
- Keep code and documentation simple and beginner-friendly.
- Prefer explicit, step-by-step authentication flows (e.g., login, token issuance, session management).
- Avoid advanced patterns unless necessary for learning purposes.
- Reference the README for project intent and update it with any major changes.

## Integration Points
- If integrating with external services (OAuth, databases, etc.), provide clear setup instructions and sample configs.
- Use environment variables for secrets and credentials; document required variables in the README.

## Example Patterns
- If implementing login, show both backend validation and frontend form handling.
- For token-based auth, demonstrate token creation, storage, and verification.

## Key Files
- `README.md`: Project intent and any documented workflows.
- Add new files with clear names (e.g., `backend.js`, `frontend.html`, `auth.js`) and document their purpose.

## Other Notes
- I'd like to put this in a CICD workflow, using AWS resources, with GitHub Actions.

- If you startup the dotnet project, if you want to do anything else in the terminal, you will need to do it in a new window. The agent gets in a loop if you try to do everything in the same terminal window.

---

**If any conventions or workflows are unclear, ask the user for clarification and update this file accordingly.**
