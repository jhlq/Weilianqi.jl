#importall Weilianqi #Why doesn't this work?

game=newgame()
unit=newunit((0,0,1),(3,1,2))
placeunit!(game,unit)
@test isa(game.map[(3,1,2)],Unit)
