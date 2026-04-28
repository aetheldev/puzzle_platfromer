/*

Build script.

Note: doesn't make sense to abstract this away for re-use.
There's too many project-specific settings here, so it's not worth the effort.

*/

#+feature dynamic-literals
#+feature using-stmt
package build

import path "core:path/filepath"
import "core:fmt"
import "core:os"
import "core:strings"
import "core:log"
import "core:reflect"
import "core:time"

// we are assuming we're right next to the bald collection
import logger "../utils/logger"
import utils "../utils"

EXE_NAME :: "game"

Target :: enum {
	windows,
	mac,
	linux,
}

Game_Kind :: enum {
	full,
	demo,
	playtest,
}

main :: proc() {
	context.logger = logger.logger()
	context.assertion_failure_proc = logger.assertion_failure_proc

	game_kind:= Game_Kind.full
	regen_shaders := true

	release, debug : bool
	for arg in os.args {
		switch arg {
			case "release": release = true
			case "debug": debug = true
			case "playtest": game_kind = .playtest
			case "demo": game_kind = .demo
			case "regen_shaders": regen_shaders = true
			case "skip_shader_regen": regen_shaders = false
		}
	}

	start_time := time.now()

	// note, ODIN_OS is built in, but we're being explicit
	assert(ODIN_OS == .Windows || ODIN_OS == .Darwin || ODIN_OS == .Linux, "unsupported OS target")

	target: Target
	#partial switch ODIN_OS {
	case .Windows:
		target = .windows
	case .Darwin:
		target = .mac
	case .Linux:
		target = .linux
	case:
		{
			log.error("Unsupported os:", ODIN_OS)
			return
		}
	}
	fmt.println("Building for", target)

	// gen the generated.odin
	{
		file := "sauce/generated.odin"

		f, err := os.open(file, os.O_WRONLY | os.O_CREATE | os.O_TRUNC)
		if err != nil {
			fmt.eprintln("Error:", err)
		}
		defer os.close(f)

		using fmt
		fprintln(f, "//")
		fprintln(f, "// MACHINE GENERATED via build.odin")
		fprintln(f, "// do not edit by hand!")
		fprintln(f, "//")
		fprintln(f, "")
		fprintln(f, "package main")
		fprintln(f, "")
		fprintln(f, "Platform :: enum {")
		fprintln(f, "	windows,")
		fprintln(f, "	mac,")
		fprintln(f, "	linux,")
		fprintln(f, "}")
		fprintln(f, tprintf("PLATFORM :: Platform.%v", target))
		fprintln(f, "")
		fprintln(f, "Game_Kind :: enum {")
		fprintln(f, "	full,")
		fprintln(f, "	demo,")
		fprintln(f, "	playtest,")
		fprintln(f, "}")
		fprintln(f, tprintf("GAME_KIND :: Game_Kind.%v", game_kind))
	}

	// Shader regeneration is opt-in because the checked-in sokol/gfx bindings are
	// older than the local shdc output format on current toolchains.
	if regen_shaders {
		shader_backend: string
		shdc_dir: string
		switch target {
		case .windows:
			shdc_dir = "sokol-shdc-win.exe"
			shader_backend = "hlsl5"
		case .mac:
			shdc_dir = "sokol-shdc-mac"
			shader_backend = "metal_macos"
		case .linux:
			shdc_dir = "sokol-shdc-linux"
			shader_backend = "glsl430"
		}

		utils.fire(
			shdc_dir,
			"-i",
			"sauce/shader.glsl",
			"-o",
			"sauce/generated_shader.odin",
			"-l",
			shader_backend,
			"-f",
			"sokol_odin",
		)

		// Current local sokol-shdc outputs slightly newer Odin code than the
		// checked-in sokol/gfx bindings use. Normalize generated names/layout hints
		// back to the binding format used by this repo.
		shader_file := "sauce/generated_shader.odin"
		shader_bytes, shader_read_err := os.read_entire_file_from_path(shader_file, context.temp_allocator)
		if shader_read_err != nil {
			log.error(shader_read_err)
			return
		}
		shader_text := string(shader_bytes)
		shader_text, _ = strings.replace_all(shader_text, "desc.views[", "desc.images[", context.temp_allocator)
		shader_text, _ = strings.replace_all(shader_text, ".texture.", ".", context.temp_allocator)
		shader_text, _ = strings.replace_all(shader_text, "desc.texture_sampler_pairs[", "desc.image_sampler_pairs[", context.temp_allocator)
		shader_text, _ = strings.replace_all(shader_text, ".view_slot =", ".image_slot =", context.temp_allocator)
		for i in 0..<16 {
			line := fmt.tprintf("        desc.attrs[%v].base_type = .FLOAT\n", i)
			shader_text, _ = strings.replace_all(shader_text, line, "", context.temp_allocator)
			line = fmt.tprintf("        desc.attrs[%v].base_type = .INT\n", i)
			shader_text, _ = strings.replace_all(shader_text, line, "", context.temp_allocator)
			line = fmt.tprintf("        desc.attrs[%v].base_type = .UINT\n", i)
			shader_text, _ = strings.replace_all(shader_text, line, "", context.temp_allocator)
		}
		shader_write_err := os.write_entire_file(shader_file, shader_text)
		if shader_write_err != nil {
			log.error(shader_write_err)
			return
		}
	}

	wd, wd_err := os.get_working_directory(context.temp_allocator)
	if wd_err != nil {
		log.error(wd_err)
		return
	}

	//utils.make_directory_if_not_exist("build")

	out_dir: string
	switch target {
		case .windows: out_dir = "build/windows_%v"
		case .mac: out_dir = "build/mac_%v"
		case .linux: out_dir = "build/linux_%v"
	}
	out_dir = fmt.tprintf(out_dir, release ? "release" : "debug")
	// on the end here, extra flags for playtest and whatnot ?

	// delete the build folder if it's release mode, that way we clean shit up
	if release {
		err := os.remove_all(out_dir)
		if err != nil {
			log.error(err)
			return
		}
	}

	full_out_dir_path, join_err := path.join({wd, out_dir}, context.temp_allocator)
	if join_err != nil {
		log.error(join_err)
		return
	}
	log.info(full_out_dir_path)
	utils.make_directory_if_not_exist(full_out_dir_path)

	// build command
	{
		out_name := EXE_NAME
		when ODIN_OS == .Windows {
			out_name = EXE_NAME + ".exe"
		}
		c: [dynamic]string = {
			"odin",
			"build",
			"sauce",
			fmt.tprintf("-out:%v/%v", out_dir, out_name),
		}
		if debug || !release {
			append(&c, "-debug")
			// append(&c, "-o:speed")
		}
		if release {
			append(&c, fmt.tprintf("-define:RELEASE=%v", release))
			append(&c, "-o:speed")
		}
		// not needed, it's easier to just generate code into generated.odin
		utils.fire(..c[:])
	}

	// copy stuff into folder
	{
		// NOTE, if it already exists, it won't copy (to save build time)
		files_to_copy: [dynamic]string

		switch target {
		case .windows:
			append(&files_to_copy, "sauce/fmod/studio/lib/windows/x64/fmodstudio.dll")
			append(&files_to_copy, "sauce/fmod/studio/lib/windows/x64/fmodstudioL.dll")
			append(&files_to_copy, "sauce/fmod/core/lib/windows/x64/fmod.dll")
			append(&files_to_copy, "sauce/fmod/core/lib/windows/x64/fmodL.dll")

		case .mac:
			append(&files_to_copy, "sauce/fmod/studio/lib/darwin/libfmodstudio.dylib")
			append(&files_to_copy, "sauce/fmod/studio/lib/darwin/libfmodstudioL.dylib")
			append(&files_to_copy, "sauce/fmod/core/lib/darwin/libfmod.dylib")
			append(&files_to_copy, "sauce/fmod/core/lib/darwin/libfmodL.dylib")
		case .linux:
		//TODO: linux fmod support
		}

		for src in files_to_copy {
			dir, file_name := path.split(src)
			//assert(os.exists(dir), fmt.tprint("directory doesn't exist:", dir, file_name))
			dest := fmt.tprintf("%v/%v", out_dir, file_name)
			if !os.exists(dest) {
				os.copy_file(dest, src)
			}
		}
	}

	// copy res folder so the game can run from the build output directory in both
	// debug and release configurations.
	utils.copy_directory(fmt.tprintf("%v/res", out_dir), "res")

	fmt.println("DONE in", time.diff(start_time, time.now()))
}


// value extraction example:
/*
target: Target
found: bool
for arg in os2.args {
	if strings.starts_with(arg, "target:") {
		target_string := strings.trim_left(arg, "target:")
		value, ok := reflect.enum_from_name(Target, target_string)
		if ok {
			target = value
			found = true
			break
		} else {
			log.error("Unsupported target:", target_string)
		}
	}
}
*/
