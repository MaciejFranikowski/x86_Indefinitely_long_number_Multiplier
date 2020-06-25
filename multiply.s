SYSEXIT  = 1
SYSREAD  = 3
SYSWRITE = 4
STDIN    = 0
STDOUT   = 1
EXIT     = 0
SYSCALL  = 0x80

# Code multiplies two numbers given as input.
# Modify the label 'number_length' to change the length of input numbers
number_length = 256
# Buffer_length is twice the size of input numbers,
# which stems from multiplication properties.
buffer_length = number_length * 2

# Data segment.
.data

first_number:
.space number_length

second_number:
.space number_length

output_buffer:
.space buffer_length

number_bytes_read:
.space 4

# Code segment.
.text
.globl _start
_start:

# Calling system function READ, reading the first number.
movl $SYSREAD, %eax
movl $STDIN, %ebx
movl $first_number, %ecx
movl $number_length, %edx
int $SYSCALL

# Moving the number of bytes read into memory
movl %eax, number_bytes_read

# Calling system function READ, reading the second number.
movl $SYSREAD, %eax
movl $STDIN, %ebx
movl $second_number, %ecx
movl $number_length, %edx
int $SYSCALL

# Adding the number of bytes read from the second reading,
# to the number of bytes from the first one.
addl %eax, number_bytes_read

# Checking if the number of overall bytes read is 0,
# if so, jump to the finish.
cmpl $0, number_bytes_read
je finish

# Making sure that the registers used as index variables contain zeros.
# Edi register is used for moving in the first number.
movl $0 ,  %edi
# Esi register is used for moving in the second number.
movl $0 ,  %esi
# Ecx register is the sum of esi and edi, used to move in the output_buffer.
movl $0 ,  %ecx

# Beggining of the multiplication algorythm
outer_loop:
	cmpl $number_length, %edi
	jae outer_loop_end
	
	# Pushf is necessary here, because there needs to be
	# some EFLAGS register with CF = 0 on stack during the first
	# inner loop rotation. Popf is here, because during debugging
	# the stack filled up, as it was only written to, it has to be popped.
	popf
	clc
	pushf
	
	# Moving the contents of edi to ecx, which guarantees it to be
	# the sum of edi and esi at the beggining of the inner loop
	movl %edi, %ecx

	movl $0 ,  %esi 

	inner_loop:
		cmpl $number_length , %esi 
		jae inner_loop_end
		
		# Multiplicating bytes from the first number and the second 
		# number. The ah register contains the higher part of the
		# result, al the lower part.
		movb first_number(%edi), %al
		mulb second_number(%esi)
		
		# Here I pop the EFLAGS register form the stack.
		# On the first rotation of the loop, it will
		# contain a register w CF = 0, which is assured in the outer
		# loop. After the first rotation, the popped register
		# contains information if the addition of the higher byte
		# resulted in creating a carry (przeniesienie).
		popf

		# Initially i tried adding 0 with carry to  the higher byte
		# of the result, but that could also create a carry,
		# which could also create a carry, etc.
		# I noticed that the max result of multiplication is
		# FF x FF = FE 01. So you can add the carry to the higher
		# byte of the result ofthat multiplication, which will 
		# never create a carry (przeniesienie).
		adcb $0 , %ah

		# Here I add without carry, the lower part of the result of
		# the multiplication to the output_buffer.
		addb %al,  output_buffer(%ecx)
		
		# Here I add with carry (from the previous addition), 
		# the higher part of the result of the multiplication
		# to the output_buffer.
		incl %ecx
		adcb %ah, output_buffer(%ecx)
		decl %ecx

		# As I mentioned before, here i push the EFLAGS,
		# containing the information whether a carry was
		# created in the last addition.
		pushf

		incl %esi
		incl %ecx
		jmp inner_loop
	inner_loop_end:

	incl %edi
	jmp outer_loop
outer_loop_end:

# Calling system function WRITE, writing the output_buffer, to STDOUT
movl $SYSWRITE, %eax
movl $STDOUT, %ebx
movl $output_buffer, %ecx
movl $buffer_length, %edx 
int $SYSCALL

# Cleanup for the output_buffer.
movl $0, %edi
buffer_cleanup:
	
	cmpl $buffer_length, %edi
	jae buffer_cleanup_end
	andl $0 , output_buffer(%edi)
	incl %edi
	jmp buffer_cleanup

buffer_cleanup_end:

# Jump to the beggining of the code.
jmp _start
finish:

# Concluding the code with the system function EXIT.
movl $SYSEXIT, %eax
movl $EXIT, %ebx
int $SYSCALL

