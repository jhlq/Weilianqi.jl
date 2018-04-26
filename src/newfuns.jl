function newunit(color=(1,0,0),loc=(0,0,Inf),unitspec::Dict=Dict())
	ir=haskey(unitspec,:ir)?unitspec[:ir]:2
	pl=haskey(unitspec,:pl)?unitspec[:pl]:[2]
	passover=haskey(unitspec,:passover)?unitspec[:passover]:false
	passoverself=haskey(unitspec,:passoverself)?unitspec[:passoverself]:true
	inclusive=haskey(unitspec,:inclusive)?unitspec[:inclusive]:false
	groundlevel=haskey(unitspec,:groundlevel)?unitspec[:groundlevel]:true
	live=haskey(unitspec,:live!)?unitspec[:live!]:spreadlife!
	baselife=haskey(unitspec,:baselife)?unitspec[:baselife]:6
	harvest=haskey(unitspec,:harvest)?unitspec[:harvest]:standard_harvest #(game,unit)->[0.0,0,0,0,0]
	name=haskey(unitspec,:name)?unitspec[:name]:""
	costfun=haskey(unitspec,:costfun)?unitspec[:costfun]:standard_costfun
	canspawn=haskey(unitspec,:canspawn)?unitspec[:canspawn]:false
	return Unit(color,ir,pl,passover,passoverself,inclusive,loc,groundlevel,live,baselife,harvest,name,costfun,canspawn,false)
end
function newunit(dic::Dict)
	unitspec=units[dic[:name]]
	return newunit(dic[:color],dic[:loc],unitspec)
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
function newboard(shells=6,initlocs=[(0,0,2)],grid=0,c=@GtkCanvas(),sizemod=5,size=30,offsetx=0,offsety=0,bgcolor=(0,0,0),gridcolor=(1/2,1/2,1/2),expandbasecost=-1)
	if grid==0
		grid=makegrid(shells,initlocs)
	end
	board=Board(shells,initlocs,grid,c, sizemod,size,offsetx,offsety,0,0,bgcolor,gridcolor,expandbasecost)
	return board
end

