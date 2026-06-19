#!/bin/zsh
set -e
cd "$(dirname "$0")"
source "../../../run_graphics.sh"
run_graphics "gp09_normal_mapping" "../../../../sauce/sokol"
