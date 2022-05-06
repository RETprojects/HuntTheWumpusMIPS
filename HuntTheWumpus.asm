#CMPEN 351 Final Project
#Hunt the Wumpus
#created April 11, 2022

#This is a version of the 1970s text-based adventure game Hunt the Wumpus.
#The game involves traveling through a cave network of 20 rooms connected like the vertices of a dodecahedron
#and trying to "shoot" a beast called the Wumpus using "crooked arrows" that can fire in crooked lines through the network.
#Hazards include being attacked by the Wumpus, getting carried to another cave by a "super bat", falling into a pit, shooting yourself with an arrow, or running out of arrows.

.data
#20 caves connected by tunnels
#This 2D array stores the rooms adjacent to each room (e.g., room 1 leads to rooms 5, 8, and 2)
rooms:	.word
	5, 8, 2
	1, 10, 3
	2, 12, 4
	3, 14, 5
	4, 6, 1
	15, 5, 7
	6, 17, 8
	7, 1, 9
	8, 18, 10
	9, 2, 11
	10, 19, 12
	11, 3, 13
	12, 20, 14
	13, 4, 15
	14, 16, 6
	17, 15, 20
	16, 7, 18
	17, 9, 19
	18, 11, 20
	19, 13, 16

# width and height of the array
.eqv ARRAY_W 3
.eqv ARRAY_H 20

# size of 1 row = width * size of 1 item
# items are 4 bytes each, so 3 * 4
.eqv ARRAY_ROW_SIZE 12

#1 cave contains the player at a time
playerLoc:	.word 1	#the player starts the game in cave 1
#1 cave contains the Wumpus; this is subject to change
wumpusLoc:	.word 0
#2 caves randomly contain pits
pitLoc1:	.word 0
pitLoc2:	.word 0
#2 caves randomly contain bats; this may change at some point in the game
batLoc1:	.word 0
batLoc2:	.word 0

arrowsLeft:	.word 5	#you begin the game w/ 5 arrows in your quiver

#What the player will see:
newline:	.asciiz "\n"
space:		.asciiz " "
instructions:	.asciiz "Hunt The Wumpus\nYou are a hunter who has entered a network of 20 caves, connected like the vertices of a dodecahedron, to kill a monster known as the 'Wumpus'.\nYou are equipped with five 'crooked arrows' that can travel through up to five connected rooms. Hazards include the Wumpus, two 'bottomless' pits,\nand two 'super bats' which can carry you to another cave if disturbed. You will know of hazards in some adjacent cave without knowing which cave contains the hazard.\nFor reference, here are the adjacencies of each room:\nRoom#	Adjacent rooms\n1:	5, 8, 2\n2:	1, 10, 3\n3:	2, 12, 4\n4:	3, 14, 5\n5:	4, 6, 1\n6:	15, 5, 7\n7:	6, 17, 8\n8:	7, 1, 9\n9:	8, 18, 10\n10:	9, 2, 11\n11:	10, 19, 12\n12:	11, 3, 13\n13:	12, 20, 14\n14:	13, 4, 15\n15:	14, 16, 6\n16:	17, 15, 20\n17:	16, 7, 18\n18:	17, 9, 19\n19:	18, 11, 20\n20:	19, 13, 16\nGood luck!\n"
wumpusWarning:	.asciiz "You smell a Wumpus...\n"
batWarning:	.asciiz "You hear the rustling of large wings...\n"
pitWarning:	.asciiz "You feel a draft from below...\n"
youAreIn:	.asciiz "You are in room #"
tunnelsLeadTo:	.asciiz "Tunnels lead to rooms "
shootOrMove:	.asciiz "Shoot or Move (S-M)? "
whereTo:	.asciiz "Where to? "
enterNoRooms:	.asciiz "No. of rooms (1-5)? "
fiveRooms:	.asciiz "The arrow will fire through 5 caves.\n"
enterARoom:	.asciiz "Next room #: "
randomArrowLoc:	.asciiz "The arrow is in room #"
numArrowsLeft:	.asciiz "Arrows left: "
hitByArrow:	.asciiz "You were hit by your own arrow.\n"
winMsg:		.asciiz "AHA! You got the Wumpus! You win!\n"
loseMsg:	.asciiz "You lose!\n"
eaten:		.asciiz "The Wumpus ate you.\n"
outOfArrows:	.asciiz "You ran out of arrows. Better luck next time!\n"
fall:		.asciiz "You fell into a pit.\n"
takenByBat:	.asciiz "A bat has taken you to room #"
wumpusRan:	.asciiz "The Wumpus got spooked and ran to some other cave.\n"
invalidNum:	.asciiz "Sorry, please choose a valid, directly accessible room #.\n"

