

import rand

const font := [
	[u8(0xF0), u8(0x90), u8(0x90), u8(0x90), u8(0xF0)],  // 0
	[u8(0x20), u8(0x60), u8(0x20), u8(0x20), u8(0x70)], //  1
	[u8(0xF0), u8(0x10), u8(0xF0), u8(0x80), u8(0xF0)], //  2
	[u8(0xF0), u8(0x10), u8(0xF0), u8(0x10), u8(0xF0)], //  3
	[u8(0x90), u8(0x90), u8(0xF0), u8(0x10), u8(0x10)], //  4
	[u8(0xF0), u8(0x80), u8(0xF0), u8(0x10), u8(0xF0)], //  5
	[u8(0xF0), u8(0x80), u8(0xF0), u8(0x90), u8(0xF0)], //  6
	[u8(0xF0), u8(0x10), u8(0x20), u8(0x40), u8(0x40)], //  7
	[u8(0xF0), u8(0x90), u8(0xF0), u8(0x90), u8(0xF0)], //  8
	[u8(0xF0), u8(0x90), u8(0xF0), u8(0x10), u8(0xF0)], //  9
	[u8(0xF0), u8(0x90), u8(0xF0), u8(0x90), u8(0x90)], //  A
	[u8(0xE0), u8(0x90), u8(0xE0), u8(0x90), u8(0xE0)], //  B
	[u8(0xF0), u8(0x80), u8(0x80), u8(0x80), u8(0xF0)], //  C
	[u8(0xE0), u8(0x90), u8(0x90), u8(0x90), u8(0xE0)], //  D
	[u8(0xF0), u8(0x80), u8(0xF0), u8(0x80), u8(0xF0)], //  E 
	[u8(0xF0), u8(0x80), u8(0xF0), u8(0x80), u8(0x80)],	//	F
]

struct Screen{
	pub:	
		display_width    int = 64	
		display_height   int = 32	
	mut:	
		display [32][64]u8
}

const mem_size         = 4096
const num_of_registers = 16
const f                = 15

struct Chip8{
	pub mut:
		ram  [mem_size]u8
		v [num_of_registers]u8
		screen Screen
		pc u16 = 0x200
		i  u16
		stack Stack
		delay_timer u8
		is_draw     bool
}

fn (mut chip Chip8) start_cpu(){

	chip.screen = Screen{}

	// load font in the memory
	for sprite in font {
		chip.set_ram(sprite, chip.i)
	}
}

fn (mut chip Chip8) run(){	
	mut instruction := chip.fetch()
	chip.decode_and_run(instruction)
}


fn (mut chip Chip8) set_ram(instructions []u8, index u16) {
	
	mut j := index

	for i := 0; i < instructions.len; i++ {
		chip.ram[j] = instructions[i]
		j++
	}	
}

fn (mut chip Chip8) fetch() u16{

	mut instruction := u16(0x00)
	
	mut half_instruction := chip.ram[chip.pc]

	instruction = instruction | half_instruction
	instruction = instruction << 8
	half_instruction = chip.ram[chip.pc + 1]
	
	instruction = instruction | half_instruction

	return instruction
}

