type Unit
	color
	ir::Integer #influence radius
	pl::Array{Int,1} #permitted layers
	passover::Bool
	passoverself::Bool
	inclusive::Bool
	loc
	groundlevel::Bool
	live!::Function
	baselife::Number
	harvest::Function
	name::String
	costfun::Function
	canspawn::Bool
	harvested
	graphic::Array #of vertices (x,y) where x is distance in radians from origin
	extra #for arbitrary functionality, define your own units and add them to units in units.jl
end
type Group
	spawns
	body
	units
	#lifmap #I want this
	points
	#allowdebt::Bool #should require sudo password irl, finally got that degree because of pressure from society and now you want to relax to get the creative juices going? Well tough luck, into the hamsterwheel, slave! For being self-proclaimed planetary rulers humen don't seem to have all that much time, baboons can be more with their children. But hey, they have money, gotta give em that, they cut down the trees they need to breathe and caused the largest mass extinction since the dinosaurs to play a game of who has most...
	harvested::Bool
end
type Board
	shells::Integer #layers of locations to add to the initial ones
	initlocs #initial locations
	grid
	c #GtkCanvas
	sizemod::Number #zoom
	size::Number
	offsetx::Number 
	offsety::Number
	panx::Number 
	pany::Number
	bgcolor #background
	gridcolor
	#expandbasecost::Number #deprecated because creating new land where our units can live free is not something that should be hindered... You want to make more baby units then go right ahead, we will even help you!
end
type Game
	name::String #defaults to a timestamp, a good name makes Game feel special and unique
	map #add locations here without changing board.grid to go offgrid!
	groups #units like grouping around babymakers
	spawns #units that can make babies
	units #All units!
	unitparams #for unit to be placed, this is just a string in an array now...
	color #(r,g,b), do not let r+g+b exceed 1, unless you want superpowered units
	colors
	colind::Integer #index of colors -> color
	colmax::Integer #return to first color after max
	colock::Bool #place a single color
	delete::Bool #delete units (by clicking on them)
	sequence::Array{Any} #placed units and performed (harvests/)expands/deletions
	board::Board #changing this after game is initialized causes segfaults
	printscore::Bool #who needs dis when we 'ave fancy labels
	points #not used anymore
	season::Integer #number of harvests, seasons and harvests will become relevant again in phase 2
	win #GtkWindow
	window #initial aspect ratio, funnily named...
	lifemap #deprecated. No! Reprecated
	g #GtkGrid
	gui::Dict #Gtk placeholder
	autoharvest::Bool #costs have been removed so no longer relevant, return to the source
end
