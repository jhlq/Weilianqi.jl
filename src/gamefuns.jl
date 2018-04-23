function adjacent(game,unit::Unit)
	hadj=adjacent(unit.loc)
	adj=Unit[]
	for h in hadj
		u=game.map[h]
		if isa(u,Unit)
			push!(adj,u)
		end
	end
	return adj 
end
function resetmap(game)
	for loc in game.board.grid #keys(game.map)? No, offgrid locations are safe
		game.map[loc]=0
	end
	drawboard(game)
	reveal(game.board.c)
end

function getgroup_dep(game,hex)
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
function getcellgroup(game,unit::Unit)
	white=(1,1,1)
	group=[unit]
	if unit.color==white 
		adju=adjacent(game,unit)
		for u in adju
			g=getcellgroup(game,u) #can this be optimized when there are several white units?
			for gu in g
				if !in(gu,cellgroup)
					push!(cellgroup,gu)
				end
			end
		end
		return group
	end
	temp=[unit]
	while !isempty(temp)
		temp2=Unit[]
		for t in temp
			for h in adjacent(t.loc)
				tu=game.map[h]
				if !in(tu,cellgroup) && !in(tu,temp) && !in(tu,temp2) && isa(tu,Unit) && (tu.color==unit.color || tu.color==white)
					push!(temp2,tu)
				end
			end
		end
		for t2 in temp2
			push!(cellgroup,t2)
		end
		temp=temp2
	end
	return cellgroup
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
function spreadlife(game,unit)
	lifemap=Dict()
	for loc in game.board.grid
		lifemap[loc]=[0.0,0,0]
	end
	return spreadlife!(game,unit,lifemap)
end
function unitslive(game,color)
	lifemap=Dict()
	for loc in game.board.grid
		lifemap[loc]=[0.0,0,0]	#this is sometimes redundant and sometimes needed...
	end
	for (loc,unit) in game.map
		if isa(unit,Unit) && (color==(1,1,1) || unit.color==color || unit.color==(1,1,1))
			unit.live!(game,unit,lifemap)
		end
	end
	return lifemap
end

function lifluence(game,unit::Unit)
	lifemap=unitslive(game,unit.color)
	connectedunits=Unit[unit]
	cwhite=Unit[]
	group=[unit.loc]
	if unit.color==(1,1,1)
		push!(cwhite,unit)
		stuff=Dict()
		#stuff[:loced]=[unit.loc]
		reach=makegrid(7)
		for loc in reach
			u=game.map[loc]
			if isa(u,Unit) && u.color!=(1,1,1) && !haskey(stuff,u.color)	#!in(loc,stuff[:loced])
				lmu=lifluence(game,u)
				if in(unit,lmu[3])
					stuff[u.color]=lmu
				end
			end
		end
		for (col,lm) in stuff
			for l in lm[1]
				if !in(l,group)
					push!(group,l)
				end
			end
			for cu in lm[2]
				if !in(cu,connectedunits)
					push!(connectedunits,cu)
				end
			end
			for cw in lm[3]
				if !in(cw,cwhite)
					push!(cwhite,cw)
				end
			end
		end
		return (group,connectedunits,cwhite)
	end
	temp=[unit.loc]
	while !isempty(temp)
		temp2=Tuple[]
		for t in temp
			for h in adjacent(t)
#				lmt=lifemap[t]
#				lmh=lifemap[h]
#				canspread=true
				if !in(h,group) && !in(h,temp) && !in(h,temp2) && in(h,game.board.grid) && sum(lifemap[h])>0
					push!(temp2,h)
					u=game.map[h]
					if isa(u,Unit) 
						push!(connectedunits,u)
						if u.color==(1,1,1)
							push!(cwhite,u)
						end
					end
				end
			end
		end
		for t2 in temp2
			push!(group,t2)
		end
		temp=temp2
	end
	return (group,connectedunits,cwhite)
end
function placeseq!(game)
	for (loc,unit) in game.sequence
		if game.map[loc]!=0
			error("Something in the way at $loc")
		end
		if unit.canspawn
			push!(game.spawns,unit)
		end
		game.map[loc]=unit
	end
end
function getgroup(game,unit::Unit,color=-1,connectedunits=Unit[],lifemap=-1) #why don't white units get added to spawns? Maybe they shouldn't, bug in our favor. They should be available as partial spawns, divide white into 3 spawn units
	if color==-1
		color=unit.color
	end
#	if lifemap==-1
		lifemap=unitslive(game,unit.color)
