#!/bin/zsh
set -e
cd "$(dirname "$0")"
# macOS keyboard-focus fix lives in learn/run_graphics.sh (see that file for why).
source "../../../run_graphics.sh"
run_graphics "p06_idle_widget" "../../../../sauce/sokol"
