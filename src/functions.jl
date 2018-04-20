include("types.jl")

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

function influence(game,hex,groundlevel=false,passover=false,passoverself=true,inclusive=true)
	unit=game.map[hex]
	white=(1,1,1)
	group=Dict(hex=>6.0)
	temp=Dict(hex=>6.0)
	for rad in 1:unit.ir
		temp2=Dict()
		for t in temp
			for h in adjacent(t[1],1,groundlevel)
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
function allinfluence(game,groundlevel=false,bools=(true,false,true,true))
	influencemap=Dict()
	for (loc,player) in game.map
		if !groundlevel || loc[3]==2
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
function peekharvest(game,groundlevel=false,bools=(true,false,true,true))
	influencemap=allinfluence(game,groundlevel,bools)
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
function spreadlife!(game,unit,lifemap)
	white=(1,1,1)
	hex=unit.loc
	lifemap[hex].+=unit.baselife.*unit.color
	temp=Dict(hex=>unit.baselife)
	checked=[hex]
	for rad in 1:unit.ir
		temp2=Dict()
		for t in temp
			for h in adjacent(t[1],1,unit.groundlevel)
				if !in(h,keys(temp)) && !in(h,keys(temp2)) && !in(h,checked) && in(h,game.board.grid) 
					lif=(unit.baselife/6/rad).*unit.color
					if game.map[h]==0 || unit.passover
						temp2[h]=lif
					elseif unit.passoverself && (game.map[h].color==unit.color || game.map[h].color==white)
						temp2[h]=lif
					elseif unit.inclusive && game.map[h]!=0 #&& !in(h,keys(temp2))
						lifemap[h].+=lif
					end
				end
				push!(checked,h)
			end
		end
		for (h2,i2) in temp2
			lifemap[h2].+=i2
		end
		temp=temp2
	end
	return lifemap
end
function allunitslive!(game)
	lifemap=Dict()
	for loc in game.board.grid
		lifemap[loc]=[0.0,0,0]
	end
	for (loc,unit) in game.map
		if isa(unit,Unit)
			unit.live!(game,unit,lifemap)
		end
	end
	game.lifemap=lifemap
	return lifemap
end
function getpoints!(game,unit,loc,distance)
	l=game.lifemap[loc]
	lif=distance==0?unit.baselife:(unit.baselife/6/distance)
	ncol=numcolors(l)
	points=[0.0,0,0,0,0]
	if ncol==3
		points[5]=min(min(l...),lif)
		l.-=points[5]
		lif-=points[5]
	end
	if ncol==1 && game.map[loc]==0
		ci=l[1]==0?(l[2]==0?3:2):1
		points[1]=min(l[ci],lif)
		game.lifemap[loc][ci]-=points[1]
		lif-=points[1]
	else
		lifc=lif.*unit.color
		for c in 1:3
			if lifc[c]>0
				points[c+1]+=min(lifc[c],l[c%3+1])
				game.lifemap[loc][c%3+1]-=points[c+1]
			end
		end
	end
	game.points.+=points
	#println(points,loc)
	return points
end
function unitharvest!(game,unit)
	white=(1,1,1)
	#lifemap[hex]+=unit.baselife.*unit.color
	getpoints!(game,unit,unit.loc,0)
	temp=[unit.loc]
	checked=[unit.loc]
	points=[0.0,0,0,0,0]
	for rad in 1:unit.ir
		temp2=[]
		for t in temp
			for h in adjacent(t,1,unit.groundlevel)
				if !in(h,temp) &&!in(h,checked) && in(h,game.board.grid) 
#					lif=(unit.baselife/6/rad).*unit.color
					if game.map[h]==0 || unit.passover
						points+=getpoints!(game,unit,h,rad)
						push!(temp2,h)
					elseif unit.passoverself && (game.map[h].color==unit.color || game.map[h].color==white)
						points+=getpoints!(game,unit,h,rad)
						push!(temp2,h)
					elseif unit.inclusive && game.map[h]!=0
						points+=getpoints!(game,unit,h,rad)
					end
				end
				push!(checked,h)
			end
		end
#		for (h2,i2) in temp2
#			lifemap[h2].+=i2
#		end
		temp=temp2
	end
	return points
end
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
	return points
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
function printpoints(game)
	harv=round.(peekharvest(game),1,10)
	println("Black: ",harv[1]," Red: ",harv[2]," Green: ",harv[3]," Blue: ",harv[4]," White: ",harv[5])#," Total: ",sum(harv))
end
function nearestwhite(game,hex,layer=false)
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
function hex_to_pixel(q,r,size)
    x = size * sqrt(3) * (q + r/2)
    y = size * 3/2 * r
    return x, y
end
function pixel_to_hex(x,y,size)
    q = (x * sqrt(3)/3 - y / 3) / size
    r = y * 2/3 / size
    return (q, r)
end

function triangle(ctx,x,y,size,up=-1)
	polygon(ctx, [Point(x,y),Point(x+size,y),Point(x+size/2,y+up*size)])
	fill(ctx)
end
function hexlines(ctx,x,y,size)
	size*=2
	move_to(ctx,x-size/4,y-size*sin(pi/3)/2)
	rel_line_to(ctx,size/2,size*sin(pi/3))
	move_to(ctx,x-size/2,y)
	rel_line_to(ctx,size,0)
	move_to(ctx,x+size/4,y-size*sin(pi/3)/2)
	rel_line_to(ctx,-size/2,size*sin(pi/3))
	stroke(ctx)
end

