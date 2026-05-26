# Install the anti-hallucination skill

One-step install paths for the agents I've tested. The skill body lives in [`skill.md`](skill.md); copy the block between the two horizontal rules under "The skill, copy-paste ready."

## GitHub Copilot (VS Code custom instructions)

1. Open VS Code Settings → search for "copilot instructions."
2. Open `.github/copilot-instructions.md` in your workspace (create it if missing).
3. Paste the skill block at the top of the file. Put project-specific instructions after it.
4. Reload the Copilot Chat window.

Verification: open Copilot Chat in agent mode and run test prompt **B-1** from [`test-prompts.md`](test-prompts.md). If the agent invents a file path, the instructions are not being read.

## Cline (`.clinerules`)

1. In your project root, open or create `.clinerules`.
2. Paste the skill block at the top.
3. Start a new Cline task — `.clinerules` is loaded per-task.

Verification: run test prompt **B-1**. If the agent volunteers an invented function name without flagging it as an assumption, the rules file is not loaded.

## Cursor (`.cursorrules`)

1. In your project root, open or create `.cursorrules`.
2. Paste the skill block at the top.
3. Restart Cursor or reload the workspace.

Verification: as above.

## Claude Desktop / MCP-aware agents

If your agent supports MCP, load the skill as a system prompt fragment via your MCP server's prompt-injection layer. There's no first-party path for this yet; see the [roadmap](../../../docs/roadmap.md) Wave 4-A for the planned MCP server that injects this automatically.

## Manual / one-off use

For a single high-stakes prompt without persistent install, paste the skill block at the top of your chat message, followed by a blank line and your actual request. The agent treats it as instructions for that turn.

## Uninstall

Delete the pasted block from the instructions file. There is no other side-effect; the skill is pure text.

## Verifying the install actually took effect

The most reliable check is the test harness in [`test-prompts.md`](test-prompts.md). Run all five prompts in two sessions (loaded vs not loaded), record the diffs, and compare against the expected behaviors. If at least three out of five show the expected before/after delta, the skill is working as advertised in your setup.
