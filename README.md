# Weilianqi

Welcome to a fun and beneficial game that trains the mind and teamwork skills!

Wei-lian-qi is chinese for surround-connect-game. To play it first start julia then type:
```
Pkg.add("Gtk") #unless already installed
Pkg.clone("https://github.com/jhlq/Weilianqi.jl") #if you haven't already
using Weilianqi
game=newgame();
harvest(game) #after clicking a few times on the intersections of the board
```

What is the objective? There are many! One is to figure out how the scoring system works!
