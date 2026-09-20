# homebrew-tap

Homebrew formulae for tools I maintain.

```bash
brew tap smithclay/tap
```

## Formulae

| Formula | What it is |
| --- | --- |
| [`duckdb-otlp`](Formula/duckdb-otlp.rb) | Stream, store, and query OpenTelemetry (OTLP) data in DuckDB |
| [`claudetainer`](Formula/claudetainer.rb) | Claude Code workflows for any dev container |
| [`ohcommodore`](Formula/ohcommodore.rb) | Multi-coding-agent control plane on exe.dev VMs |

### duckdb-otlp as a background service

```bash
brew install smithclay/tap/duckdb-otlp
brew services start duckdb-otlp
```

That runs `duckdb-otlp serve` with its defaults — OTLP/HTTP on `127.0.0.1:4318`,
OTLP/gRPC on `127.0.0.1:4317`, streaming into a local DuckLake under
`~/.local/share/duckdb-otlp`. Loopback-bound with no token, so authentication is
disabled automatically. Logs land in `$(brew --prefix)/var/log/duckdb-otlp.log`.

The data directory is deliberately left at the CLI's own default rather than
moved under `$(brew --prefix)/var`, so `duckdb-otlp query` reads the same catalog
the service writes. Note that the running server holds an exclusive lock on the
control database — stop the service before querying it, or run the server with a
Quack SQL endpoint instead.

`brew services` can only ever run the defaults: duckdb-otlp has no config file,
and the launchd plist is rewritten on every restart. For a custom mode, port,
bind host or token, run the server yourself.

## Automation

`duckdb-otlp` bumps itself. [`update-duckdb-otlp.yml`](.github/workflows/update-duckdb-otlp.yml)
polls the upstream releases API every six hours; when the tag moves,
[`update-duckdb-otlp.py`](.github/scripts/update-duckdb-otlp.py) rewrites the
version, URLs and checksums, CI installs and tests the result on macOS and
Linux, and only then does the bump land on `main`.

Checksums come from the release's `SHA256SUMS` asset, cross-checked against the
per-asset digest the GitHub API reports, so a bump downloads nothing.

This is a pull model with **no credentials anywhere** — no PAT, no GitHub App
key, no cross-repo secret. The tap reads a public API and pushes to itself with
the built-in `GITHUB_TOKEN`. The tradeoff is up to six hours of lag, and the
fact that GitHub disables scheduled workflows in a repository that has gone 60
days without a commit.

To pull a release in immediately, or to pin an older tag:

```bash
gh workflow run update-duckdb-otlp.yml            # latest release
gh workflow run update-duckdb-otlp.yml -f tag=v0.7.0
```
