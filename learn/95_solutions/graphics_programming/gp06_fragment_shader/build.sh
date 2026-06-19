#!/bin/zsh
set -e
cd "$(dirname "$0")"
source "../../../run_graphics.sh"
run_graphics "gp06_fragment_shader" "../../../../sauce/sokol"