.text

Main:
	#print instructions
	li $v0, 4
	la $a0, instructions
	syscall
	
	#initialize the random number generator
	li $v0, 30 #get system time
	syscall
	move $a1, $a0 #the seed is $a1 (the high order 32 bits of the measured system time)
	li $a0, 0 #generator number
	li $v0, 40 #set seed
	syscall
	
	#initialize Wumpus location, pit locations, and bat locations
	#set wumpusLoc, pitLoc1, pitLoc2, batLoc1, and batLoc2 to random ints from 2 to 20
	li $a0, 0 #use generator 0
	li $a1, 19 #upper bound bound is 19
	li $v0, 42 #generate 0 <= int < 19
	syscall
	add $a0, $a0, 2 #add 2 (2 <= int < 21)
	sw $a0, wumpusLoc
	syscall
	add $a0, $a0, 2
	sw $a0, pitLoc1
	syscall
	add $a0, $a0, 2
	sw $a0, pitLoc2
	syscall
	add $a0, $a0, 2
	sw $a0, batLoc1
	syscall
	add $a0, $a0, 2
	sw $a0, batLoc2
	
	#This is the infinite loop that keeps gameplay going until a win or a loss occurs.
gameplayLoop:
	la $a0, rooms
	lw $a1, playerLoc
	jal CaveCheck
	j gameplayLoop
	
exitGame:
	#exit once finished with the game
	li $v0, 10
	syscall

#Procedures:

#CaveCheck
#Displays cave number, clues, and adjacent cave numbers, then asks the player to shoot or move.
#Inputs:
#	$a0 - rooms
#	$a1 - playerLoc
#Outputs:
#	$a1 - player location (if Shoot was called)
CaveCheck:
	#tell the player what cave they are in
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	li $v0, 4
	la $a0, youAreIn
	syscall
	add $a0, $a1, $zero
	li $v0, 1
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	la $a0, tunnelsLeadTo
	syscall
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	
	#get all adjacent cave numbers
	#first adjacent cave # is stored into $t1
	addi $t4, $a1, -1
	mul $t4, $t4, ARRAY_ROW_SIZE # $t4 = Rr: multiply row by size of *one row*
	la $t1, ($a0)
	li $t5, 0                    # $t5 = Bc: multiply col by size of *one item* (index 0 * 4)
	add $t1, $t1, $t4
	add $t1, $t1, $t5            # $t1 = A + Rr + Bc
	#second adjacent cave # into $t2
	la $t2, ($a0)
	li $t5, 4                    # $t5 = Bc: multiply col by size of *one item* (index 1 * 4)
	add $t2, $t2, $t4
	add $t2, $t2, $t5            # $t2 = A + Rr + Bc
	#third adjacent cave # into $t3
	la $t3, ($a0)
	li $t5, 8                    # $t5 = Bc: multiply col by size of *one item* (index 2 * 4)
	add $t3, $t3, $t4
	add $t3, $t3, $t5            # $t3 = A + Rr + Bc
	
	#print all three rooms that connect to the current room
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	li $v0, 1 #print integer
	lw $a0, 0($t1)
	syscall
	li $v0, 4
	la $a0, space #to separate the numbers
	#print_str " "
	syscall
	li $v0, 1 #print integer
	lw $a0, 0($t2)
	syscall
	li $v0, 4
	la $a0, space #to separate the numbers
	#print_str " "
	syscall
	li $v0, 1 #print integer
	lw $a0, 0($t3)
	syscall
	li $v0, 4
	la $a0, newline
	#println_str ""
	syscall
	
	lw $t1, 0($t1)
	lw $t2, 0($t2)
	lw $t3, 0($t3)
	
	#if any adjacent room contains the Wumpus, a bat, or a pit, give a clue
	lw $t0, wumpusLoc
	
	beq $t0, $t1, wumpusNear
	beq $t0, $t2, wumpusNear
	beq $t0, $t3, wumpusNear
