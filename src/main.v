module main

import os
import gg
import gx
import time

struct Emulator {
pub mut:
	chip8   Chip8
	graphic &gg.Context = unsafe { nil }
}

fn (mut emulator Emulator) draw_block(i f32, j f32) {
	emulator.graphic.draw_rect_filled(j, i, f32(20), f32(20), gx.rgb(0, 255, 0))
}

fn (mut emulator Emulator) load_rom() ! {
	if os.args.len <= 1 {
		return error('ROM path not especified!')
	}
	mut file := os.open(os.args[1])!
	defer { file.close() }
	println('Loading ROM in the memory...')
	mut instructions := file.read_bytes(1024)
	mut index := u16(0x200)
	emulator.chip8.set_ram(instructions, index)
	println('ROM successfully loaded into memory!')
}

fn frame(mut emulator Emulator) {
	emulator.graphic.begin()
	for y in 0 .. emulator.chip8.screen.display_height {
		for x in 0 .. emulator.chip8.screen.display_width {
			pixel := emulator.chip8.screen.display[y][x]
			if pixel == 1 {
				emulator.draw_block(f32(y * 20), f32(x * 20))
			}
		}
	}
	emulator.graphic.end()
}

fn (mut emulator Emulator) run(ms_per_tick int) {
	for {
		emulator.chip8.run()
		emulator.chip8.cycles++
		emulator.chip8.update_timers()
		if emulator.chip8.cpu_clock == emulator.chip8.cycles {
			emulator.chip8.cycles = 0
		}
		time.sleep(ms_per_tick * time.millisecond)
	}
}

fn on_event(e &gg.Event, mut emulator Emulator) {
	if e.typ == .key_down {
		x := int(e.key_code)
		// eprintln('>>> e.typ: ${e.typ} | e.key_code: ${e.key_code} | x: ${x} | x.hex(): ${x.hex()}')
		emulator.chip8.set_key(x)
	}
	if e.typ == .key_up {
		emulator.chip8.set_key(0)
	}
}

fn main() {
	mut emulator := &Emulator{
		chip8: Chip8{}
	}
	emulator.load_rom()!
	emulator.chip8.start_cpu()
	emulator.graphic = gg.new_context(
		bg_color:     gx.rgb(0, 0, 0)
		width:        1280
		height:       640
		window_title: 'V CHIP-8 Emulator'
		user_data:    emulator
		frame_fn:     frame
		event_fn:     on_event
	)
	// Ensure a constant rate of updates to the emulator, no matter
	// what the refresh rate is, by running the updates in a separate
	// independent thread:
	spawn emulator.run(8)
	emulator.graphic.run()
}
