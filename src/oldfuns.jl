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
