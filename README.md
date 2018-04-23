# Weilianqi

Welcome to a fun and beneficial game that trains the mind and teamwork skills!

Weilianqi is played on a triangular grid like that formed by the flower of life.

Wei-lian-qi is chinese for surround-connect-game. To play it first start julia (0.6) then type:
```
Pkg.add("Gtk") #unless already installed
Pkg.clone("https://github.com/jhlq/Weilianqi.jl") #if you haven't already
Pkg.checkout("Weilianqi") #to get the latest version
using Weilianqi
game=newgame();
```

Click the harvest button when the points are depleted or you feel like collecting more points. 

Type center(game,(x,y)) in console to center the board on a location.

What is the main objective? There are many! One is to figure out how the scoring system works! Another to create pretty formations. A most important goal is to have fun!
