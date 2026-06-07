# O01 — Your First Odin Program

## Goal

Write, compile, and run a program that prints text to the terminal.
Understand what every single line does and how it differs from JavaScript.

---

## If You Know JS/TS...

In JavaScript, your first program probably looked like this:

```js
// script.js
console.log("Hello, world!");
```

And you ran it with:

```sh
node script.js
```

There was no compile step. Node read your file, interpreted it, and ran it.
The file could be named anything. There was no special structure requirement.

In a React project, you might have:

```jsx
// App.jsx
export default function App() {
  return <h1>Hello, world!</h1>;
}
```

Here, the framework decides when your function runs.
You write a component, React calls it when it needs to render.

Keep both of these mental models in mind — Odin works differently from both.

---

## How Odin Does It

```odin
package o01_first_program

import "core:fmt"

main :: proc() {
    fmt.println("Hello from Odin!")
}
```

And you run it with:

```sh
odin run .
```

That is the complete program. Let us break down every single part.

---

## Deep Dive — Line By Line

### `package o01_first_program`

Every Odin file starts with a package declaration. This is not optional.

In JS, a file is just a file. You might use `export` and `import`, but
there is no required first line. In Odin, the very first line must declare
which package this file belongs to.

**Important rule:** the package name must match the directory name.
If your file lives in a folder called `o01_first_program`, the package
must be `package o01_first_program`.

Think of it like this:
- In JS, a "module" is one file.
- In Odin, a "package" is one directory. All `.odin` files in that
  directory share the same package and can see each other's declarations.

There is no `package.json`. There is no `node_modules`. The directory
structure IS the module system.

### `import "core:fmt"`

This imports the `fmt` (format) package from Odin's standard library.

In JS, this would be similar to:
```js
const fmt = require("core/fmt");
// or
import * as fmt from "core:fmt";
```

But there are key differences:
- `"core:fmt"` is a built-in collection. `core` means "standard library."
- There is no npm. There is no package manager. Standard library comes
  with the compiler.
- You reference packages by path, not by installing them.

The `fmt` package gives you printing functions:
- `fmt.println(...)` — print with newline (like `console.log`)
- `fmt.printf(...)` — formatted print (like `printf` in C)
- `fmt.tprintf(...)` — formatted print that returns a string

### `main :: proc() {`

This is where JS developers need to pay the most attention.

In JS, you would write:
```js
function main() { ... }
// or
const main = () => { ... }
```

In Odin:
```odin
main :: proc() { ... }
```

Let us break this apart:

- `main` — the name.
- `::` — this means "compile-time constant binding." It says "the name
  `main` is permanently bound to what follows." This is stronger than
  `const` in JS — it is resolved at compile time, not runtime.
