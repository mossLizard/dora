Welcome to the FUTURE location of the world's worst JSON editor!

STATUS: NOT FUNCTIONAL!!!!


ACTIONS
 --- bttn : desc
  N  ADD  : Add an item to the current layer. provide key, then provide immediate val ("str hello") or path ("B/const/pi")
  S  COPY : Copy selected element to another location. Provide path ("B/tmp/one"); will prompt key if ending with / ("B/tmp/")
  K  KEY  : Quickly overwrite the key of selected element. Provide str or num immediates ONLY!
  V  VAL  : Quickly overwrite the value of selected element. Provide immediate or path.
  I  INST : Insert layers between current layer and selected element. Providing a path will add ALL layers between it and the root.
          |   inserting "B/tmp/one/" at "A/beep/(str test)" will result in "A/beep/tmp/one/(str test)"
  P  CHOP : Remove this table element and reparent its children. 
          |   Chopping "A/beep/tmp" will move "A/beep/tmp/*" to "A/beep/*"
          |   THIS is the function I am writing Dora for! THIS RIGHT HERE!!! it will make editing SO much easier!
  A  A    : Use clipboard A
  B  B    : Use clipboard B
  C  C    : Use clipboard C

Notes on value entry:
  bol : boolean (it will accept "bool" as well)
  num : number (I don't know go ask LUA about it)
  str : string
  tab : table. Usually added as an empty table.

Notes on path entry:
  Your clipboard roots are A/ B/ and C/
  ./ is replaced with the current layer on entry
  ../, .../ etc are replaced with the parent layer, grandparent layer, etc.
  

