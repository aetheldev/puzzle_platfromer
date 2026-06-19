#!/bin/zsh
set -e
cd "$(dirname "$0")"
source "../../../run_graphics.sh"
run_graphics "d06_two_detective_coop" "../../../../sauce/sokol"
