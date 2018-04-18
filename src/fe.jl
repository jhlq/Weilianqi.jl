#=
storage=Dict()
storage[:players]=[(1,0,0),(0,1,0),(0,0,1),(1,1,1)]
storage[:player]=1
storage[:lock]=false
lock=()->storage[:lock]=!storage[:lock]
storage[:np]=3 #numplayers
np=(n)->storage[:np]=n
storage[:layers]=6 #shells
storage[:window]=(900,700)
storage[:sizemod]=9
storage[:size]=storage[:window][2]/(storage[:layers]*storage[:sizemod]) #overwritten by draw
storage[:offsetx]=0
storage[:offsety]=0
storage[:sequence]=Array{Tuple,1}()
storage[:delete]=false
delete=()->storage[:delete]=!storage[:delete]

storage[:spacing]=10
storage[:onlylayer]=2 #disable hi/lo moves, 0 to disable the disabling.
storage[:printscore]=true

backgroundcolor=[0,0,0]
gridcolor=[1,1,1]
=#

include("be.jl")
using Gtk, Graphics
#c=@GtkCanvas()
#win=GtkWindow(c, "Weilianqi",900,700)
#storage[:ctx]=getgc(c)

type Unit
	color
	ir #influence radius
	pl #permitted layers
end
type Board
	shells::Integer #layers of locations to add to the initial ones
	initlocs #initial locations
	grid
	c #GtkCanvas
	win #GtkWindow
	window #initial aspect ratio
	sizemod #zoom
	size
	offsetx #pan
	offsety
	bgcolor #background
	gridcolor
end
type Game
	map
	unitparams #to be placed
	color 
	colors
	colind::Integer #index
	colmax::Integer #return to first color after max
	colock::Bool #place a single color
	delete::Bool #delete units
	sequence::Array #placed units
	board::Board
	printscore::Bool
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
function drawboard(game,ctx,w,h)
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
			arc(ctx, loc[1]+offset[1]+w/2, loc[2]+offset[2]+h/2, size/3, 0, 2pi)
			fill(ctx)
			#set_source_rgb(ctx,game.board.gridcolor...)
			#arc(ctx, loc[1]+offset[1]+w/2, loc[2]+offset[2]+h/2, size/3, 0, 2pi)
			#stroke(ctx)
		end
	end
end
function drawboard(game::Game)
	ctx=getgc(game.board.c)
	h=height(game.board.c)
	w=width(game.board.c)
	drawboard(game,ctx,w,h)
end


function newunit(color=(1,0,0),ir=3,pl=[2])
	return Unit(color,ir,pl)
end
function newboard(shells=6,initlocs=[(0,0,2)],grid=0,c=@GtkCanvas(),win=0,window=(900,700),sizemod=5,size=30,offsetx=0,offsety=0,bgcolor=(0,0,0),gridcolor=(1,1,1))
	if grid==0
		grid=makegrid(shells,initlocs)
	end
	if win==0
		win=GtkWindow(c, "Weilianqi",window[1],window[2])
	end
	board=Board(shells,initlocs,grid,c,win,window,sizemod,size,offsetx,offsety,bgcolor,gridcolor)
	return board
end
function allowedat(unitparams,loc)
	yes=true
	if !in(loc[3],unitparams[3])
		yes=false
	end
	return yes
end
function newgame(boardparams=[],unitparams=[(1,0,0),3,[2]],map=Dict(),unit=0,color=(1,0,0),colors=[(1,0,0),(0,1,0),(0,0,1),(1,1,1)],colind=1,colmax=3,colock=false,delete=false,sequence=[((0,0,2),Unit((1,1,1),3,[2]))],board=0,printscore=false)
	if board==0
		board=newboard(boardparams...)
	end
	for loc in board.grid
		map[loc]=0
	end
	game=Game(map,unitparams,color,colors,colind,colmax,colock,delete,sequence,board,printscore)
	placeseq(game.sequence,game.map)
	@guarded function drawsignal(widget)
		ctx=getgc(widget)
		h=height(widget)
		w=width(widget)
		game.board.window=(w,h)
		game.board.size=game.board.window[2]/(game.board.shells*game.board.sizemod)
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
					nu=newunit(game.unitparams...)
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
			end
		end
		drawboard(game,ctx,w,h)
		reveal(widget)
	end
	show(game.board.c)
	return game
end


#=
initgame([(0,0,2),(6,6,2)])
if storage[:printscore]
	printscore()
end
@guarded draw(c) do widget
    ctx = getgc(c)
    h = height(c)
    w = width(c)
	storage[:window]=(w,h)
	storage[:size]=storage[:window][2]/(storage[:layers]*storage[:sizemod])
    
	set_source_rgb(ctx,0,0,0)
	size=storage[:size]
	drawboard(ctx,w,h)
end


@guarded function drawsignal(widget)
	    ctx = getgc(widget)
    h = height(widget)
    w = width(widget)
	storage[:window]=(w,h)
	storage[:size]=storage[:window][2]/(storage[:layers]*storage[:sizemod])
    
	set_source_rgb(ctx,0,0,0)
	size=storage[:size]
	drawboard(ctx,w,h)
end
draw(drawsignal,c)


c.mouse.button1press = @guarded (widget, event) -> begin
    ctx = getgc(widget)

	h = height(c)
	w = width(c)
	size=storage[:size]
	q,r=pixel_to_hex(event.x-w/2-storage[:offsetx],event.y-h/2-storage[:offsety])
	maindiff=abs(round(q)-q)+abs(round(r)-r)
	qup,rup=pixel_to_hex(event.x-w/2+size*cos(pi/6),event.y-h/2+sin(pi/6)*size)
	updiff=abs(round(qup)-qup)+abs(round(rup)-rup)
	qdown,rdown=pixel_to_hex(event.x-w/2+size*cos(pi/6),event.y-h/2-sin(pi/6)*size)
	downdiff=abs(round(qdown)-qdown)+abs(round(rdown)-rdown)
	best=findmin([maindiff,updiff,downdiff])[2]
	hex=[(round(Int,q),round(Int,r),2),(round(Int,qup),round(Int,rup),3),(round(Int,qdown),round(Int,rdown),1)][best]
	if storage[:onlylayer]==0 || storage[:onlylayer]==hex[3]
		exists=in(hex,keys(storage[:map]))
		if exists
			if storage[:delete]==true && storage[:map][hex]!=0
				storage[:map][hex]=0
				push!(storage[:sequence],(hex,0))
			elseif storage[:map][hex]==0
				storage[:map][hex]=storage[:player]
				push!(storage[:sequence],(hex,storage[:player]))
				hs=adjacent(hex)
				push!(hs,hex)
				for he in hs
					if in(he,keys(storage[:map]))
						g=getgroup(he)
						if !isempty(g) && liberties(g)==0
							for gh in g
								storage[:map][gh]=0
							end
						end
					end
				end
				if !storage[:lock]
					storage[:player]=storage[:player]%storage[:np]+1
				end
			end
			if storage[:printscore]
				printscore()
			end
		end
	end
#	println((event.x-w/2,event.y-h/2),',',["main","up","down"][best])
	drawboard(ctx,w,h)
	reveal(widget)
end
show(c)
=#
