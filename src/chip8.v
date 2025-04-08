import rand

const keyboard = {
	0x31: 0x01 // keycode 1  - 1
	0x32: 0x02 // keycode 2  - 2
	0x33: 0x03 // keycode 3  - 3
	0x34: 0x0C // keycode 4  - C
	0x51: 0x04 // keycode Q  - 4
	0x57: 0x05 // keycode W  - 5
	0x45: 0x06 // keycode E  - 6
	0x52: 0x0D // keycode R  - D
	0x41: 0x07 // keycode A  - 7
	0x53: 0x08 // keycode S  - 8
	0x44: 0x09 // keycode D  - 9
	0x46: 0x0E // keycode F  - E
	0x5A: 0x0A // keycode Z  - A
	0x58: 0x00 // keycode X  - 0
	0x43: 0x0B // keycode C  - B
	0x56: 0x0F // keycode V  - F
}

const font = [
	[u8(0xF0), u8(0x90), u8(0x90), u8(0x90), u8(0xF0)], // 0
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
	[u8(0xF0), u8(0x80), u8(0xF0), u8(0x80), u8(0x80)], //	F
]

struct Screen {
pub:
	display_width  int = 64
	display_height int = 32
mut:
	display [32][64]u8
}

const mem_size = 4096
const num_of_registers = 16
const f = 15

struct Chip8 {
	cpu_clock u8 = 9
pub mut:
	ram         [mem_size]u8
	v           [num_of_registers]u8
	screen      Screen
	pc          u16 = 0x200
	i           u16
	stack       Stack
	delay_timer u8
	sound_timer u8
	is_draw     bool
	key         u8
	cycles      u8
}

fn (mut chip Chip8) start_cpu() {
	chip.screen = Screen{}

	// load font in the memory
	for sprite in font {
		chip.set_ram(sprite, chip.i)
	}
}

fn (mut chip Chip8) run() {
	mut instruction := chip.fetch()
	chip.decode_and_run(instruction)
}

@[direct_array_access]
fn (mut chip Chip8) set_ram(instructions []u8, index u16) {
	mut j := index
	for i := 0; i < instructions.len; i++ {
		chip.ram[j] = instructions[i]
		j++
	}
}

@[direct_array_access]
fn (mut chip Chip8) fetch() u16 {
	mut instruction := u16(0x00)
	mut half_instruction := chip.ram[chip.pc]
	instruction = instruction | half_instruction
	instruction = instruction << 8
	half_instruction = chip.ram[chip.pc + 1]
	instruction = instruction | half_instruction
	return instruction
}

