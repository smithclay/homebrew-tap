class DuckdbOtlp < Formula
  desc "Stream, store, and query OpenTelemetry (OTLP) data in DuckDB"
  homepage "https://smithclay.github.io/duckdb-otlp/"
  version "0.7.2"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/smithclay/duckdb-otlp/releases/download/v0.7.2/duckdb-otlp-v0.7.2-darwin-arm64.tar.gz"
      sha256 "c014701be366161514c19204fa3ae7d039fb8a07f0124dd129e6e6d3858dd1ed"
    end
    on_intel do
      url "https://github.com/smithclay/duckdb-otlp/releases/download/v0.7.2/duckdb-otlp-v0.7.2-darwin-amd64.tar.gz"
      sha256 "d5091249a1211201e8c6cbb3ecc5e98def522a0f625241a423cb4604dafeff2d"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/smithclay/duckdb-otlp/releases/download/v0.7.2/duckdb-otlp-v0.7.2-linux-arm64.tar.gz"
      sha256 "cf22f145652f81b9bb3779a069cf64c3e0815a36e3dc765721ad3751e5d81c93"
    end
    on_intel do
      url "https://github.com/smithclay/duckdb-otlp/releases/download/v0.7.2/duckdb-otlp-v0.7.2-linux-amd64.tar.gz"
      sha256 "6d6862c7fe5ec0f3e3f6e1236190819a5ddc47af5a1b677df6e63ca0b0777e27"
    end
  end

  def install
    bin.install "duckdb-otlp"
  end

  # Defaults only: duckdb-otlp has no config file, and `brew services` rewrites the
  # plist on every restart, so anything set here is all a managed service can get.
  # Those defaults are the safe ones -- loopback-only listeners, and the data
  # directory left where the CLI looks for it so `duckdb-otlp query` reads the same
  # catalog the service writes.
  service do
    run [opt_bin/"duckdb-otlp", "serve"]
    keep_alive true
    restart_delay 5
    working_dir var
    log_path var/"log/duckdb-otlp.log"
    error_log_path var/"log/duckdb-otlp.log"
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      `brew services start duckdb-otlp` runs `duckdb-otlp serve` with its defaults:
      OTLP/HTTP on 127.0.0.1:4318 and OTLP/gRPC on 127.0.0.1:4317, streaming into a
      local DuckLake under ~/.local/share/duckdb-otlp. Bound to loopback with no
      token, authentication is disabled automatically.

      Point an OpenTelemetry exporter at http://127.0.0.1:4318/v1/{logs,traces,metrics}.

      The running server holds an exclusive lock on the control database, so
      `duckdb-otlp query` cannot read it while the service is up. Stop the service
      first, or run the server with a Quack SQL endpoint instead:

        brew services stop duckdb-otlp
        duckdb-otlp query "SELECT * FROM otlp_logs LIMIT 10"

      Service logs: #{var}/log/duckdb-otlp.log

      To change the mode, ports, bind host or token, run the server yourself rather
      than through `brew services`:

        duckdb-otlp serve --mode parquet --http 4418 --grpc 0

      Start the service without sudo: as a root daemon the data directory would
      resolve under root's home instead of yours.
    EOS
  end

  test do
    assert_match "duckdb-otlp", shell_output("#{bin}/duckdb-otlp version")

    # `validate` resolves every path and plans the catalog SQL without binding a
    # port or touching the network, so it exercises the binary hermetically.
    output = shell_output("#{bin}/duckdb-otlp validate --data-dir #{testpath}/data")
    assert_match "Mode: local-ducklake", output
    assert_match "OTLP http: otlp:127.0.0.1:4318", output
  end
end
