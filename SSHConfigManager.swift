import SwiftUI
import AppKit
import Carbon.HIToolbox

struct SSHEntry: Identifiable, Equatable {
    var id = UUID()
    var title: String
    var hostName: String = ""
    var user: String = ""
    var identityFile: String = ""
    var extraLines: [String] = []
}

@main
struct SSHConfigManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .onAppear {
                    appDelegate.openWindow = {
                        openWindow(id: "main")
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
        }
            .defaultSize(width: 640, height: 620)
            .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var openWindow: (() -> Void)?
    private var statusItem: NSStatusItem?
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem?.button else { return }
        button.image = NSImage(systemSymbolName: "terminal.fill", accessibilityDescription: "SSH Config Manager")
        button.target = self
        button.action = #selector(openMainWindow)
        button.toolTip = "SSH Config Manager"
        registerOpenShortcut()
    }

    @objc private func openMainWindow() { openWindow?() }

    private func registerOpenShortcut() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue().openMainWindow()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        let identifier = EventHotKeyID(signature: OSType(0x5353484D), id: 1)
        RegisterEventHotKey(UInt32(kVK_ANSI_Slash), UInt32(cmdKey | optionKey | shiftKey), identifier, GetApplicationEventTarget(), 0, &hotKey)
    }
}

struct ContentView: View {
    private let configURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh/config")
    private let backupDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh/config-manager-backups")
    private let defaultIdentity = "~/.ssh/id_rsa"

