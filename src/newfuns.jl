function newunit(color=(1,0,0),loc=(0,0,Inf),unitspec::Dict=Dict())
	ir=haskey(unitspec,:ir)?unitspec[:ir]:2
	pl=haskey(unitspec,:pl)?unitspec[:pl]:[2]
	passover=haskey(unitspec,:passover)?unitspec[:passover]:false
	passoverself=haskey(unitspec,:passoverself)?unitspec[:passoverself]:true
	inclusive=haskey(unitspec,:inclusive)?unitspec[:inclusive]:false
	groundlevel=haskey(unitspec,:groundlevel)?unitspec[:groundlevel]:true
	live=haskey(unitspec,:live!)?unitspec[:live!]:spreadlife!
	baselife=haskey(unitspec,:baselife)?unitspec[:baselife]:6
	harvest=haskey(unitspec,:harvest!)?unitspec[:harvest!]:(game,unit)->[0.0,0,0,0,0]
	name=haskey(unitspec,:name)?unitspec[:name]:""
	costfun=haskey(unitspec,:costfun)?unitspec[:costfun]:standard_costfun
	canspawn=haskey(unitspec,:canspawn)?unitspec[:canspawn]:false
	return Unit(color,ir,pl,passover,passoverself,inclusive,loc,groundlevel,live,baselife,harvest,name,costfun,canspawn,false)
end
function newgroup(unit::Unit)
	units=[unit]
	spawns=Unit[]
	if unit.canspawn
		push!(spawns,unit)
	end
	group=Group(spawns,units,[0.0,0,0,0,0],false,false)
	#group.lifmap=lifmap(group)
	return group
end
function newgroup(units::Array{Unit})
	spawns=Unit[]
	for u in units
		if u.canspawn
			push!(spawns,u)
		end
	end
	group=Group(spawns,units,[0.0,0,0,0,0],false,false)
	#group.lifmap=lifmap(group)
	return group
end
function newgroup(spawns::Array,units::Array)
	return Group(spawns,units,[0.0,0,0,0,0],false,false)
end
function newboard(shells=9,initlocs=[(0,0,2)],grid=0,c=@GtkCanvas(),sizemod=5,size=30,offsetx=0,offsety=0,bgcolor=(0,0,0),gridcolor=(1/2,1/2,1/2),expandbasecost=-1)
	if grid==0
		grid=makegrid(shells,initlocs)
	end
	board=Board(shells,initlocs,grid,c, sizemod,size,offsetx,offsety,bgcolor,gridcolor,expandbasecost)
	return board
end

