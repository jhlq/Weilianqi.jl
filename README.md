# Weilianqi

Welcome to a fun and beneficial game that trains the mind and teamwork skills!

Weilianqi is played on a triangular grid like that formed by the flower of life.

Wei-lian-qi is chinese for surround-connect-game. To play it first start julia (0.6) then type:
```
Pkg.add("Gtk") #unless already installed
Pkg.clone("https://github.com/jhlq/Weilianqi.jl") #if you haven't
Pkg.checkout("Weilianqi") #to get the latest version
using Weilianqi
game=newgame("name");
```

Type save(game) in console to save the game, loadgame("name") to load it. Savefiles are stored in ~/weilianqi/saves/ and the name can be changed with game.name="newname" or through the textbox when using the buttons.

What is the main objective? There are many! One is to figure out how the scoring system works! Another to create pretty formations. A most important goal is to have fun!
