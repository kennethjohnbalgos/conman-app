cask "ssh-conman" do
  version "1.1.1"
  sha256 "2d28d881674a8691f7b09bc4493e5395a241e8fecfa9a706c44f83bc030ab80c"

  url "https://raw.githubusercontent.com/kennethjohnbalgos/conman-app/main/SSH-ConMan-#{version}.zip"
  name "SSH ConMan"
  desc "Menu bar SSH configuration manager"
  homepage "https://github.com/kennethjohnbalgos/conman-app"

  depends_on macos: :sonoma

  app "SSH ConMan.app"

  uninstall quit: "local.ssh-config-manager"
end
