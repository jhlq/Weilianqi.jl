function allunitsharvest!(game)
	#groundlevel=false
	#if unit.pl=[2]
	#	groundlevel=true
	#end
	#bools=(unit.passover,unit.passoverself,unit.inclusive)
	#influencemap=allinfluence(game,unit.groundlevel,bools)
	allunitslive!(game)
	points=[0.0,0,0,0,0]
	for (loc,unit) in game.map
		if unit!=0
			points.+=unit.harvest!(game,unit)
#			println(points)
		end
	end
	#game.points.+=points
	game.season+=1
	push!(game.sequence,:harvest)
	GAccessor.text(game.g[1,2],pointslabel(game))
	return points
end


