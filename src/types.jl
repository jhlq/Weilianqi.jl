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
	harvested::Bool
	graphic::Array #of vertices (x,y) where x is distance in radians from origin
	extra #for arbitrary functionality
end
type Group
	spawns
	body
	units
	#lifmap
	points
	#allowdebt::Bool
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
	expandbasecost::Number
end
type Game
	name::String
	map
	groups
	spawns
	units
	unitparams #to be placed
	color 
	colors
	colind::Integer #index
	colmax::Integer #return to first color after max
	colock::Bool #place a single color
	delete::Bool #delete units
	sequence::Array{Any} #Tuple{Tuple{Int64,Int64,Int64},Any},1} #placed units and performed harvests/expands
	board::Board
	printscore::Bool
	points #not used anymore
	season::Integer #number of harvests
	win #GtkWindow
	window #initial aspect ratio
	lifemap #deprecated
	g #GtkGrid
	gui::Dict #Gtk placeholder
	autoharvest::Bool #costs have been removed so no longer relevant, return to the source
end
