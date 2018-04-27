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

function getcellgroup(game,unit::Unit)
	white=(1,1,1)
	cellgroup=[unit]
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
		return cellgroup
	end
	temp=[unit]
	while !isempty(temp)
		temp2=Unit[]
		for t in temp
			for h in adjacent(t.loc)
				if in(h,keys(game.map))
					tu=game.map[h]
					if !in(tu,cellgroup) && !in(tu,temp) && !in(tu,temp2) && isa(tu,Unit) && (tu.color==unit.color || tu.color==white)
						push!(temp2,tu)
					end
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


function placeseq!(game)
	for entry in game.sequence
		if isa(entry,Unit)
			placeunit!(game,entry)
		elseif entry==:harvest
			harvest!(game)
		elseif entry[1]==:expand
			expandboard!(game,entry[2]...,false)
		end
	end
end
function getgroup(game,unit::Unit,color=-1,connectedunits=Unit[]) #why don't white units get added to spawns? Maybe they shouldn't, bug in our favor. They should be available as partial spawns, divide white into 3 spawn units. Fixed some stuff, still good bugs? Well, this should be rewritten rather than bugged down, first a initgroup that gets the body.
	if color==-1
		color=unit.color
	end
	lifemap=unitslive(game,unit.color)
	if !in(unit,connectedunits)
		push!(connectedunits,unit)
	end
	cwhite=Unit[]
	if color==(1,1,1) #this needs to be rewritten to allow colored spawns, sorta works now but... nonbody groups autojoin white group
		push!(cwhite,unit)
		stuff=Dict()
		reach=makegrid(7) #should be minimum twice the maximum ir of all units +1
		for lo in reach
			loc=lo.+(unit.loc.-(0,0,2))
			if !in(loc,keys(game.map))
				continue
			end
			u=game.map[loc]
			if isa(u,Unit) && distance(u.loc,unit.loc)<(u.ir+unit.ir+2) && !haskey(stuff,u.color) && !in(u,connectedunits) && u.color!=(1,1,1)
				subgroup=getgroup(game,u,u.color,connectedunits)
				if in(unit,subgroup.spawns)
					stuff[u.color]=subgroup
				end
			end
		end
		for (col,sg) in stuff
			for cu in sg.units 
				if !in(cu,connectedunits)
					push!(connectedunits,cu)
				end
			end
			for cw in sg.spawns
				if !in(cw,cwhite)
					push!(cwhite,cw)
				end
			end
		end
		body=getcellgroup(game,cwhite[1])
		return newgroup(cwhite,body,connectedunits)
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
									nsg=getgroup(game,adju,color,connectedunits)
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
	body=getcellgroup(game,connectedunits[1])
	return newgroup(cwhite,body,connectedunits)
end
function samegroup(group1::Group,group2::Group)
	for unit in group1.units
		if !in(unit,group2.units)
			return false
		end
	end
	return true
end
function updategroups!(game::Game) #sometimes doesn't find most recent unit..? Or is there an issue when deleting units? Maybe fixed
	groups=Group[]
	for spawn in game.spawns
		push!(groups,getgroup(game,spawn))
	end
	unique=Group[groups[1]]
	for group in groups
		for uniq in unique
			if samegroup(group,uniq)
				break
			end
			push!(unique,group)
		end
	end
	game.groups=unique	
end

function placeunit!(game,unit)
	if game.map[unit.loc]==0
		game.map[unit.loc]=unit
		if !in(unit,game.sequence) 
			push!(game.sequence,unit)
		end
		if !in(unit,game.units) 
			push!(game.units,unit)
		end
		if unit.canspawn && !in(unit,game.spawns)
			push!(game.spawns,unit)
		end
	end
	return "<3"
end
function removeunit!(game,unit::Unit)
	game.map[unit.loc]=0
	push!(game.sequence,(:delete,unit))
	i=findfirst(u->u==unit,game.units)
	if i>0
		deleteat!(game.units,i)
	end
	if unit.canspawn
		i=findfirst(u->u==unit,game.spawns)
		deleteat!(game.units,i)
	end
	return "<3"
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
#lifemap=allunitslive! #maybe not store lifemap in game since it gets modified in so many places. Rewrite everything to work with a temp lifemap. Or rather have a solid lifemap and a temp harvest ledger
function lifemap(game)
	lifemap=Dict()
	for loc in game.board.grid
		lifemap[loc]=[0.0,0,0]
	end
	for unit in game.units
		unit.live!(game,unit,lifemap)
	end
	return lifemap
