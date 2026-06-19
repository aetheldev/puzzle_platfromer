#!/bin/zsh
set -e
cd "$(dirname "$0")"
source "../../../run_graphics.sh"
run_graphics "d03_dialog_system" "../../../../sauce/sokol"
