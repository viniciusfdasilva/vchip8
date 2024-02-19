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
	emulator.graphic.draw_rect_filled(f32((j - 1) * 20) + 14, f32((i - 1) * 20), f32(20 - 1), f32(20 - 1), gx.rgb(255,255,255))
}

fn (mut emulator Emulator) load_rom() !{

	arguments := os.args.clone()

	if arguments.len > 1 {
		
		mut file := os.open(arguments[1])!
		defer { file.close() }
		
		println(' Loading ROM in the memory...\n')
		load_animate()
		
		mut instructions := file.read_bytes_at(1024, 0)
		mut index := 0x200
		emulator.chip8.set_ram(instructions, index)

		println('ROM successfully loaded into memory!')

	}else{
		panic('ROM path not especified!')
	}
}

fn draw_screen(mut emulator Emulator){
	
	display_height := emulator.chip8.screen.display_height
	display_width  := emulator.chip8.screen.display_width

	for y := 0; y < display_height; y++ {
		for x := 0; x < display_width; x++ {

			pixel := emulator.chip8.screen.display[y][x]

			if pixel == 1 {
				emulator.draw_block(f32(y*10), f32(x*10))
			}
		}
	}
}

fn (mut emulator Emulator) show_display(){
	emulator.graphic.run()
}

//fn (emulator Emulator) keyboard(input string) !string{
//
//	match input {
//		'1' {
//			return 0x0001
//		},
//
//		'2' {
//
//		},
//
//		'3' {
//
//		},
//
//		'4' {
//
//		},
//
//		'Q', 'q' {
//
//		},
//
//		'W', 'w' {
//
//		},
//
//		'E', 'e' {
//
//		},
//
//		'R', 'r' {
//
//		},
//
//		'A', 'a' {
//
//		},
//
//		'S', 's' {
//
//		},
//
//		'D', 'd' {
//
//		},
//
//		'F', 'f' {
//
//		},
//
//		'Z', 'z' {
//
//		},
//
//		'X', 'x' {
//
//		},
//
//		'C', 'c' {
//
//		},
//
//		'V', 'v' {
//
//		},
//
//		else {
//			panic('Invalid key!')
//		}
//	}
//	
//}

fn is_graphic() bool{
	return os.environ()['DISPLAY'] != ''
}

fn frame(){
	print('oi')
}

fn main() {

	mut emulator := &Emulator{
		chip8 : Chip8{}
	}

	if emulator.is_graphic {

		emulator.load_rom()!
		emulator.chip8.start_cpu()
		emulator.chip8.run()
		print('oi')
		emulator.graphic = gg.new_context(
								bg_color: gx.rgb(0, 0, 0)
								width: 1280
								height: 640
								window_title: 'V CHIP-8 Emulator'
								frame_fn : draw_screen
								user_data: emulator
							)
		//emulator.show_display()
	}else{
		panic('System is not graphic!')
	}
}
