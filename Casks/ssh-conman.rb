cask "ssh-conman" do
  version "1.1.0"
  sha256 "e0bee3c65a76aa9819356575a04ce2635e5e602daa8dde347f01158c9a8efddd"

  url "https://raw.githubusercontent.com/kennethjohnbalgos/ssh-app/main/SSH-ConMan-#{version}.zip"
  name "SSH ConMan"
  desc "Menu bar SSH configuration manager"
  homepage "https://github.com/kennethjohnbalgos/ssh-app"

  depends_on macos: :sonoma

  app "SSH ConMan.app"

  uninstall quit: "local.ssh-config-manager"
end