fn (mut chip Chip8) decode_and_run(instruction u16) {

	mut nnn, mut nn, mut n, mut x, mut y := 0x00, 0x00, 0x00, 0x00, 0x00
   
	mut opcode_msb := instruction & 0xF000
	mut opcode_lsb := instruction & 0x00FF
	mut is_jump := false
	chip.is_draw = false

	//println(opcode_lsb)
	match opcode_msb{

		0x0000 {

			match opcode_lsb {
				0xEE {
					chip.pc = chip.stack.pop() or { panic(err) }
					// Returns from a subroutine
				}

				0xE0 {
					chip.is_draw = true
					for i := 0; i < chip.screen.display_height; i++{
						for j := 0; j < chip.screen.display_width; j++ {
							chip.screen.display[i][j] = 0
						}
					}
				}

				//0NNN {
				//	nnn = instruction & 0x0FFF
					// Calls machine code routine
				//}

				else{
					panic('Invalid instruction! 0x${instruction.hex()}')
				}
			}
		}

		0x1000 {
			nnn = instruction & 0x0FFF
			chip.pc = u16(nnn)
			is_jump = true
			// Jumps to address NNN
		}

		0x2000 {

			nnn = instruction & 0x0FFF

			chip.stack.push(chip.pc)
			chip.pc = u16(nnn)
			is_jump = true
			// Calls subroutine at NNN
		}

		0x3000 {
			x  = (instruction & 0x0F00) >> 8
			nn = instruction & 0x00FF

			if chip.v[x] == nn { chip.pc += 2 }
			// Skips the next instruction if VX equals NN
		}

		0x4000 {
			x  = (instruction & 0x0F00) >> 8
			nn = instruction & 0x00FF

			if chip.v[x] != nn { chip.pc += 2 }
			// Skips the next instruction if VX does not equal NN 
		}

		0x5000 {
			x = (instruction & 0x0F00) >> 8
			y = (instruction & 0x00F0) >> 4

			if chip.v[x] == chip.v[y] { chip.pc += 2 }
			// Skips the next instruction if VX equals VY 
		}

		0x6000 {
			x  = (instruction & 0xF00) >> 8
			nn = instruction & 0x00FF

			chip.v[x] = u8(nn)
			// Sets VX to NN
		}

		0x7000 {
			x  = (instruction & 0xF00) >> 8
			nn = instruction & 0x00FF

			chip.v[x] += u8(nn)
			// Adds NN to VX (carry flag is not changed)
		}

		0x8000 {
			x = (instruction & 0x0F00) >> 8
			y = (instruction & 0x00F0) >> 4
			opcode_lsb = instruction & 0x000F

			match opcode_lsb {
				0x00 {
					chip.v[x] = chip.v[y]
					// Sets VX to the value of VY
				}

				0x01 {
					chip.v[x] |= chip.v[y]
					// Sets VX to VX or VY. (bitwise OR operation).
				}

				0x02 {
					chip.v[x] &= chip.v[y]
					// Sets VX to VX and VY. (bitwise AND operation)
				}

				0x03 {
					chip.v[x] ^= chip.v[y]			
					// Sets VX to VX xor VY
				}

				0x04 {

					xy := chip.v[x] + chip.v[y]
					
					if xy > 255 {
						chip.v[f] = 1
					}else{
						chip.v[f] = 0
					}

					chip.v[x] = xy
					// Adds VY to VX. VF is set to 1 when there's an overflow, and to 0 when there is not.
				}

				0x05 {
					xy := chip.v[x] - chip.v[y]

					if chip.v[x] >= chip.v[y] {
						chip.v[f] = 1
					}else{
						chip.v[f] = 0
					}

					chip.v[x] = xy
					// VY is subtracted from VX. VF is set to 0 when there's an underflow, and 1 when there is not. (i.e. VF set to 1 if VX >= VY and 0 if not)
				}

				0x06 {
					chip.v[f] = (chip.v[x] & 0xF0) >> 7
					chip.v[x] = chip.v[x] >> 1
					// Stores the least significant bit of VX in VF and then shifts VX to the right by 1
				}

				0x07 {

					xy := chip.v[y] - chip.v[x]

					if chip.v[y] >= chip.v[x] {
						chip.v[f] = 1
					}else{
						chip.v[f] = 0
					}

					chip.v[x] = xy
					// Sets VX to VY minus VX. VF is set to 0 when there's an underflow, and 1 when there is not. (i.e. VF set to 1 if VY >= VX).
				}

				0x0E {

					chip.v[f] = (chip.v[x] & 0xF0) >> 7

					chip.v[x] = chip.v[x] >> 1
					// Stores the most significant bit of VX in VF and then shifts VX to the left by 1.
				}

				else{
					panic('Invalid instruction! 0x${instruction.hex()}')
				}
			}

		}

		0x9000 {
			x = (instruction & 0x0F00) >> 8
			y = (instruction & 0x00F0) >> 4

			if chip.v[x] != chip.v[y] { chip.pc += 2 }
		}

		0xA000 {
			nnn = instruction & 0x0FFF

			chip.i = u16(nnn)
		}

		0xB000 {
			nnn = instruction & 0x0FFF

			chip.pc = u16(nnn + chip.v[0])
			is_jump = true
		}

		0xC000 {
			x  = (instruction & 0x0F00) >> 8
			nn = instruction & 0x00FF 

			randint := rand.intn(256) or { panic(err) }

			chip.v[x] = u8(randint & nn)
		}

		0xD000 {

			chip.is_draw = true
			x = (instruction & 0x0F00) >> 8
			y = (instruction & 0x00F0) >> 4
			n = (instruction & 0x000F)

			mut regvy := u16(chip.v[y])
			mut regvx := u16(chip.v[x])

			chip.v[f] = 0

			for y_coord := 0; y_coord < n; y_coord++ {
				
				pixel := chip.ram[chip.i + y_coord]
				
				for x_coord := 0; x_coord < 8; x_coord++ {
					
					if (pixel & (0x80 >> x_coord)) != 0 {
						if chip.screen.display[regvy + y_coord][regvx + x_coord] == 1 {
							chip.v[f] = 1
						}
						
						chip.screen.display[regvy + y_coord][regvx + x_coord] ^= 1
					}
				}
			}
		}

		//0xE000 {
		//	x = (opcode & 0x0F00) >> 8
		//	s_opcode = opcode & 0x00FF
//
		//	match s_opcode {
//
		//		0x9E {
//
		//		},
//
		//		0xA1 {
//
		//		},
		//	}
		//},
//
		//0xF000 {
		//	x = (opcode & 0x0F00) >> 8
		//	s_opcode = opcode & 0x00FF
//
		//	match s_opcode {
		//		0x07{
//
		//		},
//
		//		0x0A{
//
		//		},
//
		//		0x15{
//
		//		},
//
		//		0x18{
//
		//		},
//
		//		0x1E{
		//			chip.i += chip.v[x]
		//		},
//
		//		0x29{
//
		//		},
//
		//		0x33{
//
		//		},
//
		//		0x55{
//
		//		},
//
		//		0x65{
//
		//		},
		//	}
		//},

		else {
			panic('Invalid instruction! 0x${instruction.hex()}')
		}
	}
	if !is_jump { chip.pc += 2 }
}