#	end
	if !in(unit,connectedunits)
		push!(connectedunits,unit)
	end
	cwhite=Unit[]
	if color==(1,1,1)
		push!(cwhite,unit)
		stuff=Dict()
		reach=makegrid(7)
		for lo in reach
			loc=lo.+(unit.loc.-(0,0,2))
			if !in(loc,keys(game.map))
				continue
			end
			u=game.map[loc]
			if isa(u,Unit) && !haskey(stuff,u.color) && !in(u,connectedunits) && u.color!=(1,1,1)
				subgroup=getgroup(game,u,u.color,connectedunits)#,lifemap)
				if in(unit,subgroup.spawns)
					stuff[u.color]=subgroup
				end
				#lmu=lifluence(game,u)
				#if in(unit,lmu[3])
				#	stuff[u.color]=lmu
				#end
			end
		end
		for (col,sg) in stuff
			#for l in lm[1]
			#	if !in(l,ulocs)
			#		push!(ulocs,l)
			#	end
			#end
			for cu in sg.units #lm[2]
				if !in(cu,connectedunits)
					push!(connectedunits,cu)
				end
			end
			for cw in sg.spawns #lm[3]
				if !in(cw,cwhite)
					push!(cwhite,cw)
				end
			end
		end
		#return (group,connectedunits,cwhite)
		return newgroup(cwhite,connectedunits)
	end
	ulocs=[unit.loc]
	temp=[unit.loc]
	while !isempty(temp)
		temp2=Tuple[]
		for t in temp
			for h in adjacent(t)
				if !in(h,ulocs) && !in(h,temp) && !in(h,temp2) && in(h,game.board.grid) && sum(lifemap[h])>0 
					push!(temp2,h)
					u=game.map[h]
					if isa(u,Unit) && !in(u,connectedunits)
						push!(connectedunits,u)
						if u.color==(1,1,1)
							push!(cwhite,u)
							for adjwu in adjacent(u.loc)
								adju=game.map[adjwu]
								if isa(adju,Unit) && adju.color==color && !in(adju,connectedunits)
									nsg=getgroup(game,adju,color,connectedunits)#,lifemap)
									for cu in nsg.units 
										if !in(cu,connectedunits)
											push!(connectedunits,cu)
										end
									end
									for cw in nsg.spawns
										if !in(cw,cwhite)
											push!(cwhite,cw)
										end
									end
								end
							end
						end
					end
				end
			end
		end
		for t2 in temp2
			push!(ulocs,t2)
		end
		temp=temp2
	end
#	return (group,connectedunits,cwhite)
	return newgroup(cwhite,connectedunits)
end
function samegroup(group1::Group,group2::Group)
	for unit in group1.units
		if !in(unit,group2.units)
			return false
		end
	end
	return true
end
function updategroups!(game::Game)
	groups=Group[]
	for spawn in game.spawns
		push!(groups,getgroup(game,spawn))
	end
	unique=Group[groups[1]]
	for group in groups
		notin=true
		for uniq in unique
			if samegroup(group,uniq)
				notin=false
				break
			end
			push!(unique,group)
		end
	end
	game.groups=unique	
end
function connectedunits(game,unit)
	(lif,cu,cw)=lifluence(game,unit)
	cellconnected=getcellgroup(game,unit)
	return (cw,cellconnected,cu) #connected white units, connected by cells, connected by lifluence
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
		if numcolors(l)==1
			l[1]=0;l[2]=0;l[3]=0
		end
	end
	if ncol==1 && game.map[loc]==0
		ci=l[1]==0?(l[2]==0?3:2):1
		if l[ci]>1;l[ci]=1;end
		h=min(l[ci],lif,1)
		points[1]=h
		l[ci]-=h
#		if h>=1
#			game.lifemap[loc][ci]=0
#		else
##			game.lifemap[loc][ci]=(1-h)
#		end
	else
		lifc=lif.*unit.color
		for c in 1:3
			if lifc[c]>0
				points[c+1]+=min(lifc[c],l[c%3+1])
				game.lifemap[loc][c%3+1]-=points[c+1]
			end
		end
		if numcolors(l)==1
			l=[0,0,0]
		end
	end
	game.points.+=points
	#println(points,loc)
	return points
end
function unitharvest!(game,unit)
	points=[0.0,0,0,0,0]
	if unit.harvested
		return points
	end

	white=(1,1,1)
	#lifemap[hex]+=unit.baselife.*unit.color
	points+=getpoints!(game,unit,unit.loc,0)
	temp=[unit.loc]
	checked=[unit.loc]
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

function checkharvest(game,unit::Unit)
	return unit.harvest!(game,unit)
end
function checkharvest(game,group::Group)
	points=[0.0,0,0,0,0]
	for unit in group.units
		if unit!=0
			points.+=checkharvest(game,unit)
		end
	end
	return points
end
function checkharvest(game::Game)
	game=deepcopy(game) #this is silly, remove ! from unit.harvest!
	allunitslive!(game)
	points=[0.0,0,0,0,0]
	for group in game.groups
		points+=checkharvest(game,group)
	end
	return points
end
function harvest!(game,group::Group)
	if !group.harvested
		harv=checkharvest(game,group) #some stuff needs to be rewritten to avoid the deepcopy above
		group.points+=harv
		group.harvested=true
		for unit in group.units
			unit.harvested=true
		end
	end
end
function allgroupsharvest!(game)
	for group in game.groups
		harvest!(game,group)
	end
end

function collectharvest!(game::Game)
	for group in game.groups
		game.points+=group.points
		#println(game.points)
		group.points-=group.points
	end
