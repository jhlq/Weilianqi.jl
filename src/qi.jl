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

function loadgame(name::String,backtrack::Integer=0)
	game=newgame()
	path=joinpath(homedir(),"weilianqi","saves",name)
	lines=readlines(path)
	seqstr=lines[end-backtrack]
	loadsequence!(game,seqstr)
	game.name=name
	return game
end
