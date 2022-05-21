# Hunt the Wumpus
This MIPS assembly language project is a version of the 1973 text-based adventure game *Hunt the 
Wumpus*, originally created by Gregory Yob. The premise of the game is that you are hunting a monster 
(the Wumpus) in a network of twenty caves (or “rooms”) using "crooked arrows" that can turn 
corners in the network. There are multiple hazards in the caves, such as the Wumpus, two “super bats” 
that can carry you to a random cave, and two bottomless pits. You win the game when the Wumpus is 
killed with an arrow.

## MARS Configuration Details:
The project uses the default configuration of the MARS MIPS simulator. You read messages and 
enter input (using a keyboard) through the Run I/O window in the bottom panel.

## How to Use:
Run the program in MARS, and an introduction to the game, an explanation of the instructions, and a 
table containing the room numbers and what room numbers are connected to them are displayed.

Here is the cave network, as explained by the table of rooms (credit: Carlburch, https://commons.wikimedia.org/wiki/File:Wumpus-map.svg):

![alt text](https://github.com/RETprojects/HuntTheWumpusMIPS/blob/5ad64c699e4f46e34abcbef14974f60443e3a82f/1024px-Wumpus-map.svg.png)

Then, for your first turn, you will see what room number you are in (you start in cave #1) and which 
caves can be accessed directly from your room (5, 8, and 2). If there is a hazard in one or more of these 
rooms, you will also see a clue for each of these hazards, but you will not know which caves the hazards 
are located in. You will then be prompted to enter S to shoot one of your five arrows into some other 
cave(s) or M to move to one of the adjacent caves. If you enter a character that is not associated with 
either of these options, the game will display the information and the prompt again until you enter a 
valid option.

If you enter M, you will be prompted to enter a room number to move to. You may enter one of the 
current adjacent cave numbers. If you enter a cave number that is not one of the adjacent cave numbers 
(or is out of the 1-20 range entirely), the game will tell you about your mistake and ask you to enter a 
valid adjacent room number. If the new room contains a bat, the bat will relocate you to a new random 
cave. If the new room contains a pit, you lose (you fall into the pit). If the new room contains a Wumpus, 
there is a 75% chance that the Wumpus will be startled and run to another cave and a 25% chance that 
you lose (the Wumpus eats you). If the Wumpus runs back into the same cave, you lose (the Wumpus 
eats you anyway). The hazards of the pits and the Wumpus will also be checked for any cave that a bat 
may carry you into.

If you enter S, you will be prompted to enter the number of rooms to fire through. This can be a number 
from 1 to 5. If you enter an invalid number, the game will automatically choose 5. Your arrow count will 
be decreased by one during a shoot action. You will be prompted to enter an adjacent cave number to 
fire your arrow into. As with the move action, if you enter an invalid cave number, the game will choose 
a valid cave number at random; you will then be notified of the new location of the arrow. If you 
entered that you would fire the arrow through more than one cave, the game will ask you repeatedly for 
the next cave number in the arrow’s path until you have entered the last cave number on the arrow’s
path or the arrow’s path has entered your cave or the Wumpus’s cave. (Adjacent room numbers to the 
arrow’s current location are displayed so you know which numbers to enter.) If you entered your own 
location as a cave number for the path, you lose (the arrow hits you). If the arrow enters the cave 
currently containing the Wumpus, you win (you killed the Wumpus). Otherwise, if the arrow has ended 
its path, the Wumpus is startled and moves to a random cave. If that cave is your current cave, you lose
(you are eaten). If your arrow count is now zero and you have not killed the Wumpus, you lose.

After the turn completes, if you haven’t already won or lost the game, you will move on to the next turn, 
which contains the same steps as before.
