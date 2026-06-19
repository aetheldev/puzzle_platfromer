#!/bin/zsh
set -e
cd "$(dirname "$0")"
source "../../../run_graphics.sh"
run_graphics "gp10_bloom_depth" "../../../../sauce/sokol"
