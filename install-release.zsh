#!/bin/zsh
# run destructive with DRY_RUN=false <script>

set -euo pipefail

DRY_RUN="${DRY_RUN:-true}"

APP_NAME="clipGuard"
SCHEME="clipGuard"
PROJECT="clipGuard.xcodeproj"

ARCHIVE_PATH="$HOME/Developer/Builds/${APP_NAME}.xcarchive"
ARCHIVED_APP_PATH="$ARCHIVE_PATH/Products/Applications/${APP_NAME}.app"
APPLICATION_PATH="/Applications/${APP_NAME}.app"

run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "[dry-run] $*"
  else
    echo "[run] $*"
    "$@"
  fi
}

echo "DRY_RUN=$DRY_RUN"
echo

run rm -rf "$ARCHIVE_PATH"
run rm -rf "$APPLICATION_PATH"

run xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH"

if [[ ! -d "$ARCHIVED_APP_PATH" ]]; then
  echo "Error: archived app not found at:"
  echo "  $ARCHIVED_APP_PATH"
  exit 1
fi

run cp -R "$ARCHIVED_APP_PATH" /Applications/

echo
echo "Done."
echo "Installed app path:"
echo "  $APPLICATION_PATH"