end
function newledger(game)
	ledger=Dict()
	for loc in game.board.grid
		ledger[loc]=[[0.0,0,0],0.0,0,0,0]
	end
	return ledger
end
function getpoints!(game,unit,loc,distance,ledger)
	llm=game.lifemap[loc] #local lifemap
	ll=ledger[loc]
	lif=distance==0?unit.baselife:(unit.baselife/6/distance)
	ncol=numcolors(llm)
	l=llm.-ll[5]
	ncoll=numcolors(l)
	points=[[0.0,0,0],0.0,0,0,0]
	if ncol==3 && ncoll==3
		points[5]=min(min(l...),lif)
		#l.-=points[5]
		ll.+=points
		lif-=points[5]
		if numcolors(l)==1
			l[1]=0;l[2]=0;l[3]=0
		end
		l=llm.-ll[5]
	end
	if ncol==1 && game.map[loc]==0 && sum(ll[1])<1
		ci=l[1]==0?(l[2]==0?3:2):1
		if l[ci]>1;l[ci]=1;end
		h=min(l[ci],lif,1)
		points[1]=points[1].+h.*unit.color
#if points[1][1]!=0;println(points[1],loc,l,llm);end #useful for debugging
		#l[ci]-=h
		ll[1]=ll[1]+points[1]
	else
		l=l-ll[2:4]
		lifc=lif.*unit.color
		for c in 1:3
			if lifc[c]>0
				points[c+1]+=min(lifc[c],l[c%3+1])
				#game.lifemap[loc][c%3+1]-=points[c+1] #problem? *trollface* Solved!
				ll[c+1]+=points[c+1]
			end
		end
		#if numcolors(l)==1
		#	l=[0,0,0]
		#end
	end
	return points
end
function unitharvest(game,unit,ledger)
	points=[[0.0,0,0],0.0,0,0,0]
	if unit.harvested
		return points
	end

	white=(1,1,1)
	points.+=getpoints!(game,unit,unit.loc,0,ledger)
	temp=[unit.loc]
	checked=[unit.loc]
	for rad in 1:unit.ir
		temp2=[]
		for t in temp
			for h in adjacent(t,1,unit.groundlevel)
				if !in(h,temp) &&!in(h,checked) && in(h,game.board.grid) 
					if game.map[h]==0 || unit.passover
						p=getpoints!(game,unit,h,rad,ledger)
						points.+=p
						push!(temp2,h)
					elseif unit.passoverself && (game.map[h].color==unit.color || game.map[h].color==white)
						points.+=getpoints!(game,unit,h,rad,ledger) #problem!
						push!(temp2,h)
					elseif unit.inclusive && game.map[h]!=0
						points.+=getpoints!(game,unit,h,rad,ledger) #*seriousface* solving by deprecating game.lifemap. No! Long live the lifemap+ledger union
					end
				end
				push!(checked,h)
			end
		end
		temp=temp2
	end
	return points
end

function checkharvest(game,unit::Unit,ledger)
	return unit.harvest(game,unit,ledger)
end
function checkharvest(game,group::Group,ledger)
	points=[[0.0,0,0],0.0,0,0,0]
	for unit in group.units
		p=checkharvest(game,unit,ledger)
		if !in(unit,group.body)
			points.+=p./3
		else 
			points.+=p
		end
	end
	return points
end
function checkharvest(game::Game)
	#game=deepcopy(game) #this is silly, remove ! from unit.harvest! Done, still updates lifemap thou. 
	updategroups!(game) #this shouldn't count as modifying the state of the game since if they arent correct the state is incorrect and should always be updated
	#allunitslive!(game)
	game.lifemap=lifemap(game)
	ledger=newledger(game)
	points=[[0.0,0,0],0.0,0,0,0]
	for group in game.groups
		points+=checkharvest(game,group,ledger)
#		group.harvested=true
#		for unit in group.units
#			unit.harvested=true
#		end
	end
#	for group in game.groups
#		group.harvested=false
#		for unit in group.units
#			unit.harvested=false
#		end
#	end	#may need to do this to avoid units in multiple groups to multiharvest, but can't do it now because it should harvest to the group where it is in the body
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
function bonds(game)
	nc=0
	#checked=[]
	for (loc,unit) in game.map
	#	push!(checked,loc)
		if isa(unit,Unit) 
			for c in adjacent(unit.loc)
				if in(c,keys(game.map))
					ac=game.map[c]
					if isa(ac,Unit) && ac.color!=unit.color
						nc+=1
					end
				end
			end
		end
	end
	return Int(nc/2)