@[direct_array_access]
fn (mut chip Chip8) decode_and_run(instruction u16) {
	mut nnn, mut nn, mut n, mut x, mut y := 0x00, 0x00, 0x00, 0x00, 0x00

	mut opcode_msb := instruction & 0xF000
	mut opcode_lsb := instruction & 0x00FF
	mut is_jump := false
	chip.is_draw = false

	if chip.delay_timer > 0 {
		chip.delay_timer--
	}
	if chip.sound_timer > 0 {
		chip.sound_timer--
	}

	match opcode_msb {
		0x0000 {
			match opcode_lsb {
				0xEE {
					chip.pc = chip.stack.pop() or { panic(err) }
					// Returns from a subroutine
				}
				0xE0 {
					chip.is_draw = true
					for i := 0; i < chip.screen.display_height; i++ {
						for j := 0; j < chip.screen.display_width; j++ {
							chip.screen.display[i][j] = 0
						}
					}
				}
				// 0NNN {
				//	nnn = instruction & 0x0FFF
				// Calls machine code routine
				//}
				else {
					nnn = instruction & 0x0FFF
					// panic('Invalid instruction! 0x${instruction.hex()}')
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
			x = (instruction & 0x0F00) >> 8
			nn = instruction & 0x00FF

			if chip.v[x] == nn {
				chip.pc += 2
			}
			// Skips the next instruction if VX equals NN
		}
		0x4000 {
			x = (instruction & 0x0F00) >> 8
			nn = instruction & 0x00FF

			if chip.v[x] != nn {
				chip.pc += 2
			}
			// Skips the next instruction if VX does not equal NN
		}
		0x5000 {
			x = (instruction & 0x0F00) >> 8
			y = (instruction & 0x00F0) >> 4

			if chip.v[x] == chip.v[y] {
				chip.pc += 2
			}
			// Skips the next instruction if VX equals VY
		}
		0x6000 {
			x = (instruction & 0x0F00) >> 8
			nn = instruction & 0x00FF

			chip.v[x] = u8(nn)
			// Sets VX to NN
		}
		0x7000 {
			x = (instruction & 0x0F00) >> 8
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
					} else {
						chip.v[f] = 0
					}

					chip.v[x] = (xy & 0xFF)
					// Adds VY to VX. VF is set to 1 when there's an overflow, and to 0 when there is not.
				}
				0x05 {
					if chip.v[x] > chip.v[y] {
						chip.v[f] = 1
					} else {
						chip.v[f] = 0
					}

					chip.v[x] -= chip.v[y]
					// VY is subtracted from VX. VF is set to 0 when there's an underflow, and 1 when there is not. (i.e. VF set to 1 if VX >= VY and 0 if not)
				}
				0x06 {
					if chip.v[x] % 2 == 1 {
						chip.v[f] = 1
					} else {
						chip.v[f] = 0
					}

					chip.v[x] = chip.v[x] >> 1
					// Stores the least significant bit of VX in VF and then shifts VX to the right by 1
				}
				0x07 {
					xy := chip.v[y] - chip.v[x]

					if chip.v[y] > chip.v[x] {
						chip.v[f] = 1
					} else {
						chip.v[f] = 0
					}

					chip.v[x] = xy
					// Sets VX to VY minus VX. VF is set to 0 when there's an underflow, and 1 when there is not. (i.e. VF set to 1 if VY >= VX).
				}
				0x0E {
					if (chip.v[x] & 10000000) == 1 {
						chip.v[f] = 1
					} else {
						chip.v[f] = 0
					}

					chip.v[x] = chip.v[x] << 1
					// Stores the most significant bit of VX in VF and then shifts VX to the left by 1.
				}
				else {
					panic('Invalid instruction! 0x${instruction.hex()}')
				}
			}
		}
		0x9000 {
			x = (instruction & 0x0F00) >> 8
			y = (instruction & 0x00F0) >> 4

			if chip.v[x] != chip.v[y] {
				chip.pc += 2
			}
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
			x = (instruction & 0x0F00) >> 8
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
					if (regvy + y_coord) < chip.screen.display_height
						&& (regvx + x_coord) < chip.screen.display_width {
						if (pixel & (0x80 >> x_coord)) != 0 {
							if chip.screen.display[regvy + y_coord][regvx + x_coord] == 1 {
								chip.v[f] = 1
							}

							chip.screen.display[regvy + y_coord][regvx + x_coord] ^= 1
						}
					}
				}
			}
		}
		0xE000 {
			x = (instruction & 0x0F00) >> 8
			opcode_lsb = instruction & 0x00FF

			match opcode_lsb {
				0x9E {
					if chip.key == chip.v[x] {
						chip.pc += 2
					}
				}
				0xA1 {
					if chip.key != chip.v[x] {
						chip.pc += 2
					}
				}
				else {
					panic('Invalid instruction 0x${instruction.hex()}')
				}
			}
		}
		0xF000 {
			x = (instruction & 0x0F00) >> 8
			opcode_lsb = instruction & 0x00FF

			match opcode_lsb {
				0x07 {
					chip.v[x] = chip.delay_timer
				}
				0x0A {
					chip.v[x] = chip.key
				}
				0x15 {
					chip.delay_timer = chip.v[x]
				}
				0x18 {
					chip.sound_timer = chip.v[x]
				}
				0x1E {
					chip.i += chip.v[x]
				}
				0x29 {
					chip.i = u16(chip.v[x] * 0x5)
				}
				0x33 {
					chip.ram[chip.i] = u8(chip.v[x] / 100)
					chip.ram[chip.i + 1] = u8((u8(chip.v[x] / 10)) % 10)
					chip.ram[chip.i + 2] = u8(chip.v[x] % 100) % 10
				}
				0x55 {
					for i := chip.v[0]; i <= x; i++ {
						chip.ram[chip.i + i] = chip.v[i]
					}
					chip.i = u16(x + 1)
				}
				0x65 {
					for i := chip.v[0]; i <= x; i++ {
						chip.v[x] = chip.ram[chip.i + i]
					}
					chip.i = u16(x + 1)
				}
				else {
					panic('Invalid instruction! 0x${instruction.hex()}')
				}
			}
		}
		else {
			panic('Invalid instruction! 0x${instruction.hex()}')
		}
	}
	if !is_jump {
		chip.pc += 2
	}
}

fn (mut chip Chip8) update_timers() {
	if chip.delay_timer > 0 {
		chip.delay_timer--
	}
	if chip.sound_timer > 0 {
		chip.sound_timer--
	}
}

@[direct_array_access]
fn (mut chip Chip8) set_key(key int) {
	chip.key = u8(keyboard[key])
}
