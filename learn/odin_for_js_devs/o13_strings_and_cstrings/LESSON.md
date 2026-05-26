# O13 — Strings And CStrings

## Goal

Understand what strings really are in Odin, why there are two string
types, and how this differs from the JavaScript string you are used to.

---

## If You Know JS/TS...

JavaScript strings are magical:

```js
const s = "Hello, world!";
s.length;           // 13
s.toUpperCase();    // "HELLO, WORLD!"
s.slice(0, 5);      // "Hello"
s.includes("world"); // true
`Score: ${42}`;     // template literal
s + " More text";   // concatenation
```

JS strings are:
- Immutable (you cannot change individual characters)
- UTF-16 encoded internally
- Objects with dozens of built-in methods
- Garbage collected
- Concatenation creates new strings on the heap

You never think about encoding, memory layout, or ownership.

---

## How Odin Does It

### `string` — Odin's main string type

```odin
s := "Hello, world!"
```

Internally, an Odin string is:
```odin
// Simplified — this is the actual layout
string :: struct {
    data: ^u8,     // pointer to the first byte
    len:  int,     // number of bytes
}
```

That is it. Two fields. 16 bytes on 64-bit systems.

A string is a **slice of bytes.** It does not own the data — it points
to it. String literals point to read-only memory baked into the binary.

Key differences from JS:
- No methods (no `.toUpperCase()`, no `.slice()`)
- No garbage collection (string data must live somewhere valid)
- UTF-8 encoded (not UTF-16)
- Not null-terminated (length is stored, no trailing `\0`)
- Immutable content (you cannot change bytes through a string)

### `cstring` — for C interoperability

```odin
cs: cstring = "Hello from C"
```

A `cstring` is a null-terminated string — it ends with a `\0` byte.
This is what C libraries (like Sokol, FMOD, stb) expect.

You will see `cstring` in Sokol bindings:
```odin
window_title = "My Game",   // Odin string literal auto-converts to cstring
```

Most of the time, string literals work as both `string` and `cstring`.
But when you build strings dynamically, you may need explicit conversion.

### String operations use `core:strings` and `core:fmt`

```odin
import "core:strings"
import "core:fmt"

upper := strings.to_upper("hello")
has := strings.contains("game dev", "game")
label := fmt.tprintf("Score: %d", 42)
```

No method syntax. Standalone procedures from imported packages.

---

## Deep Dive

### Why two string types?

Odin strings are length-prefixed: `{pointer, length}`.
C strings are null-terminated: data ends with `\0`.

These are different trade-offs:

| Feature | Odin `string` | C `cstring` |
|---------|--------------|-------------|
| Know length | O(1) via `.len` | O(n) must scan for `\0` |
| Can contain `\0` | Yes | No (it would end the string) |
| Memory overhead | 16 bytes header | 1 extra byte for `\0` |
| C library compatible | No | Yes |

Games use both because:
- Odin code uses `string` (safe, known length, fast)
- C libraries (Sokol, FMOD) expect `cstring` (null-terminated)

### No string interpolation

JS:
```js
const label = `HP: ${health}/${maxHealth}`;
```

Odin has no template literals. Use `fmt.tprintf`:
```odin
label := fmt.tprintf("HP: %d/%d", health, max_health)
```

`fmt.tprintf` uses the temp allocator — the result is valid until
the frame ends. For permanent strings, use `fmt.aprintf` (which
allocates on the heap — you must free it).

### No string concatenation with `+`

JS:
```js
const full = first + " " + last;
```

Odin:
```odin
full := strings.concatenate({first, " ", last})
// or
full := fmt.tprintf("%s %s", first, last)
```

The `+` operator does not work on strings. This prevents accidental
heap allocations from casual concatenation.

### Iterating over strings

```odin
for ch in "Hello" {
    fmt.println(ch)   // ch is a rune (Unicode code point)
}

for b, i in "Hello" {
    fmt.println(i, b) // b is a rune, i is byte offset
}
```

`rune` in Odin = one Unicode code point (like `char` in some languages).
This handles multi-byte UTF-8 correctly.

### String comparison

```odin
a := "hello"
b := "hello"
if a == b {
    fmt.println("equal")
}
```

String `==` compares content, not identity. Same behavior as JS `===`
for strings.

---

## Line-by-Line: Solution Reference

Open:
- `learn/solutions/odin_for_js_devs/o13_strings_and_cstrings/main.odin`

Line refs:
- basic string usage: lines 6-14
- string operations: lines 16-26
- cstring: lines 28-35
- iteration: lines 37-45
- formatting: lines 47-55
- main: lines 57-end

---

## What Would Break If...

### You tried `s + " world"` (concatenation with +)?
```
Error: Operator '+' not defined for string
```
Use `strings.concatenate` or `fmt.tprintf`.

### You passed an Odin `string` where a C API expects `cstring`?
Might compile with auto-conversion for literals, but dynamically built
strings need explicit `strings.clone_to_cstring` or use `fmt.ctprintf`.

### You used a `tprintf` string after the frame reset?
Dangling pointer. The temp allocator wiped it. The string now contains
garbage data. Only use `tprintf` strings within the current frame.

### You tried `s.length`?
```
Error: string has no field 'length'
```
Use `len(s)`.

---

## Common JS-Developer Mistakes

1. **Expecting string methods.**
   No `.toUpperCase()`, `.slice()`, `.includes()`. Use `core:strings`.

2. **Concatenating with `+`.**
   Does not work. Use `fmt.tprintf` or `strings.concatenate`.

3. **Expecting template literals.**
   No backtick strings. Use `fmt.tprintf("HP: %d", health)`.

4. **Not understanding temp allocator lifetime.**
   `fmt.tprintf` result is only valid until frame ends.

5. **Confusing `string` and `cstring`.**
   Both are string-like but have different memory layout.
   Sokol APIs take `cstring`. Most Odin code uses `string`.

---

## Mental Model

**JS string** = a magical gift-wrapped box. It has methods, it resizes
itself, it cleans itself up. You never see what is inside.

**Odin string** = a piece of paper with an address and a page count.
The address says where the text lives. The page count says how long
it is. The paper does not own the text — it just knows where it is.

**cstring** = same text but with a period at the end (the `\0`). C
libraries need that period to know where the text stops.

---

## Exercises

### Exercise 1 — Basic String
Create a string variable. Print it. Print its length with `len()`.

### Exercise 2 — String Operations
Import `core:strings`. Use `strings.to_upper`, `strings.contains`, and
`strings.has_prefix` on a test string. Print each result.

### Exercise 3 — Formatted String
Use `fmt.tprintf` to build "Player at (%.1f, %.1f)" with two f32 values.
Print it. Write a comment about when this string becomes invalid.

### Exercise 4 — Iterate Characters
Loop over "Odin" using `for ch in "Odin"`. Print each character.

---

## Exit Criteria

- [ ] You understand string = `{pointer, length}`
- [ ] You can use `len(s)` instead of `.length`
- [ ] You can use `core:strings` functions
- [ ] You can use `fmt.tprintf` for formatted strings
- [ ] You understand `cstring` vs `string`
- [ ] You know `tprintf` strings are temp-allocated

---

## Why This Matters For Game Dev

Strings in games:
- Level names, file paths, debug labels, UI text
- Sokol window title = `cstring`
- FMOD event names = `cstring`
- Debug prints = `fmt.tprintf` (temp allocated, fast)

Understanding string memory means you will not accidentally use freed
strings or leak string memory in your game loop.

---

## Next Lesson

`learn/odin_for_js_devs/o14_defer_and_cleanup`
