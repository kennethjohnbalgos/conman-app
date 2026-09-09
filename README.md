# SSH Config Manager

A lightweight native macOS app for viewing and editing `~/.ssh/config`.

It includes a ready-to-open app bundle and its Swift source code. No third-party dependencies are used.

## Install the included app

1. Download this repository as a ZIP from GitHub and unzip it, or clone it with Git.
2. Drag **SSH Config Manager.app** to your Applications folder (or any folder you prefer).
3. Open the app. Because this app is not notarized, macOS may warn that it is from an unidentified developer. Control-click the app, choose **Open**, then choose **Open** again.
4. When you first use **Connect**, allow the app to control Terminal if macOS asks. This is how it opens your SSH connection in Terminal.

The included build is universal, so it works on both Intel and Apple Silicon Macs. If it does not open on your Mac, build it locally using the instructions below.

It requires macOS 14 Sonoma or later.

## Build from source

You need Apple’s Command Line Tools or Xcode, which provides the standard `swiftc` compiler.

```sh
git clone git@github.com:kennethjohnbalgos/ssh-app.git
cd ssh-app
./build.sh
```

The command creates and opens **SSH Config Manager.app** in the project folder. You can then move it to Applications.

## How to use it

- **Recent** is the default page and shows up to 20 hosts you have connected to recently.
- Choose a host from **Hosts** to view or edit it. Hosts are listed alphabetically.
- Use **Add** to create a host; new entries default `IdentityFile` to `~/.ssh/id_rsa`.
- **Connect** opens Terminal using the current form values, even if you have not saved your edits yet.
- **Test** makes a non-interactive SSH connection attempt with an eight-second timeout and shows whether it succeeded.
- **Save** asks for confirmation, writes the current configuration to `~/.ssh/config`, and creates a timestamped backup in `~/.ssh/config-manager-backups` first.
- **Delete** asks for confirmation, then immediately backs up and updates `~/.ssh/config`.

The app keeps unedited SSH directives and comments within each host entry.

## After changing the project manually

Yes—run `./build.sh` after changing the Swift source, app icon, or `Info.plist`. It recompiles the app and updates **SSH Config Manager.app**. If the app is already open, quit it before rebuilding, then open the rebuilt app.