function newgame(name=string(round(Integer,time())),boardparams=[],unitparams=[(1,0,0),3,[2],"standard"],map=Dict(),unit=0,color=(1,0,0),colors=[(1,0,0),(0,1,0),(0,0,1),(1,1,1)],colind=1,colmax=3,colock=false,delete=false,sequence=[((0,0,2),newunit((1,1,1),(0,0,2),units["white"]))],board=0,printscore=false,points=[0.0,0,0,0,0],season=0,win=0,window=(900,700),autoharvest=true)
	if board==0
		board=newboard(boardparams...)
	end
	for loc in board.grid
		map[loc]=0
	end
	game=Game(name,map,Group[],Unit[],unitparams,color,colors,colind,colmax, colock,delete,sequence,board,printscore,points,season,win,window,0,0,Dict(),autoharvest)
	#placeseq(game.sequence,game.map)
	placeseq!(game)
	updategroups!(game)
	if win==0
		box=GtkBox(:h)
		harvestbtn=GtkButton("Harvest")
		scorelabel=GtkLabel(pointslabel(game))
		passbtn=GtkButton("Next color (overrides colorlock)")
		#colabel=GtkLabel(string(game.color))
		autoharvestcheck = GtkCheckButton("Autoharvest")
		setproperty!(autoharvestcheck,:active,game.autoharvest)
		colockcheck = GtkCheckButton("Lock color")
		setproperty!(colockcheck,:active,game.colock)
		scalemaxfac=100
		zoomscale = GtkScale(false, 1:scalemaxfac)
		zlabel=GtkLabel("Zoom")
		zadj=Gtk.Adjustment(zoomscale)
		setproperty!(zadj,:value,game.board.sizemod)
		omax=scalemaxfac*30
		xoscale = GtkScale(false, -omax:omax)
		xlabel=GtkLabel("Pan x")
		xadj=Gtk.Adjustment(xoscale)
		setproperty!(xadj,:value,game.board.offsetx)
		yoscale = GtkScale(false, -omax:omax)
		ylabel=GtkLabel("Pan y")
		yadj=Gtk.Adjustment(yoscale)
		setproperty!(yadj,:value,game.board.offsety)
		spexpx=GtkSpinButton(-1000:1000)
		Gtk.G_.value(spexpx,game.board.shells)
		spexpy=GtkSpinButton(-1000:1000)
		Gtk.G_.value(spexpy,game.board.shells)
		spexpshell=GtkSpinButton(0:1000)
		Gtk.G_.value(spexpshell,game.board.shells)
		xexplabel=GtkLabel("X loc")
		yexplabel=GtkLabel("Y loc")
		shellexplabel=GtkLabel("Radius")
		expbtn=GtkButton("Expand board at (X,Y)")
		centerbtn=GtkButton("Center board on (X,Y)")
		deletecheck=GtkCheckButton("Delete")
		setproperty!(deletecheck,:active,game.delete)
		g=GtkGrid()
		g[1,1]=harvestbtn
		g[1,2]=scorelabel
		g[2,3]=passbtn
		g[1,4]=autoharvestcheck
		g[1,5]=colockcheck
		g[1,6]=zlabel
		g[1,7]=xlabel
		g[1,8]=ylabel
		g[2,6]=zoomscale
		g[2,7]=xoscale
		g[2,8]=yoscale
		g[1,9]=xexplabel
		g[1,10]=yexplabel
		g[2,9]=spexpx
		g[2,10]=spexpy
		g[1,11]=shellexplabel
		g[2,11]=spexpshell
		g[2,12]=expbtn
		g[2,13]=centerbtn
		g[1,14]=deletecheck
		push!(box,game.board.c)	
		push!(box,g)
		game.g=g
		game.gui[:harvestbtn]=harvestbtn
		game.gui[:scorelabel]=scorelabel
		setproperty!(box,:expand,game.board.c,true)
		game.win=GtkWindow(box,"Weilianqi $name",window[1],window[2])
		showall(game.win)
		id = signal_connect(harvestbtn, "clicked") do widget
			harvest!(game)
			#GAccessor.text(label,pointslabel(game))
		end
		id = signal_connect(passbtn, "clicked") do widget
			pass(game)
		end
		id = signal_connect(zoomscale, "value-changed") do widget
			game.board.sizemod=Gtk.G_.value(widget)
		end
		id = signal_connect(xoscale, "value-changed") do widget
			game.board.offsetx=-Gtk.G_.value(widget)
		end
		id = signal_connect(yoscale, "value-changed") do widget
			game.board.offsety=-Gtk.G_.value(widget)
		end
		id = signal_connect(autoharvestcheck, "clicked") do widget
			game.autoharvest=getproperty(widget,:active,Bool)
		end
		id = signal_connect(colockcheck, "clicked") do widget
			game.colock=getproperty(widget,:active,Bool)
		end
		id = signal_connect(deletecheck, "clicked") do widget
			game.delete=getproperty(widget,:active,Bool)
		end
		id = signal_connect(expbtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			r=Gtk.G_.value(spexpshell)
			remain=expandboard!(game,Integer(r),[(x,y,2)])
			#if remain<0
			#	println(abs(remain)," too few black points.")
			#end
		end
		id = signal_connect(centerbtn, "clicked") do widget
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			center(game,(x,y))
		end
	end
	if points==[0,0,0,0,0]
		harvest!(game)
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
							harvest!(game)
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
				GAccessor.text(scorelabel,pointslabel(game))
				updategroups!(game)
			end
		end
		drawboard(game,ctx,w,h)
		reveal(widget)
	end
	show(game.board.c)
	return game
end

