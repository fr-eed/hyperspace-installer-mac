# Hyperspace macOS Install Instructions:

Download the Hyperspace Mac Beta Files:
FTL.Hyperspace.1.20.1-experimental-MacOS.zip (from github, will be included in the compiled installer (I think or not))

.
├── Hyperspace.ftl
├── MacOS
│   ├── Hyperspace.1.6.12.amd64.dylib
│   ├── Hyperspace.1.6.13.amd64.dylib
│   └── Hyperspace.command
└── README.txt


Next, you'll need to locate your FTL installation. 
``~/Library/Application Support/Steam/steamapps/common/FTL Faster Than Light/`` // this folder contains .app of the game

Note:
path is different for different verions like GOG, Humble, Steam, Epic, Heroic or custom
Probably auto scan all dirs and suggest to install in one of them or select custom .app location


This is the FTL installation path on Steam (I don't know where it is for GOG or Humble).
Now, right-click the FTL app and select the second option, "Show Package Contents" (or something similar; my system isn't in English).


Navigate into the `Contents` folder and text-edit `Info.plist` or open it in any 

You'll need to edit this section:
```xml
<key>CFBundleExecutable</key>
<string>FTL</string>
```
Edit the string under `CFBundleExecutable` and change `FTL` to `Hyperspace.command`, then save the file.
It should look like this afterward:
```xml
<key>CFBundleExecutable</key>
<string>Hyperspace.command</string>
```

The next step is to go into the `Contents/MacOS` folder (located next to the `Info.plist` file). Now, you need to be sure which version of FTL you have (can be checked by the autoinstaller so it would pic 13 or 12 version or show an error):
- If you are on Steam, copy `Hyperspace.1.6.13.amd64.dylib`.
- If you are on any other platform, copy `Hyperspace.1.6.12.amd64.dylib`.
Also, copy every other file from the zip except for `hyperspace.ftl`.

If you aren't installing Hyperspace for Steam, you'll also need to edit the `Hyperspace.command` file. This line needs the version number changed:
```bash
export DYLD_INSERT_LIBRARIES="$DIR/Hyperspace.1.6.13.amd64.dylib"
```
Change `1.6.13` to `1.6.12`. *Make sure to save the changes!*
```bash
export DYLD_INSERT_LIBRARIES="$DIR/Hyperspace.1.6.12.amd64.dylib"
```


Once these steps are done, you'll need to patch the `hyperspace.ftl` file (or most likely FTL: Multiverse) with FTLMan, which can be downloaded [here](https://github.com/afishhh/ftlman/releases)
Choose:
- `ftlman-aarch64-apple-darwin.tar.gz` if you are on Apple Silicon (M1, etc.)
- `ftlman-x86_64-apple-darwin.tar.gz` if you are using an Intel Mac.

Unzip the downloaded file (if not already done) and run the FTLMan executable. You might get a warning that it isn't verified, so you may need to allow it in System Settings under Privacy & Security (at the bottom, where you can tell macOS to run it). Older versions of macOS might just require a right-click and selecting "Open" from the pop-up.

Once FTLMan has started, open the settings and point it to the `ftl.dat` file, which is located here for Steam:
```
/Users/username/Library/Application Support/Steam/steamapps/common/FTL Faster Than Light/FTL.app/Contents/Resources/
```
Make sure to change `/Users/username/` to your macOS username.
After that, hit "Scan". Now you can drop all the mods you want (Multiverse, hyperspace.ftl, or anything else) into the "mods" folder that was extracted alongside the FTLMan executable, and then press "Apply".
With those steps, you should be good to go. Now just start FTL like you normally would, and it should hopefully work.


Important to codesign the app (requires admin privilage)

codesign -f -s - --timestamp=none --all-architectures --deep /Users/dino/Library/Application\ Support/Steam/steamapps/common/FTL\ Faster\ Than\ Light/FTL.app 


It will overwite  the existing code signature with your own and should allow you to launch the Application again

---

# Automated PKG Installer (New Approach)

## Overview
The PKG installer automates all the above steps. User just downloads and runs the `.pkg` file.

## Installation Directory Structure
After installation, `~/Documents/FTLHyperspace/` will contain:
```
~/Documents/FTLHyperspace/
├── ftlman              (the mod manager executable, pre-codesigned)
└── mods/
    └── hyperspace.ftl  (the mod file)
```

## What's Bundled in the PKG
- `ftlman` (x86_64, Intel Mac only) - pre-codesigned, ready to run
- Hyperspace.1.6.12.amd64.dylib (Intel Macs)
- Hyperspace.command launcher script
- hyperspace.ftl mod file
- Installation script (postinstall.sh)

## Automated Installation Steps
1. User downloads and runs the `.pkg` file
2. Installer auto-detects FTL.app location (Steam, GOG, Humble, or prompts for custom path)
3. Installer reads FTL version from the app binary:
   - If version is 1.6.13 → use Hyperspace.1.6.13.amd64.dylib
   - If version is 1.6.12 → use Hyperspace.1.6.12.amd64.dylib
   - If version is anything else → raise "Unsupported FTL version" error and abort
4. Installer copies ftlman and mods folder to `~/Documents/FTLHyperspace/`
5. Installer patches hyperspace.ftl into ftl.dat via: `~/Documents/FTLHyperspace/ftlman patch ~/Documents/FTLHyperspace/mods/hyperspace.ftl -d /path/to/ftl/data`
6. Installer modifies FTL.app:
   - Edits `Info.plist` to change CFBundleExecutable from "FTL" to "Hyperspace.command"
   - Copies the correct dylib (1.6.12 or 1.6.13) into `FTL.app/Contents/MacOS/`
   - Copies Hyperspace.command into `FTL.app/Contents/MacOS/`
   - Edits Hyperspace.command to update the dylib version in the DYLD_INSERT_LIBRARIES line (matching the detected FTL version)
7. Installer codesigns FTL.app with: `codesign -f -s - --timestamp=none --all-architectures --deep /path/to/FTL.app`
8. Installation complete! User can launch FTL normally.

## User Extensions (Optional)
Users can add more mods to `~/Documents/FTLHyperspace/mods/` and run:
```bash
~/Documents/FTLHyperspace/ftlman patch ~/Documents/FTLHyperspace/mods/your-mod.ftl -d /path/to/ftl/data
```

## Admin Privileges Required
The installer requires admin password to:
- Create `~/Documents/FTLHyperspace/` directory
- Modify FTL.app (plist, copy files)
- Codesign FTL.app