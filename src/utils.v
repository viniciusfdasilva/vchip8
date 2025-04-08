module main

struct Stack {
pub mut:
	addresses [16]u16
	i_control int
}

fn (stack Stack) is_empty() bool {
	return stack.i_control == 0
}

@[direct_array_access]
fn (mut stack Stack) push(address u16) {
	stack.addresses[stack.i_control] = address
	stack.i_control++
}

@[direct_array_access]
fn (mut stack Stack) pop() !u16 {
	if stack.is_empty() {
		return error('Stack is empty!')
	} else {
		val := stack.addresses[stack.i_control - 1]
		stack.addresses[stack.i_control - 1] = 0
		stack.i_control--
		return val
	}
}