- `proc()` — this declares a procedure (Odin's word for function).
  `proc()` means "a procedure that takes no parameters and returns nothing."
- `{ ... }` — the body.

**Why `::` and not `:=`?**

Odin has three assignment operators:
- `::` — compile-time constant. The value is fixed forever. Used for
  functions, types, and constants.
- `:=` — runtime variable declaration with type inference. Like `let` in
  JS but you cannot reassign without `=`.
- `=` — reassignment of an existing variable.

Examples:
```odin
PI :: 3.14159          // compile-time constant (like const PI = ... but stricter)
x := 42                // runtime variable, type inferred as int
x = 100                // reassign x
```

**Why `proc` and not `function`?**

Odin calls functions "procedures." This is just naming. The concept is
the same: a named block of code that can take inputs and produce outputs.
But Odin procedures have important differences from JS functions:
- No closures (cannot capture variables from outer scope)
- No `this`
- No method syntax
- Parameters must have explicit types

### `fmt.println("Hello from Odin!")`

This prints the string and adds a newline. It is the direct equivalent
of `console.log("Hello from Odin!")`.

Unlike JS, Odin strings use double quotes only. Single quotes are for
individual characters (runes), not strings.

### The closing `}`

Ends the procedure body. Same as JS.

---

## What Would Break If...

### You removed the package line?
```
Error: Expected a package declaration at the start of the file.
```
Every Odin file MUST start with `package name`. No exceptions.

### You wrote `function main()` instead of `main :: proc()`?
```
Error: Expected ':' or ':=' after identifier 'function'.
```
Odin does not have the `function` keyword. It uses `proc`.

### You wrote `console.log(...)` instead of `fmt.println(...)`?
```
Error: Undeclared name: console
```
There is no `console` in Odin. There is no browser. There is no runtime
object model. `fmt.println` writes directly to stdout.

### You forgot `import "core:fmt"`?
```
Error: Undeclared name: fmt
```
Unlike JS where some globals exist automatically (`console`, `Math`,
`JSON`), Odin has almost no implicit imports. You must import everything
you use.

### You named the package differently from the folder?
```
Error: Package name mismatch.
```
If the folder is `o01_first_program`, the package must be
`o01_first_program`. Not `main`, not `hello`, not `my_program`.

Exception: when you want a standalone executable, some projects use
`package main`. But for learning, match the folder name.

---

## Common JS-Developer Mistakes

1. **Writing `let` or `const` instead of `:=` or `::`.**
   Odin does not have `let`, `const`, or `var`. Use `:=` for variables,
   `::` for constants.

2. **Expecting string interpolation like `` `Hello, ${name}` ``.**
   Odin has no template literals. Use `fmt.printf("Hello, %s\n", name)`
   or `fmt.tprintf("Hello, %s", name)` to build formatted strings.

3. **Expecting the program to run without compiling.**
   JS is interpreted (or JIT compiled invisibly). Odin compiles to a
   native binary first, then you run the binary. `odin run .` does both
   steps together for convenience.

4. **Creating a file outside the package directory.**
   In JS, you can import from anywhere. In Odin, a package is a
   directory. Files outside that directory are a different package.

5. **Using semicolons.**
   Odin does not use semicolons. Line endings are implicit statement
   terminators. If you add `;` it might work in some places but it is
   not idiomatic and can cause confusion.

---

## Mental Model

Think of an Odin program like a small factory:

- The **package** declaration is the factory name on the building.
- The **imports** are the supply trucks bringing in tools.
- The **main proc** is the assembly line — it runs from top to bottom,
  once, and then the factory closes.
- `odin run .` is pressing the "start" button on the factory.

In JS/React, your code often waits for events, re-renders, or runs
callbacks. In a basic Odin program, code runs top-to-bottom and exits.
(Later, when we add Sokol, the app loop will call your procedures
repeatedly — but the mental model of "code runs, then stops" is the
correct starting point.)

---

## Read The Solution

Open:
- `learn/95_solutions/odin_for_js_devs/o01_first_program/main.odin`

Read all of it — it is short.

Line refs:
- package + import: lines 1-3
- main proc: lines 5-17

After reading, close it.

---

## Exercises

### Exercise 1 — Hello World
Create your own `main.odin` in this folder.
Print "Hello from Odin!" to the terminal.
Run it with `zsh build.sh`.

### Exercise 2 — Print Your Name
Add a variable with your name. Print it using `fmt.printf`.
Example output: `My name is Mert`

### Exercise 3 — Simple Math
Create two number variables. Print their sum, difference, and product.
Example output:
```
10 + 3 = 13
10 - 3 = 7
10 * 3 = 30
```

### Exercise 4 — Multi-Line Output
Print 5 lines of text. Each line should say something different.
Try using both `fmt.println` and `fmt.printf`.

---

## Exit Criteria

- [x] Your program compiles and runs with `zsh build.sh`
- [x] You can explain what `package`, `import`, `::`, `proc`, and `fmt.println` do
- [x] You can change the printed text without breaking anything
- [x] You understand the difference between `::` and `:=` (even if you have not used `:=` yet)

---

## Why This Matters For Game Dev

Every game starts as a program. Before you can draw pixels or handle
input, you need to be able to write, compile, and run Odin code
confidently. This lesson is the absolute foundation.

Later, when you see `main :: proc()` in game code, you will know it is
just a procedure bound with `::`. When you see `import sg "sokol/gfx"`,
you will know it is an import with an alias. Nothing magical — just the
same building blocks you learned here.

---

## Next Lesson

`learn/10_odin_for_js_devs/o02_variables_and_types`
