include("units.jl")

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
end
function drawboard(game::Game)
	ctx=getgc(game.board.c)
	h=height(game.board.c)
	w=width(game.board.c)
	drawboard(game,ctx,w,h)
end

function newunit(color,loc,unitspec::Dict)
	ir=haskey(unitspec,:ir)?unitspec[:ir]:3
	pl=haskey(unitspec,:pl)?unitspec[:pl]:[2]
	passover=haskey(unitspec,:passover)?unitspec[:passover]:false
	passoverself=haskey(unitspec,:passoverself)?unitspec[:passoverself]:true
	inclusive=haskey(unitspec,:inclusive)?unitspec[:inclusive]:false
	groundlevel=haskey(unitspec,:groundlevel)?unitspec[:groundlevel]:true
	live=haskey(unitspec,:live!)?unitspec[:live!]:spreadlife!
	baselife=haskey(unitspec,:baselife)?unitspec[:baselife]:6
	harvest=haskey(unitspec,:harvest!)?unitspec[:harvest!]:(game,unit)->[0.0,0,0,0,0]
	name=haskey(unitspec,:name)?unitspec[:name]:""
	return Unit(color,ir,pl,passover,passoverself,inclusive,loc,groundlevel,live,baselife,harvest,name)
end
#function newunit(color=(1,0,0),ir=3,pl=[2])
#	return Unit(color,ir,pl)
#end
function newboard(shells=9,initlocs=[(0,0,2)],grid=0,c=@GtkCanvas(),sizemod=5,size=30,offsetx=0,offsety=0,bgcolor=(0,0,0),gridcolor=(1/2,1/2,1/2))
	if grid==0
		grid=makegrid(shells,initlocs)
	end
	board=Board(shells,initlocs,grid,c, sizemod,size,offsetx,offsety,bgcolor,gridcolor)
	return board
end
function allowedat(unitparams,loc)
	yes=true
	if !in(loc[3],unitparams[3])
		yes=false
	end
	return yes
end
function unitcost(game,loc,unitparams)
	distance=nearestwhite(game,loc,loc[3]==2)
	cost=distance*unitparams[2]
	cost*=sum(unitparams[1]) #only if sum>1?
	return cost
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
function harvest(game::Game)
	game.season+=1
	game.points+=peekharvest(game)
end
function pointslabel(game)
	points=round.(game.points,3)
	return "Points!\nBlack:\t$(points[1]) \nRed:\t$(points[2]) \nGreen:\t$(points[3]) \nBlue:\t$(points[4]) \nWhite: $(points[5]) \nSeason: $(game.season) "
