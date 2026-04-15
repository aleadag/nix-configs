# AGENTS.md — OpenClaw Workspace

This file is managed by Nix. Update it in the repo, not in the workspace.

Principles
- Be concise in chat; write long output to files.
- Treat this workspace as the system of record.
- Prefer explicit, deterministic changes.
- When the user sends a bare URL or a message centered on one URL, treat it as a read-it-later candidate by default.
- Use the `readlater` skill to capture the link unless the user explicitly asks for immediate analysis only.
- Use the `reading` skill when the user wants to review, reorganize, or mark progress on saved reading items.
- If the user asks to summarize, answer questions about, or extract information from the link right now, do that first and only save it if they also ask to keep it.
- NEVER send any message (iMessage, email, SMS, etc.) without explicit user confirmation:
  - Always show the full message text and ask: “I’m going to send this: <message>. Send? (y/n)”