    @State private var preamble: [String] = []
    @State private var entries: [SSHEntry] = []
    @State private var selection: UUID?
    @State private var title = ""
    @State private var hostName = ""
    @State private var user = ""
    @State private var identityFile = "~/.ssh/id_rsa"
    @State private var status = ""
    @State private var confirmation: Confirmation?
    @State private var alertMessage: String?
    @State private var hasStructuralChanges = false
    @State private var showRecent = true
    @State private var recentHostTitles: [String] = []

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading) {
                    Text("Hosts").font(.headline)
                    List(selection: $selection) {
                        ForEach(entries) { entry in
                            Text(entry.title).lineLimit(1).tag(entry.id)
                        }
                    }
                    .frame(minWidth: 170, maxHeight: .infinity)
                    .onChange(of: selection) { _, id in loadSelection(id) }
                }
                .frame(maxWidth: 190, maxHeight: .infinity)

                Group {
                    if showRecent {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Hosts").font(.headline)
                            if recentEntries.isEmpty {
                                ContentUnavailableView("No recent connections", systemImage: "clock", description: Text("Hosts you connect to will appear here."))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                List(recentEntries) { entry in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(entry.title)
                                            if !entry.hostName.isEmpty { Text(entry.hostName).font(.caption).foregroundStyle(.secondary) }
                                        }
                                        Spacer()
                                        Button("Connect") { connect(to: entry) }
                                        Button(role: .destructive) { removeRecent(entry.title) } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.borderless)
                                        .help("Remove from Recent")
                                    }
                                }
                            }
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Host details").font(.headline)
                            formField("Host title", text: $title, hint: "github-work")
                            formField("HostName", text: $hostName, hint: "github.com")
                            formField("User", text: $user, hint: "git")
                            formField("IdentityFile", text: $identityFile, hint: defaultIdentity)
                            Divider().padding(.vertical, 5)
                            HStack {
                                Spacer()
                                Button("Connect") { connect(to: formEntry) }.disabled(formEntry.hostNameOrTitle.isEmpty)
                                Button("Test") { test(formEntry) }.disabled(formEntry.hostNameOrTitle.isEmpty)
                                Button("Save") { requestSave() }.keyboardShortcut("s", modifiers: .command).disabled(!hasChanges)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            HStack {
                Button("Add") { clearForm() }
                Button("Delete", role: .destructive) { requestDelete() }
                    .disabled(selection == nil)
                Button("Recent") { showRecentPage() }
                Spacer()
                Text(status).font(.caption).foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(minWidth: 620, idealWidth: 640, maxWidth: 680, minHeight: 500, idealHeight: 620, maxHeight: 800)
        .onAppear { loadConfig() }
        .onExitCommand { NSApplication.shared.keyWindow?.performClose(nil) }
        .alert(item: $confirmation) { action in
            switch action {
            case .save:
                Alert(title: Text("Save changes?"), message: Text("This will update the ~/.ssh/config. Continue?"), primaryButton: .default(Text("Save")) { saveConfig() }, secondaryButton: .cancel())
            case let .delete(id, name):
                Alert(title: Text("Delete host?"), message: Text("Remove '\(name)' from ~/.ssh/config? A backup will be created first."), primaryButton: .destructive(Text("Delete")) { deleteAndSave(id) }, secondaryButton: .cancel())
            }
        }
        .alert("SSH Config Manager", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK") { alertMessage = nil }
        } message: { Text(alertMessage ?? "") }
    }

    private enum Confirmation: Identifiable {
        case save, delete(UUID, String)
        var id: String { switch self { case .save: return "save"; case let .delete(id, _): return "delete-\(id)" } }
    }

    private func formField(_ label: String, text: Binding<String>, hint: String) -> some View {
        HStack { Text(label).frame(width: 90, alignment: .trailing); TextField(hint, text: text).textFieldStyle(.roundedBorder) }
    }

    private var recentEntries: [SSHEntry] {
        recentHostTitles.compactMap { recentTitle in entries.first { $0.title == recentTitle } }
    }

    private func loadConfig() {
        do {
            let source = FileManager.default.fileExists(atPath: configURL.path) ? try String(contentsOf: configURL, encoding: .utf8) : ""
            (preamble, entries) = parse(source)
            sortEntries()
            hasStructuralChanges = false
            recentHostTitles = UserDefaults.standard.stringArray(forKey: "recentSSHHosts") ?? []
            showRecentPage()
            status = ""
        } catch { show(error) }
    }

    private func parse(_ source: String) -> ([String], [SSHEntry]) {
        var before: [String] = [], result: [SSHEntry] = [], current: SSHEntry?
        func finish() { if let current { result.append(current) } }
        for line in source.components(separatedBy: .newlines) {
            let parts = line.trimmingCharacters(in: .whitespaces).split(maxSplits: 1, whereSeparator: { $0 == " " || $0 == "\t" })
            let key = parts.first?.lowercased() ?? "", value = parts.count > 1 ? String(parts[1]) : ""
            if key == "host" && !value.isEmpty { finish(); current = SSHEntry(title: value); continue }
            guard var entry = current else { before.append(line); continue }
            switch key {
            case "hostname": entry.hostName = value
            case "user": entry.user = value
            case "identityfile": entry.identityFile = value
            default: entry.extraLines.append(line)
            }
            current = entry
        }
        finish()
        return (before, result)
    }

    private func renderedConfig() -> String {
        var lines = preamble
        if !lines.isEmpty && !(lines.last?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) { lines.append("") }
        for (index, entry) in entries.enumerated() {
            lines.append("Host \(entry.title)")
            if !entry.hostName.isEmpty { lines.append("    HostName \(entry.hostName)") }
            if !entry.user.isEmpty { lines.append("    User \(entry.user)") }
            if !entry.identityFile.isEmpty { lines.append("    IdentityFile \(entry.identityFile)") }
            lines.append(contentsOf: entry.extraLines)
            if index < entries.count - 1 { lines.append("") }
        }
        return lines.joined(separator: "\n").trimmingCharacters(in: .newlines) + "\n"
    }

    private var formEntry: SSHEntry {
        SSHEntry(id: selection ?? UUID(), title: title.trimmingCharacters(in: .whitespaces), hostName: hostName.trimmingCharacters(in: .whitespaces), user: user.trimmingCharacters(in: .whitespaces), identityFile: identityFile.trimmingCharacters(in: .whitespaces), extraLines: entries.first(where: { $0.id == selection })?.extraLines ?? [])
    }
    private var hasChanges: Bool {
        if hasStructuralChanges { return true }
        guard let id = selection else { return !title.trimmingCharacters(in: .whitespaces).isEmpty }
        return entries.first(where: { $0.id == id }) != formEntry
    }
    private func clearForm() { selection = nil; title = ""; hostName = ""; user = ""; identityFile = defaultIdentity; showRecent = false }
    private func showRecentPage() { selection = nil; showRecent = true }
    private func loadSelection(_ id: UUID?) { guard let id, let entry = entries.first(where: { $0.id == id }) else { return }; showRecent = false; title = entry.title; hostName = entry.hostName; user = entry.user; identityFile = entry.identityFile }
    private func stageForm() -> Bool {
        let cleanedTitle = title.trimmingCharacters(in: .whitespaces)
        if cleanedTitle.isEmpty && selection == nil { return true }
        guard !cleanedTitle.isEmpty else { alertMessage = "Enter a Host title first."; return false }
        let entry = formEntry
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry } else { entries.append(entry) }
        selection = entry.id; sortEntries()
        return true
    }
    private func sortEntries() { entries.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending } }
    private func requestSave() { if stageForm() { confirmation = .save } }
    private func requestDelete() {
        guard let id = selection, let entry = entries.first(where: { $0.id == id }) else { return }
        confirmation = .delete(id, entry.title)
    }
    private func deleteAndSave(_ id: UUID) {
        entries.removeAll { $0.id == id }
        clearForm()
        hasStructuralChanges = true
        saveConfig()
    }

    private func backupCurrent() throws -> URL? {
        guard FileManager.default.fileExists(atPath: configURL.path) else { return nil }
        try FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let formatter = DateFormatter(); formatter.dateFormat = "yyyyMMdd-HHmmss"
        let url = backupDirectory.appendingPathComponent("config.\(formatter.string(from: Date())).backup")
        try FileManager.default.copyItem(at: configURL, to: url)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        return url
    }
    private func saveConfig() {
        do {
            try FileManager.default.createDirectory(at: configURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            let backup = try backupCurrent()
            try renderedConfig().write(to: configURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: configURL.path)
            hasStructuralChanges = false
            status = backup.map { "Saved. Backup: \($0.lastPathComponent)" } ?? "Saved new config."
        } catch { show(error) }
    }
    private func connect(to entry: SSHEntry) {
        recordRecent(entry.title)
        let destination = entry.user.isEmpty ? entry.hostNameOrTitle : "\(entry.user)@\(entry.hostNameOrTitle)"
        var command = "ssh"
        if !entry.identityFile.isEmpty { command += " -i \(shellQuote(expandHome(entry.identityFile)))" }
        command += " \(shellQuote(destination))"
        let script = "tell application \"Terminal\"\nactivate\ndo script \(appleScriptQuote(command))\nend tell"
        guard let appleScript = NSAppleScript(source: script) else { alertMessage = "Could not prepare the Terminal command."; return }
        var errorInfo: NSDictionary?
        _ = appleScript.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let reason = errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown macOS automation error."
            alertMessage = "Could not open Terminal.\n\n\(reason)"
        }
    }
    private func recordRecent(_ title: String) {
        recentHostTitles.removeAll { $0 == title }
        recentHostTitles.insert(title, at: 0)
        recentHostTitles = Array(recentHostTitles.prefix(20))
        UserDefaults.standard.set(recentHostTitles, forKey: "recentSSHHosts")
    }
    private func removeRecent(_ title: String) {
        recentHostTitles.removeAll { $0 == title }
        UserDefaults.standard.set(recentHostTitles, forKey: "recentSSHHosts")
    }
    private func test(_ entry: SSHEntry) {
        let destination = entry.user.isEmpty ? entry.hostNameOrTitle : "\(entry.user)@\(entry.hostNameOrTitle)"
        guard !destination.isEmpty else { alertMessage = "This host needs a HostName or Host title to test."; return }
        status = "Testing \(entry.title)…"
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ssh")
            var arguments = ["-o", "BatchMode=yes", "-o", "ConnectTimeout=8", "-o", "StrictHostKeyChecking=yes"]
            if !entry.identityFile.isEmpty { arguments += ["-i", self.expandHome(entry.identityFile)] }
            arguments += [destination, "exit"]
            process.arguments = arguments
            let output = Pipe(); process.standardError = output; process.standardOutput = output
            do {
                try process.run(); process.waitUntilExit()
                let details = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                DispatchQueue.main.async {
                    if process.terminationStatus == 0 { self.alertMessage = "Connection test succeeded for \(entry.title)." }
                    else { self.alertMessage = "Connection test failed for \(entry.title).\n\n\(details.isEmpty ? "SSH returned status \(process.terminationStatus)." : details)" }
                    self.status = ""
                }
            } catch { DispatchQueue.main.async { self.show(error); self.status = "" } }
        }
    }
    private func expandHome(_ value: String) -> String { value.hasPrefix("~/") ? FileManager.default.homeDirectoryForCurrentUser.path + String(value.dropFirst()) : value }
    private func shellQuote(_ value: String) -> String { "'\(value.replacingOccurrences(of: "'", with: "'\\\"'\\\"'"))'" }
    private func appleScriptQuote(_ value: String) -> String { "\"\(value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\"" }
    private func show(_ error: Error) { alertMessage = error.localizedDescription }
}

private extension SSHEntry {
    var hostNameOrTitle: String { hostName.isEmpty ? title : hostName }
}
