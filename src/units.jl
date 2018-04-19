include("functions.jl")

function standard_live!(game,unit,lifemap)
	spreadlife!(game,unit,lifemap)
end
function standard_harvest!(game,unit)
	unitharvest!(game,unit)
end
units=Dict("standard"=>Dict(:live! => standard_live!,:harvest! => standard_harvest!,:name => "standard"))
function white_harvest!(game,unit)
	p=[12,0,0,0,12]
	game.points.+=p
	return p
end
units["white"]=Dict(:harvest! => white_harvest!,:name => "white")
