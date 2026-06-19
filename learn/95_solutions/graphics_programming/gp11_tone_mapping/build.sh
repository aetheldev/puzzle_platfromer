#!/bin/zsh
set -e
cd "$(dirname "$0")"
source "../../../run_graphics.sh"
run_graphics "gp11_tone_mapping" "../../../../sauce/sokol"
