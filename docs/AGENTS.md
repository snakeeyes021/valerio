# AI Development Guide & System Prompts

This document serves as a "system prompt" for any AI agent working on this repository. Please read and adhere to these constraints before making architectural changes or suggesting solutions.

## Core Architectural Constraints

1. **The Containerized Environment:** This project strictly uses a Distrobox container (currently Ubuntu 24.04) running on an immutable host. Do *not* suggest Flatpak, Snap, or AppImage packaging for the core engine unless explicitly directed. Always respect the container boundaries.
2. **The Custom Wine Engine:** We compile a specific custom branch of Wine (`zhiyi/wine`) to get experimental `dcomp` stubs necessary for Steinberg's UI. Do *not* suggest replacing this with standard Wine-Staging or Proton unless explicitly directed, as it will break the application.
3. **No Absolute Development Paths:** Scripts must be user-agnostic. Do not hardcode paths like `~/dev/steinberg-on-linux`. Use relative paths or dynamic XDG directories (e.g., `~/.local/share/wineprefixes/dorico`).
4. **URI Handoff Logic:** Web login tokens (`net-steinberg-sam://`, `net-steinberg-sda://`) are passed from the host browser to the containerized Windows binaries using custom `.desktop` files. Do not alter this fundamental handoff mechanism; it is the core solution to the authentication problem on Linux.

## Context & Roadmap Retention
*   **Blueprint & Philosophy:** Refer to `docs/ARCHITECTURE.md` (formerly `dorico_linux_state.md`) to understand the technical blueprint and current state of the machine.
*   **Active Subtasks:** Refer to `docs/backlog.md` for granular, nitty-gritty implementation subtasks and current goals.
*   **Historical Context:** There are files at `docs/archive_bottles_flatpak_method.md` and `docs/shared_conversation.md` that contain some historical context (the flatpak method being an alternate attempt that went in a different direction but that may have some valuable material and the shared conversation being a brainstorming session to nail down the direction of the current attempt). The shared conversation doc is large, so don't waste tokens reading it unless instructed to do so. Likewise the flatpak method is usually not relevant, so in most cases, don't bother with it either.

## The "Document-As-You-Go" Mandate

**CRITICAL INSTRUCTION FOR ALL AI AGENTS:**

Treat your context window as highly volatile and ephemeral. To prevent "context rot" and ensure smooth handoffs to future agents (or human developers), you must act as a Senior Engineer and proactively document your work *while* you work.

*   **Distill Insights:** When a complex problem is solved, a new architectural decision is made, or an important dependency quirk is discovered (e.g., the `libicu` native vs. MSI requirement), immediately distill this finding into `docs/ARCHITECTURE.md`.
*   **Track Work:** When new subtasks are discovered or scope expands, immediately append them to `docs/backlog.md`.
*   **Update Continuously:** Do not wait until the end of a long session to summarize. Update documentation files continuously as part of your natural development cycle.
*   **Never Lose Context:** If a conversation thread is reaching a conclusion, explicitly verify that all valuable context, script modifications, and roadmap items have been persisted to the repository files before concluding the task.