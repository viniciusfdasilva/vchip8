module main

import os
import gg
import gx

struct Emulator{

	pub mut:
		chip8      Chip8
		graphic    &gg.Context = unsafe { nil }
		is_graphic bool = is_graphic()
}

fn (mut emulator Emulator) draw_block(i f32, j f32) {
	emulator.graphic.draw_rect_filled(j,i, f32(20), f32(20), gx.rgb(0,255,0))
}

fn (mut emulator Emulator) load_rom() !{

	arguments := os.args.clone()

	if arguments.len > 1 {
		
		mut file := os.open(arguments[1])!
		defer { file.close() }
		
		println(' Loading ROM in the memory...\n')
		load_animate()
		
		mut instructions := file.read_bytes(1024)
		mut index := u16(0x200)
		emulator.chip8.set_ram(instructions, index)

		println('ROM successfully loaded into memory!')

	}else{
		panic('ROM path not especified!')
	}
}

fn frame(mut emulator Emulator){
	
	emulator.graphic.begin()

	emulator.chip8.run()
	emulator.chip8.cycles++;
	emulator.chip8.update_timers()
	
	display_height := emulator.chip8.screen.display_height
	display_width  := emulator.chip8.screen.display_width
	
	for y := 0; y < display_height; y++ {
		for x := 0; x < display_width; x++ {

			pixel := emulator.chip8.screen.display[y][x]
			
			if pixel == 1 {
				emulator.draw_block(f32((y)*20), f32((x)*20))
			}
		}
	}

	if emulator.chip8.cpu_clock == emulator.chip8.cycles {
		emulator.chip8.cycles = 0
	}

	emulator.graphic.end()
}

fn (mut emulator Emulator) show_display(){
	emulator.graphic.run()
}

fn is_graphic() bool{
	return os.environ()['DISPLAY'] != ''
}

fn main() {

	mut emulator := &Emulator{
		chip8 : Chip8{}
	}

	if emulator.is_graphic {

		emulator.load_rom()!
		emulator.chip8.start_cpu()

		emulator.graphic = gg.new_context(
									bg_color: gx.rgb(0, 0, 0)
									width: 1280
									height: 640
									window_title: 'V CHIP-8 Emulator'
									user_data: emulator
									frame_fn : frame
									event_fn: on_event
								)

		emulator.show_display()

	}else{
		panic('System is not graphic!')
	}
}

fn on_event(e &gg.Event, mut emulator Emulator){
	emulator.chip8.set_key(e.char_code)
}