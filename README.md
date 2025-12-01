  # Hyperspace macOS Installer

> ⚠️ **Under Development** — This project is experimental and uses a [fork of FTL Hyperspace](https://github.com/fr-eed/FTL-Hyperspace-Dino) with macOS support. Once macOS support is merged into the main FTL Hyperspace project, this will be updated to use the official repository.

A native macOS installer for [FTL: Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace), a binary mod for [FTL: Faster Than Light](https://subsetgames.com/ftl.html). Handles installation of Hyperspace into your FTL game directory and manages mod dependencies with [ftlman](https://github.com/afishhh/ftlman).

## What It Does

- **Detects** your FTL: Faster Than Light installation (Steam, GOG, or custom location)
- **Identifies** your FTL version (supports v1.6.12 and v1.6.13)
- **Installs** Hyperspace dynamic library and patches FTL game data
- **Manages** mod dependencies automatically with ftlman

## For Mod Creators

This project can be used as a base to create custom installers for other FTL mods or modpaks built on FTL Hyperspace. Use the GitHub Actions workflow to build and distribute branded installers without managing compilation infrastructure.

**Example:** Package your mod with Hyperspace pre-installed, customize the installer name and icon, and distribute a ready-to-use macOS installer to your players.

## Requirements

- **macOS** 13.0 or later
- **FTL: Faster Than Light** v1.6.12 or v1.6.13
- Administrator privileges for installation

## Installation of Hyperspace using the installer

1. Download the latest `Hyperspace-*.dmg` from [Releases](https://github.com/fr-eed/hyperspace-installer-mac/releases)
2. Open the DMG and run the installer
3. If macOS blocks the app, go to **System Settings → Privacy & Security** and click **Open Anyway**
4. Select your FTL installation location (Steam, GOG, or custom)
5. Follow the on-screen prompts
6. Launch FTL and enjoy Hyperspace!

**Installing additional mods:**
- Open the mods folder
- Add your `.ftl` or `.zip` mod files
- Patch them using ftlman

## Creating Custom Installers

### Using GitHub Actions (Recommended)

Use the `build-installer` action from your own repository:

1. **In your workflow**, add a step that calls the action:
   ```yaml
   - name: Build custom installer
     id: build-installer
     uses: fr-eed/hyperspace-mac-autoinstaller/actions/build-installer@main
     with:
       arch: ${{ matrix.arch }}
       installer-bundle-version: "1.0.0"
       hyperspace-version: "v1.20.2"
       installer-name: "My Awesome FTL Mod Pack"
       mod-files: |
         ${{ github.workspace }}/mods/mod1.ftl
         ${{ github.workspace }}/mods/mod2.ftl
       icon-path: "${{ github.workspace }}/my-icon.icns"
   ```

   **Parameters:**
   - `arch` — `x86_64` (Intel, better compatibility) or `arm64` (Apple Silicon). Use a matrix workflow to build both and speed up installation on new Macs.
   - `installer-bundle-version` — Version shown to users (e.g., `1.0.0`)
   - `hyperspace-version` — Hyperspace release to bundle (minimum `v1.20.2` for macOS)
   - `installer-name` — Display name in the installer and app
   - `mod-files` — Absolute paths to mod files (order matters — installed in this order)
   - `icon-path` — Optional path to `.icns` icon file (512×512 recommended)

   **Outputs:**
   - `dmg-path` — Path to the built DMG file (use this to upload to releases)

3. **Upload the DMG to your release**:
   ```yaml
   - name: Upload DMG to release
     uses: softprops/action-gh-release@v1
     with:
       tag_name: v1.0                                       # Your Github Release tag
       files: ${{ steps.build-installer.outputs.dmg-path }}
   ```

The action automatically builds for both architectures (Intel and Apple Silicon). When using a matrix workflow, each architecture builds independently and outputs its DMG path.

### Using Local Scripts

Fork this repository and edit `build-app.sh` to customize for your needs:

```bash
# Build the installer
./build-app.sh

# Outputs to: release/{arch}/{--installer-name}.app and creates DMG
```

Edit `build-app.sh` to customize:
- **Installer name**: Change `--installer-name` parameter
- **Icon**: Replace `HSInstaller.icns` with your own
- **Mods**: Update `--mod-files` to include your mod files
- **Hyperspace version**: Modify the `--hyperspace-version` parameter

## Development

This project uses Swift for the UI and shell scripts for installation logic.

```bash
# Build locally
./build-app.sh

# Review the build output
open release/arm64/Hyperspace.app
```

The build system is separated into stages:
1. **Compile** Swift executable (one-time, produces binary)
2. **Package** binary into installer with mods and config (reusable)

This allows mod creators to build custom installers without managing compilation infrastructure.