end
function pointslabel(game)
	points=checkharvest(game)
	bp=round.(points[1],1)
	points[1]=0
	points=round.(points,1)
	return "Points!\nLite:\nRed\t$(bp[1])\nGreen\t$(bp[2])\nBlue\t$(bp[3])\nLife:\nRed\t$(points[2])\nGreen\t$(points[3])\nBlue\t$(points[4])\nLight: $(points[5])"
end
function infolabel(game)
	rgb=[0,0,0]
	for unit in game.units
		rgb.+=unit.color
	end
	return "Information!\nUnits: $(length(game.units))\nRed: $(rgb[1])\nGreen: $(rgb[2])\nBlue: $(rgb[3])\nBonds: $(bonds(game))"
end
function undo!(game) #wont undo captures? Maybe when reloading sequence. There aren't captures anymore. Wont undo board expansions
	removeunit!(game.units[end])
	if !game.colock
		game.colind-=1
		if game.colind<1
			game.colind=game.colmax
		end
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
	for rad in 1:1000000
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
	offx=game.board.offsetx+game.board.panx
	offy=game.board.offsety+game.board.pany
	for loc in game.board.grid
		if loc[3]==2
			x,y=hex_to_pixel(loc[1],loc[2],size)
			hexlines(ctx,x+w/2+offx,y+h/2+offy,size)
		end
	end
	for unit in game.units
		set_source_rgb(ctx,unit.color...)
		offset=(offx,offy)
		if unit.loc[3]==1
			offset=offset.+(-cos(pi/6)*size,sin(pi/6)*size)
		elseif unit.loc[3]==3
			offset=offset.+(-cos(pi/6)*size,-sin(pi/6)*size)
		end
		loc=hex_to_pixel(unit.loc[1],unit.loc[2],size)
		floc=(loc[1]+offset[1]+w/2,loc[2]+offset[2]+h/2)
		rad=size*0.866/2
		arc(ctx,floc[1],floc[2],rad, 0, 2pi) #why isn't the circle radius the distance between locs?
		fill(ctx)
		#set_source_rgb(ctx,game.board.gridcolor...) #border
		#arc(ctx, loc[1]+offset[1]+w/2, loc[2]+offset[2]+h/2, size/3, 0, 2pi)
		#stroke(ctx)
		if !isempty(unit.graphic)
			set_source_rgb(ctx,game.board.bgcolor...)
			points=Point[]
			for p in unit.graphic
				push!(points,Point(floc[1]+rad*p[1],floc[2]+rad*p[2]))
			end
			polygon(ctx,points)
			fill(ctx)
		end
	end
	#showall(game.board.win)
	reveal(game.board.c)
	GAccessor.text(game.gui[:scorelabel],pointslabel(game))
	GAccessor.text(game.gui[:newslabel],infolabel(game))
end
function drawboard(game::Game)
	ctx=getgc(game.board.c)
	h=height(game.board.c)
	w=width(game.board.c)
	drawboard(game,ctx,w,h)
end

function expandboard!(game::Game,shells::Integer=6,initlocs=[(6,6,2)],basecost=-1,reveal=true)
	patch=makegrid(shells,initlocs)
	for loc in patch
		if !in(loc,keys(game.map))
			game.map[loc]=0
			push!(game.board.grid,loc)
		end
	end
	push!(game.sequence,(:expand,[shells,initlocs,basecost]))
	if reveal
		drawboard(game)
	end
	return "<3"
end
function zoom(game,factor)
	game.board.sizemod*=factor
	drawboard(game)
end
function pass!(game,nomax::Bool=false)
	max=game.colmax
	if nomax
		max=length(game.colors)
	end
	game.colind=game.colind%max+1
	game.color=game.colors[game.colind]
	drawboard(game)
end

function center(game,hex)
	game.board.sizemod=Gtk.G_.value(game.gui[:zadj])/10
	game.board.size=game.window[2]/(game.board.shells*game.board.sizemod)
	loc=hex_to_pixel(hex[1],hex[2],game.board.size)
	game.board.offsetx=-loc[1]+getproperty(game.gui[:xadj],:value,Float64)
	game.board.offsety=-loc[2]+getproperty(game.gui[:yadj],:value,Float64)
	drawboard(game)
	return true
end

