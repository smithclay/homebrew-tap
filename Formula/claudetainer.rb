class Claudetainer < Formula
  desc "Claude Code workflows for any dev container"
  homepage "https://github.com/smithclay/claudetainer"
  url "https://github.com/smithclay/claudetainer/releases/download/cli-v0.4.0/claudetainer"
  sha256 "972ea487cee2b7fa8d5167233005fe3b3837ff78f0385e7875243760e7eb4144"
  license "MIT"
  version "0.4.0"

  depends_on "node" => :optional
  depends_on "docker" => :optional

  def install
    # Since the URL points to a single binary, install it directly
    bin.install "claudetainer"
  end

  test do
    # Test that the binary exists and can show help
    assert_match "Claudetainer CLI", shell_output("#{bin}/claudetainer --help")
    assert_match version.to_s, shell_output("#{bin}/claudetainer --version")
  end

  def caveats
    <<~EOS
      Claudetainer requires the DevContainer CLI to function:
        npm install -g @devcontainers/cli

      For full functionality, you'll also need:
        - Docker Desktop or Docker Engine
        - Git (for GitHub preset support)

      To get started:
        claudetainer init
        claudetainer up
        claudetainer ssh

      More info: #{homepage}
    EOS
  end
end
