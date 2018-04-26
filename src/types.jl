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
end
type Group
	spawns
	units
	#lifmap
	points
	allowdebt::Bool
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
	points
	season::Integer #number of harvests
	win #GtkWindow
	window #initial aspect ratio
	lifemap
	g #GtkGrid
	gui::Dict #Gtk placeholder
	autoharvest::Bool
end
