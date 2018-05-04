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
	for unit in game.units 
		if (color==(1,1,1) || unit.color==color || unit.color==(1,1,1)) #white, your superpowers are being removed, enjoy them while you can
			unit.live!(game,unit,lifemap)
		end
	end
	return lifemap
end
function unitslive(game)
	lifemap=Dict()
	for loc in game.board.grid
		lifemap[loc]=[0.0,0,0]
	end
	for unit in game.units
		unit.live!(game,unit,lifemap)
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

function getgroup(game,unit)
	lifemap=unitslive(game,unit.color)
	connectedunits=[unit]
	spawns=Unit[]
	body=getcellgroup(game,unit)
	for unit in body
		if unit.canspawn
			push!(spawns,unit)
		end
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
					end
				end
			end
		end
		for t2 in temp2
			push!(ulocs,t2)
		end
		temp=temp2
	end
	return newgroup(spawns,body,connectedunits)
end
function getgroups(game)
	groups=Group[]
	for spawn in game.spawns
		g=getgroup(game,spawn)
		if !hasgroup(groups,g)
			push!(groups,g)
		end
	end
	return groups
end
function sync!(game::Game)
	game.groups=getgroups(game)
	game.lifemap=unitslive(game)
	GAccessor.text(game.gui[:scorelabel],pointslabel(game,false))
	GAccessor.text(game.gui[:newslabel],infolabel(game))
end
function placeable(game,unit::Unit)
	if haskey(game.map,unit.loc) && game.map[unit.loc]!=0
		return false
	elseif !in(unit.loc[3],unit.pl)
		return false
	end
	return true
end
function placeunit!(game,unit)
	if placeable(game,unit)
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
function findunit(unit::Unit,units)
	i=0
	for u in units
		i+=1
		if unit.loc==u.loc && unit.color==u.color && unit.name==u.name
			return i
		end
	end
	return 0
end
function removeunit!(game,unit::Unit)
	game.map[unit.loc]=0
	push!(game.sequence,(:delete,unit))
	i=findunit(unit,game.units)
	if i>0
		deleteat!(game.units,i)
	end
	if unit.canspawn
		i=findunit(unit,game.spawns)
		deleteat!(game.spawns,i)
	end
	return "<3"
end

function newledger(game)
	ledger=Dict()
	for loc in game.board.grid
		ledger[loc]=[[0.0,0,0],0.0,0,0,0]
	end
	return ledger
end
function getpoints!(game,unit,loc,distance,ledger,partial=1) #remake cleaner. Meaning, more humanreadable? ll lci llm l lci lif. OMG this place is bugprone, readability helps. 
	llm=game.lifemap[loc] #local lifemap
	ll=ledger[loc]
	lif=distance==0?unit.baselife:(unit.baselife/6/distance)
	lif=lif*partial
	ncol=numcolors(llm)
	l=llm.-ll[5] #local life - lightharvest
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
		#l[ci]-=h
		ll[1]=ll[1]+points[1]
	else
		#l=l-ll[2:4] #something is wrong here... Aha! Green doesn't harvest green, green harvests blue!
		l[1]-=ll[4]
		l[2]-=ll[2]
		l[3]-=ll[3]
		lifc=lif.*unit.color #nooo? Yes?
		for c in 1:3
			if lifc[c]>0
				points[c+1]+=min(l[c],l[c%3+1],lifc[c]) #no! Maybe...
				#game.lifemap[loc][c%3+1]-=points[c+1] #problem? *trollface* Solved!
				ll[c+1]+=points[c+1]
			end
		end
#if ll[3]!=0 && unit.color==(0,1,0);println(loc,ll,l);end #useful for debugging
	end
	return points
end
function unitharvest(game,unit,ledger,partial=1)
	points=[[0.0,0,0],0.0,0,0,0]
	if unit.harvested || unit.harvested>=1
		return points
	end

	white=(1,1,1) #remove?
	points.+=getpoints!(game,unit,unit.loc,0,ledger)
	temp=[unit.loc]
	checked=[unit.loc]
	for rad in 1:unit.ir
		temp2=[]
		for t in temp
			for h in adjacent(t,1,unit.groundlevel)
				if !in(h,temp) &&!in(h,checked) && in(h,game.board.grid) 
					if game.map[h]==0 || unit.passover #why not merge these clauses?
						p=getpoints!(game,unit,h,rad,ledger,partial)
						points.+=p
						push!(temp2,h)
					elseif unit.passoverself && (game.map[h].color==unit.color || game.map[h].color==white)
						points.+=getpoints!(game,unit,h,rad,ledger) #problem! Not anymore! Why are the comments still here? Why not? I asked first! They liven up the code. OK then
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

function checkharvest(game,unit::Unit,ledger,partial=1)	#| ^
	return unit.harvest(game,unit,ledger,partial)	#L_|
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
function checkharvest(game::Game,sync::Bool=true)
	#game=deepcopy(game) #this is silly, remove ! from unit.harvest! Done, still updates lifemap thou. Not anymore, now puts harvest data in a ledger
	if sync
		sync!(game) #this shouldn't count as modifying the state of the game since if they arent correct the state is incorrect and should always be updated. Maybe we don't have to sync thou since it is always synced upon new move... Robustness over velocity!
	end
	ledger=newledger(game)
	points=[[0.0,0,0],0.0,0,0,0]
	for group in game.groups
		#points+=checkharvest(game,group,ledger)
# !
		for unit in group.body
			points+=checkharvest(game,unit,ledger)
			unit.harvested=true
		end
	end
	for group in game.groups
