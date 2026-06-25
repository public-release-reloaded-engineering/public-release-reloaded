#!/usr/bin/env bash
# Populate opam-repository/packages/ from releases/ opam files.
#
# Usage: scripts/populate-opam-repo.sh [VERSION]
#
# VERSION defaults to the version derived from the releases sub-submodule branch
# name (e.g. v0.18_preview.130.100+614+reloaded).  The +reloaded suffix ensures
# these packages do not conflict with upstream Jane Street opam packages, which
# use the same v0.18* prefix without +reloaded.
#
# Idempotent: re-running overwrites the destination opam files in-place, which
# is a no-op when nothing has changed.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RELEASES_DIR="$REPO_ROOT/releases"
OPAM_REPO="$REPO_ROOT/opam-repository/packages"

# Derive version from the branch of the first sub-submodule that has one,
# or accept it as a CLI argument.
if [[ $# -ge 1 ]]; then
  VERSION="$1"
else
  VERSION=$(git -C "$RELEASES_DIR" submodule foreach --quiet \
    'git branch --show-current 2>/dev/null' 2>/dev/null \
    | grep -m1 '+reloaded' || true)
  if [[ -z "$VERSION" ]]; then
    echo "ERROR: could not determine version from sub-submodule branches." >&2
    echo "Pass VERSION as the first argument." >&2
    exit 1
  fi
fi

echo "Populating opam-repository for version: $VERSION"
echo "Source:      $RELEASES_DIR"
echo "Destination: $OPAM_REPO"
echo ""

count=0
while read -r src; do
  pkg=$(basename "$src" .opam)
  dest_dir="$OPAM_REPO/$pkg/$pkg.$VERSION"
  dest="$dest_dir/opam"

  mkdir -p "$dest_dir"

  # Extract the git URL from dev-repo: to use as the installable source.
  # dev-repo has the form:
  #   dev-repo: "git+https://github.com/public-release-reloaded/PKG.git#BRANCH"
  # opam's url.src accepts the same git+ URL; no checksum is required for
  # git sources.  Without a url block the package is discoverable but cannot
  # be installed via `opam install`.
  url_src=$(grep '^dev-repo:' "$src" | sed 's/dev-repo: *"\(.*\)"/\1/' || true)

  # Prepend the version: field (source files omit it — dune generates it from
  # the git tag at build time, but the opam repository needs it explicitly).
  {
    echo "version: \"$VERSION\""
    cat "$src"
    if [[ -n "$url_src" ]]; then
      printf '\nurl {\n  src: "%s"\n}\n' "$url_src"
    fi
  } > "$dest"

  count=$((count + 1))
done < <(find "$RELEASES_DIR" -name "*.opam" | sort)

echo "Wrote $count packages."
