# SSH Config Manager

A native SwiftUI macOS app for editing `~/.ssh/config`, with no third-party dependencies.

Build and launch it once from Terminal:

```sh
cd /Users/Kenn/.codex/.chatgpt-projects/g-p-6a915e7dc6ac8191a90f1e26b00f7651/ssh-config-manager
./build.sh
```

This creates **SSH Config Manager.app** in the same folder. You can then open that app normally from Finder. This needs Apple's Command Line Tools / Xcode (the standard `swiftc` compiler).

## After changing the project manually

Yes—run `./build.sh` again after changing the Swift source, app icon, or `Info.plist`. It recompiles the application and replaces the contents of **SSH Config Manager.app**. If the app is already open, quit it first, then open the rebuilt app again.

It lists existing `Host` entries alphabetically; lets you add, edit, and delete entries; and supplies `~/.ssh/id_rsa` as the default identity file for a new entry. Save applies form changes and writes the config. Each host has Connect (opens Terminal with the SSH command) and Test (a non-interactive connection check with an 8-second timeout).

Saving always asks for confirmation. Before it replaces `~/.ssh/config`, it writes a timestamped backup into `~/.ssh/config-manager-backups`.
