#!/usr/bin/env nix-shell
#!nix-shell -i bash -p libarchive curl common-updater-scripts

set -eu -o pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
root=../../../../..
export NIXPKGS_ALLOW_UNFREE=1

version() {
  (cd "$root" && nix-instantiate --eval --strict -A "$1.version" | tr -d '"')
}

vivaldi_version_old=$(version vivaldi)
vivaldi_version=$(curl -sS https://vivaldi.com/download/ | sed -rne 's/.*vivaldi-stable_([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+-[0-9]+)_amd64\.deb.*/\1/p')

if [[ "$vivaldi_version" = "$vivaldi_version_old" ]]; then
  echo "vivaldi is already up-to-date"
  exit
fi

# Download vivaldi and save hash and file path.
url="https://downloads.vivaldi.com/stable/vivaldi-stable_${vivaldi_version}_amd64.deb"
mapfile -t prefetch < <(nix-prefetch-url --print-path "$url")
hash=${prefetch[0]}
path=${prefetch[1]}

nixpkgs="$(git rev-parse --show-toplevel)"
default_nix="$nixpkgs/pkgs/applications/networking/browsers/vivaldi/default.nix"
ffmpeg_nix="$nixpkgs/pkgs/applications/networking/browsers/vivaldi/ffmpeg-codecs.nix"

(cd "$root" && update-source-version vivaldi "$vivaldi_version" "$hash")

git add "${default_nix}"
git commit -m "vivaldi: ${vivaldi_version_old} -> ${vivaldi_version}"

# Check vivaldi-ffmpeg-codecs version.
chromium_version_old=$(version vivaldi-ffmpeg-codecs)
ffmpeg_update_script=$(bsdtar xOf "$path" data.tar.xz | bsdtar xOf - ./opt/vivaldi/update-ffmpeg)
chromium_version=$(sed -rne 's/^FFMPEG_VERSION_DEB\=([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+).*/\1/p' <<< $ffmpeg_update_script)
download_subdir=$(sed -rne 's/.*FFMPEG_URL_DEB\=https:\/\/launchpadlibrarian\.net\/([0-9]+)\/.*_amd64\.deb/\1/p' <<< $ffmpeg_update_script)

if [[ "$chromium_version" != "$chromium_version_old" ]]; then
  # replace the download prefix
  sed -i $ffmpeg_nix -e "s/\(https:\/\/launchpadlibrarian\.net\/\)[0-9]\+/\1$download_subdir/g"
  (cd "$root" && update-source-version vivaldi-ffmpeg-codecs "$chromium_version")

  git add "${ffmpeg_nix}"
  git commit -m "vivaldi-ffmepg-codecs: $chromium_version_old -> $chromium_version"
fi
