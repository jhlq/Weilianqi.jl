include("types.jl")
include("functions.jl")
include("units.jl")
include("gamefuns.jl")
include("newfuns.jl")

function distance(loc1,loc2=(0,0,2))
	oloc=loc1.-loc2
	m=max(abs(oloc[1]),abs(oloc[2]))
	return max(m,abs(oloc[1]+oloc[2]))+oloc[3]
end
function save(game)
	dic=Dict()
	dic[:name]=game.name
	dic[:shells]=game.board.shells
	dic[:initlocs]=game.board.initlocs
	dic[:colind]=game.colind
	dic[:colmax]=game.colmax
	dic[:colock]=game.colock
	dic[:delete]=game.delete
	dic[:sequence]=[]
	for entry in game.sequence
		if isa(entry,Unit)
			unit=entry
		#elseif !isa(entry,Symbol) && length(entry)>1 && isa(entry[2],Unit)
		#	unit=entry[2]
		else
			push!(dic[:sequence],entry)
			continue
		end
		udic=Dict()
		udic[:name]=unit.name
		udic[:color]=unit.color
		udic[:loc]=unit.loc
		push!(dic[:sequence],udic)
	end
	dir=joinpath(homedir(),"weilianqi","saves",game.name)
	if !ispath(dir)
		touch(dir)
	end
	io=open(dir,"a+")
	write(io,string(dic),"\n")
	close(io)
	println("Saved $(length(game.units)) units at $dir")
end
function loadsequence!(game::Game,seq,originoffset=(0,0,0))
	for entry in seq
		if entry==:harvest
			harvest!(game)
		elseif entry[1]==:expand
			expandboard!(game,entry[2]...,false)
		else
			(loc,unit)=entry
			loco=loc.+originoffset
			placeunit!(game,unit)
		end
	end
	return "<3"
end
function loadic(dic::Dict,originoffset=(0,0,0))
	#game.board=newboard(dic[:shells],dic[:initlocs]) #seeeegfault
	game=newgame(dic[:name],[dic[:shells],dic[:initlocs]],sequence=[])
	game.colind=dic[:colind]
	game.color=game.colors[game.colind]
	game.colmax=dic[:colmax]
	game.colock=dic[:colock]
	setproperty!(game.gui[:colockcheck],:active,game.colock)
	game.delete=dic[:delete]
	setproperty!(game.gui[:deletecheck],:active,game.delete)
	for entry in dic[:sequence]
		if isa(entry,Dict)
			if entry[:name]=="spawn";entry[:name]="queen";end
			unit=newunit(entry)
			unit.loc=unit.loc.+originoffset
			placeunit!(game,unit)
		elseif entry==:harvest
			harvest!(game)
		elseif entry[1]==:expand
			expandboard!(game,entry[2][1],entry[2][2],false) #loadicing
		elseif entry[1]==:delete
			removeunit!(game,entry[2])
		end
	end
	return game
end
function string2game(lastlineofsavefile)
	dic=eval(parse(lastlineofsavefile))
	return loadic(dic)
end
function loadgame(name::String,backtrack::Integer=0)
	path=joinpath(homedir(),"weilianqi","saves",name)
	lines=readlines(path)
	dic=eval(parse(lines[end-backtrack]))
	if isa(dic,Dict)
		game=loadic(dic)
	else
		game=newgame(name)
		loadsequence!(game,dic)
	end
	return game	
end

