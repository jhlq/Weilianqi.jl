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
	GAccessor.text(game.g[1,2],pointslabel(game))
	return points
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
function connectedunits(game,unit)
	(lif,cu,cw)=lifluence(game,unit)
	cellconnected=getcellgroup(game,unit)
	return (cw,cellconnected,cu) #connected white units, connected by cells, connected by lifluence
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
function updategroups_dep!(game::Game) #sometimes doesn't find most recent unit..? Or is there an issue when deleting units? Maybe fixed. Now it sometimes adds the most recent unit twice...
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

function getgroup_dep(game,unit::Unit,color=-1,connectedunits=Unit[]) #why don't white units get added to spawns? Maybe they shouldn't, bug in our favor. They should be available as partial spawns, divide white into 3 spawn units. Fixed some stuff, still good bugs? Well, this should be rewritten rather than bugged down, first a initgroup that gets the body.
	if color==-1
		color=unit.color
	end
	lifemap=unitslive(game,unit.color)
	if !in(unit,connectedunits)
		push!(connectedunits,unit)
	end
	cwhite=Unit[] #connected spawns
	if color==(1,1,1) #this needs to be rewritten to allow colored spawns, sorta works now but... nonbody groups automerge with white group
		push!(cwhite,unit)
		stuff=Dict()
		reach=makegrid(7) #should be minimum twice the maximum ir of all units +1, should be a better way
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
	body=getcellgroup(game,connectedunits[1]) #tempfix
	return newgroup(cwhite,body,connectedunits)
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

function printpoints(game)
	harv=round.(peekharvest(game),1,10)
	println("Black: ",harv[1]," Red: ",harv[2]," Green: ",harv[3]," Blue: ",harv[4]," White: ",harv[5])#," Total: ",sum(harv))
end
function nearestwhite(game,hex,layer=false) #rewrite to check for spawn? Or spawning is always done from groups? This isn't even needed now that costs are gone
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
function getexpandcost(shells::Integer=6,initlocs=[(6,6,2)],basecost=50) #deprecated
	patch=makegrid(shells,initlocs)
	cost=length(patch)+basecost*length(initlocs)
	return cost
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