wumpusFound:
	lw $t0, batLoc1
	
	move $t0, $t0
	beq $t0, $t1, batNear
	beq $t0, $t2, batNear
	beq $t0, $t3, batNear
	
	lw $t0, batLoc2
	
	move $t0, $t0
	beq $t0, $t1, batNear
	beq $t0, $t2, batNear
	beq $t0, $t3, batNear
batFound:
	lw $t0, pitLoc1
	
	move $t0, $t0
	beq $t0, $t1, pitNear
	beq $t0, $t2, pitNear
	beq $t0, $t3, pitNear
	
	lw $t0, pitLoc2
	
	move $t0, $t0
	beq $t0, $t1, pitNear
	beq $t0, $t2, pitNear
	beq $t0, $t3, pitNear
	j contToNextAction
wumpusNear:
	la $a0, wumpusWarning
	syscall #$v0 is already 4
	j wumpusFound
batNear:
	la $a0, batWarning
	syscall
	j batFound
pitNear:
	la $a0, pitWarning
	syscall
contToNextAction:
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	
	#make the player choose their next action (shoot or move)
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	la $a0, shootOrMove
	syscall #print the "Shoot or Move?" prompt ($v0 is already 4)
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	
	li $v0, 12 #read a single character
	syscall #now the character is stored in $v0
	
	beq $v0, 'S', _case_s
	beq $v0, 's', _case_s
	beq $v0, 'M', _case_m
	beq $v0, 'm', _case_m
	
	#if the character isn't S or M, do nothing:
	jr $ra
_case_s:
	addi $sp, $sp, -4
	sw $ra, 0($sp) #store $ra to the stack (nested procedures require each prior return address to be saved)
	la $a0, rooms
	lw $a1, arrowsLeft
	lw $a2, playerLoc
	lw $a3, wumpusLoc
	jal Shoot
	sw $a1, arrowsLeft #update the number of arrows left (decreased by 1)
	lw $ra, 0($sp) #restore $ra
	addi $sp, $sp, 4
	
	jr $ra
_case_m:
	addi $sp, $sp, -4
	sw $ra, 0($sp) #store $ra to the stack (nested procedures require each prior return address to be saved)
	jal Move
	lw $ra, 0($sp) #restore $ra
	addi $sp, $sp, 4
	
	jr $ra

#Shoot
#Allows the player to enter how many caves that the arrow will fire through, then select the specific cave numbers along the arrow's trajectory.
#Inputs:
#	$a0 - rooms
#	$a1 - arrowsLeft
#	$a2 - playerLoc
#	$a3 - wumpusLoc
#Outputs:
#	
Shoot:
	#prompt the player to enter how many caves to fire through (1-5)
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	li $v0, 4
	la $a0, newline
	syscall
	la $a0, enterNoRooms
	syscall
	#get the number of caves
	li $v0, 5
	syscall #now the number of caves is stored in $v0
	move $t6, $v0	#move the value in $v0 to $t6
	#if the number isn't 1-5, choose 5 and inform the player as such
	beq $t6, 1, validNoOfCaves
	beq $t6, 2, validNoOfCaves
	beq $t6, 3, validNoOfCaves
	beq $t6, 4, validNoOfCaves
	beq $t6, 5, validNoOfCaves
	li $t6, 5
	la $a0, fiveRooms
	li $v0, 4
	syscall
validNoOfCaves:
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	
	#decrement arrow count
	addi $a1, $a1, -1
	#set the arrow's location to the player's location
	move $t0, $a2
