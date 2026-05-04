#!/usr/bin/env bash

#
# Credits
# =======
#
# Original script: https://github.com/rojo-rbx/rokit/blob/36a5619/scripts/install.sh
#
# Modified for CompeyDev/setup-rokit:
#   - Fuzzy version matching (e.g. "1", "1.2" in addition to "1.2.3")
#   - Optional leading "v" prefix on version argument (v1.2.3 and 1.2.3 both work)
#   - Switches to the releases list endpoint for fuzzy lookups so the newest
#     qualifying release is selected automatically
#

#
# License
# =======
# The original script was licensed under the MIT. Changes have been licensed under
# the same, with different copyright holders.
#
# A copy of the original license has been produced verbatim below:
#
#   Copyright (c) 2024

#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:

#   The above copyright notice and this permission notice shall be included in all
#   copies or substantial portions of the Software.

#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.
#

PROGRAM_NAME="rokit"
REPOSITORY="rojo-rbx/rokit"

set -eo pipefail

# Make sure we have all the necessary commands available
dependencies=(
    curl
    unzip
    uname
    tr
)

for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo "ERROR: '$dep' is not installed or available." >&2
        exit 1
    fi
done

# Warn the user if they are not using a shell we know works (bash, zsh)
if [ -z "$BASH_VERSION" ] && [ -z "$ZSH_VERSION" ]; then
    echo "WARNING: You are using an unsupported shell. Automatic installation may not work correctly." >&2
fi

# Let the user know their access token was detected, if provided
if [ ! -z "$GITHUB_PAT" ]; then
    echo "NOTE: Using provided GITHUB_PAT for authentication"
fi

# Determine OS and architecture for the current system
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
case "$OS" in
    darwin) OS="macos" ;;
    linux) OS="linux" ;;
    cygwin*|mingw*|msys*) OS="windows" ;;
    *)
        echo "Unsupported OS: $OS" >&2
        exit 1 ;;
esac
ARCH="$(uname -m)"
case "$ARCH" in
    x86_64) ARCH="x86_64" ;;
    x86-64) ARCH="x86_64" ;;
    arm64) ARCH="aarch64" ;;
    aarch64) ARCH="aarch64" ;;
    *)
        echo "Unsupported architecture: $ARCH" >&2;
        exit 1 ;;
esac

# Construct file pattern for our desired zip file based on OS + arch
# NOTE: This only works for exact patterns "binary-X.Y.Z-os-arch.zip"
# and WILL break if the version contains extra metadata / pre-release
VERSION_PATTERN="[0-9]*\\.[0-9]*\\.[0-9]*"
API_URL="https://api.github.com/repos/$REPOSITORY/releases/latest"
if [ ! -z "$1" ]; then
    # Strip leading 'v' prefix if present, then build a prefix-anchored semver
    # pattern to support fuzzy versions like "1", "1.2", or "1.2.3".
    # Examples:
    #   "1"     -> matches 1.X.Y  (e.g. 1.0.0, 1.23.456)
    #   "1.2"   -> matches 1.2.Y  (e.g. 1.2.0, 1.2.99)
    #   "1.2.3" -> matches 1.2.3  (exact)
    #   "v1.2"  -> same as "1.2" (v prefix stripped)
    INPUT_VERSION="${1#v}"

    # Count dots to determine how specific the version is
    DOT_COUNT="${INPUT_VERSION//[^.]}"
    DOT_COUNT="${#DOT_COUNT}"

    if [ "$DOT_COUNT" -eq 0 ]; then
        # Major only: e.g. "1" matches "1.X.Y"
        VERSION_PATTERN="${INPUT_VERSION}\\.[0-9]*\\.[0-9]*"
        # Use the GitHub list endpoint and filter locally (no exact tag to target)
        API_URL="https://api.github.com/repos/$REPOSITORY/releases"
        printf "\n[1 / 3] Looking for latest $PROGRAM_NAME release matching v${INPUT_VERSION}.x.x\n"
    elif [ "$DOT_COUNT" -eq 1 ]; then
        # Major.minor only: e.g. "1.2" matches "1.2.Y"
        VERSION_PATTERN="${INPUT_VERSION}\\.[0-9]*"
        API_URL="https://api.github.com/repos/$REPOSITORY/releases"
        printf "\n[1 / 3] Looking for latest $PROGRAM_NAME release matching v${INPUT_VERSION}.x\n"
    else
        # Full semver: e.g. "1.2.3", exact tag lookup
        VERSION_PATTERN="$INPUT_VERSION"
        API_URL="https://api.github.com/repos/$REPOSITORY/releases/tags/v$INPUT_VERSION"
        printf "\n[1 / 3] Looking for $PROGRAM_NAME release with tag 'v${INPUT_VERSION}'\n"
    fi
