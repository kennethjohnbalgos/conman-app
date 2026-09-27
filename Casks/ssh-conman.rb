cask "ssh-conman" do
  version "1.1.2"
  sha256 "06a32a787d88f4b3d6eca00409a369b64c34d0cb80d02cab7a18865544b1fe88"

  url "https://raw.githubusercontent.com/kennethjohnbalgos/conman-app/main/SSH-ConMan-#{version}.zip"
  name "SSH ConMan"
  desc "Menu bar SSH configuration manager"
  homepage "https://github.com/kennethjohnbalgos/conman-app"

  depends_on macos: :sonoma

  app "SSH ConMan.app"

  uninstall quit: "local.ssh-config-manager"
end
