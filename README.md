# SSH ConMan

A native menu bar app for managing `~/.ssh/config` on macOS 14 Sonoma or later. The included app supports both Intel and Apple Silicon Macs.

## Install with Homebrew

```sh
brew tap kennethjohnbalgos/ssh-app https://github.com/kennethjohnbalgos/ssh-app.git
brew install --cask kennethjohnbalgos/ssh-app/ssh-conman
open -a 'SSH ConMan'
```

The app appears as a terminal icon in the menu bar, not in the Dock. If macOS warns that the app is from an unidentified developer, open **Applications**, Control-click **SSH ConMan**, and choose **Open**. The app is ad hoc signed and is not notarized.

To uninstall the app:

```sh
brew uninstall --cask kennethjohnbalgos/ssh-app/ssh-conman
brew untap kennethjohnbalgos/ssh-app
```

Uninstalling leaves your `~/.ssh/config`, its backups, and SSH keys untouched. If you turned on **Start at login**, switch it off in the app before uninstalling, or remove SSH ConMan from **System Settings → General → Login Items** afterward.

## Install without Homebrew

Download the repository from GitHub and drag **SSH ConMan.app** to Applications. Open it from Applications. The first **Connect** action may ask for permission to control Terminal; choose **Allow**.

## Use the app

- Click the menu bar terminal icon to open or focus the window. Command–Option–Shift–/ also opens it. Escape closes the window while the menu bar app keeps running.
- The app opens on **Recent Hosts**, showing up to 20 hosts you have connected to. Each row has **Connect** and a trash button to remove it from Recent.
- Use **Search hosts** above the alphabetical list to filter hosts as you type. Select a host to edit its fields.
- Click **Recent** at the top of the editor to return to Recent Hosts.
- Open the bottom-left gear menu for **Add Host**, **Start at login**, and **Quit**. Add Host starts a new form with `~/.ssh/id_rsa` as the default identity file.
- **Connect** opens Terminal using the values currently shown in the form, even before you save them. **Test** checks SSH access without prompting for a password and reports success or failure.
- **Save** confirms the change and writes `~/.ssh/config`. **Delete** is available for an existing host below the form; after confirmation, it removes the host immediately. Both actions create a timestamped copy of the previous config in `~/.ssh/config-manager-backups`.

The app keeps other SSH directives and comments within each host entry. A non-interactive Test can fail when a host requires a password or a first-time host-key prompt, even if an interactive Connect works.

## Build from source

Install Apple's Command Line Tools or Xcode, then run:

```sh
git clone git@github.com:kennethjohnbalgos/ssh-app.git
cd ssh-app
./build.sh
```

The script compiles both Mac architectures, signs the bundle locally, and opens **SSH ConMan.app**. Use `./build.sh --no-open` to rebuild without launching. Rebuild after editing the Swift source, icon, or `Info.plist`, and quit any older running copy before opening the new one.
