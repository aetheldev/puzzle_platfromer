#!/bin/zsh
set -e
cd "$(dirname "$0")"
odin run . -collection:sokol=../../../sauce/sokol