# !
		for unit in group.units
			if !unit.harvested || unit.harvested<1
				partial=min(1/3,1-unit.harvested)
				points+=checkharvest(game,unit,ledger,partial)
				unit.harvested+=partial
			end
		end
		group.harvested=true
	end
	for group in game.groups
		group.harvested=false
		for unit in group.units
			unit.harvested=false
		end
	end	
#may need to do this to avoid units in multiple groups to multiharvest, but can't do it now because it should harvest to the group where it is in the body, so have to harvest with bodies first. Or let it harvest partially
	return points
end

function bonds(game)
	nc=0
	#checked=[]
	for (loc,unit) in game.map #rewrite with game.units?
	#	push!(checked,loc) #this didnt work...
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
function pointslabel(game,sync::Bool=true)
	points=checkharvest(game,sync)
	bp=round.(points[1],1)
	points[1]=0
	points=round.(points,1)
	return "Points!\nLite:\nRed\t$(bp[1])\nGreen\t$(bp[2])\nBlue\t$(bp[3])\nLife:\nRed\t$(points[2])\nGreen\t$(points[3])\nBlue\t$(points[4])\nLight:\t$(points[5])"
end
function infolabel(game)
	rgb=[0.0,0,0]
	for unit in game.units
		rgb.+=unit.color
	end
	rgb=round.(rgb,1)
	return "Information!\nUnits: $(length(game.units))\nRed: $(rgb[1])\nGreen: $(rgb[2])\nBlue: $(rgb[3])\nBonds: $(bonds(game))"
end
function undo!(game) #wont undo captures? Maybe when reloading sequence. There aren't captures anymore. Wont undo board expansions. Maybe it should? Not much use now... Easy right, just pop the seq and reload
	removeunit!(game.units[end])
	if !game.colock
		game.colind-=1
		if game.colind<1
			game.colind=game.colmax
		end
	end
	return hex
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
	offx=game.board.offsetx+game.board.panx
	offy=game.board.offsety+game.board.pany
	for (lo,lif) in game.lifemap
		if sum(lif)>0 && lo[3]==2
			offset=(offx,offy)
			#if lo[3]==1
			#	offset=offset.+(-cos(pi/6)*size,sin(pi/6)*size)
			#elseif lo[3]==3
			#	offset=offset.+(-cos(pi/6)*size,-sin(pi/6)*size)
			#end
			plo=hex_to_pixel(lo[1],lo[2],size)
			ploc=(plo[1]+offset[1]+w/2,plo[2]+offset[2]+h/2)
			rad=size*0.866/2
			col=lif./(lif+3)
			set_source_rgb(ctx, col...)
			arc(ctx,ploc[1],ploc[2],rad*2, 0, 2pi)
			fill(ctx)
		end
	end
	set_source_rgb(ctx, game.board.gridcolor...)
	for loc in game.board.grid
		if loc[3]==2
			x,y=hex_to_pixel(loc[1],loc[2],size)
			hexlines(ctx,x+w/2+offx,y+h/2+offy,size)
		end
	end
	for unit in game.units
		offset=(offx,offy)
		if unit.loc[3]==1
			offset=offset.+(-cos(pi/6)*size,sin(pi/6)*size)
		elseif unit.loc[3]==3
			offset=offset.+(-cos(pi/6)*size,-sin(pi/6)*size)
		end
		loc=hex_to_pixel(unit.loc[1],unit.loc[2],size)
		floc=(loc[1]+offset[1]+w/2,loc[2]+offset[2]+h/2)
		rad=size*0.866/2
		#unit border:
		set_source_rgb(ctx,game.board.gridcolor...) 
		arc(ctx, floc[1],floc[2],rad+1, 0, 2pi)
		stroke(ctx)
		set_source_rgb(ctx,unit.color...)
		arc(ctx,floc[1],floc[2],rad, 0, 2pi) #why isn't the circle radius the distance between locs? Whyyyy whyyyy someone pleeease fiiix
		fill(ctx)
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
	#showall(game.board.win) #should probably look up the difference between all these revealing methods
	reveal(game.board.c)
end
function drawboard(game::Game)
	ctx=getgc(game.board.c)
	h=height(game.board.c)
	w=width(game.board.c)
	drawboard(game,ctx,w,h)
end

function expandboard!(game::Game,shells::Integer=6,initlocs=[(6,6,2)],reveal=true)
	patch=makegrid(shells,initlocs)
	for loc in patch
		if !in(loc,keys(game.map))
			game.map[loc]=0
			push!(game.board.grid,loc)
		end
	end
	push!(game.sequence,(:expand,[shells,initlocs]))
	if reveal #without this there is sometimes some severe error (when loadicing)
		drawboard(game)
	end
	return "<3"
end
function zoom(game,factor)
	game.board.sizemod*=factor
	drawboard(game)
end
function pass!(game,nomax::Bool=false,reverse::Bool=false)
	max=game.colmax
	if nomax
		max=length(game.colors)
	end
	if reverse
		game.colind=game.colind-1
		if game.colind==0
			game.colind=max
		end
	else
		game.colind=game.colind%max+1
	end
	game.color=game.colors[game.colind]
	drawboard(game)
end

function center(game,hex)
	#game.board.sizemod=Gtk.G_.value(game.gui[:zadj])/10
	game.board.size=game.window[2]/(game.board.shells*game.board.sizemod)
	loc=hex_to_pixel(hex[1],hex[2],game.board.size)
	game.board.offsetx=-loc[1]+getproperty(game.gui[:xadj],:value,Float64)
	game.board.offsety=-loc[2]+getproperty(game.gui[:yadj],:value,Float64)
	drawboard(game)
	return true
end

