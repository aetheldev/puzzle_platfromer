package o10_imports_and_packages

import "core:fmt"
import "core:math"
import "core:strings"
// import "core:os"

main :: proc() {
	fmt.println("sqrt", math.sqrt(f64(1.4)))
	fmt.println("upper", strings.to_upper("upper"))
}