else
    # Fetch the latest release from the GitHub API
    printf "\n[1 / 3] Looking for latest $PROGRAM_NAME release\n"
fi
FILE_PATTERN="${PROGRAM_NAME}-${VERSION_PATTERN}-${OS}-${ARCH}.zip"

# Use curl to fetch the latest release data from GitHub API
if [ ! -z "$GITHUB_PAT" ]; then
    RELEASE_JSON_DATA=$(curl --proto '=https' --tlsv1.2 -sSf "$API_URL" \
        -H "X-GitHub-Api-Version: 2022-11-28" -H "Authorization: token $GITHUB_PAT")
else
    RELEASE_JSON_DATA=$(curl --proto '=https' --tlsv1.2 -sSf "$API_URL" \
        -H "X-GitHub-Api-Version: 2022-11-28")
fi

# Check if the release was fetched successfully
if [ -z "$RELEASE_JSON_DATA" ] || [[ "$RELEASE_JSON_DATA" == *"Not Found"* ]]; then
    echo "ERROR: Release was not found. Please check your network connection and version string." >&2
    exit 1
fi

# Try to extract the asset url from the response by searching for a
# matching asset name, and then picking the "url" that came before it.
#
# When using the list endpoint (fuzzy versions), the JSON contains multiple
# releases ordered newest-first. We pick the FIRST asset whose name matches
# FILE_PATTERN, which is therefore the most recent qualifying release.
RELEASE_ASSET_ID=""
RELEASE_ASSET_NAME=""
while IFS= read -r current_line; do
    if [[ "$current_line" == *'"url":'* && "$current_line" == *"https://api.github.com/repos/$REPOSITORY/releases/assets/"* ]]; then
        RELEASE_ASSET_ID="${current_line##*/releases/assets/}"
        RELEASE_ASSET_ID="${RELEASE_ASSET_ID%%\"*}"
    elif [[ "$current_line" == *'"name":'* ]]; then
        current_name="${current_line#*: \"}"
        current_name="${current_name%%\"*}"
        if [[ "$current_name" =~ $FILE_PATTERN ]]; then
            if [ -n "$RELEASE_ASSET_ID" ]; then
                RELEASE_ASSET_ID="$RELEASE_ASSET_ID"
                RELEASE_ASSET_NAME="$current_name"
                break
            else
                RELEASE_ASSET_ID=""
            fi
        else
            RELEASE_ASSET_ID=""
        fi
    fi
done <<< "$RELEASE_JSON_DATA"

if [ -z "$RELEASE_ASSET_ID" ] || [ -z "$RELEASE_ASSET_NAME" ]; then
    echo "ERROR: Failed to find asset that matches the pattern \"$FILE_PATTERN\" in the release listing." >&2
    exit 1
fi

# Download the file using curl and make sure it was successful
echo "[2 / 3] Downloading '$RELEASE_ASSET_NAME'"
RELEASE_DOWNLOAD_URL="https://api.github.com/repos/$REPOSITORY/releases/assets/$RELEASE_ASSET_ID"
ZIP_FILE="${RELEASE_ASSET_NAME%.*}.zip"
if [ ! -z "$GITHUB_PAT" ]; then
    curl --proto '=https' --tlsv1.2 -L -o "$ZIP_FILE" -sSf "$RELEASE_DOWNLOAD_URL" \
        -H "X-GitHub-Api-Version: 2022-11-28" -H "Accept: application/octet-stream"  -H "Authorization: token $GITHUB_PAT"
else
    curl --proto '=https' --tlsv1.2 -L -o "$ZIP_FILE" -sSf "$RELEASE_DOWNLOAD_URL" \
        -H "X-GitHub-Api-Version: 2022-11-28" -H "Accept: application/octet-stream"
fi
if [ ! -f "$ZIP_FILE" ]; then
    echo "ERROR: Failed to download the release archive '$ZIP_FILE'." >&2
    exit 1
fi

# Unzip only the specific file we want and make sure it was successful
BINARY_NAME="$PROGRAM_NAME"
if [ "$OS" = "windows" ]; then
    BINARY_NAME="${BINARY_NAME}.exe"
fi
unzip -o -q "$ZIP_FILE" "$BINARY_NAME" -d .
rm "$ZIP_FILE"
if [ ! -f "$BINARY_NAME" ]; then
    echo "ERROR: The file '$BINARY_NAME' does not exist in the downloaded archive." >&2
    exit 1
fi

# Execute the file and remove it when done
printf "[3 / 3] Running $PROGRAM_NAME installation\n\n"
if [ "$OS" != "windows" ]; then
    chmod +x "$BINARY_NAME"
fi
./"$BINARY_NAME" self-install
rm "$BINARY_NAME"

