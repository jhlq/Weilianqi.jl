include("functions.jl")

function standard_live!(game,unit,lifemap)
	spreadlife!(game,unit,lifemap)
end
function standard_harvest!(game,unit)
	unitharvest!(game,unit)
end
function standard_costfun(game,unit)
	distance=nearestwhite(game,unit.loc,unit.loc[3]==2)
	cost=distance*unitparams[2]
	cost*=sum(unitparams[1]) #only if sum>1? How do we create such units? Are smaller units good? Do they take less space?
	return cost
end
units=Dict("standard"=>Dict(:live! => standard_live!,:harvest! => standard_harvest!,:name => "standard"),:costfun => standard_costfun)
function white_harvest!(game,unit)
	p=[12,0,0,0,12]
	game.points.+=p
	return p
end
function white_costfun(game,unit)
	return unit.ir*100
end
units["white"]=Dict(:harvest! =>white_harvest!,:name=>"white",:inclusive=>true,:passover=>true,:baselife=>18,:costfun=>white_costfun,:canspawn=>true)
