# Odin For JS/TS Developers

## Who This Is For

You know JavaScript or TypeScript well.
You may know React.
You have never written Odin, C, or any systems-level language.
Game programming is new to you.

## What This Track Teaches

How to read and write Odin code by mapping every concept to something you already know from JS/TS.

This is NOT a generic Odin tutorial.
This is specifically designed to bridge the gap between web development thinking and game development thinking.

## Why This Comes First

The game lessons in `learn/30_fundamentals/` use Odin code that looks foreign if you have never seen:
- `::` vs `:=` vs `=`
- `proc` instead of `function`
- `struct` instead of `class`
- pointers (`^`, `&`)
- no garbage collector
- no `async/await`
- no `npm`

This track teaches all of that before you touch any game code.

## Order

1. `o01_first_program`
2. `o02_variables_and_types`
3. `o03_procs_not_functions`
4. `o04_structs_not_classes`
5. `o05_enums_and_switches`
6. `o06_arrays_slices_dynamic`
7. `o07_pointers_and_refs`
8. `o08_memory_without_gc`
9. `o09_context_system`
10. `o10_imports_and_packages`
11. `o11_error_handling`
12. `o12_for_loops_and_iteration`
13. `o13_strings_and_cstrings`
14. `o14_defer_and_cleanup`
15. `o15_reading_compiler_errors`
16. `o16_debugging_and_printing`

## How To Use

1. Read `LESSON.md` in each folder
2. Only look at specific solution lines the lesson tells you to read
3. Close the solution
4. Write your own `main.odin` in the lesson folder
5. Run with `zsh build.sh`
6. Do not move on until exit criteria are met

## Solutions

Runnable references live in:
- `learn/95_solutions/odin_for_js_devs/`

## After This Track

When you finish o16, move to:
- `learn/20_game_thinking_for_web_devs/` (coming soon)
- Then `learn/30_fundamentals/t01_hello_window`
