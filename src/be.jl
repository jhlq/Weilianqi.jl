saveseq=(game)->write("saves/$(round(Integer,time())).txt","$(game.sequence)")
function placeseq(seq,map,originoffset=(0,0,0))
	for (loc,unit) in seq
		map[loc.+originoffset]=unit
	end
end
function loadseq(filename,originoffset=(0,0,0))
	push!(storage[:sequence],eval(parse(read("saves/"*filename,String))))
	placeseq()
end

function makegrid(layers=3,startlocs=[(0,0,2)])
	grid=Set{Tuple}()
	push!(grid,startlocs...)
	connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0), (0,0,1),(1,0,1),(0,1,1),(0,0,-1),(1,0,-1),(1,-1,-1)]
	for layer in 1:layers
		tgrid=Array{Tuple,1}()
		for loc in grid
			if loc[3]==2
				for c in connections
					x,y,z=loc
					x+=c[1];y+=c[2];z+=c[3]
					push!(tgrid,(x,y,z))
				end
			end
		end
		for t in tgrid
			push!(grid,t)
		end
	end
	return grid
end
function adjacent(hex,spacing=1,layer=false)
	connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0), (0,0,1),(1,0,1),(0,1,1),(0,0,-1),(1,0,-1),(1,-1,-1)]
	if layer
		connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0)]
	end
	if hex[3]==1
		if layer
			connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0)]
		else
			connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0), (0,0,1),(-1,0,1),(-1,1,1)]
		end
	elseif hex[3]==3
		if layer
			connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0)]
		else
			connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0),(0,0,-1),(-1,0,-1),(0,-1,-1)]
		end
	end
	adj=Array{Tuple,1}()
	for c in connections
		x,y,z=hex
		x+=spacing*c[1];y+=spacing*c[2];z+=spacing*c[3]
		push!(adj,(x,y,z))
	end
	return adj
end
function placewhite(spacing::Integer,ori=(0,0,2))
	white=length(storage[:players])
	if !haskey(storage[:map],ori) || storage[:map][ori]==white
		return
	end
	storage[:map][ori]=white
	push!(storage[:sequence],(ori,white))
	adj=adjacent(ori,spacing,true)
	for ad in adj
		placewhite(spacing,ad)
	end
end

function initgame(startlocs=[(0,0,2)])
	storage[:grid]=makegrid(storage[:layers],startlocs)
	storage[:map]=Dict((0,0,2)=>0)
	for loc in storage[:grid]
		storage[:map][loc]=0
	end
	placewhite(storage[:spacing]) 
end

function resetmap(game)
	for loc in game.board.grid
		game.map[loc]=0
	end
	drawboard(game)
	reveal(game.board.c)
end



function getgroup(game,hex)
	player=game.map[hex]
	white=(1,1,1)
	if player==0
		return []
	end
	group=Tuple[hex]
	temp=[hex]
	while !isempty(temp)
		temp2=Tuple[]
		for t in temp
			for h in adjacent(t)
				if !in(h,group) && !in(h,temp) && !in(h,temp2) && in(h,keys(game.map)) && (game.map[h]==player || game.map[h]==white)
					push!(temp2,h)
				end
			end
		end
		for t2 in temp2
			push!(group,t2)
		end
		temp=temp2
	end
	return group
end
function liberties(group)
	if isempty(group)
		return 1
	end
	checked=Tuple[]
	libs=0
	for hex in group
		for h in adjacent(hex)
			if !in(h,group) && !in(h,checked) && in(h,keys(storage[:map]))
				if storage[:map][h]==0
					libs+=1
				end
				push!(checked,h)
			end
		end
	end
	return libs
end
function connections()
	nc=0
	for (loc,col) in storage[:map]
		if col>0 
			for c in adjacent(loc)
				if in(c,keys(storage[:map]))
					ac=storage[:map][c]
					if ac!=0 && ac!=col
						nc+=1
					end
				end
			end
		end
	end
	return nc/2
end
function freelocs(layer=2)
	free=0
	tot=0
	for (loc,col) in storage[:map]
		if loc[3]==layer
			tot+=1
			if col==0
				free+=1
			end
		end
	end
	return (free,tot)
end

function influence(game,hex,layer=true,passover=false,passoverself=true,inclusive=true)
	unit=game.map[hex]
	white=(1,1,1)
	group=Dict(hex=>6.0)
	temp=Dict(hex=>6.0)
	for rad in 1:unit.ir
		temp2=Dict()
		for t in temp
			for h in adjacent(t[1],1,layer)
				if !in(h,keys(group)) && !in(h,keys(temp)) && !in(h,keys(temp2)) && in(h,keys(game.map)) 
					inf=1/rad
					if game.map[h]==0 || passover
						temp2[h]=inf
					elseif passoverself && (game.map[h].color==unit.color || game.map[h].color==white)
						temp2[h]=inf
					end
					if inclusive && game.map[h]!=0 && !in(h,keys(temp2))
						group[h]=inf
					end
				end
			end
		end
		for (h2,i2) in temp2
			group[h2]=i2
		end
		temp=temp2
	end
	return group
end
function allinfluence(game,layer=2,bools=(true,false,true,true))
	influencemap=Dict()
	for (loc,player) in game.map
		if loc[3]==layer
			influencemap[loc]=[0.0,0,0]
		end
	end
	for (loc,unit) in game.map
		if unit!=0
			col=unit.color
			infl=influence(game,loc,bools...)
			for inf in infl
				influencemap[inf[1]].+=inf[2].*col
			end
		end
	end
	return influencemap
end
function numcolors(rgb)
	nc=0
	for c in rgb
		if c>0
			nc+=1
		end
	end
	return nc
end
function peekharvest(game,layer=2,bools=(true,false,true,true))
	influencemap=allinfluence(game,layer,bools)
	brgbw=[0.0,0,0,0,0]
	for (iloc,inf) in influencemap
		ninf=numcolors(inf)
		if ninf==3
			brgbw[5]+=min(inf...)
		end
		if ninf==1
			brgbw[1]+=min(sum(inf),1)
		else
			for c in 1:3
				brgbw[c+1]+=min(inf[c],inf[c%3+1])
			end
		end
	end
	for c in 2:4
		brgbw[c]-=brgbw[5]
	end
	return brgbw
end

function undo() #wont undo captures?
	hex=pop!(storage[:sequence])
	storage[:map][hex[1]]=0
	storage[:player]=storage[:player]-1
	if storage[:player]<1
		storage[:player]=storage[:np]
	end
	return hex
end
function pass()
	storage[:player]=storage[:player]%storage[:np]+1
end
function printpoints(game)
	harv=round.(peekharvest(game),1,10)
	println("Black: ",harv[1]," Red: ",harv[2]," Green: ",harv[3]," Blue: ",harv[4]," White: ",harv[5])#," Total: ",sum(harv))
end
function nearestwhite(game,hex,layer=true)
	white=(1,1,1)
	group=[hex]
	temp=[hex]
	for rad in 1:game.board.shells*9
		temp2=[]
		for t in temp
			for h in adjacent(t,1,layer)
				if in(h,keys(game.map))
					unit=game.map[h]
					if unit!=0 && unit.color==white
						return rad
					end
					if !in(h,group) && !in(h,temp) && !in(h,temp2)  
						push!(temp2,h)
					end
				end
			end
		end
		for h2 in temp2
			push!(group,h2)
		end
		temp=temp2
	end
	return Inf
end

