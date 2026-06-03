#!/bin/zsh
set -e
cd "$(dirname "$0")"
# macOS keyboard-focus fix lives in learn/run_graphics.sh.
source "../../run_graphics.sh"
run_graphics "s00_foundation" "../../../sauce/sokol"
