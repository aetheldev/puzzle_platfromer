package o13_strings_and_cstrings

import "core:fmt"
import "core:strings"

main :: proc() {
	// === 1. Basic string ===
	fmt.println("=== Basic String ===")
	greeting := "Hello, Odin!"
	fmt.println("  string:", greeting)
	fmt.println("  length:", len(greeting))
	// string is {pointer, length}. No .length property — use len().

	// === 2. String operations via core:strings ===
	fmt.println("\n=== String Operations ===")
	upper := strings.to_upper("hello game dev")
	fmt.println("  to_upper:", upper)

	has := strings.contains("puzzle platformer", "puzzle")
	fmt.println("  contains 'puzzle':", has)

	prefix := strings.has_prefix("res/levels/level_01.txt", "res/")
	fmt.println("  has_prefix 'res/':", prefix)

	// === 3. cstring for C libraries ===
	fmt.println("\n=== CString ===")
	// String literals auto-convert to cstring in most contexts.
	// Sokol window_title, FMOD event names, etc. expect cstring.
	title: cstring = "My Game Window"
	fmt.println("  cstring:", title)
	fmt.println("  cstring is null-terminated for C compatibility")

	// === 4. Formatted strings (temp allocated) ===
	fmt.println("\n=== Formatted Strings ===")
	score := 42
	health : f32 = 75.5
	label := fmt.tprintf("Score: %d  HP: %.1f", score, health)
	fmt.println("  tprintf:", label)
	fmt.println("  ^^^ temp allocated. Valid this frame only in game code.")

	// === 5. Iterate characters ===
	fmt.println("\n=== Iterate Characters ===")
	fmt.print("  chars of 'Odin': ")
	for ch in "Odin" {
		fmt.printf("'%c' ", ch)
	}
	fmt.println()

	// With byte index
	fmt.println("  with byte index:")
	for ch, i in "Hello" {
		fmt.printf("    [%d] '%c'\n", i, ch)
	}

	// === 6. No + concatenation ===
	fmt.println("\n=== Concatenation ===")
	first := "Game"
	second := "Dev"
	// full := first + second  ← ERROR: + not defined for string
	full := fmt.tprintf("%s %s", first, second)
	fmt.println("  concatenated:", full)

	full2, _ := strings.concatenate({first, " ", second})
	fmt.println("  strings.concatenate:", full2)

	// === Key takeaways ===
	fmt.println("\n--- Takeaways ---")
	fmt.println("  string = {pointer, length}. No methods.")
	fmt.println("  cstring = null-terminated for C APIs.")
	fmt.println("  len(s) not s.length")
	fmt.println("  core:strings for operations.")
	fmt.println("  fmt.tprintf for formatting (temp allocated).")
	fmt.println("  No + for concatenation. No template literals.")
}