function newgame(name=string(round(Integer,time())),boardparams=[],unitparams=["standard"],map=Dict(),unit=0,color=(1,0,0),colors=colorsets[1],colind=1,colmax=3,colock=false,delete=false,sequence=[newunit((1,1,1),(0,0,2),units["spawn"])],board=0,printscore=false,points=[0.0,0,0,0,0],season=0,win=0,window=(900,700),autoharvest=true)
	if board==0
		board=newboard(boardparams...)
	end
	for loc in board.grid
		map[loc]=0
	end
	game=Game(name,map,Group[],Unit[],Unit[],unitparams,color,colors,colind,colmax, colock,delete,sequence,board,printscore,points,season,win,window,0,0,Dict(),autoharvest)
	#placeseq(game.sequence,game.map)
	placeseq!(game)	
	updategroups!(game)
	if win==0
		box=GtkBox(:h)
		savebtn=GtkButton("Save")
		loadbtn=GtkButton("Load")
		nameentry=GtkEntry()
		setproperty!(nameentry,:text,game.name)
		scorelabel=GtkLabel(pointslabel(game))
		passbtn=GtkButton("Next color")
		#colabel=GtkLabel(string(game.color))
		#autoharvestcheck = GtkCheckButton("Autoharvest")
		#setproperty!(autoharvestcheck,:active,game.autoharvest)
		colockcheck=GtkCheckButton("Lock color")
		setproperty!(colockcheck,:active,game.colock)
		scalemaxfac=100
		zoomscale = GtkScale(false, 1:scalemaxfac*10)
		zlabel=GtkLabel("Zoom")
		zadj=Gtk.Adjustment(zoomscale)
		setproperty!(zadj,:value,game.board.sizemod*10)
		omax=scalemaxfac*30
		xoscale = GtkScale(false, -omax:omax)
		xlabel=GtkLabel("Pan x")
		xadj=Gtk.Adjustment(xoscale)
		setproperty!(xadj,:value,game.board.panx)
		yoscale = GtkScale(false, -omax:omax)
		ylabel=GtkLabel("Pan y")
		yadj=Gtk.Adjustment(yoscale)
		setproperty!(yadj,:value,game.board.pany)
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
		deletecheck=GtkCheckButton("Enable deletion")
		setproperty!(deletecheck,:active,game.delete)
		clabel1=GtkLabel("Place")
		clabel2=GtkLabel("units")
		unitscombo=GtkComboBoxText()
		staind=0;staindset=false
		for c in keys(units)
			push!(unitscombo,c)
			if !staindset && c=="standard"
				staindset=true
			elseif !staindset
				staind+=1
			end
		end
		setproperty!(unitscombo,:active,staind)
		g=GtkGrid()
		g[1,1]=savebtn
		g[2,1]=nameentry
		g[3,1]=loadbtn
		g[1,2]=scorelabel
		g[2,3]=deletecheck
		g[1,3]=passbtn
		#g[1,4]=autoharvestcheck
		g[2,2]=colockcheck
		g[1,4]=clabel1
		g[3,4]=clabel2
		g[2,4]=unitscombo
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
		push!(box,game.board.c)	
		push!(box,g)
		game.g=g
		#game.gui[:harvestbtn]=harvestbtn
		game.gui[:scorelabel]=scorelabel
		game.gui[:yoscale]=yoscale
		game.gui[:xoscale]=xoscale
		game.gui[:zadj]=zadj
		game.gui[:xadj]=xadj
		game.gui[:yadj]=yadj
		game.gui[:colockcheck]=colockcheck
		game.gui[:deletecheck]=deletecheck
		setproperty!(box,:expand,game.board.c,true)
		game.win=GtkWindow(box,"Weilianqi $name",window[1],window[2])
		showall(game.win)
		id = signal_connect(savebtn, "clicked") do widget
			game.name=getproperty(nameentry,:text,String)
			save(game)
		end
		id = signal_connect(loadbtn, "clicked") do widget
			loadgame(getproperty(nameentry,:text,String))
		end
		id = signal_connect(passbtn, "clicked") do widget
			pass!(game,getproperty(colockcheck,:active,Bool))
		end
		signal_connect(unitscombo, "changed") do widget, others...
			unitname=Gtk.bytestring( GAccessor.active_text(unitscombo) ) 
			#println("Active element is \"$unitname\" at index $idx")
			game.unitparams[end]=unitname
		end
		id = signal_connect(zoomscale, "value-changed") do widget
			game.board.sizemod=Gtk.G_.value(widget)/10
			drawboard(game)
		end
		id = signal_connect(xoscale, "value-changed") do widget
			game.board.panx=-Gtk.G_.value(widget)*10
			drawboard(game)
		end
		id = signal_connect(yoscale, "value-changed") do widget
			game.board.pany=-Gtk.G_.value(widget)*10
			drawboard(game)
		end
		#id = signal_connect(autoharvestcheck, "clicked") do widget
		#	game.autoharvest=getproperty(widget,:active,Bool)
		#end
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
			#xadj=Gtk.Adjustment(xoscale)
			#setproperty!(xadj,:value,0)
			x=Gtk.G_.value(spexpx)
			y=Gtk.G_.value(spexpy)
			center(game,(x,y))
		end
	end
#	if points==[0,0,0,0,0]
#		harvest!(game)
#	end
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
		ctx=getgc(widget)
		h=height(game.board.c)
		w=width(game.board.c)
		nu=newunit(game.color,0,units[game.unitparams[end]])
		size=game.board.size
		offx=game.board.offsetx+game.board.panx
		offy=game.board.offsety+game.board.pany
		q,r=pixel_to_hex(event.x-w/2-offx,event.y-h/2-offy,size)
		maindiff=abs(round(q)-q)+abs(round(r)-r)
		qup,rup=pixel_to_hex(event.x-w/2+size*cos(pi/6),event.y-h/2+sin(pi/6)*size,size)
		updiff=abs(round(qup)-qup)+abs(round(rup)-rup)
		qdown,rdown=pixel_to_hex(event.x-w/2+size*cos(pi/6),event.y-h/2-sin(pi/6)*size,size)
		downdiff=abs(round(qdown)-qdown)+abs(round(rdown)-rdown)
		if length(nu.pl)==1
			best=(nu.pl[1]+1)%3+1
		else
			best=findmin([maindiff,updiff,downdiff])[2]
		end
		hex=[(round(Int,q),round(Int,r),2),(round(Int,qup),round(Int,rup),3),(round(Int,qdown),round(Int,rdown),1)][best]
		nu.loc=hex
		exists=in(hex,keys(game.map))
		if exists
			if game.delete==true && game.map[hex]!=0 && isa(game.map[hex],Unit)
				removeunit!(game,game.map[hex])
			elseif game.map[hex]==0 && placeable(game,nu) 
				placeunit!(game,nu)
				if !game.colock
					game.colind=game.colind%game.colmax+1
					game.color=game.colors[game.colind]
				end
			end
			if game.printscore
				printpoints(game)
			end
			#GAccessor.text(scorelabel,pointslabel(game))
			updategroups!(game)
		end
		drawboard(game,ctx,w,h)
		reveal(widget)
	end
	show(game.board.c)
	return game
end

