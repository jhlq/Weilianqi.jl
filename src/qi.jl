include("units.jl")
include("gamefuns.jl")
include("newfuns.jl")

function allowedat(unitparams,loc)
	yes=true
	if !in(loc[3],unitparams[3])
		yes=false
	end
	return yes
end


function getexpandcost(shells::Integer=6,initlocs=[(6,6,2)],basecost=50)
	patch=makegrid(shells,initlocs)
	cost=length(patch)+basecost*length(initlocs)
	return cost
end
function distance(loc1,loc2=(0,0,2))
	oloc=loc1.-loc2
	m=max(abs(oloc[1]),abs(oloc[2]))
	return max(m,abs(oloc[1]+oloc[2]))+oloc[3]
end
function save(game)
	dir=joinpath(homedir(),"weilianqi","saves",game.name)
	if !ispath(dir)
		touch(dir)
	end
	io=open(dir,"a+")
	write(io,string(game.sequence),"\n")
	close(io)
end
#savelite=(game)->write("~/.weilianqi/$(round(Integer,time())).txt","$(game.sequence)")
function loadsequence!(game::Game,seqstr::String,originoffset=(0,0,0))
	seq=eval(parse(seqstr))
	for entry in seq
		if entry==:harvest
			harvest!(game)
		elseif entry[1]==:expand
			expandboard!(game,entry[2]...,false)
		else
			(loc,unit)=entry
			loco=loc.+originoffset
			placeunit!(game,unit)
#			game.map[loco]=unit
#			push!(game.sequence,(loco,unit))
		end
	end
	#GAccessor.text(game.g[1,2],pointslabel(game))
	#drawboard(game)
	return true
end
function loadgame(name::String,backtrack::Integer=0)
	game=newgame(name)
	path=joinpath(homedir(),"weilianqi","saves",name)
	lines=readlines(path)
	seqstr=lines[end-backtrack]
	loadsequence!(game,seqstr)
	return game
end
