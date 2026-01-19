class Ohcommodore < Formula
  desc "Lightweight multi-coding agent control plane on exe.dev VMs"
  homepage "https://github.com/smithclay/ohcommodore"
  url "https://github.com/smithclay/ohcommodore.git", revision: "fc893b893ce71cadd745cebf431fc002474fc1e7"
  version "0.1.0"
  license "MIT"
  head "https://github.com/smithclay/ohcommodore.git", branch: "main"

  depends_on "jq"

  def install
    libexec.install "ohcommodore", "flagship", "cloudinit"
    bin.install_symlink libexec/"ohcommodore"
  end

  test do
    assert_match "ohcommodore", shell_output("#{bin}/ohcommodore help")
  end

  def caveats
    <<~EOS
      ohcommodore requires:
        - An exe.dev account with SSH access configured
        - A GitHub PAT (GH_TOKEN) for creating ships

      To get started:
        ohcommodore init              # Bootstrap flagship VM
        ohcommodore fleet status      # Check fleet status

      More info: #{homepage}
    EOS
  end
end
