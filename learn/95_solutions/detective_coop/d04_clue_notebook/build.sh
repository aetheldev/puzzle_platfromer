#!/bin/zsh
set -e
cd "$(dirname "$0")"
source "../../../run_graphics.sh"
run_graphics "d04_clue_notebook" "../../../../sauce/sokol"
