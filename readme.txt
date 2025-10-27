Welcome to the FUTURE location of the world's worst JSON editor!

STATUS: NOT FUNCTIONAL!!!!



From startup, Dora presents you with 3 Tablets, labelled A, B, and C. Click the 3 buttons in the bottom left to switch the active tablet. The Tablets are the surface on which your work is done, like the canvas of a painting program. but with three of them. If you launched Dora with an additional argument, the file you specified will be loaded into A, while B and C remain blank. 
The center of the screen shows a list of keys and values; the contents of the active tablet! Double-click a "tab" type item to open it and view its contents instead. Click the ".." at the top of the list to return to the parent table. 
Your work on the Tablets is likely to take you deep through nested tables upon nested tables. The path through these nestings to your current view is shown at the top of the screen, as if this were a file system rather than a table.
The rest of the buttons at the bottom correspond to editing actions you can take. To understand the indended use of Dora, let's take a look at the Copy action.

Dora is an odd program, since it was made for an odd machine. To see how it is used, let's take an example.
  Say we have an item in A, at "A/noise_router/final_density/", named "argument1". It describes a mathematical function that we want to copy elsewhere in A, say at "A/noise_router/initial_density_without_jaggedness/argument2/argument2/argument1".
  The most trivial way to do this is to navigate to the first path, select "argument1", use COPY, and type out that mess of a second path. That would work perfectly, but only if you remember exactly where you want to place it.
  Let's do something else. Select that "argument1", use COPY, and place it in "B/". You now have a copy of the function in B. Then navigate to where you want to paste it, use ADD, and enter "B/argument1" when it asks for a Value. And voila!
  It took an extra operation to perform, but there was much less messing about with parsing long paths. Plus, if you want to alter the function a little, you can do so from B, then copy it to A or C as you like!



When asked for a VALUE:
  - enter a path to provide the value of the item at the end of the path.
  - enter "bol " or "bool " followed by "true" or "false" to provide a boolean value
  - enter "num " followed by some sort of number that lua can read, to provide a numerical value.
  - enter "str " followed by a string to provide a string value
  - enter "tab " to provide an empty table value
  - enter "lst " followed by an integer to provide a list (be very careful with these!)
  - enter "nil"  to delete the item or cancel the operation.
  - enter nothing to cancel the operation.

When asked for a KEY:
  - enter "str " plus a name to make a string key.
  - enter "val " followed by a path to name the item after the VALUE of the target. Better hope that's a string!
  - enter "nil" to delete the item or cancel the operation.
  - enter nothing to cancel the operation.
