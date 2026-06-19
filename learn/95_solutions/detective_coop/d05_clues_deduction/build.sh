#!/bin/zsh
set -e
cd "$(dirname "$0")"
source "../../../run_graphics.sh"
run_graphics "d05_clues_deduction" "../../../../sauce/sokol"
