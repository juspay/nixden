#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <base-lima-template>" >&2
  exit 1
fi

base_template=$1
repo=${DEVBOX_RELEASE_REPO:-juspay/devbox}
api_url="https://api.github.com/repos/${repo}/releases/latest"

release_json=$(curl -fsSL "$api_url")
tag=$(jq -r '.tag_name // empty' <<<"$release_json")

if [ -z "$tag" ]; then
  echo "Could not find latest release tag for ${repo}" >&2
  exit 1
fi

image_entry() {
  local arch=$1
  local asset_name asset_url sha_url sha512

  asset_name=$(
    jq -r --arg arch "$arch" '
      [ .assets[]
        | select(.name | test("^devbox(-.*)?-" + $arch + "\\.qcow2$"))
        | .name
      ] | first // empty
    ' <<<"$release_json"
  )

  if [ -z "$asset_name" ]; then
    echo "Could not find ${arch} qcow2 asset in ${repo} ${tag}" >&2
    exit 1
  fi

  asset_url=$(
    jq -r --arg name "$asset_name" '
      .assets[]
      | select(.name == $name)
      | .browser_download_url
    ' <<<"$release_json"
  )
  sha_url=$(
    jq -r --arg name "${asset_name}.sha512" '
      .assets[]
      | select(.name == $name)
      | .browser_download_url
    ' <<<"$release_json"
  )

  if [ -z "$asset_url" ] || [ -z "$sha_url" ]; then
    echo "Could not find ${asset_name} and matching .sha512 asset in ${repo} ${tag}" >&2
    exit 1
  fi

  sha512=$(curl -fsSL "$sha_url" | awk '{ print $1 }')
  if ! [[ "$sha512" =~ ^[0-9a-fA-F]{128}$ ]]; then
    echo "Invalid SHA-512 for ${asset_name}" >&2
    exit 1
  fi

  cat <<EOF
  - location: "${asset_url}"
    arch: "${arch}"
    digest: "sha512:${sha512}"
EOF
}

cat <<EOF
# Generated from the latest ${repo} release: ${tag}
images:
EOF
image_entry "aarch64"
image_entry "x86_64"

awk '
  /^images:[[:space:]]*$/ {
    seen_images = 1
    skipping = 1
    next
  }
  !seen_images {
    next
  }
  skipping && /^[^[:space:]-]/ {
    skipping = 0
  }
  !skipping {
    print
  }
' "$base_template"