pathLoop:
	#check the loop counter $t6 (number of caves left to fire through)
	beq $t6, 0, endOfPathLoop
	
	#get the cave numbers adjacent to the arrow's current location
	#store the first adjacent cave # into $t1
	addi $t4, $a2, -1
	mul $t4, $t4, ARRAY_ROW_SIZE # $t4: multiply row by size of 1 row
	li $t5, 0                    # $t5: multiply col by size of 1 room (index 0 * 4)
	add $t1, $a0, $t4
	add $t1, $t1, $t5            # $t1 = the proper cave at the index
	#second adjacent cave # into $t2
	li $t5, 4                    # $t5: multiply col by size of 1 room (index 1 * 4)
	add $t2, $a0, $t4
	add $t2, $t2, $t5            # $t2 = the proper cave at the index
	#third adjacent cave # into $t3
	li $t5, 8                    # $t5: multiply col by size of 1 room (index 2 * 4)
	add $t3, $a0, $t4
	add $t3, $t3, $t5            # $t3 = the proper cave at the index
	
	lw $t1, 0($t1)
	lw $t2, 0($t2)
	lw $t3, 0($t3)
	
	#print all three rooms that connect to the current room
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	li $v0, 1 #print integer
	move $a0, $t1
	syscall
	li $v0, 4
	la $a0, space #to separate the numbers
	syscall
	li $v0, 1 #print integer
	move $a0, $t2
	syscall
	li $v0, 4
	la $a0, space #to separate the numbers
	syscall
	li $v0, 1 #print integer
	move $a0, $t3
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	
	#allow the user to choose a cave # from this list
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	li $v0, 4
	la $a0, enterARoom #print the prompt to enter the next cave # for the arrow to enter
	syscall
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	
	li $v0, 5 #read integer
	syscall #the new arrow location is stored in $v0
	move $t7, $v0 #copy the arrow location (in $v0) to $t7
	
	#if cave # is invalid, choose one at random
	beq $t7, $t1, validNewArrowLoc
	beq $t7, $t2, validNewArrowLoc
	beq $t7, $t3, validNewArrowLoc
	
	addi $sp, $sp, -12
	sw $v0, 0($sp)
	sw $a1, 4($sp)
	sw $a0, 8($sp)
	li $v0, 42 #generate a random number
	li $a0, 0
	li $a1, 3 #range is 0-2
	syscall #the random number is stored in $a0
	beq $a0, 0, arrow0
	beq $a0, 1, arrow1
	beq $a0, 2, arrow2
	j arrow_break
arrow0:
	move $t7, $t1
	#tell the player that the arrow is now in the first adjacent cave ($t1)
	li $v0, 4
	la $a0, randomArrowLoc
	syscall
	li $v0, 1
	move $a0, $t7
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	j arrow_break
arrow1:
	move $t7, $t2
	#tell the player that the arrow is now in the second adjacent cave ($t2)
	li $v0, 4
	la $a0, randomArrowLoc
	syscall
	li $v0, 1
	move $a0, $t7
	syscall
	li $v0, 4
	la $a0, newline
	syscall
	j arrow_break
arrow2:
	move $t7, $t3
	#tell the player that the arrow is now in the third adjacent cave ($t3)
	li $v0, 4
	la $a0, randomArrowLoc
	syscall
	li $v0, 1
	move $a0, $t7
	syscall
	li $v0, 4
	la $a0, newline
	syscall
arrow_break:
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $v0, 0($sp)
	addi $sp, $sp, 12
validNewArrowLoc:
	#update arrow location w/ the new cave #
	move $t0, $t7
	
	#if the arrow hits the Wumpus's cave, the player wins
	beq $t0, $a3, DisplayWin
	#else if the arrow returns to the player's cave, the player loses
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	la $a0, hitByArrow
	lw $t9, playerLoc
	beq $t0, $t9, DisplayLoss
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	
	sub $t6, $t6, 1 #increment the counter
	move $a2, $t0 #update $a2 for the next iteration
	j pathLoop
