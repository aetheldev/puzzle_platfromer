#!/bin/zsh
set -e
cd "$(dirname "$0")"
# This is the EXERCISE folder. Write your own main.odin here from the LESSON.md,
# then run this to build it. Runnable answer lives in:
#   learn/95_solutions/co_op/parallel_worlds_puzzle/prototype/
# macOS keyboard-focus fix lives in learn/run_graphics.sh (see that file for why).
source "../../../run_graphics.sh"
run_graphics "prototype" "../../../../sauce/sokol"
