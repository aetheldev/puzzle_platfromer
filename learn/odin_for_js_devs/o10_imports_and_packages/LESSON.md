# O10 — Imports And Packages

## Goal

Understand how Odin organizes code into packages, how imports work,
and why there is no npm, no node_modules, and no package.json.

---

## If You Know JS/TS...

JavaScript has a rich module ecosystem:

```js
// Named import
import { useState } from "react";

// Default import
import express from "express";

// Relative import
import { helper } from "./utils/helper";

// Dynamic import
const module = await import("./lazy-module.js");
```

And a package manager:
```sh
npm install react
# Creates node_modules/react/
# Adds to package.json
```

You install dependencies. A tool downloads them. `node_modules` can
grow to hundreds of megabytes. Version conflicts happen. Lock files
exist to prevent drift.

**Odin has none of this.** No npm. No package manager. No `node_modules`.
No `package.json`. No lock files.

---

## How Odin Does It

### Package = directory

Every directory with `.odin` files is a package. The directory name
IS the package name.

```
my_game/
  main.odin         ← package my_game
  player.odin       ← also package my_game (same directory)
  utils/
    helpers.odin    ← package utils (different directory)
```

All `.odin` files in the same directory share one package. They can
see each other's declarations without importing. This is like having
all functions in one JS file, but split across physical files.

### Import syntax

```odin
// Standard library
import "core:fmt"          // fmt.println, fmt.printf, etc.
import "core:math"         // math.sqrt, math.sin, etc.
import "core:os"           // os.read_entire_file, etc.

// Import with alias
import sg "sokol/gfx"      // sg.setup, sg.make_image, etc.

// Base library (runtime)
import "base:runtime"      // runtime.Context, etc.
```

### Collection paths

Odin uses "collections" to find packages:

- `"core:fmt"` → look in Odin's standard library
- `"base:runtime"` → look in Odin's base library
- `"sokol/gfx"` → look in a custom collection (specified at build time)

Build command:
```sh
odin run . -collection:sokol=../../sauce/sokol
```

This says: "when code writes `import "sokol/gfx"`, find it at
`../../sauce/sokol/gfx`."

### No circular imports

```
package A imports package B
package B imports package A  ← ERROR: circular dependency
```

Odin forbids circular imports. If A needs B and B needs A, you must
restructure. This forces cleaner dependency graphs than JS allows.

---

## Deep Dive

### Why no package manager?

Odin's philosophy: dependencies should be vendored (copied into your
project) and managed manually.

Pros:
- No version conflicts.
- No "left-pad" incidents (dependency disappearing from registry).
- You can read and modify your dependencies.
- Builds are reproducible without lock files.
- No `node_modules` folder.

Cons:
- You update dependencies manually.
- Discovering packages is less convenient.

For game dev, this is usually fine because:
- You have few external dependencies (Sokol, FMOD, maybe stb libraries).
- You vendor them once and they rarely change.
- Your game code is the main thing you write, not library glue.

### Standard library structure

```
core:           ← standard library
  core:fmt      ← formatting and printing
  core:math     ← math functions
  core:os       ← file I/O, process, path
  core:strings  ← string manipulation
  core:mem      ← memory utilities
  core:slice    ← slice utilities
  core:log      ← logging

base:           ← runtime basics
  base:runtime  ← Context, allocators, trap

vendor:         ← vendored third-party bindings
  vendor:stb    ← stb libraries (image, truetype, etc.)
```

### Multi-file packages

In this repo:

```
sauce/
  game.odin              ← package main
  entity.odin            ← package main (same package!)
  core_main.odin         ← package main
  core_render.odin       ← package main
```

All files in `sauce/` are `package main`. They can all see each other's
types, procs, and variables. No imports needed between them.

This is different from JS where every file is its own module with
explicit exports/imports.

### Visibility

Odin has no `export` or `public`/`private` keywords for procedures.
Everything inside a package is visible to everything else in that
same package.

For cross-package visibility: everything is public by default. You can
mark something `@(private)` or `@(private="file")` to restrict it:

```odin
// Visible to entire package (default)
helper :: proc() { ... }

// Only visible in this file
@(private="file")
internal_helper :: proc() { ... }
```

---

## Line-by-Line: Solution Reference

Open:
- `learn/solutions/odin_for_js_devs/o10_imports_and_packages/main.odin`

Line refs:
- imports: lines 1-5
- using standard library: lines 8-15
- string operations: lines 17-22
- math operations: lines 24-28
- main: lines 30-end

---

## What Would Break If...

### You imported a package you do not use?
```
Error: Unused import: "core:math"
```
Odin does not allow unused imports. This keeps code clean.
In JS, unused imports are warnings at best.

### You tried circular imports?
```
Error: Cyclic package dependency detected
```
Restructure so dependencies flow one direction.

### You wrote `import { println } from "core:fmt"`?
```
Error: Syntax error
```
Odin does not have destructured imports. You import the package and
use `fmt.println`. No cherry-picking individual names at import time.

### You forgot `-collection:sokol=...` in the build command?
```
Error: Package 'sokol/gfx' not found
```
Custom collections must be specified at build time.

---

## Common JS-Developer Mistakes

1. **Expecting `import { x } from ...` syntax.**
   Odin imports whole packages. Use `fmt.println`, not `println`.

2. **Looking for `package.json` or `npm install`.**
   Does not exist. Vendor your dependencies manually.

3. **Expecting each file to be its own module.**
   All files in one directory = one package. They share everything.

4. **Forgetting unused import rule.**
   Odin errors on unused imports. Remove what you do not use.

5. **Using relative paths like `"./utils"`.**
   Odin uses collection-based paths, not relative file paths for
   external packages. Within same package, no import needed at all.

---

## Mental Model

Think of packages like **departments in a building:**

- Everyone in the same department (directory) can talk to each other
  freely. No paperwork (import) needed.
- To talk to another department, you need a formal channel (import).
- The building directory (`core:`, `base:`, custom collections) tells
  you where departments are located.
- There is no outsourcing service (npm). If you need something from
  outside, you bring a copy into your building (vendor it).

---

## Exercises

### Exercise 1 — Multi-Import
Import `core:fmt`, `core:math`, and `core:strings`.
Use one function from each: `fmt.println`, `math.sqrt`, `strings.to_upper`.

### Exercise 2 — Unused Import
Add `import "core:os"` but do not use it. Try to compile.
Observe the error. Remove it.

### Exercise 3 — Explain This Repo
Look at `sauce/game.odin` and `sauce/entity.odin`.
They are both `package main`. Explain in a comment why they do not
need to import each other.

### Exercise 4 — Collection Flag
Write a comment explaining what this build command does:
```sh
odin run . -collection:sokol=../../sauce/sokol
```

---

## Exit Criteria

- [ ] You can import standard library packages
- [ ] You can use aliased imports (`import sg "sokol/gfx"`)
- [ ] You understand package = directory
- [ ] You understand multi-file packages share declarations
- [ ] You know there is no npm — dependencies are vendored
- [ ] You can explain the `-collection:` flag

---

## Why This Matters For Game Dev

Your game code lives in `sauce/` as one big `package main`. All game
files see each other. External dependencies (Sokol, FMOD) are vendored
in subdirectories. The build script specifies collection paths.

Understanding this means you know:
- Where to add new game files (same directory = same package)
- How to add new external libraries (vendor them, add collection flag)
- Why imports look the way they do in every lesson

---

## Next Lesson

`learn/odin_for_js_devs/o11_error_handling`