endOfPathLoop:
	#else if the player has run out of arrows (and we found that the arrow did not hit the Wumpus), the player loses
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	la $a0, outOfArrows
	beq $a1, 0, DisplayLoss
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	#else, the Wumpus is startled and runs to another cave; update the Wumpus's location to a random cave #
	addi $sp, $sp, -4
	sw $a1, 0($sp) #store $a1 (arrowsLeft) to the stack
	li $v0, 42
	li $a0, 0
	li $a1, 20
	syscall #the random cave # is stored in $a0
	lw $a1, 0($sp) #restore $a1
	addi $sp, $sp, 4
	addi $a0, $a0, 1
	move $a3, $a0
	sw $a3, wumpusLoc
		#if the Wumpus has moved to the player's cave, the player loses
		addi $sp, $sp, -4
		sw $a0, 0($sp) #store $a0 to the stack
		la $a0, eaten
		beq $a2, $a3, DisplayLoss
		lw $a0, 0($sp) #restore $a0
		addi $sp, $sp, 4
		#else, indicate that the Wumpus has run to another cave and display the number of remaining arrows
		li $v0, 4
		la $a0, wumpusRan
		syscall
		la $a0, numArrowsLeft
		syscall
		li $v0, 1
		move $a0, $a1
		syscall
		la $a0, newline
		li $v0, 4
		syscall
	
	jr $ra

#Move
#Allows the player to enter which cave number, out of the adjacent cave numbers, to move to for the next turn.
#Inputs:
#	$a0 - rooms
#	$a1 - playerLoc
#Outputs:
#	
Move:
	#load wumpusLoc, pitLoc1, pitLoc2, batLoc1, and batLoc2 into temp registers
	lw $t0, wumpusLoc
	lw $t6, pitLoc1
	lw $t7, pitLoc2
	lw $t8, batLoc1
	lw $t9, batLoc2
ask:	
	#prompt the player to enter an adjacent room # to move to
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	li $v0, 4
	la $a0, newline
	syscall
	la $a0, whereTo
	syscall
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	
	#the player enters a room #
	li $v0, 5
	syscall #the new room # is now stored in $v0
	
	#get the adjacent cave numbers for reference
	#store the first adjacent cave # into $t1
	addi $t4, $a1, -1
	mul $t4, $t4, ARRAY_ROW_SIZE # $t4 = Rr: multiply row by size of *one row*
	li $t5, 0                    # $t5 = Bc: multiply col by size of *one item* (index 0 * 4)
	add $t1, $a0, $t4
	add $t1, $t1, $t5            # $t1 = A + Rr + Bc
	#second adjacent cave # into $t2
	li $t5, 4                    # $t5 = Bc: multiply col by size of *one item* (index 1 * 4)
	add $t2, $a0, $t4
	add $t2, $t2, $t5            # $t2 = A + Rr + Bc
	#third adjacent cave # into $t3
	li $t5, 8                    # $t5 = Bc: multiply col by size of *one item* (index 2 * 4)
	add $t3, $a0, $t4
	add $t3, $t3, $t5            # $t3 = A + Rr + Bc
	
	lw $t1, 0($t1)
	lw $t2, 0($t2)
	lw $t3, 0($t3)
	
	#if $v0 is a valid adjacent room #, update the player location to $v0
	#else, inform the player that they made a mistake and ask them to choose again
	beq $v0, $t1, validNewPlayerLoc
	beq $v0, $t2, validNewPlayerLoc
	beq $v0, $t3, validNewPlayerLoc
	
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	li $v0, 4
	la $a0, invalidNum
	syscall
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	j ask #ask the player again
validNewPlayerLoc:
	sw $v0, playerLoc #update the player location variable
	#if the new cave contains a bat, move the player to any random cave
	beq $v0, $t8, batEncountered
	beq $v0, $t9, batEncountered
	j noBatEncountered
