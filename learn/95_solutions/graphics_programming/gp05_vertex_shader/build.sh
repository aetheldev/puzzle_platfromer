#!/bin/zsh
set -e
cd "$(dirname "$0")"
source "../../../run_graphics.sh"
run_graphics "gp05_vertex_shader" "../../../../sauce/sokol"
