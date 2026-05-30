#!/bin/zsh
set -e
cd "$(dirname "$0")"
# Build and run
odin run . -collection:sokol=../../../../sauce/sokol