end
function newseason!(game)
	for group in game.groups
		group.harvested=false
		for unit in group.units
			unit.harvested=false
		end
	end
	game.season+=1
end
function harvest!(game::Game)
	allunitslive!(game) #maybe call only when new units are placed. But then placing units takes longer...
	updategroups!(game)
	allgroupsharvest!(game)
	collectharvest!(game)
	newseason!(game)
	push!(game.sequence,:harvest)
	GAccessor.text(game.g[1,2],pointslabel(game))
	return game.points
end
function unitcost(game,loc,unitparams)
	distance=nearestwhite(game,loc,loc[3]==2)
	cost=distance*unitparams[2]
	cost*=sum(unitparams[1]) #only if sum>1?
	return cost
end
function unitcost(game,unit::Unit)
	return unit.costfun(game)
end
function subtractcost(game,cost,color)
	rgb=cost.*color
	srgb=sum(rgb)
	if rgb[1]<=game.points[2] && rgb[2]<=game.points[3] && rgb[3]<=game.points[4]
		game.points[2]-=rgb[1]
		game.points[3]-=rgb[2]
		game.points[4]-=rgb[3]
	elseif srgb/2<=game.points[5] && srgb/2<=game.points[1]
		game.points[1]-=srgb/2
		game.points[5]-=srgb/2
	else
		return false
	end
	return true
end
function pointslabel(game)
#	points=round.(game.points,3)
	points=round.(checkharvest(game),3)
	return "Points!\nBlack:\t$(points[1]) \nRed:\t$(points[2]) \nGreen:\t$(points[3]) \nBlue:\t$(points[4]) \nWhite: $(points[5]) \nSeason: $(game.season) "
end

function undo!(game) #wont undo captures? Maybe when reloading sequence
	hex=pop!(game.sequence)
	game.map[hex[1]]=0
	game.colind-=1
	if game.colind<1
		game.colind=game.colmax
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

function drawboard(game,ctx,w,h)
	game.board.size=game.window[2]/(game.board.shells*game.board.sizemod)
	size=game.board.size
	rectangle(ctx, 0, 0, w, h)
	set_source_rgb(ctx, game.board.bgcolor...)
	fill(ctx)
	set_source_rgb(ctx, game.color...)
	arc(ctx, size, size, 3size, 0, 2pi)
	fill(ctx)
	set_source_rgb(ctx, game.board.gridcolor...)
	for loc in game.board.grid
		if loc[3]==2
			x,y=hex_to_pixel(loc[1],loc[2],size)
			hexlines(ctx,x+w/2+game.board.offsetx,y+h/2+game.board.offsety,size)
		end
	end
	for move in game.map
		if move[2]!=0
			set_source_rgb(ctx,move[2].color...)
			offset=(game.board.offsetx,game.board.offsety)
			if move[1][3]==1
				offset=offset.+(-cos(pi/6)*size,sin(pi/6)*size)
			elseif move[1][3]==3
				offset=offset.+(-cos(pi/6)*size,-sin(pi/6)*size)
			end
			loc=hex_to_pixel(move[1][1],move[1][2],size)
			arc(ctx, loc[1]+offset[1]+w/2, loc[2]+offset[2]+h/2, size*0.866/2, 0, 2pi) #why isn't the circle radius the distance between locs?
			fill(ctx)
			#set_source_rgb(ctx,game.board.gridcolor...)
			#arc(ctx, loc[1]+offset[1]+w/2, loc[2]+offset[2]+h/2, size/3, 0, 2pi)
			#stroke(ctx)
		end
	end
	#showall(game.board.win)
	reveal(game.board.c)
	GAccessor.text(game.g[1,2],pointslabel(game))
end
function drawboard(game::Game)
	#println(game.points)
	ctx=getgc(game.board.c)
	h=height(game.board.c)
	w=width(game.board.c)
	drawboard(game,ctx,w,h)
end

function expandboard!(game::Game,shells::Integer=6,initlocs=[(6,6,2)],basecost=-1,reveal=true)
	patch=makegrid(shells,initlocs)
#	basecost=game.board.expandbasecost
#	if basecost==-1
#		for iloc in initlocs
#			basecost+=distance(iloc)*10 #should be distance from spawn
#		end
#	end
#	cost=length(patch)+basecost*length(initlocs)
#	remains=game.points[1]-cost
#	if remains>=0
		for loc in patch
			if !in(loc,keys(game.map))
				game.map[loc]=0
				push!(game.board.grid,loc)
			end
		end
#		game.points[1]=remains
		push!(game.sequence,(:expand,[shells,initlocs,basecost]))
		if reveal
			drawboard(game)
		end
#	end
	return "<3"
end
function zoom(game,factor)
	game.board.sizemod*=factor
	drawboard(game)
end
function pass(game)
	game.colind=game.colind%game.colmax+1
	game.color=game.colors[game.colind]
	drawboard(game)
end

function center(game,hex)
	loc=hex_to_pixel(hex[1],hex[2],game.board.size)
	game.board.offsetx=-loc[1]
	game.board.offsety=-loc[2]
	drawboard(game)
	return true
end
