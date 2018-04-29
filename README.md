# Weilianqi

Welcome to a fun and beneficial game that trains the mind and teamwork skills! Find out why Go (Weiqi) is the most played game on earth without the stressful edgy (looking at you, half point komi!) competitiveness. Fun playful competitiveness remains, the kind with trading and balancing. If you already have experience with Go you will likely be pleased since I do have dan level in both correspondence as well as live Go and ought to know what makes us tick.

Weilianqi is played on a triangular grid like that formed by the flower of life.

Wei-lian-qi is chinese for surround-connect-game, validated by a native chinese speaker who said: "It sounds interesting for me. At least everytime when I spell this name out I feel that this is some kind of old chinese literature name.." 

To play it first start julia (0.6) then type:
```
Pkg.add("Gtk") #unless already installed
Pkg.clone("https://github.com/jhlq/Weilianqi.jl") #if you haven't
Pkg.checkout("Weilianqi") #to get the latest version
using Weilianqi
game=newgame("name");
```

There are many ways to initialize the board, most can be obtained manually by deleting and expanding. Here are a few presets (work in progress):
```
g1=newgame("normal",sequence=[newunit((1,0,0),(-1,1,2),units["queen"]),newunit((0,1,0),(0,-1,2),units["queen"]),newunit((0,0,1),(1,0,2),units["queen"])]);
g2=newgame("split",[5,[(-15,0,2),(0,15,2),(15,-15,2)],15],sequence=[newunit((1,0,0),(-15,0,2),units["queen"]),newunit((0,1,0),(0,15,2),units["queen"]),newunit((0,0,1),(15,-15,2),units["queen"])]);
r1=rand(Int)%10;r2=rand(Int)%10;g3=newgame("stochastic",[3,[(0,0,2),(3+r1,3+r2,2)]],sequence=[newunit((1,0,0),(0,0,2),units["queen"]),newunit((0,1,0),(3+r1,3+r2,2),units["queen"])]);
#coming soon newgame("tunnelrace")
```

Type save(game) in console to save the game, loadgame("name") to load it. Savefiles are stored in ~/weilianqi/saves/ and the name can be changed with game.name="newname" or through the textbox when using the buttons.

What is the main objective? There are many! One is to figure out how the scoring system works! Another to create pretty formations. A most important goal is to have fun!

Since the scoring system isn't that obvious (especially if one looks at the getpoints! function) some hints may be in order. Red loves green who loves blue who loves red. Everyone loves light. Spread out to win, but not so thin, that you shed skin.
