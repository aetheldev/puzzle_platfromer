package o10_imports_and_packages

import "core:fmt"
import "core:math"
import "core:strings"

main :: proc() {
	// === Using core:fmt ===
	fmt.println("=== core:fmt ===")
	fmt.println("  Hello from fmt.println")
	name := "developer"
	fmt.printf("  Formatted: Welcome, %s!\n", name)
	label := fmt.tprintf("Score: %d", 42)
	fmt.println("  tprintf result:", label)

	// === Using core:strings ===
	fmt.println("\n=== core:strings ===")
	upper := strings.to_upper("hello odin")
	fmt.println("  to_upper:", upper)
	has := strings.contains("game developer", "game")
	fmt.println("  contains 'game':", has)

	// === Using core:math ===
	fmt.println("\n=== core:math ===")
	val := math.sqrt(f64(144))
	fmt.println("  sqrt(144):", val)
	pi := math.PI
	fmt.println("  PI:", pi)

	// === Package = directory ===
	fmt.println("\n=== Package Rules ===")
	fmt.println("  1. Package name = directory name")
	fmt.println("  2. All .odin files in same dir = same package")
	fmt.println("  3. No import needed between files in same package")
	fmt.println("  4. Unused imports = compiler error")
	fmt.println("  5. No npm. No node_modules. Vendor your deps.")

	// === Collection flag ===
	fmt.println("\n=== Collection Flag ===")
	fmt.println("  odin run . -collection:sokol=../../sauce/sokol")
	fmt.println("  Means: 'sokol' collection lives at ../../sauce/sokol")
	fmt.println("  So import \"sokol/gfx\" finds ../../sauce/sokol/gfx")

	// === Import alias ===
	fmt.println("\n=== Import Alias ===")
	fmt.println("  import sg \"sokol/gfx\"")
	fmt.println("  Now use sg.setup(), sg.make_image(), etc.")
	fmt.println("  Alias keeps code short when package name is long.")

	fmt.println("\n--- Takeaways ---")
	fmt.println("  import \"core:fmt\"      standard library")
	fmt.println("  import sg \"sokol/gfx\"  aliased collection package")
	fmt.println("  package = directory. No export keyword by default.")
	fmt.println("  Unused imports error. Circular imports error.")
}
