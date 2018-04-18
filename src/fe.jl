include("be.jl")

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

using Gtk, Graphics
c = @GtkCanvas()
win = GtkWindow(c, "Weilianqi",storage[:window][1],storage[:window][2])
#storage[:ctx]=getgc(c)


initgame([(0,0,2),(6,6,2)])

function hex_to_pixel(q,r,size=storage[:size])
    x = size * sqrt(3) * (q + r/2)
    y = size * 3/2 * r
    return x, y
end
function pixel_to_hex(x, y, size=storage[:size])
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
function drawboard(ctx,w,h)
	size=storage[:size]
	rectangle(ctx, 0, 0, w, h)
	set_source_rgb(ctx, backgroundcolor...)
	fill(ctx)
	set_source_rgb(ctx, storage[:players][storage[:player]]...)
	arc(ctx, size, size, 3size, 0, 2pi)
	fill(ctx)
	set_source_rgb(ctx, gridcolor...)
	for loc in storage[:grid]
		if loc[3]==2
			x,y=hex_to_pixel(loc[1],loc[2],size)
			hexlines(ctx,x+w/2+storage[:offsetx],y+h/2+storage[:offsety],size)
		end
	end
	for move in storage[:map]
		if move[2]>0
			set_source_rgb(ctx, storage[:players][move[2]]...)
			offset=(storage[:offsetx],storage[:offsety])
			if move[1][3]==1
				offset=(-cos(pi/6)*size+storage[:offsetx],sin(pi/6)*size+storage[:offsety])
			elseif move[1][3]==3
				offset=(-cos(pi/6)*size+storage[:offsetx],-sin(pi/6)*size+storage[:offsety])
			end
			loc=hex_to_pixel(move[1][1],move[1][2])
			#println(loc)
			arc(ctx, loc[1]+offset[1]+w/2, loc[2]+offset[2]+h/2, size/3, 0, 2pi)
			fill(ctx)
			set_source_rgb(ctx,gridcolor...)
			#arc(ctx, loc[1]+offset[1]+w/2, loc[2]+offset[2]+h/2, size/3, 0, 2pi)
			#stroke(ctx)
		end
	end
end

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
