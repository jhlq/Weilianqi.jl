colorsets=[[(1,0,0),(0,1,0),(0,0,1),(1/2,0,1/2),(0.15,0.7,0.15)],[(1,0,0),(0,1,0),(0,0,1),(1/2,1/2,0),(1/2,0,1/2),(0,1/2,1/2),(0.15,0.7,0.15)]]
setcolorset=(game,set::Int=2)->game.colors=colorsets[set] #modify game.color to set a temporary custom color

units=Dict("standard"=>Dict(:name=>"standard", :ir=>2, :pl=>[2])) #change :pl to [1,2,3] to place anywhere

units["tunnel"]=Dict(:name=>"tunnel", :ir=>0, :pl=>[1]) #these by default cannot be placed under/over surrounded territory without permission, such permissions are not hard coded but may rather result in a rejected/modified merge request
units["bridge"]=Dict(:name=>"bridge", :ir=>0, :pl=>[3])
units["queen"]=Dict(:name=>"queen", :canspawn=>true, :graphic=>[(0.5,0.5),(-0.5,0.5),(0,-0.5)])
units["universal"]=Dict(:name=>"universal", :pl=>[1,2,3])

#white unit is a spawn for all colors whereas any unit with color (1,1,1) "is" every color, so a white spawn is a spawn for all and "white" as a unit spec can be removed. White superpowers are being removed 
#=
function white_harvest(game,unit)
	p=[12,0,0,0,12]
	#game.points.+=p
	return p
end
units["white"]=Dict(:harvest=>white_harvest, :name=>"white", :inclusive=>true, :passover=>true, :baselife=>18, :canspawn=>true)
=#
function standard_costfun(game,unit) #costs have been removed, our hive will dispatch all units proposed that create agreeable formations 
	distance=nearestwhite(game,unit.loc,unit.loc[3]==2)
	cost=distance*unitparams[2]
	cost*=sum(unitparams[1]) #only if sum>1? How do we create such units? Are smaller units good? Do they take less space?
	return cost
end
function standard_live!(game,unit,lifemap)
	spreadlife!(game,unit,lifemap)
end
function standard_harvest(game,unit,ledger)
	unitharvest(game,unit,ledger)
end
standard_harvest! =standard_harvest #for savefile backwardscompat