batEncountered:
	#move the player to a random cave
	addi $sp, $sp, -12
	sw $v0, 0($sp)
	sw $a1, 4($sp)
	sw $a0, 8($sp)
	li $v0, 42 #generate a random number
	li $a0, 0
	li $a1, 20 #range is 0-19
	syscall #the random number is stored in $a0
	addi $a0, $a0, 1 #range is 1-20
	move $t8, $a0 #store the random location in $t8 (we don't need the first bat location anymore for this iteration)
	#tell the player that they have been snatched by the bat
	la $a0, takenByBat
	li $v0, 4
	syscall
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $v0, 0($sp)
	addi $sp, $sp, 12
	
	#update the player location to the random cave #
	move $v0, $t8
	sw $v0, playerLoc
	move $t8, $v0
	sw $v0, playerLoc
	#print the new room number
	addi $sp, $sp, -8
	sw $v0, 0($sp)
	sw $a0, 4($sp)
	li $v0, 1
	move $a0, $t8 #the new room #
	syscall
	la $a0, newline
	li $v0, 4
	syscall
	lw $a0, 4($sp)
	lw $v0, 0($sp)
	addi $sp, $sp, 8
noBatEncountered:
	#else if the new cave contains a pit, the player loses
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack
	la $a0, fall
	beq $v0, $t6, DisplayLoss
	beq $v0, $t7, DisplayLoss
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	#else if the new cave contains the Wumpus, generate a random integer from 0 to 3
	bne $v0, $t0, noWumpusEncountered
	
	addi $sp, $sp, -12
	sw $v0, 0($sp)
	sw $a1, 4($sp)
	sw $a0, 8($sp)
	li $v0, 42 #generate a random number
	li $a0, 0
	li $a1, 4 #range is 0-3
	syscall #the random number is stored in $a0
	beq $a0, 0, wumpusEats
	beq $a0, 1, wumpusRuns
	beq $a0, 2, wumpusRuns
	beq $a0, 3, wumpusRuns
	#if the int is 0, the player loses (eaten by the Wumpus)
wumpusEats:
	la $a0, eaten
	jal DisplayLoss
wumpusRuns:
	#else, the Wumpus runs to another cave; update the Wumpus's location to a random cave #
	li $v0, 42
	li $a0, 0
	li $a1, 20
	syscall #the random cave # is stored in $a0
	addi $a0, $a0, 1
	move $a3, $a0
	sw $a3, wumpusLoc
		#if the Wumpus has moved to the player's cave (again), the player loses
		addi $sp, $sp, -4
		sw $a0, 12($sp) #store $a0 to the stack
		la $a0, eaten
		beq $a2, $a3, DisplayLoss
		lw $a0, 12($sp) #restore $a0
		addi $sp, $sp, 4
	lw $a0, 8($sp)
	lw $a1, 4($sp)
	lw $v0, 0($sp)
	addi $sp, $sp, 12
	
noWumpusEncountered:
	jr $ra

#DisplayWin
#Indicate that the player has won the game and exit.
DisplayWin:
	#play the victory sound
	li $v0, 31 #play MIDI sound and return immediately
	li $a0, 66 #pitch (F#)
	li $a1, 250 #duration (250 ms)
	li $a2, 57 #instrument (trumpet)
	li $a3, 127 #volume
	syscall
	li $a0, 74 #pitch (D)
	li $a1, 500
	syscall #play the sound a second time
	
	la $a0, winMsg
	li $v0, 4
	syscall #print the message
	
	j exitGame

#DisplayLoss
#Indicate that the player has lost the game and exit.
#Inputs:
#	$a0 - string describing the reason why the player lost
DisplayLoss:
	#play the losing sound
	addi $sp, $sp, -4
	sw $a0, 0($sp) #store $a0 to the stack (preserve the passed-in message)
	li $v0, 31 #play MIDI sound and return immediately
	li $a0, 56 #pitch (Ab)
	li $a1, 250 #duration (250 ms)
	li $a2, 58 #instrument (trombone)
	li $a3, 127 #volume
	syscall
	la $a1, 500
	syscall #play the sound a second time
	lw $a0, 0($sp) #restore $a0
	addi $sp, $sp, 4
	
	li $v0, 4
	syscall #display the reason why the player lost
	la $a0, loseMsg
	syscall #print the message
	
	j exitGame
