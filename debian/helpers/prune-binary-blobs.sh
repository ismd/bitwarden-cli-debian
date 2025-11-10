#!/bin/bash
# Remove Windows-only prebuilt binaries that cannot be shipped in Debian.
# This script is invoked by create-orig-tarball.sh before the archive is
# created to keep the orig tarball DFSG-compliant and lintian-clean.

set -euo pipefail

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 <source-tree>" >&2
	exit 1
fi

TARGET_DIR=$1

if [[ ! -d "$TARGET_DIR" ]]; then
	echo "ERROR: Target directory '$TARGET_DIR' does not exist" >&2
	exit 1
fi

log() {
	echo "[prune-binary-blobs] $*"
}

remove_dir() {
	local rel="$1"
	local abs="${TARGET_DIR%/}/$rel"
	if [[ -e "$abs" ]]; then
		log "Removing directory: $rel"
		rm -rf "$abs"
	fi
}

log "Pruning Windows-specific binaries from $(realpath "$TARGET_DIR")"

# Known directories that only contain Windows executables.
remove_dir "node_modules/7zip-bin/win"
remove_dir "node_modules/app-builder-bin/win"
remove_dir "node_modules/electron-winstaller/vendor"
remove_dir "node_modules/@electron/windows-sign/vendor"

# Remove win32 prebuilds for bundled native modules (bufferutil, utf-8-validate, etc.).
if [[ -d "${TARGET_DIR%/}/node_modules" ]]; then
	while IFS= read -r dir; do
		rel="${dir#$TARGET_DIR/}"
		log "Removing Windows prebuild directory: $rel"
		rm -rf "$dir"
	done < <(find "${TARGET_DIR%/}/node_modules" -type d -path '*/prebuilds/win32-*' 2>/dev/null)

	# Catch any loose .exe/.dll/.com files that live in win-only subpaths.
	while IFS= read -r file; do
		rel="${file#$TARGET_DIR/}"
		if [[ "$rel" == *"/win/"* ]] || [[ "$rel" == *"/win32"* ]] || [[ "$rel" == *"/vendor/"* ]]; then
			case "$file" in
				*.exe|*.dll|*.com)
					log "Removing Windows binary: $rel"
					rm -f "$file"
					;;
			esac
		fi
	done < <(find "${TARGET_DIR%/}/node_modules" -type f \( -iname '*.exe' -o -iname '*.dll' -o -iname '*.com' \) 2>/dev/null)
fi

log "Finished pruning Windows binaries"
