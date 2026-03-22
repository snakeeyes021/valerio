# Steinberg Dorico on Linux

## The Mission
This project aims to bring Steinberg Dorico (and the broader Steinberg software ecosystem) to Linux with near-native performance and stability. 

Historically, Steinberg software has been notoriously difficult to run on Linux due to its reliance on complex background services (Steinberg Activation Manager, License Engine), strict IPC (Inter-Process Communication) requirements, and newer Windows APIs like DirectComposition (`dcomp`). 

Our goal is to solve these technical hurdles and create a **reproducible, automated, and user-friendly** deployment system.

## Philosophy & Architectural Aims
1. **Empirical Precision:** We don't guess. We rely on logs, exact version hashing, and empirical testing to ensure every component in the chain is accounted for.
2. **Reproducibility:** The environment must be entirely scriptable. A developer should be able to run a single command to compile the engine, fetch dependencies, and generate the working state from scratch.
3. **The "Plug-and-Play" End Goal:** Whether through automated installers or a pre-configured image, the ultimate goal is a zero-friction experience for the end-user. 

## Current Architecture: The Container Method
After initial attempts using Flatpak/Bottles were thwarted by aggressive sandboxing (which blocked the licensing engine's IPC and browser handoffs), we pivoted to a **Containerized approach using Distrobox and Docker**.

*   **The Engine:** We compile a custom branch of Wine (`zhiyi/wine`) that includes experimental `dcomp` stubs required for Dorico 6's UI to render.
*   **The Environment:** Distrobox allows us to run an Ubuntu container that shares the host's X11/Wayland display, DBus, and Pipewire audio natively, completely bypassing the sandbox isolation issues that plague Flatpak.
*   **The Handoff:** We use custom `.desktop` URI handlers to seamlessly pass OAuth tokens from the host's native Linux web browser directly into the containerized Steinberg Activation Manager.

## Delivery Mechanisms & The Future
Currently, we are building the "recipe" inside a Docker container. Depending on licensing and legal constraints from Steinberg, this recipe can be packaged in several ways:

1. **The "Template Prefix" Docker Image:** We can distribute a Docker image containing the compiled Wine engine and a pre-installed Dorico prefix. A first-run wrapper script copies this "Template Prefix" to the user's local home folder and updates the registry, providing a true one-click install without extra packaging layers.
2. **AppImage:** If legally permitted, the engine and binaries can be packed into a single, executable AppImage. Because AppImages do not enforce strict sandboxing, this retains all the benefits of our current Distrobox architecture.
3. **Flatpak:** The hardest route, as it would require us to re-engineer our solution to punch exact IPC and networking holes through the strict Flatpak sandbox, but it remains a viable distribution target once the core engine is perfected.

## Repository Structure & Documentation
*   `dorico_linux_state.md`: The active, living blueprint, tracking our current environment, hashes, and Technical Debt / To-Do list.
*   `archive_bottles_flatpak_method.md`: A historical record of our previous attempts and roadblocks using Bottles.
*   `build/` & `setup/` scripts: The shell scripts used to bootstrap the Wine engine and prefix.