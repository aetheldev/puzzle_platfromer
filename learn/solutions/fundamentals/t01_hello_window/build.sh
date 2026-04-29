#!/bin/zsh
# Build & run T01 — Hello Window
set -e
cd "$(dirname "$0")"
odin run . -collection:sokol=../../../../sauce/sokol