end
function newgame(name=string(round(Integer,time())),boardparams=[],unitparams=[(1,0,0),3,[2],"standard"],map=Dict(),unit=0,color=(1,0,0),colors=[(1,0,0),(0,1,0),(0,0,1),(1,1,1)],colind=1,colmax=3,colock=false,delete=false,sequence=[((0,0,2),newunit((1,1,1),(0,0,2),units["white"]))],board=0,printscore=false,points=[0.0,0,0,0,0],season=0,win=0,window=(900,700),autoharvest=false)
	if board==0
		board=newboard(boardparams...)
	end
	for loc in board.grid
		map[loc]=0
	end
	game=Game(name,map,unitparams,color,colors,colind,colmax, colock,delete,sequence,board,printscore,points,season,win,window,0,0,autoharvest)
	placeseq(game.sequence,game.map)
	if win==0
		box=GtkBox(:h)
		harvestbtn=GtkButton("Harvest")
		label=GtkLabel(pointslabel(game))
		passbtn=GtkButton("Pass")
		g=GtkGrid()
		gg=Dict()
		g[1,1]=harvestbtn
		g[1,2]=label
		g[1,3]=passbtn
		push!(box,game.board.c)	
		push!(box,g)
		game.g=g
		setproperty!(box,:expand,game.board.c,true)
		game.win=GtkWindow(box,"Weilianqi",window[1],window[2])
		showall(game.win)
		id = signal_connect(harvestbtn, "clicked") do widget
			allunitsharvest!(game)
			#GAccessor.text(label,pointslabel(game))
		end
		id = signal_connect(passbtn, "clicked") do widget
			pass(game)
		end
	end
	if points==[0,0,0,0,0]
		allunitsharvest!(game)
	end
	@guarded function drawsignal(widget)
		ctx=getgc(widget)
		h=height(widget)
		w=width(widget)
		game.window=(w,h)
		game.board.size=game.window[2]/(game.board.shells*game.board.sizemod)
		drawboard(game,ctx,w,h)
	end
	draw(drawsignal,game.board.c)
	game.board.c.mouse.button1press = @guarded (widget, event) -> begin
		ctx = getgc(widget)
		h = height(game.board.c)
		w = width(game.board.c)
		size=game.board.size
		q,r=pixel_to_hex(event.x-w/2-game.board.offsetx,event.y-h/2-game.board.offsety,size)
		maindiff=abs(round(q)-q)+abs(round(r)-r)
		qup,rup=pixel_to_hex(event.x-w/2+size*cos(pi/6),event.y-h/2+sin(pi/6)*size,size)
		updiff=abs(round(qup)-qup)+abs(round(rup)-rup)
		qdown,rdown=pixel_to_hex(event.x-w/2+size*cos(pi/6),event.y-h/2-sin(pi/6)*size,size)
		downdiff=abs(round(qdown)-qdown)+abs(round(rdown)-rdown)
		best=findmin([maindiff,updiff,downdiff])[2]
		hex=[(round(Int,q),round(Int,r),2),(round(Int,qup),round(Int,rup),3),(round(Int,qdown),round(Int,rdown),1)][best]
		if allowedat(game.unitparams,hex)
			exists=in(hex,keys(game.map))
			if exists
				if game.delete==true && game.map[hex]!=0
					game.map[hex]=0
					push!(game.sequence,(hex,0))
				elseif game.map[hex]==0
					cost=unitcost(game,hex,game.unitparams)
					afforded=subtractcost(game,cost,game.unitparams[1])
					if !afforded
						if game.autoharvest
							allunitsharvest!(game)
							afforded=subtractcost(game,cost,game.unitparams[1])
						end
						if !afforded
							println("Not enough points.")
							return
						end
					end
					#nu=newunit(game.unitparams...)
					nu=newunit(game.color,hex,units[game.unitparams[4]])
					game.map[hex]=nu
					push!(game.sequence,(hex,nu))
#					hs=adjacent(hex)	#this checks if captured
#					push!(hs,hex)
#					for he in hs
#						if in(he,keys(storage[:map]))
#							g=getgroup(he)
#							if !isempty(g) && liberties(g)==0
#								for gh in g
#									storage[:map][gh]=0
#								end
#							end
#						end
#					end
					if !game.colock
						game.colind=game.colind%game.colmax+1
						game.color=game.colors[game.colind]
						game.unitparams[1]=game.color
					end
				end
				if game.printscore
					printpoints(game)
				end
				GAccessor.text(label,pointslabel(game))
			end
		end
		drawboard(game,ctx,w,h)
		reveal(widget)
	end
	show(game.board.c)
	return game
end
function getexpandcost(shells::Integer=6,initlocs=[(6,6,2)],basecost=50)
	patch=makegrid(shells,initlocs)
	cost=length(patch)+basecost*length(initlocs)
	return cost
end
function expandboard(game::Game,shells::Integer=6,initlocs=[(6,6,2)],basecost=50)
	patch=makegrid(shells,initlocs)
	cost=length(patch)+basecost*length(initlocs)
	remains=game.points[1]-cost
	if remains>=0
		for loc in patch
			if !in(loc,game.board.grid)
				game.map[loc]=0
				push!(game.board.grid,loc)
			end
		end
		drawboard(game)
	end
	return remains
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
function save(game)
	dir=homedir()*"/.weilianqi/saves/"*game.name
	if !ispath(dir)
		touch(dir)
	end
	io=open(dir,"a+")
	write(io,string(game.sequence),"\n")
	close(io)
end
#savelite=(game)->write("~/.weilianqi/$(round(Integer,time())).txt","$(game.sequence)")
function loadsequence!(game::Game,seqstr::String,originoffset=(0,0,0))
	seq=eval(parse(seqstr))
	for entry in seq
		if entry==:harvest
			allunitsharvest!(game)
		else
			(loc,unit)=entry
			loco=loc.+originoffset
			game.map[loco]=unit
			push!(game.sequence,(loco,unit))
		end
	end
	#GAccessor.text(game.g[1,2],pointslabel(game))
	#drawboard(game)
	return true
end
function load(name::String,backtrack::Integer=0)
	game=newgame()
	path=homedir()*"/.weilianqi/saves/"*name
	lines=readlines(path)
	seqstr=lines[end-backtrack]
	loadsequence!(game,seqstr)
	return game
end
