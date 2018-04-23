include("types.jl")

#saveseq=(game)->write("saves/$(round(Integer,time())).txt","$(game.sequence)")
function placeseq(seq,map,originoffset=(0,0,0))
	for (loc,unit) in seq
		map[loc.+originoffset]=unit
	end
end
function loadseq(filename,originoffset=(0,0,0))
	push!(storage[:sequence],eval(parse(read("saves/"*filename,String))))
	placeseq()
end

function makegrid(layers=3,startlocs=[(0,0,2)],groundlevel=false)
	grid=Set{Tuple}()
	push!(grid,startlocs...)
	connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0), (0,0,1),(1,0,1),(0,1,1),(0,0,-1),(1,0,-1),(1,-1,-1)]
	if groundlevel
		connections=[(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(1,-1,0),(-1,1,0)]
	end
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
#=
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
=#
#=
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
=#
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

function numcolors(rgb)
	nc=0
	for c in rgb
		if c>0
			nc+=1
		end
	end
	return nc
end

function irlocs(unit::Unit)
	return makegrid(unit.ir,[unit.loc],unit.groundlevel)
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

