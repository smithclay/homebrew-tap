class DuckdbOtlp < Formula
  desc "Stream, store, and query OpenTelemetry (OTLP) data in DuckDB"
  homepage "https://smithclay.github.io/duckdb-otlp/"
  # Explicit because the release asset names end in the architecture: brew scans
  # the last number in `...-linux-amd64.tar.gz`, so without this every release is
  # version "64" and `brew upgrade` never sees a newer one.
  version "0.9.0"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  on_macos do
    on_arm do
      url "https://github.com/smithclay/duckdb-otlp/releases/download/v0.9.0/duckdb-otlp-v0.9.0-darwin-arm64.tar.gz"
      sha256 "4783ee2053d1b2d2b7788b50692024ea0a1acdf9cfa943a99ed8ca29dcfb0052"
    end
    on_intel do
      url "https://github.com/smithclay/duckdb-otlp/releases/download/v0.9.0/duckdb-otlp-v0.9.0-darwin-amd64.tar.gz"
      sha256 "df63e71bce1726bb848723b44fd4a0b389071adc162885de2d1301e1675965e5"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/smithclay/duckdb-otlp/releases/download/v0.9.0/duckdb-otlp-v0.9.0-linux-arm64.tar.gz"
      sha256 "a0adb7fbd3d78d5f8795578e36513983710f057acb7a9ab31c2501adec266f46"
    end
    on_intel do
      url "https://github.com/smithclay/duckdb-otlp/releases/download/v0.9.0/duckdb-otlp-v0.9.0-linux-amd64.tar.gz"
      sha256 "c8848d4979c7c4a120495811312db7fe9cda087cf365eb01bc524d578371f82a"
    end
  end

  def install
    bin.install "duckdb-otlp"
  end

  # Defaults only: duckdb-otlp has no config file, and `brew services` rewrites the
  # plist on every restart, so anything set here is all a managed service can get.
  # Those defaults are the safe ones -- loopback-only listeners, and the data
  # directory left at the CLI's default so the catalog is where the caveats say.
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

      duckdb-otlp only receives. Query what it stored with the `duckdb` CLI
      (`brew install duckdb`). The running service holds the catalog's write lock,
      so stop it first, or run the server yourself with `--quack PORT` and query
      it over Quack instead:

        brew services stop duckdb-otlp
        duckdb -c "ATTACH 'ducklake:$HOME/.local/share/duckdb-otlp/ducklake/catalog.duckdb' AS otel (READ_ONLY);
                   FROM otel.otlp_logs LIMIT 10"

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
