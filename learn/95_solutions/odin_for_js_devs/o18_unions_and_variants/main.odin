package o18_unions_and_variants

import "core:fmt"

Damage_Event :: struct {
	amount: int,
	target: string,
}

Pickup_Event :: struct {
	item: string,
}

Level_Complete_Event :: struct {
	time_seconds: f32,
}

Game_Event :: union {
	Damage_Event,
	Pickup_Event,
	Level_Complete_Event,
}

handle :: proc(event: Game_Event) {
	switch e in event {
	case Damage_Event:
		fmt.println(" ", e.target, "takes", e.amount, "damage")
	case Pickup_Event:
		fmt.println("  picked up:", e.item)
	case Level_Complete_Event:
		fmt.println("  level done in", e.time_seconds, "seconds")
	case:
		// nil — union holds nothing
		fmt.println("  (empty event)")
	}
}

main :: proc() {
	// --- Create union values: assign a variant, tag is set automatically ---
	e1: Game_Event = Damage_Event{amount = 10, target = "player"}
	e2: Game_Event = Pickup_Event{item = "key"}
	fmt.println("printing a union shows its variant:", e1)

	// --- nil by default ---
	empty: Game_Event
	if empty == nil {
		fmt.println("unassigned union is nil")
	}
	handle(empty)

	// --- Event queue: flat dynamic array, no heap-per-event ---
	events: [dynamic]Game_Event
	defer delete(events)
	append(&events, e1)
	append(&events, e2)
	append(&events, Level_Complete_Event{time_seconds = 42.5})

	fmt.println("\nProcessing event queue:")
	for event in events {
		handle(event)
	}

	// --- Type assertion with ok ---
	if dmg, ok := e1.(Damage_Event); ok {
		fmt.println("\nassertion: damage amount =", dmg.amount)
	}
	_, is_pickup := e1.(Pickup_Event)
	fmt.println("e1 is Pickup_Event?", is_pickup)

	// --- Maybe(T): the built-in optional union ---
	target: Maybe(int) // nil = no target
	if _, ok := target.?; !ok {
		fmt.println("\nno target selected")
	}
	target = 42
	if id, ok := target.?; ok {
		fmt.println("targeting entity", id)
	}

	// --- Memory: biggest variant + tag, no heap ---
	fmt.println("\n--- Memory ---")
	fmt.println("size_of(Damage_Event):", size_of(Damage_Event))
	fmt.println("size_of(Pickup_Event):", size_of(Pickup_Event))
	fmt.println("size_of(Game_Event):  ", size_of(Game_Event), "(biggest variant + tag)")

	fmt.println("\n--- Takeaways ---")
	fmt.println("Union = one of N types + runtime tag. No inheritance.")
	fmt.println("switch e in event = exhaustive, compiler-checked.")
	fmt.println("v, ok := e.(T) = safe assertion. Bare .(T) panics.")
	fmt.println("Flat arrays of unions = idiomatic event queues.")
}
