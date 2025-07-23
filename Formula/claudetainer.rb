class Claudetainer < Formula
  desc "Production-ready Claude Code workflows for any dev container"
  homepage "https://github.com/smithclay/claudetainer"
  url "https://github.com/smithclay/claudetainer/archive/v0.1.0.tar.gz"
  sha256 ""  # Will be automatically updated by GitHub Actions
  license "MIT"
  head "https://github.com/smithclay/claudetainer.git", branch: "main"

  depends_on "node" => :optional
  depends_on "docker" => :optional

  def install
    bin.install "bin/claudetainer"
    
    # Install feature files for local testing
    prefix.install "src"
    
    # Install documentation
    doc.install "README.md", "DEVELOPMENT.md", "LICENSE"
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

      Documentation: #{doc}/README.md
    EOS
  end
end