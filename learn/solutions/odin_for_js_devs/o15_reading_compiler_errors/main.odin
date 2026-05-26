package o15_reading_compiler_errors

import "core:fmt"

main :: proc() {
	fmt.println("=== Common Odin Compiler Errors Reference ===")
	fmt.println()

	fmt.println("1. Undeclared name")
	fmt.println("   Cause: typo, missing import, wrong scope")
	fmt.println("   Fix: check spelling, add import")
	fmt.println()

	fmt.println("2. Mismatched types: f32 vs i32")
	fmt.println("   Cause: mixing numeric types without cast")
	fmt.println("   Fix: f32(my_int) or i32(my_float)")
	fmt.println()

	fmt.println("3. Assignment count mismatch '2' = '1'")
	fmt.println("   Cause: proc returns 2 values, you captured 1")
	fmt.println("   Fix: result, err := proc_call()")
	fmt.println()

	fmt.println("4. Unused variable")
	fmt.println("   Cause: declared but never used")
	fmt.println("   Fix: use it, remove it, or _ = x")
	fmt.println()

	fmt.println("5. Unused import")
	fmt.println("   Cause: imported but never referenced")
	fmt.println("   Fix: remove the import line")
	fmt.println()

	fmt.println("6. Cannot convert Player to ^Player")
	fmt.println("   Cause: passing value where pointer expected")
	fmt.println("   Fix: add & — do_thing(&player)")
	fmt.println()

	fmt.println("7. Expected ':' or ':=' after identifier")
	fmt.println("   Cause: used JS keyword (function, let, const)")
	fmt.println("   Fix: use proc, :=, ::")
	fmt.println()

	fmt.println("8. Unhandled switch cases")
	fmt.println("   Cause: non-exhaustive switch on enum")
	fmt.println("   Fix: add missing cases or #partial switch")
	fmt.println()

	fmt.println("9. Parameter must have a type")
	fmt.println("   Cause: proc(a, b) without types")
	fmt.println("   Fix: proc(a, b: f32)")
	fmt.println()

	fmt.println("10. Index out of bounds (runtime)")
	fmt.println("    Cause: array[N] where N >= len")
	fmt.println("    Fix: check bounds before access")
	fmt.println()

	fmt.println("--- Strategy ---")
	fmt.println("1. Fix FIRST error only. Recompile.")
	fmt.println("2. Read file:line:col — go directly there.")
	fmt.println("3. Read ^~~~^ pointer — shows exact token.")
	fmt.println("4. Trust 'Did you mean?' suggestions.")
	fmt.println("5. Later errors often vanish after fixing first.")
}
