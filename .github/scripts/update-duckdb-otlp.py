#!/usr/bin/env python3
"""Point Formula/duckdb-otlp.rb at a duckdb-otlp release.

Checksums come from the release's own SHA256SUMS asset, cross-checked against
the per-asset `digest` the GitHub API reports. Nothing is downloaded, so a bump
costs two small API calls instead of 90 MB of tarballs.

The release job upstream always writes SHA256SUMS (`sha256sum *.tar.gz >
SHA256SUMS`), so its absence means the release shape changed -- that is a
human's problem, not something to paper over, and this exits non-zero.

Usage: update-duckdb-otlp.py [--tag vX.Y.Z] [--formula PATH]
Appends `changed`, `version` and `tag` to $GITHUB_OUTPUT when that is set.
"""

import argparse
import json
import os
import re
import sys
import urllib.error
import urllib.request

REPO = "smithclay/duckdb-otlp"
# Every platform the formula carries a url/sha256 pair for. A release missing
# any one of them is incomplete, so we refuse it rather than bump the rest.
PLATFORMS = ("darwin-arm64", "darwin-amd64", "linux-arm64", "linux-amd64")
SHA256SUMS = "SHA256SUMS"


def die(msg):
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def fetch(url, accept="application/vnd.github+json"):
    req = urllib.request.Request(url, headers={
        "Accept": accept,
        "User-Agent": "smithclay-homebrew-tap-updater",
        "X-GitHub-Api-Version": "2022-11-28",
    })
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            return resp.read()
    except urllib.error.HTTPError as e:
        die(f"GET {url} failed: HTTP {e.code} {e.reason}")
    except urllib.error.URLError as e:
        die(f"GET {url} failed: {e.reason}")


def release_for(tag):
    path = f"releases/tags/{tag}" if tag else "releases/latest"
    return json.loads(fetch(f"https://api.github.com/repos/{REPO}/{path}"))


def checksums(assets):
    """name -> sha256, from SHA256SUMS cross-checked against the API digests."""
    by_name = {a["name"]: a for a in assets}
    if SHA256SUMS not in by_name:
        die(f"release has no {SHA256SUMS} asset; refusing to guess checksums")

    sums = {}
    text = fetch(by_name[SHA256SUMS]["browser_download_url"], accept="*/*")
    for line in text.decode().splitlines():
        parts = line.split()
        if len(parts) == 2:
            sums[parts[1].lstrip("*")] = parts[0]

    for name, sha in sums.items():
        digest = (by_name.get(name) or {}).get("digest") or ""
        if digest.startswith("sha256:") and digest[7:] != sha:
            die(f"{name}: {SHA256SUMS} says {sha}, GitHub reports {digest[7:]}")
    return sums


def rewrite(text, tag, version, sums):
    base = f"https://github.com/{REPO}/releases/download/{tag}"

    text, n = re.subn(
        r'^(\s*version ")[^"]*(")',
        lambda m: m.group(1) + version + m.group(2),
        text, count=1, flags=re.MULTILINE,
    )
    if n != 1:
        die("no `version \"...\"` line found in the formula")

    for platform in PLATFORMS:
        name = f"duckdb-otlp-{tag}-{platform}.tar.gz"
        if name not in sums:
            die(f"release is missing {name}")
        # Keyed on the platform in the URL, not on position, so reordering the
        # on_macos/on_linux blocks cannot silently pair a url with a wrong hash.
        pattern = re.compile(
            r'url "[^"]*-' + re.escape(platform) + r'\.tar\.gz"\n(\s*)sha256 "[0-9a-f]{64}"'
        )
        text, n = pattern.subn(
            lambda m: f'url "{base}/{name}"\n{m.group(1)}sha256 "{sums[name]}"',
            text,
        )
        if n != 1:
            die(f"expected exactly one url/sha256 pair for {platform}, found {n}")

    return text


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    default_formula = os.path.join(here, "..", "..", "Formula", "duckdb-otlp.rb")

    ap = argparse.ArgumentParser()
    ap.add_argument("--tag", help="release tag to pin (default: latest release)")
    ap.add_argument("--formula", default=os.path.normpath(default_formula))
    args = ap.parse_args()

    release = release_for(args.tag)
    if release.get("draft") or release.get("prerelease"):
        die(f"{release['tag_name']} is a draft or prerelease")

    tag = release["tag_name"]
    if not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
        die(f"unexpected tag shape: {tag}")
    version = tag[1:]

    with open(args.formula) as f:
        text = f.read()

    current = re.search(r'^\s*version "([^"]*)"', text, re.MULTILINE)
    if not current:
        die("no `version \"...\"` line found in the formula")

    if current.group(1) == version:
        print(f"duckdb-otlp is already at {version}")
        return emit(changed=False, version=version, tag=tag)

    updated = rewrite(text, tag, version, checksums(release["assets"]))
    with open(args.formula, "w") as f:
        f.write(updated)

    print(f"duckdb-otlp {current.group(1)} -> {version}")
    return emit(changed=True, version=version, tag=tag)


def emit(*, changed, version, tag):
    out = os.environ.get("GITHUB_OUTPUT")
    if out:
        with open(out, "a") as f:
            f.write(f"changed={str(changed).lower()}\nversion={version}\ntag={tag}\n")


if __name__ == "__main__":
    main()
